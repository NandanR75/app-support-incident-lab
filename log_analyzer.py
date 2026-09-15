"""
log_analyzer.py

Parses an application log file and summarizes it by log level and by
recurring error message, similar to a quick manual triage you'd do with
grep/awk before reaching for a tool like Splunk or Kibana.

Usage:
    python3 log_analyzer.py <path_to_log_file>
"""

import re
import sys
from collections import Counter, defaultdict

LOG_LINE_RE = re.compile(
    r"^(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+"
    r"(?P<level>INFO|WARN|ERROR)\s+"
    r"(?P<message>.*)$"
)


def parse_log(path):
    entries = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            match = LOG_LINE_RE.match(line)
            if match:
                entries.append(match.groupdict())
            else:
                entries.append({"timestamp": None, "level": "UNPARSED", "message": line})
    return entries


def summarize(entries):
    level_counts = Counter(e["level"] for e in entries)

    # Group error messages by a normalized "signature" (strip numbers/IDs)
    # so repeated errors with different IDs/durations still bucket together.
    error_signatures = defaultdict(list)
    for e in entries:
        if e["level"] == "ERROR":
            signature = re.sub(r"\d+", "#", e["message"])
            error_signatures[signature].append(e["timestamp"])

    return level_counts, error_signatures


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 log_analyzer.py <path_to_log_file>")
        sys.exit(2)

    path = sys.argv[1]
    entries = parse_log(path)
    level_counts, error_signatures = summarize(entries)

    print(f"Log Analysis: {path}")
    print(f"Total lines parsed: {len(entries)}")
    print("-" * 45)
    print("Counts by level:")
    for level in ("ERROR", "WARN", "INFO", "UNPARSED"):
        if level_counts.get(level):
            print(f"  {level:<10} {level_counts[level]}")

    if error_signatures:
        print("-" * 45)
        print("Recurring error patterns (grouped, numbers normalized):")
        for sig, timestamps in sorted(error_signatures.items(), key=lambda x: -len(x[1])):
            print(f"  x{len(timestamps):<3} {sig}")
            print(f"        first seen: {timestamps[0]}   last seen: {timestamps[-1]}")
    else:
        print("No ERROR-level lines found.")


if __name__ == "__main__":
    main()
