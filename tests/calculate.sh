#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

cd "$1"

ls | sed 's/.*\.//' | sort | uniq -c
find . -name "*_Summary.csv" -type f | xargs md5sum
