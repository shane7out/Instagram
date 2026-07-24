"""
The handoff between the dashboard and the worker.

The dashboard used to post to Instagram itself, which meant two hosts logging
into the same account. Now it only writes to the database and the worker does
all Instagram I/O. These tests pin that boundary.
"""

import pytest

from conftest import FakeClient, FakeMedia
from database_models import MediaItem, MediaStatus


@pytest.fixture
def queued_item(bot):
    """One discovered item sitting in the pending queue."""
    bot.client = FakeClient(medias=[FakeMedia(1, "AAA", "creator")])
    found = bot.discover_content(hashtags=["lasvegasfood"])
    return found[0]


class TestApproval:
    def test_approving_queues_rather_than_posts(self, bot, queued_item):
        """
        The important assertion is the negative one: approving must not call
        Instagram. If it did, the dashboard would need credentials again.
        """
        before = list(bot.client.calls)

        bot.approve_media(queued_item.id)

        assert queued_item.status is MediaStatus.READY
        assert bot.client.calls == before, "approval must not touch Instagram"

    def test_approved_items_leave_the_pending_queue(self, bot, queued_item):
        assert len(bot.get_pending_content()) == 1

        bot.approve_media(queued_item.id)

        assert bot.get_pending_content() == []
        assert len(bot.get_approved_content()) == 1

    def test_rejecting_keeps_it_out_of_both_queues(self, bot, queued_item):
        bot.reject_media(queued_item.id)

        assert bot.get_pending_content() == []
        assert bot.get_approved_content() == []

    def test_approving_a_missing_item_raises(self, bot):
        with pytest.raises(Exception, match="Media not found"):
            bot.approve_media(9999)

    def test_approved_items_survive_a_restart(self, bot, db, queued_item):
        """The worker is a different process, so this must go through the db."""
        bot.approve_media(queued_item.id)

        import bot_engine
        worker = bot_engine.InstagramBot()
        worker.db_session = db

        assert [m.code for m in worker.get_approved_content()] == ["AAA"]


class TestScanRequests:
    def test_request_is_visible_to_another_process(self, bot, db):
        bot.request_scan()

        import bot_engine
        worker = bot_engine.InstagramBot()
        worker.db_session = db

        assert worker.consume_scan_request() is True

    def test_request_is_consumed_only_once(self, bot):
        bot.request_scan()

        assert bot.consume_scan_request() is True
        assert bot.consume_scan_request() is False

    def test_no_request_by_default(self, bot):
        assert bot.consume_scan_request() is False


class TestDiscoverySettingsHandoff:
    def test_settings_saved_in_the_dashboard_reach_the_worker(self, bot, db):
        bot.save_discovery_settings(
            hashtags=["tacos", "vegasfood"],
            min_followers=2500,
            min_engagement_rate=3.5,
        )

        import bot_engine
        worker = bot_engine.InstagramBot()
        worker.db_session = db
        loaded = worker.load_discovery_settings()

        assert loaded["hashtags"] == ["tacos", "vegasfood"]
        assert loaded["min_followers"] == 2500
        assert loaded["min_engagement_rate"] == 3.5

    def test_unset_settings_return_none_so_env_defaults_win(self, bot):
        loaded = bot.load_discovery_settings()

        assert loaded == {
            "hashtags": None,
            "min_followers": None,
            "min_engagement_rate": None,
        }

    def test_partial_save_leaves_the_rest_unset(self, bot):
        bot.save_discovery_settings(min_followers=99)
        loaded = bot.load_discovery_settings()

        assert loaded["min_followers"] == 99
        assert loaded["hashtags"] is None

    def test_corrupt_values_do_not_crash_the_worker(self, bot):
        bot._set_setting(bot.MIN_FOLLOWERS_KEY, "not a number")

        assert bot.load_discovery_settings()["min_followers"] is None


class TestScanStatsHandoff:
    def test_stats_are_readable_by_the_dashboard(self, bot, db):
        bot.client = FakeClient(medias=[FakeMedia(1, "AAA", "creator")])
        bot.discover_content(hashtags=["lasvegasfood"])

        import bot_engine
        dashboard = bot_engine.InstagramBot()
        dashboard.db_session = db

        stats = dashboard.get_last_discovery_stats()
        assert stats["accepted"] == 1
        assert stats["candidates"] == 1

    def test_absent_stats_return_empty(self, bot):
        assert bot.get_last_discovery_stats() == {}

    def test_corrupt_stats_return_empty(self, bot):
        bot._set_setting(bot.LAST_SCAN_KEY, "{broken")

        assert bot.get_last_discovery_stats() == {}
