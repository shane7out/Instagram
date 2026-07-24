"""
Worker loop behaviour.

The worker is now the only process that talks to Instagram, so it has to stay
responsive to the dashboard: an approval must not sit unposted behind a six
hour sleep.
"""

import pytest

import bot_worker
from conftest import FakeClient, FakeMedia
from database_models import MediaStatus


class FakeClock:
    """Lets a six hour wait run instantly and deterministically."""

    def __init__(self):
        self.now = 0.0

    def monotonic(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


@pytest.fixture
def clock(monkeypatch):
    c = FakeClock()
    monkeypatch.setattr(bot_worker.time, "monotonic", c.monotonic)
    monkeypatch.setattr(bot_worker.time, "sleep", c.sleep)
    return c


@pytest.fixture
def approved_item(bot):
    bot.client = FakeClient(medias=[FakeMedia(1, "AAA", "creator")])
    item = bot.discover_content(hashtags=["lasvegasfood"])[0]
    bot.approve_media(item.id)
    return item


class TestPublishApproved:
    def test_publishes_everything_in_the_queue(self, bot, approved_item, monkeypatch):
        posted = []
        monkeypatch.setattr(
            bot, "publish_media", lambda mid: posted.append(mid) or "story-1"
        )

        assert bot_worker.publish_approved(bot) == 1
        assert posted == [approved_item.id]

    def test_nothing_to_do_is_not_an_error(self, bot):
        assert bot_worker.publish_approved(bot) == 0

    def test_daily_limit_leaves_items_queued_rather_than_failing_them(
        self, bot, approved_item, monkeypatch
    ):
        """
        Letting publish_media hit the cap would mark a good item FAILED
        forever, when all it needs is to wait for tomorrow.
        """
        bot.daily_action_limit = 0
        monkeypatch.setattr(
            bot, "publish_media", lambda mid: pytest.fail("must not attempt to post")
        )

        assert bot_worker.publish_approved(bot) == 0
        assert approved_item.status is MediaStatus.READY
        assert len(bot.get_approved_content()) == 1

    def test_one_failure_does_not_block_the_rest(self, bot, monkeypatch):
        bot.client = FakeClient(medias=[
            FakeMedia(1, "AAA", "creator"),
            FakeMedia(2, "BBB", "creator"),
        ])
        for item in bot.discover_content(hashtags=["x"]):
            bot.approve_media(item.id)

        def flaky(media_id):
            if not flaky.tried:
                flaky.tried = True
                raise RuntimeError("upload failed")
            return "story-2"
        flaky.tried = False

        monkeypatch.setattr(bot, "publish_media", flaky)

        assert bot_worker.publish_approved(bot) == 1


class TestWaitForNextCycle:
    def test_waits_the_full_interval_when_nothing_happens(self, bot, clock):
        bot_worker.wait_for_next_cycle(bot, scan_interval_hours=1, poll_seconds=60)

        assert clock.now >= 3600

    def test_returns_early_when_a_scan_is_requested(self, bot, clock):
        bot.request_scan()

        bot_worker.wait_for_next_cycle(bot, scan_interval_hours=6, poll_seconds=60)

        # one poll, not six hours
        assert clock.now == 60

    def test_publishes_approvals_during_the_wait(self, bot, clock, approved_item,
                                                 monkeypatch):
        """
        Without this, approving something just before a scan meant waiting up
        to the full interval before it posted.
        """
        posted = []

        def fake_publish(media_id):
            # mirror the real contract: publishing moves the item out of READY,
            # otherwise it would be picked up again on the next poll
            posted.append(media_id)
            item = bot.db_session.get(type(approved_item), media_id)
            item.status = MediaStatus.PUBLISHED
            bot.db_session.commit()
            return "story-1"

        monkeypatch.setattr(bot, "publish_media", fake_publish)

        bot_worker.wait_for_next_cycle(bot, scan_interval_hours=1, poll_seconds=60)

        assert posted == [approved_item.id], "an item must not be posted twice"

    def test_a_scan_request_is_not_left_set_for_the_next_cycle(self, bot, clock):
        bot.request_scan()
        bot_worker.wait_for_next_cycle(bot, scan_interval_hours=6, poll_seconds=60)

        assert bot.consume_scan_request() is False
