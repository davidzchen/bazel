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

set -eu

readonly VERSION_BZL_FILE=${PWD}/$1
shift
readonly VERSION=$1

TEMPF=$(mktemp -t bazel-version-XXXXXX)
cat $VERSION_BZL_FILE | sed "s,master,${VERSION},g" > "$TEMPF"
cat "$TEMPF" > $VERSION_BZL_FILE
