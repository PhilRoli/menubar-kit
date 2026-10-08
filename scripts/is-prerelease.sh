#!/bin/bash
# Exit 0 if the tag (vMAJOR.MINOR.PATCH-suffix) is a prerelease, 1 otherwise.
TAG="${1:?Usage: is-prerelease.sh <tag>}"
[[ "$TAG" == *-* ]]
