#!/bin/bash

# sameAs Lite simple profiler
#
# Invoke \SameAsLite\Store->querySymbol via get_symbol.php or
# via cURL and REST end-point.
#
# Usage:
#
# $ bash sameas_profile.sh get [N]
# $ bash sameas_profile.sh get [N] 2> get_times.log
# $ bash sameas_profile.sh curly [N]
# $ bash sameas_profile.sh curly [N] 2> get_curly.log
#
# where:
# - N - number of iterations. Default 1.
#
# The sameAs Lite data store is assumed to have two canons and symbols:
#
# canon                                 symbol
# http.51011a3008ce7eceba27c629f6d0020c http.f9070a2d98db3c376dcd2d4d8c0cd220
# http.e5e8c7e32278573b20b15d7349a895d1 http.f26aff24a6fd831094b2520a8a5197a3
#
# These can be created via:
#
# $ php create_data.php 100 table1 testdb > mysql.sql
#
# Each canon and each symbol is accessed per iteration, and the real
# time, obtained via the bash time command, printed on standard error.
# A log file of standard output from each invocation is captured and
# placed in get.log or curly.log.
# curly.log also includes times as provided by cURL.
#
# Copyright 2015 The University of Edinburgh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#/

# Invoke \SameAsLite\Store->querySymbol via get_symbol.php.
# Parameters:
#  URI - canon or symbol URI
function get {
    time php get_symbol.php $1 >> get.log
}

# Invoke \SameAsLite\Store->querySymbol via REST endpoint.
# Parameters:
#  URI - canon or symbol URI
function curly {
     time curl -s -w "CURL TIME: %{time_total}\n" -X GET $ENDPOINT/$1 >> curly.log
}

TIMEFORMAT="%R"
ENDPOINT=http://127.0.0.1/sameas-lite/datasets/test/symbols
URLS=(
  # canon 1
  http.51011a3008ce7eceba27c629f6d0020c
  # symbol 2
  http.f26aff24a6fd831094b2520a8a5197a3
  # symbol 1
  http.f9070a2d98db3c376dcd2d4d8c0cd220
  # canon 2
  http.e5e8c7e32278573b20b15d7349a895d1
)
COMMAND=$1
if [ $# -gt 1 ]; then
  COUNT=$2
else
  COUNT=1
fi

rm -f $COMMAND.log

for i in `seq 1 $COUNT`; do
  for URL in ${URLS[@]}; do
    $1 $URL
  done
done
