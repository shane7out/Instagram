"""
Las Vegas Food Curator - Main Entry Point
Run the bot and dashboard
"""

import os
import sys
import logging
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def create_directories():
    """Create necessary directories"""
    dirs = [
        'downloads',
        'processed',
        'database',
        'logs'
    ]
    
    for d in dirs:
        Path(d).mkdir(parents=True, exist_ok=True)


def run_dashboard():
    """Run the Streamlit dashboard"""
    import streamlit as st
    st.run("dashboard.py")


def run_bot_cli():
    """Run bot in CLI mode"""
    from bot_engine import create_bot
    from video_utils import VideoProcessor
    
    print("🍽️ Las Vegas Food Curator - CLI Mode")
    print("=" * 50)
    
    # Initialize
    bot = create_bot()
    bot.init_db()
    bot.set_video_processor(VideoProcessor())
    
    # Login
    username = input("Instagram username: ")
    password = input("Instagram password: ")
    
    print("\nLogging in...")
    try:
        bot.login(username, password)
        print("✓ Login successful")
    except Exception as e:
        print(f"✗ Login failed: {e}")
        return
    
    # Main loop
    while True:
        print("\nOptions:")
        print("1. Run Discovery Scan")
        print("2. View Pending Content")
        print("3. Approve & Publish")
        print("4. View Published History")
        print("5. Exit")
        
        choice = input("\nSelect option: ")
        
        if choice == "1":
            print("\nRunning discovery scan...")
            discovered = bot.discover_content()
            print(f"✓ Found {len(discovered)} new items")
        
        elif choice == "2":
            pending = bot.get_pending_content()
            print(f"\n{len(pending)} items pending:")
            for item in pending[:10]:
                print(f"  - {item.code} by @{item.creator.username if item.creator else 'Unknown'}")
        
        elif choice == "3":
            media_id = input("Enter media ID to publish: ")
            try:
                story_id = bot.publish_media(int(media_id))
                print(f"✓ Published! Story ID: {story_id}")
            except Exception as e:
                print(f"✗ Failed: {e}")
        
        elif choice == "4":
            published = bot.get_published_content()
            print(f"\n{len(published)} published items:")
            for item in published[:10]:
                print(f"  - {item.code} ({item.date_published})")
        
        elif choice == "5":
            print("\nGoodbye!")
            break


def main():
    """Main entry point"""
    create_directories()
    
    if len(sys.argv) > 1 and sys.argv[1] == "--cli":
        run_bot_cli()
    else:
        print("Starting Streamlit Dashboard...")
        print("Run: streamlit run dashboard.py")
        print("\nOr use CLI mode:")
        print("  python main.py --cli")
        run_dashboard()


if __name__ == "__main__":
    main()
