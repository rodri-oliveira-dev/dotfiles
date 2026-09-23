#!/usr/bin/env python3
"""Format one MSBuild -getProperty:... JSON evaluation as dotnet-props text.

Internal helper: read one JSON document from stdin and print nothing until all
required property values have been checked. Do not invoke MSBuild or projects.
"""

import json
import sys


def main() -> int:
    project, *properties = sys.argv[1:]

    try:
        document = json.load(sys.stdin)
    except (ValueError, UnicodeError):
        print("Error: invalid MSBuild property JSON response.", file=sys.stderr)
        return 1

    if not isinstance(document, dict):
        print("Error: unexpected MSBuild property JSON response.", file=sys.stderr)
        return 1

    values = document.get("Properties")
    if not isinstance(values, dict) or any(
        name not in values or not isinstance(values[name], str)
        for name in properties
    ):
        print("Error: MSBuild property JSON response is missing required string values.", file=sys.stderr)
        return 1

    # Validate the whole snapshot first: a missing final property cannot leave
    # a plausible but incomplete report on stdout.
    result = [f"Project: {project}\n\n"]
    result.extend(f"{name + ':':<38} {values[name]}\n" for name in properties)
    sys.stdout.write("".join(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
