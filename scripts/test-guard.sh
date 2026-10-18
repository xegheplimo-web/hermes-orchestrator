#!/usr/bin/env bash
exec bash "$(cd "$(dirname "$0")" && pwd)/agent-hooks/test-guard.sh" "$@"
