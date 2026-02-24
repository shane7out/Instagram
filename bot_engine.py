"""
Las Vegas Food Curator - Core Bot Engine
Handles Instagram authentication, content discovery, and posting
"""

import os
import logging
import time
import random
from datetime import datetime, timedelta
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
    init_database, Creator, MediaItem, AppSettings, 
    CreatorStatus, MediaStatus, get_or_create_creator
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


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
        
    def init_db(self, db_path="lasvegas_restaurants.db"):
        """Initialize database connection"""
        self.db_session = init_database(db_path)
        logger.info("Database initialized")
        
    def set_video_processor(self, processor):
        """Set video processor"""
        self.video_processor = processor
    
    def save_session(self):
        """Save Instagram session to file"""
        session_file = f"{self.session_name}_session.json"
        self.client.dump_settings(session_file)
        logger.info(f"Session saved to {session_file}")
        
    def load_session(self):
        """Load Instagram session from file"""
        session_file = f"{self.session_name}_session.json"
        if os.path.exists(session_file):
            self.client.load_settings(session_file)
            logger.info(f"Session loaded from {session_file}")
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
        except Exception as e:
            logger.error(f"Failed to get user info for {username}: {e}")
            return None
    
    def get_engagement_rate(self, username):
        """Calculate engagement rate for a user"""
        try:
            # Get recent media
            medias = self.client.user_medias(username, amount=10)
            
            if not medias:
                return 0
            
            # Calculate average engagement
            total_likes = 0
            total_comments = 0
            
            for media in medias:
                total_likes += media.like_count
                total_comments += media.comment_count
            
            avg_likes = total_likes / len(medias)
            avg_comments = total_comments / len(medias)
            
            # Get follower count
            user_info = self.get_user_info(username)
            if not user_info or user_info['followers_count'] == 0:
                return 0
            
            followers = user_info['followers_count']
            engagement_rate = ((avg_likes + avg_comments) / followers) * 100
            
            return round(engagement_rate, 2)
            
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
        
        # Scan hashtags
        for hashtag in hashtags:
            try:
                logger.info(f"Scanning hashtag: #{hashtag}")
                
                # Get hashtag media
                medias = self.client.hashtag_medias(hashtag, amount=max_results)
                
                for media in medias:
                    # Filter: only videos
                    if media.media_type != 2:  # 2 = video
                        continue
                    
                    # Get creator info
                    creator_username = media.user.username
                    
                    # Skip if already in database
                    existing = self.db_session.query(MediaItem).filter_by(
                        original_media_pk=media.pk
                    ).first()
                    if existing:
                        continue
                    
                    # Get creator details
                    user_info = self.get_user_info(creator_username)
                    if not user_info:
                        continue
                    
                    # Skip private accounts
                    if user_info['is_private']:
                        logger.info(f"Skipping private account: {creator_username}")
                        continue
                    
                    # Filter by follower count
                    if user_info['followers_count'] < min_followers:
                        continue
                    
                    # Get engagement rate
                    engagement_rate = self.get_engagement_rate(creator_username)
                    
                    # Filter by engagement rate
                    if engagement_rate < self.min_engagement_rate:
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
                        hashtags=','.join([h.tag for h in media.hashtags]) if hasattr(media, 'hashtags') else '',
                        mentions=','.join([m.tag for h in media.usertags]) if hasattr(media, 'usertags') else '',
                        status=MediaStatus.PENDING_APPROVAL
                    )
                    
                    self.db_session.add(media_item)
                    discovered.append(media_item)
                    
                    logger.info(f"Discovered: {media.code} by @{creator_username}")
                    
                    # Rate limiting
                    time.sleep(random.uniform(2, 5))
                    
                self.db_session.commit()
                
            except Exception as e:
                logger.error(f"Error scanning hashtag {hashtag}: {e}")
                self.db_session.rollback()
                continue
        
        logger.info(f"Discovery complete. Found {len(discovered)} new items")
        return discovered
    
    def download_media(self, media_item):
        """Download media to local storage"""
        try:
            # Ensure downloads directory exists
            downloads_dir = Path("downloads")
            downloads_dir.mkdir(exist_ok=True)
            
            filename = f"{media_item.code}.mp4"
            output_path = downloads_dir / filename
            
            # Download video
            self.client.media_download(media_item.original_media_pk, output_path)
            
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
            if self.actions_today >= self.daily_action_limit:
                raise Exception("Daily action limit reached")
            
            # Upload to story
            story_id = self.client.story_upload(
                video_path,
                caption=caption or f"📸 Credit: @{creator_username}"
            )
            
            self.actions_today += 1
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
        creator = self.db_session.query(Creator).get(creator_id)
        if creator:
            creator.status = status
            self.db_session.commit()
            logger.info(f"Updated creator {creator.username} to {status.value}")
    
    def reject_media(self, media_id):
        """Reject media item"""
        media = self.db_session.query(MediaItem).get(media_id)
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
        media = self.db_session.query(MediaItem).get(media_id)
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
            self.db_session.commit()
            
            logger.info(f"Published media {media.code} to stories")
            return story_id
            
        except Exception as e:
            media.status = MediaStatus.FAILED
            media.error_message = str(e)
            self.db_session.commit()
            raise
    
    def reset_daily_counter(self):
        """Reset daily action counter"""
        self.actions_today = 0


def create_bot(config=None):
    """Factory function to create and configure bot"""
    bot = InstagramBot()
    
    if config:
        bot.min_followers = config.get('min_followers', 1000)
        bot.min_engagement_rate = config.get('min_engagement_rate', 2.0)
        bot.max_results_per_hashtag = config.get('max_results', 20)
        bot.daily_action_limit = config.get('daily_limit', 50)
    
    return bot
