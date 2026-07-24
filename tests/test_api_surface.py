"""
Pin the instagrapi surface this project depends on.

instagrapi tracks a private, moving API, so its own method names shift between
releases. Three of the calls in this codebase - hashtag_medias, media_download
and story_upload - did not exist at all, and because discovery swallowed the
resulting AttributeError the bot reported "0 items found" for months instead of
failing.

These tests are the cheap insurance against that recurring: they fail at CI time
on the next rename, rather than silently at 3am in a Railway log nobody reads.
"""

import inspect
import re
from pathlib import Path

import pytest

from instagrapi import Client

REPO = Path(__file__).resolve().parent.parent

# Files that talk to Instagram directly
CLIENT_MODULES = ["bot_engine.py", "video_utils.py"]

CALL_RE = re.compile(r'(?:self\.)?client\.(\w+)\s*\(')


def iter_client_calls():
    """Yield (module, method_name) for every client.X(...) call in the project"""
    for name in CLIENT_MODULES:
        source = (REPO / name).read_text()
        for method in sorted(set(CALL_RE.findall(source))):
            yield name, method


def test_client_modules_exist():
    for name in CLIENT_MODULES:
        assert (REPO / name).is_file(), f"{name} is missing"


def test_some_client_calls_were_found():
    """Guard against the regex silently matching nothing and vacuously passing"""
    calls = list(iter_client_calls())
    assert len(calls) >= 8, f"only found {len(calls)} client calls, regex may be broken"


@pytest.mark.parametrize("module,method", list(iter_client_calls()))
def test_client_method_exists(module, method):
    assert hasattr(Client, method), (
        f"{module} calls client.{method}(), which does not exist on instagrapi's "
        f"Client. It was probably renamed - check the changelog before patching."
    )


@pytest.mark.parametrize("method,kwarg", [
    ("video_download", "folder"),
    ("video_upload_to_story", "caption"),
    ("hashtag_medias_recent", "amount"),
    ("user_medias", "amount"),
])
def test_client_keyword_argument_exists(method, kwarg):
    params = inspect.signature(getattr(Client, method)).parameters
    assert kwarg in params, f"Client.{method}() no longer accepts {kwarg}="


def test_user_medias_takes_a_user_id_not_a_username():
    """
    Regression guard. This was called with a username, which raised, and the
    handler returned an engagement rate of 0 - so every creator failed the
    engagement filter and discovery could never accept anything.
    """
    params = list(inspect.signature(Client.user_medias).parameters)
    assert "user_id" in params
    assert "username" not in params


def test_removed_methods_stay_removed():
    """The three calls that never existed. If any reappears, revisit the fix."""
    for gone in ["hashtag_medias", "media_download", "story_upload"]:
        assert not hasattr(Client, gone), (
            f"Client.{gone}() now exists. The code was rewritten to avoid it; "
            f"that rewrite is still correct, but the comments explaining why "
            f"are now misleading."
        )
