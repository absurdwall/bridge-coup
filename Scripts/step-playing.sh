#!/bin/sh
set -eu

# Check before starting a board: the terminal carries next/stop commands.
if [ ! -t 0 ]; then
    echo "Interactive walkthrough requires a live terminal on stdin; launch this script directly." >&2
    exit 2
fi

bridge_script_dir=$(cd "$(dirname "$0")" && pwd)
bridge_binary="$bridge_script_dir/../.build/debug/bridge-play"
if [ ! -x "$bridge_binary" ]; then
    echo "Build bridge-play before starting the walkthrough." >&2
    exit 2
fi

# exec preserves the caller's terminal and the running board's lifetime.
exec "$bridge_binary" "$@" --interactive true --decisions 26
