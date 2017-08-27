#!/bin/bash

# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script used to add a new version number to the versions data file in the
# Jekyll tree, which is used to generate the dropdown containing all the
# published versions of the Bazel documentation.
#
# usage:
# scripts/release/add_doc_version.sh site/_data/versions.yml 1.0

set -eu

readonly VERSION_DATA_FILE=${PWD}/$1
shift
readonly VERSION=$1

cat <<EOF >> $VERSION_DATA_FILE
- ${VERSION}
EOF
