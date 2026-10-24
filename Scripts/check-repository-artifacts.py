#!/usr/bin/env python3
"""Reject generated evidence in the index; use --all to inspect a clean clone."""
import argparse
from pathlib import PurePosixPath
import subprocess
import sys


def git(*arguments):
    return subprocess.check_output(['git', *arguments])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--staged', action='store_true')
    mode.add_argument('--all', action='store_true')
    options = parser.parse_args()
    data = (git('diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z')
            if options.staged else git('ls-files', '-z'))
    failures = []
    for raw in data.split(b'\0'):
        if not raw:
            continue
        name = raw.decode('utf-8', errors='surrogateescape')
        path = PurePosixPath(name)
        if (name.startswith(('evals/stage1/evidence/', '.runs/'))
                or any(part in {'.build', '__pycache__'} for part in path.parts)
                or name.endswith(('.pyc', '.bundle', '.tar.gz'))
                or path.name in {'runtime-bundled-catalog.json', 'runtime-model-catalog.json'}):
            failures.append('Generated run artifact: '+name)
            continue
        size = int(git('cat-file', '-s', ':'+name))
        if size > 2 * 1024 * 1024:
            failures.append('File exceeds the 2 MiB source/fixture budget: '+name)
    if failures:
        print('\n'.join(failures), file=sys.stderr)
        print('Archive raw runs outside Git; keep only explicit small regression fixtures.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
