"""
Las Vegas Food Curator - Bot Worker
Runs the Instagram bot as a background service for scheduled discovery
"""

import os
import sys
import logging
import time
import uuid
from datetime import datetime
from pathlib import Path

# Setup logging to stdout (Railway needs this)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)


def publish_approved(bot):
    """
    Publish everything approved in the dashboard.

    The dashboard marks items READY and never talks to Instagram itself, so
    this is the only place Stories get posted.
    """
    try:
        approved = bot.get_approved_content()
    except Exception as e:
        logger.error(f"Could not read the approval queue: {e}")
        return 0

    published = 0
    for index, item in enumerate(approved):
        # Stop before the cap rather than letting publish_media fail on it.
        # Hitting the limit mid-loop would mark perfectly good items FAILED,
        # permanently, when all they need is to wait until tomorrow.
        if bot.get_actions_today() >= bot.daily_action_limit:
            logger.info(
                "Daily post limit reached, leaving %d item(s) queued for tomorrow",
                len(approved) - index
            )
            break

        try:
            story_id = bot.publish_media(item.id)
            logger.info(f"Published {item.code} -> story {story_id}")
            published += 1
        except Exception as e:
            logger.error(f"Failed to publish {item.code}: {e}")

    return published


def wait_for_next_cycle(bot, scan_interval_hours, poll_seconds=60):
    """
    Wait out the scan interval without going deaf to the dashboard.

    Sleeping the full interval in one call would leave an approval sitting for
    up to six hours, so this wakes periodically to publish approved items and
    returns early when a scan has been requested.
    """
    deadline = time.monotonic() + scan_interval_hours * 3600

    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return

        time.sleep(min(poll_seconds, remaining))

        try:
            if bot.consume_scan_request():
                logger.info("Discovery scan requested from the dashboard")
                return
        except Exception as e:
            logger.error(f"Could not check for a scan request: {e}")

        publish_approved(bot)


def main():
    """Main worker loop"""
    from bot_engine import create_bot, BUG_EXCEPTIONS
    from video_utils import VideoProcessor
    from database_models import init_database
    
    logger.info("=" * 50)
    logger.info("Las Vegas Food Curator - Bot Worker")
    logger.info("=" * 50)
    
    # Initialize
    logger.info("Initializing bot...")
    bot = create_bot()
    bot.init_db()
    bot.set_video_processor(VideoProcessor())
    
    # Get credentials from environment (Railway or local)
    username = os.environ.get("INSTAGRAM_USERNAME") or os.getenv("INSTAGRAM_USERNAME")
    password = os.environ.get("INSTAGRAM_PASSWORD") or os.getenv("INSTAGRAM_PASSWORD")
    
    logger.info(f"Username found: {bool(username)}")
    logger.info(f"Password found: {bool(password)}")
    
    if not username or not password:
        logger.error("Missing INSTAGRAM_USERNAME or INSTAGRAM_PASSWORD")
        logger.error(f"Available env vars: {list(os.environ.keys())}")
        sys.exit(1)
    
    # Login
    logger.info(f"Logging in as {username}...")
    try:
        bot.login(username, password)
        logger.info("Login successful!")
    except Exception as e:
        logger.error(f"Login failed: {e}")
        logger.error("Will retry in 60 seconds...")
        time.sleep(60)
        sys.exit(1)
    
    # Get configuration
    hashtags = os.getenv("HASHTAGS", "lasvegasfood,vegaseats,lasvegasdining,vegasfoodie").split(",")
    hashtags = [h.strip() for h in hashtags if h.strip()]
    
    scan_interval = int(os.getenv("SCAN_INTERVAL_HOURS", "6"))
    auto_approve = os.getenv("AUTO_APPROVE", "false").lower() == "true"
    
    logger.info(f"Scan interval: {scan_interval} hours")
    logger.info(f"Auto-approve: {auto_approve}")
    logger.info(f"Hashtags: {hashtags}")
    
    # Main loop
    logger.info("Starting discovery loop...")
    iteration = 0
    
    while True:
        iteration += 1
        logger.info(f"\n--- Iteration {iteration} ---")
        
        try:
            # Post anything the dashboard approved since the last pass
            published = publish_approved(bot)
            if published:
                logger.info(f"Published {published} approved item(s)")

            # Prefer settings saved from the dashboard, falling back to env vars
            saved = bot.load_discovery_settings()
            scan_hashtags = saved['hashtags'] or hashtags
            if saved['min_followers'] is not None:
                bot.min_followers = saved['min_followers']
            if saved['min_engagement_rate'] is not None:
                bot.min_engagement_rate = saved['min_engagement_rate']

            # Run discovery
            logger.info(f"Running content discovery over {len(scan_hashtags)} hashtags...")
            discovered = bot.discover_content(hashtags=scan_hashtags)

            if auto_approve and discovered:
                logger.info("Auto-approve enabled - publishing new content...")
                for item in discovered:
                    try:
                        story_id = bot.publish_media(item.id)
                        logger.info(f"Published: {story_id}")
                    except Exception as e:
                        logger.error(f"Failed to publish: {e}")

            # Get pending count
            pending = bot.get_pending_content()
            logger.info(f"Pending approval: {len(pending)}")

        except BUG_EXCEPTIONS:
            # A bug in our own code. Let the process die so Railway restarts it
            # and the traceback lands in the logs, rather than looping silently.
            logger.exception("Bug in the worker - exiting so it is not hidden")
            raise

        except Exception as e:
            logger.error(f"Error in iteration: {e}")

        # Wait, staying responsive to approvals and scan requests
        logger.info(f"Next scan in up to {scan_interval} hours")
        wait_for_next_cycle(bot, scan_interval)


if __name__ == "__main__":
    main()
