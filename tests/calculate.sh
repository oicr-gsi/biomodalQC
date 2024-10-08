#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

cd $1

find -name *_Summary.csv | xargs md5sum 
find -name *_dqsummary.html | xargs md5sum
