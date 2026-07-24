"""
State that has to survive a redeploy.

Railway's filesystem is ephemeral, so anything the bot keeps on disk is gone on
the next deploy. Two things were being kept there or in memory that should not
have been: the Instagram session, and the daily post counter.
"""

import json
import os

import pytest

from conftest import FakeClient


class TestSessionPersistence:
    def test_session_survives_a_redeploy(self, bot, db, tmp_path):
        """
        A file-based session is discarded when the container is replaced, so
        the bot logs in cold on every deploy. Repeated fresh logins from a
        datacenter IP are a good way to get the account challenged.
        """
        bot.client.set_settings({"uuids": {"phone_id": "original-id"}})
        bot.save_session()

        # A redeploy replaces the container, so anything on disk is gone.
        # Without this the file fallback would satisfy the test and it would
        # pass even if nothing were ever written to the database.
        session_file = tmp_path / bot._session_file
        if session_file.exists():
            session_file.unlink()

        import bot_engine
        redeployed = bot_engine.InstagramBot()
        redeployed.db_session = db
        redeployed.client = FakeClient()

        assert redeployed.load_session() is True
        assert redeployed.client.get_settings()["uuids"]["phone_id"] == "original-id"

    def test_reports_no_session_when_none_stored(self, bot):
        assert bot.load_session() is False

    def test_corrupt_stored_session_is_ignored_not_fatal(self, bot):
        bot._set_setting(bot._session_key, "{not valid json")

        assert bot.load_session() is False

    def test_existing_session_file_is_migrated_into_the_database(self, bot, db, tmp_path):
        """Existing deployments have a session file. Do not strand it."""
        session_file = tmp_path / bot._session_file
        session_file.write_text(json.dumps({"uuids": {"phone_id": "from-disk"}}))

        assert bot.load_session() is True
        assert bot._get_setting(bot._session_key) is not None

        import bot_engine
        later = bot_engine.InstagramBot()
        later.db_session = db
        later.client = FakeClient()
        session_file.unlink()

        assert later.load_session() is True
        assert later.client.get_settings()["uuids"]["phone_id"] == "from-disk"

    def test_falls_back_to_a_file_without_a_database(self, bot, tmp_path):
        bot.db_session = None
        bot.client.set_settings({"uuids": {"phone_id": "local-only"}})

        bot.save_session()

        assert (tmp_path / bot._session_file).is_file()


class TestDailyActionCounter:
    def test_counter_survives_a_redeploy(self, bot, db):
        """In memory, this reset to zero on every deploy, so the cap never held."""
        bot._record_action()
        bot._record_action()

        import bot_engine
        redeployed = bot_engine.InstagramBot()
        redeployed.db_session = db

        assert redeployed.get_actions_today() == 2

    def test_limit_is_enforced_from_the_persisted_count(self, bot):
        bot.daily_action_limit = 1
        bot._record_action()

        with pytest.raises(Exception, match="Daily action limit reached"):
            bot.post_to_story("video.mp4", "creator")

    def test_counter_rolls_over_on_a_new_day(self, bot):
        bot._record_action()
        assert bot.get_actions_today() == 1

        bot._set_setting(bot.ACTIONS_DATE_KEY, "2020-01-01")

        assert bot.get_actions_today() == 0

    def test_explicit_reset_clears_it(self, bot):
        bot._record_action()
        bot.reset_daily_counter()

        assert bot.get_actions_today() == 0


class TestDatabaseConfiguration:
    def test_database_url_is_used_when_set(self, tmp_path, monkeypatch):
        """
        Worker and dashboard run on different hosts. Without a shared
        DATABASE_URL each opens its own SQLite file and neither sees the
        other's rows, which breaks the whole discover-then-approve workflow.
        """
        target = tmp_path / "shared.db"
        monkeypatch.setenv("DATABASE_URL", f"sqlite:///{target}")

        from database_models import init_database
        session = init_database()

        assert str(session.get_bind().url).endswith(str(target))

    def test_falls_back_to_sqlite_without_database_url(self, tmp_path, monkeypatch):
        monkeypatch.delenv("DATABASE_URL", raising=False)

        from database_models import init_database
        session = init_database(str(tmp_path / "local.db"))

        assert "sqlite" in str(session.get_bind().url)

    def test_railway_postgres_scheme_is_rewritten(self, monkeypatch):
        """Railway and Heroku hand out postgres://, SQLAlchemy requires postgresql://"""
        import inspect
        from database_models import init_database

        source = inspect.getsource(init_database)
        assert "postgres://" in source and "postgresql://" in source
