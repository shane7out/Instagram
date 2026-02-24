"""
Las Vegas Food Curator - Streamlit Dashboard
Web interface for managing content discovery and approval
"""

import streamlit as st
import os
import sys
import time
from pathlib import Path
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from bot_engine import InstagramBot, create_bot
from video_utils import VideoProcessor
from database_models import (
    init_database, Creator, MediaItem, 
    CreatorStatus, MediaStatus, get_media_status_counts
)

# Page configuration
st.set_page_config(
    page_title="Las Vegas Food Curator",
    page_icon="🍽️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main {
        background-color: #0E1117;
    }
    .stApp {
        background-color: #0E1117;
    }
    .sidebar .sidebar-content {
        background-color: #1C1F26;
    }
    .stButton>button {
        background-color: #E1306C;
        color: white;
    }
    .stButton>button:hover {
        background-color: #C13584;
    }
    .success {
        color: #4CAF50;
    }
    .warning {
        color: #FF9800;
    }
    .error {
        color: #F44336;
    }
    .metric-card {
        background-color: #1C1F26;
        padding: 20px;
        border-radius: 10px;
        margin: 10px 0;
    }
    .creator-card {
        background-color: #1C1F26;
        padding: 15px;
        border-radius: 8px;
        margin: 10px 0;
        border-left: 4px solid #E1306C;
    }
    .media-card {
        background-color: #1C1F26;
        padding: 20px;
        border-radius: 10px;
        margin: 15px 0;
    }
