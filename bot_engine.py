"""
Las Vegas Food Curator - Core Bot Engine
Handles Instagram authentication, content discovery, and posting
"""

import os
import json
import logging
import re
import time
import random
from datetime import date, datetime, timedelta
from pathlib import Path
from instagrapi import Client
from instagrapi.exceptions import (
    ChallengeRequired, 
    TwoFactorRequired,
    ClientError,
    ClientLoginRequired,
    BadPassword,
    LoginRequired
)
import requests

from database_models import (
    init_database, Creator, MediaItem, AppSettings, PostLog,
    CreatorStatus, MediaStatus, get_or_create_creator
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

HASHTAG_RE = re.compile(r'#(\w+)')

# Exceptions that mean this code is wrong, as opposed to the network or
# Instagram being temporarily unhappy. These are never swallowed: silently
# absorbing an AttributeError is what let three calls to nonexistent client
# methods report "0 items found" for months instead of failing.
BUG_EXCEPTIONS = (
    AttributeError,
    TypeError,
    NameError,
    ImportError,
    IndexError,
    KeyError,
)


def extract_hashtags(caption):
    """Pull hashtags out of a caption. Media objects carry no hashtag field."""
    if not caption:
        return []
    return HASHTAG_RE.findall(caption)


class InstagramBot:
    """Main Instagram automation bot"""
    
    # Default hashtags to scan for Las Vegas food content
    DEFAULT_HASHTAGS = [
        'lasvegasfood',
        'vegaseats', 
        'lasvegasdining',
        'lasvegasrestaurants',
        'vegasfoodie',
        'vegasfood',
        'lasvegaseats',
        'vegasrestaurants',
        'lasvegasfoodie',
        'vegasdining'
    ]
    
    # Default locations (Las Vegas)
    DEFAULT_LOCATIONS = [
        'Las Vegas Strip',
        'Downtown Las Vegas',
        'Las Vegas',
        'Bellagio',
        'MGM Grand',
        'Caesars Palace'
    ]
    
    # app_settings keys backing the persisted daily post counter
    ACTIONS_COUNT_KEY = 'actions_today'
    ACTIONS_DATE_KEY = 'actions_date'

    def __init__(self, session_name="lasvegas_restaurants"):
        self.session_name = session_name
        self.client = Client()
        self.db_session = None
        self.video_processor = None
        
        # Settings
        self.min_followers = 1000
        self.min_engagement_rate = 2.0  # 2%
        self.max_results_per_hashtag = 20
        self.rate_limit_delay = 30  # seconds between requests
        
        # Track actions for rate limiting
        self.actions_today = 0
        self.daily_action_limit = 50

        # Rejection breakdown from the most recent discover_content() call
        self.last_discovery_stats = {}
        
    def init_db(self, db_path="lasvegas_restaurants.db"):
        """Initialize database connection"""
        self.db_session = init_database(db_path)
        logger.info("Database initialized")
        
    def set_video_processor(self, processor):
        """Set video processor"""
        self.video_processor = processor
    
    @property
    def _session_key(self):
        return f"session:{self.session_name}"

    @property
    def _session_file(self):
        return f"{self.session_name}_session.json"

    def save_session(self):
        """
        Persist the Instagram session.

        Stored in the database when one is available, because Railway's disk is
        ephemeral: a file-based session is discarded on every redeploy, so the
        bot logs in cold each time. Repeated fresh logins from a datacenter IP
        are a reliable way to get an account challenged or restricted.

        Falls back to a file when there is no database, which keeps local
        single-process use working unchanged.
        """
        if self.db_session:
            self._set_setting(self._session_key, json.dumps(self.client.get_settings()))
            logger.info("Session saved to database")
            return

        self.client.dump_settings(self._session_file)
        logger.info(f"Session saved to {self._session_file}")

    def load_session(self):
        """Restore a saved session. Returns True if one was found and applied."""
        stored = self._get_setting(self._session_key) if self.db_session else None

        if stored:
            try:
                self.client.set_settings(json.loads(stored))
                logger.info("Session loaded from database")
                return True
            except (ValueError, TypeError) as e:
                logger.warning(f"Stored session is unusable, ignoring it: {e}")

        # Fall back to a session file, migrating it into the database so the
        # next redeploy does not lose it
        if os.path.exists(self._session_file):
            self.client.load_settings(self._session_file)
            logger.info(f"Session loaded from {self._session_file}")

            if self.db_session:
                self.save_session()
                logger.info("Migrated on-disk session into the database")

            return True

        return False
    
    def login(self, username, password):
        """
        Login to Instagram
        
        Args:
            username: Instagram username
            password: Instagram password
            
        Returns:
            True if successful
        """
        try:
            # Try to load existing session
            if self.load_session():
                # Verify session is still valid
                try:
                    self.client.user_info_by_username(username)
                    logger.info("Reconnected using existing session")
                    return True
                except:
                    logger.info("Existing session expired, logging in again")
            
            # Login with credentials
            self.client.login(username, password)
            self.save_session()
            logger.info(f"Successfully logged in as {username}")
            return True
            
        except TwoFactorRequired as e:
            logger.error("Two-factor authentication required")
            raise Exception("Two-factor authentication required. Please provide the code.")
            
        except ChallengeRequired as e:
            logger.error("Instagram challenge required")
            raise Exception("Instagram challenge required. Please verify your identity.")
            
        except BadPassword as e:
            logger.error(f"Login failed: {e}")
            raise Exception(f"Login failed: {e}")
            
        except Exception as e:
            logger.error(f"Unexpected login error: {e}")
            raise
    
    def logout(self):
        """Logout from Instagram"""
        try:
            self.client.logout()
            logger.info("Logged out successfully")
        except:
            pass
    
    def get_user_info(self, username):
        """Get user information"""
        try:
            user = self.client.user_info_by_username(username)
            return {
                'pk': user.pk,
                'username': user.username,
                'full_name': user.full_name,
                'followers_count': user.follower_count,
                'following_count': user.following_count,
                'media_count': user.media_count,
                'is_private': user.is_private,
                'public_email': user.public_email
            }
        except BUG_EXCEPTIONS:
            raise
        except Exception as e:
            logger.error(f"Failed to get user info for {username}: {e}")
            return None
    
    def get_engagement_rate(self, username, user_info=None):
        """
        Calculate engagement rate for a user

        Args:
            username: Instagram username
            user_info: Optional pre-fetched get_user_info() result, to avoid a
                       second profile lookup during discovery

        Returns:
            Engagement rate as a percentage, or 0 if it cannot be determined
        """
        try:
            if user_info is None:
                user_info = self.get_user_info(username)

            if not user_info or not user_info['followers_count']:
                return 0

            # user_medias takes the numeric user pk, not the username
            medias = self.client.user_medias(user_info['pk'], amount=10)

            if not medias:
                return 0

            # Calculate average engagement
            total_likes = 0
            total_comments = 0

            for media in medias:
                total_likes += media.like_count or 0
                total_comments += media.comment_count or 0

            avg_likes = total_likes / len(medias)
            avg_comments = total_comments / len(medias)

            followers = user_info['followers_count']
            engagement_rate = ((avg_likes + avg_comments) / followers) * 100

            return round(engagement_rate, 2)

        except BUG_EXCEPTIONS:
            raise
        except Exception as e:
            logger.error(f"Failed to calculate engagement rate for {username}: {e}")
            return 0
    
    def discover_content(self, hashtags=None, locations=None, min_followers=None, max_results=None):
        """
        Discover content from hashtags and locations
        
        Args:
            hashtags: List of hashtags to scan
            locations: List of locations to scan
            min_followers: Minimum follower count
            max_results: Maximum results per source
            
        Returns:
            List of discovered media items
        """
        if hashtags is None:
            hashtags = self.DEFAULT_HASHTAGS
        if locations is None:
            locations = self.DEFAULT_LOCATIONS
        if min_followers is None:
            min_followers = self.min_followers
        if max_results is None:
            max_results = self.max_results_per_hashtag
        
        discovered = []

        # Why candidates were dropped. Without this a scan that finds nothing
        # is indistinguishable from a scan that is broken - both just report 0.
        stats = {
            'candidates': 0,
            'not_video': 0,
            'already_known': 0,
            'no_profile': 0,
            'private': 0,
            'low_followers': 0,
            'low_engagement': 0,
            'accepted': 0,
            'hashtags_failed': 0,
        }

        # Scan hashtags
        for hashtag in hashtags:
            try:
                logger.info(f"Scanning hashtag: #{hashtag}")

                # Get hashtag media
                medias = self.client.hashtag_medias_recent(hashtag, amount=max_results)

                stats['candidates'] += len(medias)

                for media in medias:
                    # Filter: only videos
                    if media.media_type != 2:  # 2 = video
                        stats['not_video'] += 1
                        continue

                    # Get creator info
                    creator_username = media.user.username

                    # Skip if already in database
                    existing = self.db_session.query(MediaItem).filter_by(
                        original_media_pk=media.pk
                    ).first()
                    if existing:
                        stats['already_known'] += 1
                        continue

                    # Get creator details
                    user_info = self.get_user_info(creator_username)
                    if not user_info:
                        stats['no_profile'] += 1
                        continue

                    # Skip private accounts
                    if user_info['is_private']:
                        stats['private'] += 1
                        logger.info(f"Skipping private account: {creator_username}")
                        continue

                    # Filter by follower count
                    if user_info['followers_count'] < min_followers:
                        stats['low_followers'] += 1
                        continue

                    # Get engagement rate (reuses user_info, no extra lookup)
                    engagement_rate = self.get_engagement_rate(
                        creator_username, user_info=user_info
                    )

                    # Filter by engagement rate
                    if engagement_rate < self.min_engagement_rate:
                        stats['low_engagement'] += 1
                        continue

                    # Get or create creator
                    creator = get_or_create_creator(
                        self.db_session,
                        username=creator_username,
                        instagram_pk=user_info['pk'],
                        full_name=user_info['full_name'],
                        follower_count=user_info['followers_count'],
                        following_count=user_info['following_count'],
                        media_count=user_info['media_count'],
                        avg_engagement=engagement_rate
                    )
                    
                    # Create media item
                    media_item = MediaItem(
                        original_media_pk=media.pk,
                        code=media.code,
                        creator_id=creator.id,
                        media_type='video' if media.media_type == 2 else 'reel',
                        caption=media.caption_text if media.caption_text else '',
                        like_count=media.like_count,
                        comment_count=media.comment_count,
                        view_count=getattr(media, 'view_count', 0),
                        hashtags=','.join(extract_hashtags(media.caption_text)),
                        mentions=','.join(
                            t.user.username for t in (media.usertags or []) if t.user
                        ),
                        status=MediaStatus.PENDING_APPROVAL
                    )
                    
                    self.db_session.add(media_item)
                    discovered.append(media_item)
                    stats['accepted'] += 1

                    logger.info(f"Discovered: {media.code} by @{creator_username}")

                    # Rate limiting
                    time.sleep(random.uniform(2, 5))

                self.db_session.commit()

            except BUG_EXCEPTIONS:
                # A bug in this code. Fail loudly rather than logging it as if
                # Instagram were at fault.
                self.db_session.rollback()
                raise

            except Exception as e:
                stats['hashtags_failed'] += 1
                logger.error(f"Error scanning hashtag {hashtag}: {e}")
                self.db_session.rollback()
                continue

        self.last_discovery_stats = stats
        self._log_discovery_stats(stats, hashtags, min_followers)

        return discovered

    def _log_discovery_stats(self, stats, hashtags, min_followers):
        """Report what a scan actually did, including why candidates were dropped"""
        logger.info(
            "Discovery complete: %d accepted from %d candidates across %d hashtags",
            stats['accepted'], stats['candidates'], len(hashtags)
        )
        logger.info(
            "  rejected: %d not video, %d already known, %d no profile, "
            "%d private, %d under %d followers, %d under %.1f%% engagement",
            stats['not_video'], stats['already_known'], stats['no_profile'],
            stats['private'], stats['low_followers'], min_followers,
            stats['low_engagement'], self.min_engagement_rate
        )

        if stats['hashtags_failed']:
            logger.warning(
                "%d of %d hashtags failed to scan - see errors above",
                stats['hashtags_failed'], len(hashtags)
            )

        # The two cases worth shouting about, because both previously looked
        # identical to a normal quiet scan
        if stats['candidates'] == 0:
            logger.warning(
                "No media returned for ANY hashtag. That is not a normal quiet "
                "scan - check credentials, rate limiting, or whether the hashtag "
                "endpoint has changed."
            )
        elif stats['accepted'] == 0:
            logger.warning(
                "%d candidates and none accepted. If this repeats, the filters "
                "are probably tuned too tight - see the rejection breakdown above.",
                stats['candidates']
            )
    
    def download_media(self, media_item):
        """Download media to local storage"""
        try:
            # Ensure downloads directory exists
            downloads_dir = Path("downloads")
            downloads_dir.mkdir(exist_ok=True)
            
            # video_download takes a destination folder and returns the path
            # it wrote, naming the file itself
            output_path = self.client.video_download(
                int(media_item.original_media_pk),
                folder=downloads_dir
            )

            # Update database
            media_item.file_path = str(output_path)
            self.db_session.commit()
            
            logger.info(f"Downloaded: {media_item.code}")
            return str(output_path)
            
        except Exception as e:
            logger.error(f"Failed to download {media_item.code}: {e}")
            media_item.status = MediaStatus.FAILED
            media_item.error_message = str(e)
            self.db_session.commit()
            raise
    
    def post_to_story(self, video_path, creator_username, caption=None):
        """
        Post video to Instagram Stories
        
        Args:
            video_path: Path to video file
            creator_username: Username to credit
            caption: Optional caption
            
        Returns:
            Story ID if successful
        """
        try:
            # Check daily limit
            if self.get_actions_today() >= self.daily_action_limit:
                raise Exception("Daily action limit reached")
            
            # Upload to story
            story = self.client.video_upload_to_story(
                Path(video_path),
                caption=caption or f"📸 Credit: @{creator_username}"
            )
            story_id = str(story.pk)

            self._record_action()
            logger.info(f"Posted story: {story_id}")

            return story_id
            
        except ClientError as e:
            logger.error(f"Client error posting story: {e}")
            raise
            
        except Exception as e:
            logger.error(f"Failed to post story: {e}")
            raise
    
    def get_pending_content(self):
        """Get all content pending approval"""
        return self.db_session.query(MediaItem).filter(
            MediaItem.status == MediaStatus.PENDING_APPROVAL
        ).order_by(MediaItem.date_discovered.desc()).all()
    
    def get_published_content(self):
        """Get all published content"""
        return self.db_session.query(MediaItem).filter(
            MediaItem.status == MediaStatus.PUBLISHED
        ).order_by(MediaItem.date_published.desc()).all()
    
    def get_creators(self, status=None):
        """Get creators, optionally filtered by status"""
        query = self.db_session.query(Creator)
        if status:
            query = query.filter(Creator.status == status)
        return query.order_by(Creator.follower_count.desc()).all()
    
    def approve_creator(self, creator_id, status=CreatorStatus.APPROVED):
        """Update creator status"""
        creator = self.db_session.get(Creator, creator_id)
        if creator:
            creator.status = status
            self.db_session.commit()
            logger.info(f"Updated creator {creator.username} to {status.value}")
    
    def reject_media(self, media_id):
        """Reject media item"""
        media = self.db_session.get(MediaItem, media_id)
        if media:
            media.status = MediaStatus.REJECTED
            self.db_session.commit()
            logger.info(f"Rejected media {media.code}")
    
    def publish_media(self, media_id, process_video=True):
        """
        Process and publish media to stories
        
        Args:
            media_id: Database ID of media item
            process_video: Whether to process video (add attribution)
            
        Returns:
            Story ID if successful
        """
        media = self.db_session.get(MediaItem, media_id)
        if not media:
            raise Exception("Media not found")
        
        try:
            # Update status
            media.status = MediaStatus.PROCESSING
            self.db_session.commit()
            
            # Download if not already
            if not media.file_path or not os.path.exists(media.file_path):
                self.download_media(media)
            
            # Process video if requested
            if process_video and self.video_processor:
                creator = media.creator
                output_filename = f"story_{media.code}.mp4"
                processed_path = self.video_processor.process_video(
                    media.file_path,
                    creator.username,
                    output_filename
                )
            else:
                processed_path = media.file_path
            
            # Post to story
            caption = f"📸 Credit: @{media.creator.username}\n\n{media.caption[:100]}..."
            story_id = self.post_to_story(processed_path, media.creator.username, caption)
            
            # Update status
            media.status = MediaStatus.PUBLISHED
            media.date_published = datetime.utcnow()
            self.db_session.add(PostLog(
                media_id=media.id,
                story_id=story_id,
                success=1
            ))
            self.db_session.commit()

            logger.info(f"Published media {media.code} to stories")
            return story_id

        except Exception as e:
            media.status = MediaStatus.FAILED
            media.error_message = str(e)
            self.db_session.add(PostLog(
                media_id=media.id,
                success=0,
                error_message=str(e)
            ))
            self.db_session.commit()
            raise
    
    def _get_setting(self, key, default=None):
        """Read a value from app_settings"""
        if not self.db_session:
            return default
        row = self.db_session.query(AppSettings).filter_by(key=key).first()
        return row.value if row else default

    def _set_setting(self, key, value):
        """Write a value to app_settings"""
        if not self.db_session:
            return
        row = self.db_session.query(AppSettings).filter_by(key=key).first()
        if row:
            row.value = str(value)
        else:
            self.db_session.add(AppSettings(key=key, value=str(value)))
        self.db_session.commit()

    def get_actions_today(self):
        """
        Posts made today, counting against daily_action_limit.

        Persisted in app_settings rather than held in memory so the cap still
        applies after a worker restart, and so it rolls over on a date change
        without anything needing to call reset_daily_counter().
        """
        if not self.db_session:
            return self.actions_today

        if self._get_setting(self.ACTIONS_DATE_KEY) != date.today().isoformat():
            return 0

        try:
            self.actions_today = int(self._get_setting(self.ACTIONS_COUNT_KEY, 0))
        except (TypeError, ValueError):
            self.actions_today = 0

        return self.actions_today

    def _record_action(self):
        """Count one post against today's limit and persist it"""
        count = self.get_actions_today() + 1
        self.actions_today = count
        self._set_setting(self.ACTIONS_COUNT_KEY, count)
        self._set_setting(self.ACTIONS_DATE_KEY, date.today().isoformat())

    def reset_daily_counter(self):
        """Reset daily action counter"""
        self.actions_today = 0
        self._set_setting(self.ACTIONS_COUNT_KEY, 0)
        self._set_setting(self.ACTIONS_DATE_KEY, date.today().isoformat())


def create_bot(config=None):
    """Factory function to create and configure bot"""
    bot = InstagramBot()
    
    if config:
        bot.min_followers = config.get('min_followers', 1000)
        bot.min_engagement_rate = config.get('min_engagement_rate', 2.0)
        bot.max_results_per_hashtag = config.get('max_results', 20)
        bot.daily_action_limit = config.get('daily_limit', 50)
    
    return bot
