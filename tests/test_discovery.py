"""
Discovery behaviour, and above all its failure reporting.

The bug that mattered here was not any single wrong method name - it was that a
broken scan and an empty scan produced identical output. These tests pin the
difference.
"""

import pytest

from conftest import FakeClient, FakeMedia, FakeUser
from bot_engine import extract_hashtags


class TestHashtagExtraction:
    def test_pulls_tags_from_caption(self):
        assert extract_hashtags("Tacos #lasvegasfood #vegaseats!") == [
            "lasvegasfood", "vegaseats"
        ]

    def test_handles_missing_caption(self):
        assert extract_hashtags(None) == []
        assert extract_hashtags("") == []

    def test_caption_with_no_tags(self):
        assert extract_hashtags("just a caption") == []


class TestDiscovery:
    def test_accepts_qualifying_content(self, bot):
        bot.client = FakeClient(medias=[FakeMedia(1, "AAA", "goodcreator")])

        found = bot.discover_content(hashtags=["lasvegasfood"])

        assert len(found) == 1
        assert found[0].code == "AAA"
        assert bot.last_discovery_stats["accepted"] == 1

    def test_records_hashtags_parsed_from_the_caption(self, bot):
        bot.client = FakeClient(medias=[FakeMedia(1, "AAA", "goodcreator")])

        found = bot.discover_content(hashtags=["lasvegasfood"])

        assert found[0].hashtags == "lasvegasfood,vegaseats"

    def test_records_mentions_from_usertags(self, bot):
        from conftest import FakeUsertag
        media = FakeMedia(1, "AAA", "goodcreator", usertags=[FakeUsertag("tagged_friend")])
        bot.client = FakeClient(medias=[media])

        found = bot.discover_content(hashtags=["lasvegasfood"])

        assert found[0].mentions == "tagged_friend"


class TestRejectionAccounting:
    """Every filter must say so, otherwise a zero result explains nothing."""

    def test_counts_non_videos(self, bot):
        bot.client = FakeClient(medias=[FakeMedia(1, "AAA", "creator", media_type=1)])

        assert bot.discover_content(hashtags=["x"]) == []
        assert bot.last_discovery_stats["not_video"] == 1

    def test_counts_private_accounts(self, bot):
        bot.client = FakeClient(
            medias=[FakeMedia(1, "AAA", "shy")],
            users={"shy": FakeUser("shy", private=True)},
        )

        assert bot.discover_content(hashtags=["x"]) == []
        assert bot.last_discovery_stats["private"] == 1

    def test_counts_low_follower_accounts(self, bot):
        bot.client = FakeClient(
            medias=[FakeMedia(1, "AAA", "tiny")],
            users={"tiny": FakeUser("tiny", followers=12)},
        )

        assert bot.discover_content(hashtags=["x"], min_followers=1000) == []
        assert bot.last_discovery_stats["low_followers"] == 1

    def test_counts_low_engagement_accounts(self, bot):
        # 550 interactions against 10 million followers is far below 2%
        bot.client = FakeClient(
            medias=[FakeMedia(1, "AAA", "huge")],
            users={"huge": FakeUser("huge", followers=10_000_000)},
        )

        assert bot.discover_content(hashtags=["x"]) == []
        assert bot.last_discovery_stats["low_engagement"] == 1

    def test_counts_already_known_media(self, bot):
        bot.client = FakeClient(medias=[FakeMedia(1, "AAA", "creator")])

        assert len(bot.discover_content(hashtags=["x"])) == 1
        assert len(bot.discover_content(hashtags=["x"])) == 0
        assert bot.last_discovery_stats["already_known"] == 1

    def test_counters_sum_to_the_candidate_total(self, bot):
        bot.client = FakeClient(medias=[
            FakeMedia(1, "AAA", "good"),
            FakeMedia(2, "BBB", "photo", media_type=1),
            FakeMedia(3, "CCC", "tiny"),
        ], users={"tiny": FakeUser("tiny", followers=5)})

        bot.discover_content(hashtags=["x"], min_followers=1000)
        s = bot.last_discovery_stats

        accounted = (s["not_video"] + s["already_known"] + s["no_profile"]
                     + s["private"] + s["low_followers"] + s["low_engagement"]
                     + s["accepted"])
        assert accounted == s["candidates"] == 3


class TestFailureVisibility:
    def test_programming_errors_are_not_swallowed(self, bot):
        """
        The regression that cost months. discover_content wrapped each hashtag
        in a bare `except Exception`, so calling a method that did not exist
        raised AttributeError, got logged as an Instagram problem, and the scan
        reported zero items found.
        """
        bot.client = FakeClient(on_hashtag=AttributeError("no such method"))

        with pytest.raises(AttributeError):
            bot.discover_content(hashtags=["lasvegasfood"])

    def test_transient_errors_are_still_tolerated(self, bot):
        """Network trouble must not abort a whole scan - that part was right."""
        bot.client = FakeClient(on_hashtag=ConnectionError("connection reset"))

        assert bot.discover_content(hashtags=["a", "b"]) == []
        assert bot.last_discovery_stats["hashtags_failed"] == 2

    def test_empty_api_response_is_distinguishable_from_filtered_out(self, bot):
        bot.client = FakeClient(medias=[])

        bot.discover_content(hashtags=["x"])

        # zero candidates means the API gave us nothing, which is the alarming
        # case - as opposed to candidates arriving and being filtered away
        assert bot.last_discovery_stats["candidates"] == 0
        assert bot.last_discovery_stats["accepted"] == 0

    def test_bug_in_a_helper_also_propagates(self, bot, monkeypatch):
        """get_user_info and get_engagement_rate had the same swallowing bug."""
        def exploding_user_info(username):
            raise AttributeError("typo in a field name")

        bot.client = FakeClient(medias=[FakeMedia(1, "AAA", "creator")])
        monkeypatch.setattr(bot.client, "user_info_by_username", exploding_user_info)

        with pytest.raises(AttributeError):
            bot.discover_content(hashtags=["x"])
