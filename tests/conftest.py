"""Shared fixtures and Instagram client fakes."""

import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO))


class FakeUser:
    """Stand-in for the object instagrapi returns from user_info_by_username"""

    def __init__(self, username, pk=1, followers=5000, private=False):
        self.pk = pk
        self.username = username
        self.full_name = username.title()
        self.follower_count = followers
        self.following_count = 100
        self.media_count = 50
        self.is_private = private
        self.public_email = None


class FakeUsertag:
    def __init__(self, username):
        self.user = FakeUser(username)


class FakeMedia:
    """Stand-in for instagrapi's Media. Note it has no `hashtags` attribute -
    neither does the real one, which is why that column was always empty."""

    def __init__(self, pk, code, username, media_type=2,
                 caption="Best tacos in town #lasvegasfood #vegaseats",
                 likes=500, comments=50, usertags=None):
        self.pk = pk
        self.code = code
        self.user = FakeUser(username)
        self.media_type = media_type
        self.caption_text = caption
        self.like_count = likes
        self.comment_count = comments
        self.view_count = 1000
        self.usertags = usertags or []


class FakeClient:
    """Minimal stand-in for instagrapi.Client covering the calls we make."""

    def __init__(self, medias=None, users=None, on_hashtag=None):
        self._medias = list(medias or [])
        self._users = dict(users or {})
        self._on_hashtag = on_hashtag
        self._settings = {"uuids": {"phone_id": "abc-123"}}
        self.calls = []

    def hashtag_medias_recent(self, name, amount=27):
        self.calls.append(("hashtag_medias_recent", name))
        if self._on_hashtag:
            raise self._on_hashtag
        return list(self._medias)

    def user_info_by_username(self, username):
        self.calls.append(("user_info_by_username", username))
        if username in self._users:
            return self._users[username]
        return FakeUser(username)

    def user_medias(self, user_id, amount=0):
        self.calls.append(("user_medias", user_id))
        # 500 likes + 50 comments against 5000 followers = 11% engagement
        return [FakeMedia(pk=900 + i, code=f"M{i}", username="x") for i in range(10)]

    def get_settings(self):
        return dict(self._settings)

    def set_settings(self, settings):
        self._settings = dict(settings)

    def dump_settings(self, path):
        import json
        Path(path).write_text(json.dumps(self._settings))

    def load_settings(self, path):
        import json
        self._settings = json.loads(Path(path).read_text())


@pytest.fixture
def db(tmp_path, monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    from database_models import init_database
    return init_database(str(tmp_path / "test.db"))


@pytest.fixture
def bot(db, tmp_path, monkeypatch):
    """A bot wired to a real database and a fake Instagram client."""
    import bot_engine

    # discovery paces itself with a 2-5s sleep per item
    monkeypatch.setattr(bot_engine.time, "sleep", lambda *a, **k: None)
    monkeypatch.chdir(tmp_path)

    b = bot_engine.InstagramBot()
    b.db_session = db
    b.client = FakeClient()
    return b
