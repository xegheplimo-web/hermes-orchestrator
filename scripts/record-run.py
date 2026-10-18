#!/usr/bin/env python3
"""Append one machine-readable run record to RUNS.jsonl (hermes.run.v1)."""
import argparse
import json
import sys
from datetime import datetime, timezone
from typing import NoReturn
from pathlib import Path

SCHEMA = "hermes.run.v1"
REQUIRED = [
    "run_id", "task_id", "agent", "model", "task_type", "duration_s",
    "exit_code", "provider_failure", "verify_status", "retry_index", "verified_by",
]
AGENTS = {"cline", "opencode", "devin", "hermes"}
VERIFY_STATUSES = {"PASS", "FAIL", "PENDING", "UNVERIFIED"}


def parse_bool(value):
    s = str(value).strip().lower()
    if s in ("true", "1", "yes", "y"):
        return True
    if s in ("false", "0", "no", "n"):
        return False
    raise argparse.ArgumentTypeError("invalid boolean value: %r" % value)


def fail(msg: str) -> NoReturn:
    print("ERROR: %s" % msg, file=sys.stderr)
    sys.exit(1)


def main():
    ap = argparse.ArgumentParser(description="Append a hermes.run.v1 record to RUNS.jsonl")
    ap.add_argument("--orchestrator-dir", default=".orchestrator")
    ap.add_argument("--run-id", required=True)
    ap.add_argument("--task-id", required=True)
    ap.add_argument("--agent", required=True)
    ap.add_argument("--model", required=True)
    ap.add_argument("--task-type", required=True)
    ap.add_argument("--duration-s", required=True, type=int)
    ap.add_argument("--exit-code", required=True, type=int)
    ap.add_argument("--provider-failure", required=True, type=parse_bool)
    ap.add_argument("--verify-status", required=True)
    ap.add_argument("--retry-index", required=True, type=int)
    ap.add_argument("--salvaged", type=parse_bool, default=False)
    ap.add_argument("--verified-by", required=True)
    ap.add_argument("--timestamp")
    args = ap.parse_args()

    if args.agent not in AGENTS:
        fail("agent must be one of %s (got %r)" % (sorted(AGENTS), args.agent))
    if args.verify_status not in VERIFY_STATUSES:
        fail("verify_status must be one of %s (got %r)" % (sorted(VERIFY_STATUSES), args.verify_status))

    agent_fail = None
    if not str(args.run_id).strip(): agent_fail = "run_id must be non-empty"
    elif not str(args.task_id).strip(): agent_fail = "task_id must be non-empty"
    elif not str(args.model).strip(): agent_fail = "model must be non-empty"
    elif not str(args.task_type).strip(): agent_fail = "task_type must be non-empty"
    elif not str(args.verified_by).strip(): agent_fail = "verified_by must be non-empty"
    elif args.duration_s < 0: agent_fail = "duration_s must be >= 0"
    elif args.retry_index < 0: agent_fail = "retry_index must be >= 0"
    if agent_fail:
        fail(agent_fail)

    runs_dir = Path(args.orchestrator_dir)
    runs_dir.mkdir(parents=True, exist_ok=True)
    runs_path = runs_dir / "RUNS.jsonl"

    existing_ids = set()
    if runs_path.exists():
        with runs_path.open("r", encoding="utf-8") as f:
            for lineno, raw in enumerate(f, 1):
                line = raw.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    # A corrupt telemetry line must never be silently skipped:
                    # appending past it would hide the damage. Refuse and leave
                    # the file untouched for investigation.
                    fail("corrupt JSON at RUNS.jsonl line %d — refusing to append "
                         "(file left untouched)" % lineno)
                if not isinstance(obj, dict) or "run_id" not in obj:
                    fail("record without run_id at RUNS.jsonl line %d — refusing to append "
                         "(file left untouched)" % lineno)
                existing_ids.add(obj["run_id"])
    if args.run_id in existing_ids:
        fail("run_id already exists: %r" % args.run_id)

    record = {
        "schema": SCHEMA,
        "run_id": args.run_id,
        "task_id": args.task_id,
        "agent": args.agent,
        "model": args.model,
        "task_type": args.task_type,
        "duration_s": args.duration_s,
        "exit_code": args.exit_code,
        "provider_failure": args.provider_failure,
        "verify_status": args.verify_status,
        "retry_index": args.retry_index,
        "salvaged": args.salvaged,
        "verified_by": args.verified_by,
        "timestamp": args.timestamp or datetime.now(timezone.utc).isoformat(),
    }

    with runs_path.open("a", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(record) + "\n")


if __name__ == "__main__":
    main()
