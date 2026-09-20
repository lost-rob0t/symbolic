#!/usr/bin/env python3
"""ActivityWatch collector for the Symbolic knowledge base.

Fetches buckets and recent events from a local ActivityWatch server and
writes sanitized JSONL observations for Prolog ingestion. Stdlib only.
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

SOURCE = "activitywatch v0.13.2"
TITLE_MAX = 80
TOKEN_MAX = 30
REDACTED = "<redacted>"
LONG_TOKEN_RE = re.compile(r"\S{%d,}" % (TOKEN_MAX + 1))
ISO_DURATION_RE = re.compile(
    r"^P(?:(\d+(?:\.\d+)?)D)?"
    r"(?:T(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)S)?)?$"
)
CLOCK_DURATION_RE = re.compile(r"^(?:(\d+):)?(\d+):(\d+(?:\.\d+)?)$")


def utc_now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def http_get_json(url, timeout):
    request = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def parse_duration(raw):
    if isinstance(raw, (int, float)):
        return float(raw)
    if not isinstance(raw, str):
        return 0.0
    text = raw.strip()
    if text.startswith(("P", "p")):
        match = ISO_DURATION_RE.match(text)
        if match:
            days, hours, minutes, seconds = (
                float(group) if group else 0.0 for group in match.groups()
            )
            return days * 86400.0 + hours * 3600.0 + minutes * 60.0 + seconds
        return 0.0
    match = CLOCK_DURATION_RE.match(text)
    if match:
        hours = float(match.group(1)) if match.group(1) else 0.0
        return hours * 3600.0 + float(match.group(2)) * 60.0 + float(match.group(3))
    try:
        return float(text)
    except ValueError:
        return 0.0


def redact_title(title):
    if not title:
        return None
    return LONG_TOKEN_RE.sub(REDACTED, title)[:TITLE_MAX]


def normalize_timestamp(ts):
    text = ts[:-1] + "+00:00" if ts.endswith("Z") else ts
    moment = datetime.fromisoformat(text)
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=timezone.utc)
    moment = moment.astimezone(timezone.utc).replace(microsecond=0)
    return moment.strftime("%Y-%m-%dT%H:%M:%SZ")


def bucket_kind(bucket):
    bucket_id = bucket.get("id", "")
    bucket_type = bucket.get("type", "")
    if "afk" in bucket_type or bucket_id.startswith("aw-watcher-afk"):
        return "afk"
    if bucket_type == "currentwindow" or bucket_id.startswith("aw-watcher-window"):
        return "window"
    return None


def bucket_host(bucket):
    host = bucket.get("hostname")
    if host:
        return host
    bucket_id = bucket.get("id", "")
    return bucket_id.split("_", 1)[1] if "_" in bucket_id else bucket_id


def iter_events(url, limit, timeout):
    buckets = http_get_json(url + "/api/0/buckets", timeout)
    for bucket_id, bucket in sorted(buckets.items()):
        kind = bucket_kind(bucket)
        if kind is None:
            print("aw_collect: skipping unsupported bucket %s" % bucket_id,
                  file=sys.stderr)
            continue
        endpoint = "%s/api/0/buckets/%s/events?limit=%d" % (
            url, urllib.parse.quote(bucket_id, safe=""), limit)
        events = http_get_json(endpoint, timeout)
        host = bucket_host(bucket)
        collected_at = utc_now_iso()
        for event in sorted(events, key=lambda item: int(item.get("id", 0))):
            data = event.get("data") or {}
            yield {
                "observation": "aw_event",
                "bucket": bucket_id,
                "event_id": event.get("id"),
                "timestamp": normalize_timestamp(event["timestamp"]),
                "duration_s": parse_duration(event.get("duration", 0.0)),
                "kind": kind,
                "app": data.get("app"),
                "title": redact_title(data.get("title")),
                "status": data.get("status"),
                "host": host,
                "collected_at": collected_at,
                "source": SOURCE,
            }


def load_state(path):
    if not path or not os.path.exists(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return (json.load(handle) or {}).get("buckets", {})
    except (OSError, ValueError):
        return {}


def save_state(path, buckets):
    if not path:
        return
    parent = os.path.dirname(os.path.abspath(path))
    os.makedirs(parent, exist_ok=True)
    document = {"buckets": buckets, "updated_at": utc_now_iso()}
    temporary = path + ".tmp"
    with open(temporary, "w", encoding="utf-8") as handle:
        json.dump(document, handle, indent=2, sort_keys=True)
        handle.write("\n")
    os.replace(temporary, path)


def ensure_parent_dir(path):
    parent = os.path.dirname(os.path.abspath(path))
    if parent:
        os.makedirs(parent, exist_ok=True)


def cmd_collect(args):
    state = load_state(args.state)
    ensure_parent_dir(args.out)
    written = 0
    highest = {}
    try:
        with open(args.out, "w", encoding="utf-8") as out:
            for record in iter_events(args.url, args.limit, args.timeout):
                bucket = record["bucket"]
                event_id = record["event_id"]
                seen = state.get(bucket)
                if seen is not None and event_id is not None and event_id <= seen:
                    continue
                out.write(json.dumps(record, sort_keys=True) + "\n")
                written += 1
                if event_id is not None:
                    highest[bucket] = max(highest.get(bucket, event_id), event_id)
    except (urllib.error.URLError, OSError, ValueError, KeyError) as exc:
        print("aw_collect: collect failed: %s" % exc, file=sys.stderr)
        return 1
    merged = dict(state)
    merged.update(highest)
    save_state(args.state, merged)
    print("aw_collect: %d events -> %s" % (written, args.out))
    return 0


def cmd_status(args):
    try:
        info = http_get_json(args.url + "/api/0/info", args.timeout)
        buckets = http_get_json(args.url + "/api/0/buckets", args.timeout)
    except (urllib.error.URLError, OSError, ValueError) as exc:
        print("aw_collect: server unreachable at %s: %s" % (args.url, exc),
              file=sys.stderr)
        return 1
    print("aw_collect: server %s version %s" % (
        info.get("hostname", "?"), info.get("version", "?")))
    print("aw_collect: %d buckets" % len(buckets))
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(prog="aw_collect.py")
    subparsers = parser.add_subparsers(dest="command", required=True)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--url", default="http://127.0.0.1:5600")
    common.add_argument("--timeout", type=float, default=10.0)
    collect_parser = subparsers.add_parser("collect", parents=[common])
    collect_parser.add_argument("--limit", type=int, default=500)
    collect_parser.add_argument("--out", required=True)
    collect_parser.add_argument("--state", default=None)
    collect_parser.set_defaults(func=cmd_collect)
    status_parser = subparsers.add_parser("status", parents=[common])
    status_parser.set_defaults(func=cmd_status)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
