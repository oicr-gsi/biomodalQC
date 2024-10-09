#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

cd "$1"

ls | sed 's/.*\.//' | sort | uniq -c
