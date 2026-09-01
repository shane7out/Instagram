#!/usr/bin/env python3
"""Turn a calendar feed into the retreat site's availability file.

Point this at an .ics feed — Google Calendar, Apple Calendar, Outlook, or a
saved file — and it rewrites the site's availability data with the dates that
are taken. Staff book retreats in whatever calendar app they already use; the
website reads the result.

    python3 tools/sync_availability.py https://calendar.google.com/.../basic.ics
    python3 tools/sync_availability.py bookings.ics --include-labels

Event summaries are NOT published by default, because a public website should
not list who is staying. Pass --include-labels only if the summaries are
already written for public view.

An event is recorded as "held" when its calendar status is TENTATIVE or its
summary starts with HOLD or TENTATIVE, "closed" when the summary mentions
CLOSED or MAINTENANCE, and "booked" otherwise. Cancelled events are skipped.

Recurring events (RRULE) are not expanded; each is recorded on its first date
only, and a warning is printed.
"""

import argparse
import datetime as dt
import json
import pathlib
import re
import sys
import urllib.request

DEFAULT_OUT = pathlib.Path(__file__).resolve().parent.parent / "docs" / "st-ritas" / "data" / "availability.json"
DEFAULT_TIMEZONE = "America/Los_Angeles"


def read_feed(source):
    """Read an .ics feed from a URL or a local path."""
    if re.match(r"^https?://", source):
        request = urllib.request.Request(source, headers={"User-Agent": "st-ritas-availability-sync"})
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.read().decode("utf-8", errors="replace")
    return pathlib.Path(source).read_text(encoding="utf-8", errors="replace")


def unfold(text):
    """Join ICS continuation lines, which begin with a space or tab."""
    lines = []
    for raw in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if raw[:1] in (" ", "\t") and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    return lines


def parse_events(lines):
    """Yield the property dict of each VEVENT in the feed."""
    event = None
    for line in lines:
        if line.startswith("BEGIN:VEVENT"):
            event = {}
        elif line.startswith("END:VEVENT"):
            if event is not None:
                yield event
            event = None
        elif event is not None and ":" in line:
            head, value = line.split(":", 1)
            name = head.split(";", 1)[0].upper()
            event.setdefault(name, value.strip())
    return


def parse_ics_date(value):
    """Take the date part of an ICS DATE or DATE-TIME value."""
    match = re.match(r"^(\d{4})(\d{2})(\d{2})", value.strip())
    if not match:
        return None
    year, month, day = (int(part) for part in match.groups())
    try:
        return dt.date(year, month, day)
    except ValueError:
        return None


def classify(event):
    """Decide how an event should show on the public calendar."""
    summary = event.get("SUMMARY", "")
    status = event.get("STATUS", "").upper()
    upper = summary.upper()

    if status == "CANCELLED":
        return None
    if status == "TENTATIVE" or upper.startswith(("HOLD", "TENTATIVE")):
        return "held"
    if "CLOSED" in upper or "MAINTENANCE" in upper:
        return "closed"
    return "booked"


def event_to_block(event, include_labels):
    """Convert one VEVENT into a block of occupied nights, or None to skip."""
    status = classify(event)
    if status is None:
        return None

    start = parse_ics_date(event.get("DTSTART", ""))
    if start is None:
        return None

    end = parse_ics_date(event.get("DTEND", "")) or start

    # An ICS end is exclusive: an all-day event ending Sep 17 releases the
    # house on the 17th, so the last night occupied is the 16th. A same-day
    # event has no overnight at all, so it holds its own single date.
    last_night = end - dt.timedelta(days=1)
    if last_night < start:
        last_night = start

    block = {
        "start": start.isoformat(),
        "end": last_night.isoformat(),
        "status": status,
    }
    if include_labels and event.get("SUMMARY"):
        block["label"] = event["SUMMARY"]
    return block


def merge(blocks):
    """Sort blocks and join any that touch or overlap within one status."""
    blocks.sort(key=lambda block: (block["start"], block["end"]))
    merged = []
    for block in blocks:
        previous = merged[-1] if merged else None
        if (
            previous
            and previous["status"] == block["status"]
            and previous.get("label") == block.get("label")
            and dt.date.fromisoformat(block["start"])
            <= dt.date.fromisoformat(previous["end"]) + dt.timedelta(days=1)
        ):
            previous["end"] = max(previous["end"], block["end"])
        else:
            merged.append(dict(block))
    return merged


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source", help="URL or path of the .ics calendar feed")
    parser.add_argument("--out", default=str(DEFAULT_OUT), help="file to write (default: docs/st-ritas/data/availability.json)")
    parser.add_argument("--include-labels", action="store_true", help="publish event summaries (off by default)")
    parser.add_argument("--timezone", default=DEFAULT_TIMEZONE, help="timezone recorded in the output file")
    parser.add_argument("--months", type=int, default=24, help="how far ahead to keep events (default: 24)")
    args = parser.parse_args()

    try:
        text = read_feed(args.source)
    except Exception as error:  # noqa: BLE001 — the message matters more than the type here
        sys.exit("Could not read the calendar feed: %s" % error)

    today = dt.date.today()
    horizon = today + dt.timedelta(days=31 * args.months)

    blocks = []
    recurring = 0
    for event in parse_events(unfold(text)):
        if "RRULE" in event:
            recurring += 1
        block = event_to_block(event, args.include_labels)
        if block is None:
            continue
        # Keep anything that has not finished yet and is not far in the future.
        if dt.date.fromisoformat(block["end"]) < today or dt.date.fromisoformat(block["start"]) > horizon:
            continue
        blocks.append(block)

    blocks = merge(blocks)

    payload = {
        "updated": today.isoformat(),
        "timezone": args.timezone,
        "note": (
            "Generated by tools/sync_availability.py. Dates are nights occupied, "
            "inclusive of both start and end. Edits made here are overwritten on the next sync."
        ),
        "blocks": blocks,
    }

    out_path = pathlib.Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    if recurring:
        print("Warning: %d recurring event(s) were recorded on their first date only." % recurring)
    print("Wrote %d block(s) to %s" % (len(blocks), out_path))


if __name__ == "__main__":
    main()
