"""
Las Vegas Food Curator - Video Processing Utilities
Handles video downloading, processing, and adding attribution overlays
"""

import os
import subprocess
import logging
from pathlib import Path
from datetime import datetime

logger = logging.getLogger(__name__)


class VideoProcessor:
    """Handles video processing with FFmpeg"""
    
    def __init__(self, downloads_dir="downloads", processed_dir="processed"):
        self.downloads_dir = Path(downloads_dir)
        self.processed_dir = Path(processed_dir)
        
        # Create directories
        self.downloads_dir.mkdir(parents=True, exist_ok=True)
        self.processed_dir.mkdir(parents=True, exist_ok=True)
    
    def download_video(self, client, media_pk, filename):
        """Download video from Instagram"""
        try:
            output_path = self.downloads_dir / filename
            client.media_download(media_pk, output_path)
            logger.info(f"Downloaded video to {output_path}")
            return str(output_path)
        except Exception as e:
            logger.error(f"Failed to download video {media_pk}: {e}")
            raise
    
    def process_video(self, input_path, creator_username, output_filename=None):
        """
        Process video: resize to 9:16 and add attribution overlay
        
        Args:
            input_path: Path to input video
            creator_username: Instagram username to credit
            output_filename: Optional output filename
            
        Returns:
            Path to processed video
        """
        if not output_filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"processed_{timestamp}.mp4"
        
        output_path = self.processed_dir / output_filename
        
        # Build FFmpeg command
        # 1. Scale to 1080x1920 (9:16 vertical)
        # 2. Add attribution overlay at bottom
        
        credit_text = f"Credit: @{creator_username}"
        
        # Check if FFmpeg is available
        try:
            subprocess.run(["ffmpeg", "-version"], check=True, capture_output=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.warning("FFmpeg not found. Using raw video without processing.")
            # Just copy the file
            import shutil
            shutil.copy(input_path, output_path)
            return str(output_path)
        
        # FFmpeg command for vertical video with credit overlay
        cmd = [
            "ffmpeg", "-y",
            "-i", input_path,
            "-vf", f"scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,drawtext=text='{credit_text}':fontcolor=white:fontsize=36:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:x=(w-text_w)/2:y=h-100:box=1:boxcolor=black@0.6:boxborderw=10",
            "-c:v", "libx264",
            "-preset", "medium",
            "-crf", "23",
            "-c:a", "copy",
            str(output_path)
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info(f"Processed video saved to {output_path}")
            return str(output_path)
        except subprocess.CalledProcessError as e:
            logger.error(f"FFmpeg processing failed: {e.stderr}")
            # Fallback: just copy the file
            import shutil
            shutil.copy(input_path, output_path)
            return str(output_path)
    
    def create_thumbnail(self, video_path, output_filename=None):
        """Create thumbnail from video"""
        if not output_filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"thumb_{timestamp}.jpg"
        
        output_path = self.downloads_dir / output_filename
        
        cmd = [
            "ffmpeg", "-y",
            "-i", video_path,
            "-ss", "00:00:01",
            "-vframes", "1",
            "-q:v", "2",
            str(output_path)
        ]
        
        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return str(output_path)
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to create thumbnail: {e}")
            return None
    
    def cleanup_files(self, file_path):
        """Remove processed files after posting"""
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                logger.info(f"Cleaned up file: {file_path}")
        except Exception as e:
            logger.warning(f"Failed to cleanup {file_path}: {e}")
    
    def get_video_duration(self, video_path):
        """Get video duration in seconds"""
        cmd = [
            "ffprobe",
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            video_path
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return float(result.stdout.strip())
        except:
            return 15  # Default to 15 seconds


def create_vertical_video(input_path, output_path, credit_text):
    """
    Create vertical (9:16) video with credit overlay
    
    Args:
        input_path: Path to input video
        output_path: Path to output video
        credit_text: Text to overlay
        
    Returns:
        True if successful
    """
    # This is a simplified version using moviepy
    try:
        from moviepy.editor import VideoFileClip, TextClip, CompositeVideoClip
        import os
        
        # Load video
        video = VideoFileClip(input_path)
        
        # Resize to vertical (9:16) - letterbox if needed
        target_width = 1080
        target_height = 1920
        
        # Calculate scaling to fill height
        aspect_ratio = video.w / video.h
        if aspect_ratio > 9/16:
            # Video is wider, scale to fill height
            video = video.resize(height=target_height)
            # Crop to center
            video = video.crop(x_center=video.w/2, width=target_width)
        else:
            # Video is taller, scale to fill width
            video = video.resize(width=target_width)
            # Crop to center
            video = video.crop(y_center=video.h/2, height=target_height)
        
        # Add credit text
        txt_clip = TextClip(
            credit_text,
            fontsize=36,
            color='white',
            font='DejaVu-Sans-Bold',
            bg_color='black@0.6',
            size=(target_width, 60)
        )
        txt_clip = txt_clip.set_position(('center', target_height - 100)).set_duration(video.duration)
        
        # Composite
        final_video = CompositeVideoClip([video, txt_clip])
        
        # Write output
        final_video.write_videofile(output_path, codec='libx264', audio_codec='aac')
        
        return True
        
    except Exception as e:
        logger.error(f"MoviePy processing failed: {e}")
        # Fallback to simple copy
        import shutil
        shutil.copy(input_path, output_path)
        return False