</style>
""", unsafe_allow_html=True)


class DashboardState:
    """Manages dashboard state"""
    
    def __init__(self):
        if 'bot' not in st.session_state:
            st.session_state.bot = None
        if 'logged_in' not in st.session_state:
            st.session_state.logged_in = False
        if 'db_session' not in st.session_state:
            st.session_state.db_session = None


def init_session():
    """Initialize session state"""
    state = DashboardState()
    
    # Initialize database
    if not st.session_state.db_session:
        st.session_state.db_session = init_database()
    
    # Initialize video processor
    if 'video_processor' not in st.session_state:
        st.session_state.video_processor = VideoProcessor()
    
    return state


def login_screen():
    """Display login screen"""
    st.title("🍽️ Las Vegas Food Curator")
    st.markdown("### Instagram Stories Automation System")
    
    col1, col2, col3 = st.columns([1, 2, 1])
    
    with col2:
        with st.form("login_form"):
            username = st.text_input("Instagram Username")
            password = st.text_input("Instagram Password", type="password")
            submit = st.form_submit_button("Login")
            
            if submit:
                if username and password:
                    try:
                        bot = create_bot()
                        bot.init_db()
                        bot.set_video_processor(st.session_state.video_processor)
                        
                        with st.spinner("Logging in..."):
                            bot.login(username, password)
                        
                        st.session_state.bot = bot
                        st.session_state.logged_in = True
                        st.success("Successfully logged in!")
                        st.rerun()
                        
                    except Exception as e:
                        st.error(f"Login failed: {str(e)}")
                else:
                    st.warning("Please enter username and password")
    
    st.markdown("---")
    st.markdown("""
    ### How It Works
    1. **Discover** - Scan hashtags for Las Vegas food content
    2. **Review** - Preview discovered content in the queue
    3. **Approve** - Select the best videos to post
    4. **Publish** - Automatically post to Instagram Stories with credit
    """)


def sidebar():
    """Render sidebar"""
    st.sidebar.title("🍽️ LV Food Curator")
    
    # Connection status
    if st.session_state.logged_in:
        st.sidebar.success("🟢 Bot Online")
        
        # Stats
        if st.session_state.db_session:
            counts = get_media_status_counts(st.session_state.db_session)
            
            st.sidebar.markdown("### 📊 Queue Stats")
            st.sidebar.metric("Pending Approval", counts.get('pending_approval', 0))
            st.sidebar.metric("Published Today", counts.get('published', 0))
            st.sidebar.metric("Total Discovered", sum(counts.values()))
        
        st.sidebar.markdown("---")
        
        # Navigation
        page = st.sidebar.radio(
            "Navigation",
            ["📥 Discovery", "📋 Content Queue", "👥 Creators", "📜 History", "⚙️ Settings"]
        )
        
        st.sidebar.markdown("---")
        
        # Logout
        if st.sidebar.button("Logout"):
            if st.session_state.bot:
                st.session_state.bot.logout()
            st.session_state.logged_in = False
            st.session_state.bot = None
            st.rerun()
    
    else:
        st.sidebar.warning("🔴 Bot Offline")
        st.sidebar.info("Please login to continue")
        page = None
    
    return page


def discovery_page():
    """Discovery page"""
    st.title("📥 Content Discovery")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.markdown("### 🔍 Scan for Content")
        
        # Hashtags
        hashtags = st.text_area(
            "Hashtags to scan (comma-separated)",
            value="lasvegasfood, vegaseats, lasvegasdining, vegasfoodie, vegasrestaurants",
            height=80
        )
        
        # Min followers
        min_followers = st.slider("Minimum Followers", 500, 50000, 1000, step=500)
        
        # Min engagement
        min_engagement = st.slider("Minimum Engagement Rate (%)", 0.5, 10.0, 2.0, step=0.5)
        
    with col2:
        st.markdown("### ⚙️ Settings")
        
        st.metric("Daily Limit", "50 posts")
        st.metric("Rate Delay", "30 seconds")
        
        # Update settings
        if st.button("Update Settings"):
            if st.session_state.bot:
                st.session_state.bot.min_followers = min_followers
                st.session_state.bot.min_engagement_rate = min_engagement
                st.success("Settings updated!")
    
    st.markdown("---")
    
    # Run discovery
    if st.button("🔎 Run Discovery Scan", type="primary"):
        if not st.session_state.bot:
            st.error("Bot not initialized")
            return
        
        hashtag_list = [h.strip() for h in hashtags.split(',') if h.strip()]
        
        with st.spinner(f"Scanning {len(hashtag_list)} hashtags..."):
            try:
                st.session_state.bot.min_followers = min_followers
                st.session_state.bot.min_engagement_rate = min_engagement
                
                discovered = st.session_state.bot.discover_content(
                    hashtags=hashtag_list,
                    min_followers=min_followers
                )
                
                st.success(f"Discovery complete! Found {len(discovered)} new items")
                
            except Exception as e:
                st.error(f"Discovery failed: {str(e)}")
    
    # Show recent discoveries
    st.markdown("### 📋 Recent Discoveries")
    
    if st.session_state.db_session:
        recent = st.session_state.db_session.query(MediaItem).order_by(
            MediaItem.date_discovered.desc()
        ).limit(10).all()
        
        for item in recent:
            with st.expander(f"📹 {item.code} by @{item.creator.username if item.creator else 'Unknown'}"):
                col1, col2 = st.columns(2)
                with col1:
                    st.write(f"**Status:** {item.status.value}")
                    st.write(f"**Likes:** {item.like_count}")
                    st.write(f"**Comments:** {item.comment_count}")
                with col2:
                    if item.creator:
                        st.write(f"**Followers:** {item.creator.follower_count}")
                        st.write(f"**Engagement:** {item.creator.avg_engagement}%")


def content_queue_page():
    """Content queue page"""
    st.title("📋 Content Queue")
    
    # Get pending content
    pending = st.session_state.bot.get_pending_content() if st.session_state.bot else []
    
    st.markdown(f"**{len(pending)}** items waiting for approval")
    
    if not pending:
        st.info("No content pending approval. Run a discovery scan first!")
        return
    
    # Filter options
    col1, col2, col3 = st.columns(3)
    with col1:
        sort_by = st.selectbox("Sort by", ["Date", "Likes", "Engagement"])
    with col2:
        filter_creator = st.text_input("Filter by creator")
    with col3:
        min_likes = st.number_input("Min likes", min_value=0, value=0)
    
    # Sort
    if sort_by == "Likes":
        pending = sorted(pending, key=lambda x: x.like_count, reverse=True)
    elif sort_by == "Engagement":
        pending = sorted(pending, key=lambda x: x.creator.avg_engagement if x.creator else 0, reverse=True)
    
    # Filter
    if filter_creator:
        pending = [p for p in pending if filter_creator.lower() in (p.creator.username if p.creator else '').lower()]
    
    if min_likes > 0:
        pending = [p for p in pending if p.like_count >= min_likes]
    
    st.markdown("---")
    
    # Display content
    for item in pending:
        creator = item.creator
        
        with st.container():
            st.markdown(f"""
            <div class="media-card">
                <h4>📹 {item.code}</h4>
                <p><strong>Creator:</strong> @{creator.username if creator else 'Unknown'}</p>
                <p><strong>Followers:</strong> {creator.follower_count if creator else 0} | 
                   <strong>Engagement:</strong> {creator.avg_engagement if creator else 0}%</p>
                <p><strong>Likes:</strong> {item.like_count} | 
                   <strong>Comments:</strong> {item.comment_count}</p>
            </div>
            """, unsafe_allow_html=True)
            
            # Show caption
            if item.caption:
                with st.expander("📝 View Caption"):
                    st.write(item.caption)
            
            # Actions
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                if st.button(f"✅ Approve", key=f"approve_{item.id}", type="primary"):
                    try:
                        with st.spinner("Publishing to Stories..."):
                            story_id = st.session_state.bot.publish_media(item.id)
                        st.success(f"Published! Story ID: {story_id}")
                        time.sleep(1)
                        st.rerun()
                    except Exception as e:
                        st.error(f"Failed: {str(e)}")
            
            with col2:
                if st.button(f"❌ Reject", key=f"reject_{item.id}"):
                    st.session_state.bot.reject_media(item.id)
                    st.rerun()
            
            with col3:
                if creator:
                    status = CreatorStatus.APPROVED if creator.status != CreatorStatus.APPROVED else CreatorStatus.BLOCKED
                    btn_text = "🟢 Approve Creator" if creator.status != CreatorStatus.APPROVED else "🔴 Block Creator"
                    if st.button(btn_text, key=f"creator_{creator.id}"):
                        st.session_state.bot.approve_creator(creator.id, status)
                        st.rerun()
            
            with col4:
                if st.button(f"👁️ View", key=f"view_{item.id}"):
                    # Show full details
                    st.json({
                        "code": item.code,
                        "creator": creator.username if creator else "Unknown",
                        "likes": item.like_count,
                        "comments": item.comment_count,
                        "caption": item.caption,
                        "hashtags": item.hashtags
                    })
            
            st.markdown("---")


def creators_page():
    """Creators management page"""
    st.title("👥 Creator Management")
    
    # Get all creators
    creators = st.session_state.bot.get_creators() if st.session_state.bot else []
    
    # Stats
    col1, col2, col3 = st.columns(3)
    
    approved = [c for c in creators if c.status == CreatorStatus.APPROVED]
    blocked = [c for c in creators if c.status == CreatorStatus.BLOCKED]
    new = [c for c in creators if c.status == CreatorStatus.NEW]
    
    with col1:
        st.metric("Total Creators", len(creators))
    with col2:
        st.metric("Approved", len(approved))
    with col3:
        st.metric("Blocked", len(blocked))
    
    st.markdown("---")
    
    # Filter tabs
    tab1, tab2, tab3, tab4 = st.tabs(["✅ Approved", "🔴 Blocked", "🆕 New", "📋 All"])
    
    with tab1:
        display_creators(approved)
    
    with tab2:
        display_creators(blocked)
    
    with tab3:
        display_creators(new)
    
    with tab4:
        display_creators(creators)


def display_creators(creators):
    """Display list of creators"""
    if not creators:
        st.info("No creators found")
        return
    
    # Search
    search = st.text_input("Search creators", key="creator_search")
    
    if search:
        creators = [c for c in creators if search.lower() in c.username.lower()]
    
    # Display
    for creator in creators:
        with st.expander(f"@{creator.username}"):
            col1, col2 = st.columns(2)
            
            with col1:
                st.write(f"**Status:** {creator.status.value}")
                st.write(f"**Followers:** {creator.follower_count:,}")
                st.write(f"**Following:** {creator.following_count:,}")
            
            with col2:
                st.write(f"**Engagement:** {creator.avg_engagement}%")
                st.write(f"**Media Count:** {creator.media_count}")
                st.write(f"**Added:** {creator.created_at.strftime('%Y-%m-%d')}")
            
            # Actions
            if st.button(f"Change to {'Blocked' if creator.status == CreatorStatus.APPROVED else 'Approved'}", 
                        key=f"toggle_{creator.id}"):
                new_status = CreatorStatus.BLOCKED if creator.status == CreatorStatus.APPROVED else CreatorStatus.APPROVED
                st.session_state.bot.approve_creator(creator.id, new_status)
                st.rerun()


def history_page():
    """History page"""
    st.title("📜 Publishing History")
    
    # Get published content
    published = st.session_state.bot.get_published_content() if st.session_state.bot else []
    
    st.markdown(f"**{len(published)}** total posts")
    
    if not published:
        st.info("No content published yet")
        return
    
    # Display
    for item in published:
        with st.expander(f"📹 {item.code} - Published {item.date_published.strftime('%Y-%m-%d %H:%M')}"):
            col1, col2 = st.columns(2)
            
            with col1:
                st.write(f"**Creator:** @{item.creator.username if item.creator else 'Unknown'}")
                st.write(f"**Likes:** {item.like_count}")
            
            with col2:
                st.write(f"**Published:** {item.date_published}")
                st.write(f"**Views:** {item.view_count}")


def settings_page():
    """Settings page"""
    st.title("⚙️ Settings")
    
    st.markdown("### Bot Configuration")
    
    col1, col2 = st.columns(2)
    
    with col1:
        min_followers = st.number_input("Minimum Followers", min_value=100, value=1000, step=100)
        min_engagement = st.number_input("Minimum Engagement Rate (%)", min_value=0.1, value=2.0, step=0.5)
    
    with col2:
        daily_limit = st.number_input("Daily Action Limit", min_value=10, value=50, step=10)
        rate_delay = st.number_input("Rate Limit Delay (seconds)", min_value=10, value=30, step=5)
    
    if st.button("Save Settings"):
        if st.session_state.bot:
            st.session_state.bot.min_followers = min_followers
            st.session_state.bot.min_engagement_rate = min_engagement
            st.session_state.bot.daily_action_limit = daily_limit
            st.session_state.bot.rate_limit_delay = rate_delay
            st.success("Settings saved!")
    
    st.markdown("---")
    
    st.markdown("### Database")
    
    col1, col2 = st.columns(2)
    
    with col1:
        if st.button("Export Creators CSV"):
            import pandas as pd
            creators = st.session_state.bot.get_creators() if st.session_state.bot else []
            df = pd.DataFrame([{
                "Username": c.username,
                "Followers": c.follower_count,
                "Engagement": c.avg_engagement,
                "Status": c.status.value
            } for c in creators])
            csv = df.to_csv(index=False)
            st.download_button("Download CSV", csv, "creators.csv", "text/csv")
    
    with col2:
        if st.button("Clear Old Data"):
            st.warning("This feature is not yet implemented")


def main():
    """Main dashboard"""
    # Initialize
    state = init_session()
    
    # Login check
    if not st.session_state.logged_in:
        login_screen()
        return
    
    # Get current page
    page = sidebar()
    
    # Route to page
    if page == "📥 Discovery":
        discovery_page()
    elif page == "📋 Content Queue":
        content_queue_page()
    elif page == "👥 Creators":
        creators_page()
    elif page == "📜 History":
        history_page()
    elif page == "⚙️ Settings":
        settings_page()


if __name__ == "__main__":
    main()
