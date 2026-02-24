"""
Las Vegas Food Curator - Bot Worker
Runs the Instagram bot as a background service for scheduled discovery
"""

import os
import sys
import logging
import time
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

# Setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()


def main():
    """Main worker loop"""
    from bot_engine import create_bot
    from video_utils import VideoProcessor
    from database_models import init_database
    
    logger.info("=" * 50)
    logger.info("🍽️ Las Vegas Food Curator - Bot Worker")
    logger.info("=" * 50)
    
    # Initialize
    logger.info("Initializing bot...")
    bot = create_bot()
    bot.init_db()
    bot.set_video_processor(VideoProcessor())
    
    # Get credentials from environment
    username = os.getenv("INSTAGRAM_USERNAME")
    password = os.getenv("INSTAGRAM_PASSWORD")
    
    if not username or not password:
        logger.error("Missing INSTAGRAM_USERNAME or INSTAGRAM_PASSWORD")
        return
    
    # Login
    logger.info(f"Logging in as {username}...")
    try:
        bot.login(username, password)
        logger.info("✓ Login successful")
    except Exception as e:
        logger.error(f"✗ Login failed: {e}")
        return
    
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
            # Run discovery
            logger.info("Running content discovery...")
            discovered = bot.discover_content(hashtags=hashtags)
            logger.info(f"Discovered {len(discovered)} new items")
            
            if auto_approve and discovered:
                logger.info("Auto-approve enabled - publishing new content...")
                for item in discovered:
                    try:
                        story_id = bot.publish_media(item.id)
                        logger.info(f"✓ Published: {story_id}")
                    except Exception as e:
                        logger.error(f"Failed to publish: {e}")
            
            # Get pending count
            pending = bot.get_pending_content()
            logger.info(f"Pending approval: {len(pending)}")
            
        except Exception as e:
            logger.error(f"Error in iteration: {e}")
        
        # Wait before next scan
        logger.info(f"Waiting {scan_interval} hours before next scan...")
        time.sleep(scan_interval * 3600)


if __name__ == "__main__":
    main()
