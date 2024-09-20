#!/usr/bin/env bash
#
# Returns the next version number for a release.
#
# Can be run four different ways.
#
# Return the next major version number, e.g. 1.0.0:
#    ./next-version.sh -m
#
# Return the next minor version number (switch is optional), e.g. 0.1.0:
#    ./next-version.sh
#    ./next-version.sh -n
#
# Return the next version number with a supplied patch value, e.g. 0.0.123:
#    ./next-version.sh -p 123
#
# Return the current version number:
#    ./next-version.sh -c

set -e

# Ensure we're in the root of the repo so that gh works as expected
cd "$(dirname "$0")/.."

LATEST_VERSION=$(gh release list --exclude-drafts --exclude-pre-releases --json tagName --limit 1 | jq -r '.[0].tagName')
if [ "$LATEST_VERSION" == "null" ]; then
  # this will be the first release
  LATEST_VERSION="0.0.0"
fi

if [ "$1" == "-c" ]; then
  echo $LATEST_VERSION
  exit 0
fi

MAJOR_VERSION=$(echo "$LATEST_VERSION" | sed -En 's/^([0-9]+)\.[0-9]+\.[0-9]+$/\1/p')
MINOR_VERSION=$(echo "$LATEST_VERSION" | sed -En 's/^[0-9]+\.([0-9]+)\.[0-9]+$/\1/p')

if [ "$1" == "-m" ]; then
  echo $((MAJOR_VERSION + 1)).0.0
  exit 0
fi
if [ "$1" == "-n" ] || [ -z "$1" ]; then
  echo $MAJOR_VERSION.$((MINOR_VERSION + 1)).0
  exit 0
fi
if [ "$1" == "-p" ] && [ ! -z "$2" ]; then
  echo $MAJOR_VERSION.$MINOR_VERSION.$2
  exit 0
fi

echo "Usage: $0 [-c | -m | -n | -p <patch>]" 1>&2
echo "  -c          Return the current version number" 1>&2
echo "  -m          Return the next major version number" 1>&2
echo "  -n          Return the next minor version number (the default)" 1>&2
echo "  -p <patch>  Return the next version number using the supplied patch number" 1>&2
exit 1
