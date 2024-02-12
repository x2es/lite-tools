#!/usr/bin/env python3
import sys
import re
from argparse import ArgumentParser
import json

# Spread outdated gems by release majority
#
# Usage:
#   ./audit-outdated-gems.py -h
#   bundle outdated | ./audit-outdated-gems.py
#   bundle outdated | ./audit-outdated-gems.py --json

GEM_NAME_IX = 0
VERSION_INSTALLED_IX = 1
VERSION_AVAILABLE_IX = 2

def print_json(gems_outdated, titles):
    json_payload = {
        'level': {},
        'stat': {}
    }
    for level in range(0, len(titles)):
        json_payload['stat'][titles[level]] = {'count': len(gems_outdated[level])}
        json_payload['level'][titles[level]] = []

        for gem in gems_outdated[level]:
            json_payload['level'][titles[level]].append({
                gem[GEM_NAME_IX]: {
                    'installed': gem[VERSION_INSTALLED_IX],
                    'available': gem[VERSION_AVAILABLE_IX]
                }
            })

    json_data = json.dumps(json_payload)
    print(json_data)


def print_human(gems_outdated, titles):
    for level in range(0, len(titles)):
        print((" " + titles[level].upper() + " " + str(len(gems_outdated[level])) + " items ").center(30, "="))
        for gem in gems_outdated[level]:
            print(gem[GEM_NAME_IX] + " " + gem[VERSION_INSTALLED_IX] + " < " + gem[VERSION_AVAILABLE_IX])


def main():
    args_parser = ArgumentParser(
        prog="audit-outdated-gems",
        description="Audit `bundle outdated` output. Usage: `bundle outdated | audit-outdated_gems`"
    )

    args_parser.add_argument("--json", help="json output", action="store_true")
    opts = args_parser.parse_args()

    gems_table = []
    for line in sys.stdin:
        parts = re.split(r'\s{2,}', line.rstrip())
        if len(parts) > 2:
            gems_table.append(parts)

    gems_outdated = [
        [],  # major X.y.y
        [],  # minor y.X.y
        [],  # patch y.y.X
        [],  # micro y.y.y.X.X.X
    ]

    for gem in gems_table:
        installed_version_string = gem[VERSION_INSTALLED_IX]
        available_version_string = gem[VERSION_AVAILABLE_IX]

        if installed_version_string == "Current" and available_version_string == "Latest":
            continue

        installed_version_parts = installed_version_string.split('.')
        available_version_parts = available_version_string.split('.')

        for part_i in range(0, max(len(installed_version_parts), len(available_version_parts))):
            if part_i < len(installed_version_parts):
                installed_version = installed_version_parts[part_i]
            else:
                installed_version = "0"

            if part_i < len(available_version_parts):
                available_version = available_version_parts[part_i]
            else:
                available_version = "0"

            if installed_version < available_version:
                slice_ix = min(part_i, 3) # any length of micro chain
                gems_outdated[slice_ix].append(gem)
                break

    titles = ['major', 'minor', 'patch', 'micro']

    if opts.json:
        print_json(gems_outdated, titles)
    else:
        print_human(gems_outdated, titles)


if __name__ == '__main__':
    main()
