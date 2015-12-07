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

def multiline(name, foo=False, visibility=None):
  """A rule with multiline documentation.

  Some more documentation about this rule here.

  Args:
    name: A unique name for this rule.
    foo: A test argument.

      Documentation for foo continued here.
    visibility: The visibility of this rule.

      Documentation for visibility continued here.
  """
  native.genrule(
      name = name,
      out = ["foo"],
      cmd = "touch $@",
      visibility = visibility,
  )
