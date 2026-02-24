# Las Vegas Food Curator 🍽️

Instagram Stories automation system for discovering and reposting high-quality Las Vegas food content.

## Features

- **Auto-Discovery**: Scan Instagram hashtags for Las Vegas food/restaurant content
- **Quality Filtering**: Automatically filter creators based on followers and engagement rate
- **Human-in-the-Loop**: Review and approve content before posting
- **Auto-Attribution**: Add credit overlay to videos before posting
- **Instagram Stories**: Post approved content to your Instagram Stories
- **Database**: Track all discovered creators and published content

## Requirements

- Python 3.9+
- FFmpeg (for video processing)
- Instagram Account

## Installation

1. **Clone or download this repository**

2. **Install dependencies**
   ```bash
   cd lvfc_bot
   pip install -r requirements.txt
   ```

3. **Install FFmpeg**
   
   **macOS:**
   ```bash
   brew install ffmpeg
   ```
   
   **Ubuntu/Debian:**
   ```bash
   sudo apt install ffmpeg
   ```
   
   **Windows:**
   Download from https://ffmpeg.org/download.html

4. **Configure credentials**
   ```bash
   cp config.example .env
   # Edit .env with your Instagram credentials
   ```

## Usage

### Option 1: Web Dashboard (Recommended)

Run the Streamlit dashboard:

```bash
cd lvfc_bot
streamlit run dashboard.py
```

Then open your browser to http://localhost:8501

### Option 2: Command Line

```bash
cd lvfc_bot
python main.py --cli
```

## How It Works

1. **Login**: Enter your Instagram credentials
2. **Discover**: Run the discovery scan to find content
3. **Review**: Go to "Content Queue" to review discovered videos
4. **Approve**: Click approve to post to Stories
5. **Attribution**: The system automatically adds "Credit: @username" to videos

## Project Structure

```
lvfc_bot/
├── bot_engine.py        # Core Instagram automation
├── dashboard.py         # Streamlit web interface
├── database_models.py   # Database models
├── video_utils.py       # Video processing utilities
├── main.py              # Entry point
├── requirements.txt     # Python dependencies
└── config.example       # Configuration template
```

## Configuration Options

| Setting | Default | Description |
|---------|---------|-------------|
| MIN_FOLLOWERS | 1000 | Minimum followers for creators |
| MIN_ENGAGEMENT_RATE | 2.0 | Minimum engagement rate (%) |
| MAX_RESULTS_PER_HASHTAG | 20 | Results to fetch per hashtag |
| DAILY_ACTION_LIMIT | 50 | Max posts per day |

## Important Notes

- **Rate Limiting**: The bot includes delays between actions to avoid Instagram restrictions
- **Copyright**: Ensure you have permission from creators before reposting
- **Account Safety**: Follow Instagram's terms of service
- **Two-Factor Auth**: If enabled, you'll need to provide the code during login

## Troubleshooting

### Login Issues
- Make sure credentials are correct
- Check for two-factor authentication
- Instagram may require verification - try logging in manually first

### Discovery Issues
- Increase rate limit delay in settings
- Check your internet connection
- Some hashtags may have no recent video content

### Video Processing
- Ensure FFmpeg is properly installed
- Check that video files are not corrupted

## License

MIT License

## Disclaimer

This tool is for educational purposes. Users are responsible for complying with Instagram's Terms of Service and obtaining proper permissions from content creators.
