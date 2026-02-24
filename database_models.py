"""
Las Vegas Food Curator - Database Models
SQLite-based database for managing creators and content
"""

from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Enum, ForeignKey, Text, BigInteger
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
import enum

Base = declarative_base()


class CreatorStatus(enum.Enum):
    NEW = "new"
    APPROVED = "approved"
    BLOCKED = "blocked"


class MediaStatus(enum.Enum):
    DISCOVERED = "discovered"
    PENDING_APPROVAL = "pending_approval"
    PROCESSING = "processing"
    READY = "ready"
    PUBLISHED = "published"
    FAILED = "failed"
    REJECTED = "rejected"


class Creator(Base):
    """Content creator information"""
    __tablename__ = 'creators'

    id = Column(Integer, primary_key=True)
    username = Column(String(100), unique=True, nullable=False)
    instagram_pk = Column(BigInteger, unique=True)
    full_name = Column(String(200))
    follower_count = Column(Integer, default=0)
    following_count = Column(Integer, default=0)
    media_count = Column(Integer, default=0)
    avg_engagement = Column(Float, default=0.0)
    is_private = Column(Integer, default=0)
    status = Column(Enum(CreatorStatus), default=CreatorStatus.NEW)
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    media_items = relationship("MediaItem", back_populates="creator")

    def __repr__(self):
        return f"<Creator {self.username} ({self.follower_count} followers)>"


class MediaItem(Base):
    """Discovered media content"""
    __tablename__ = 'media_items'

    id = Column(Integer, primary_key=True)
    original_media_pk = Column(BigInteger, unique=True)
    creator_id = Column(Integer, ForeignKey('creators.id'))
    code = Column(String(50))  # Instagram media code
    media_type = Column(String(20))  # video, reel, image
    file_path = Column(String(500))
    thumbnail_path = Column(String(500))
    caption = Column(Text)
    like_count = Column(Integer, default=0)
    comment_count = Column(Integer, default=0)
    view_count = Column(Integer, default=0)
    status = Column(Enum(MediaStatus), default=MediaStatus.DISCOVERED)
    hashtags = Column(Text)
    mentions = Column(Text)
    date_discovered = Column(DateTime, default=datetime.utcnow)
    date_published = Column(DateTime, nullable=True)
    error_message = Column(Text, nullable=True)

    creator = relationship("Creator", back_populates="media_items")

    def __repr__(self):
        return f"<MediaItem {self.code} by {self.creator.username if self.creator else 'Unknown'}>"


class AppSettings(Base):
    """Application settings"""
    __tablename__ = 'app_settings'

    id = Column(Integer, primary_key=True)
    key = Column(String(100), unique=True, nullable=False)
    value = Column(Text)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<AppSettings {self.key}>"


class PostLog(Base):
    """Log of posted content"""
    __tablename__ = 'post_logs'

    id = Column(Integer, primary_key=True)
    media_id = Column(Integer, ForeignKey('media_items.id'))
    posted_at = Column(DateTime, default=datetime.utcnow)
    story_id = Column(String(100))
    success = Column(Integer, default=1)
    error_message = Column(Text, nullable=True)

    def __repr__(self):
        return f"<PostLog {self.id} - {'Success' if self.success else 'Failed'}>"


def init_database(db_path="lasvegas_restaurants.db"):
    """Initialize the database"""
    engine = create_engine(f'sqlite:///{db_path}')
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()


def get_or_create_creator(session, username, instagram_pk=None, **kwargs):
    """Get existing creator or create new one"""
    creator = session.query(Creator).filter_by(username=username).first()
    
    if not creator:
        creator = Creator(
            username=username,
            instagram_pk=instagram_pk,
            **kwargs
        )
        session.add(creator)
        session.commit()
    
    return creator


def get_media_status_counts(session):
    """Get counts of media items by status"""
    from sqlalchemy import func
    counts = session.query(
        MediaItem.status,
        func.count(MediaItem.id)
    ).group_by(MediaItem.status).all()
    
    result = {}
    for status, count in counts:
        result[status.value] = count
    
    return result
