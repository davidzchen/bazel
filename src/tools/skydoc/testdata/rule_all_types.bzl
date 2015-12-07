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

def impl(ctx):
  return struct()

all_types = rule(
    implementation = impl,
    attrs = {
        "arg_bool": attr.bool(),
        "arg_int": attr.int(),
        "arg_int_list": attr.int_list(),
        "arg_label": attr.label(),
        "arg_label_list": attr.label_list(),
        "arg_license": attr.license(),
        "arg_output": attr.output(),
        "arg_output_list": attr.output_list(),
        "arg_string": attr.string(),
        "arg_string_dict": attr.string_dict(),
        "arg_string_list": attr.string_list(),
        "arg_string_list_dict": attr.string_list_dict(),
    },
)
"""Test rule with all types.

Args:
  name: A unique name for this rule.
  arg_bool: A boolean argument.
  arg_int: An integer argument.
  arg_int_list: A list of integers argument.
  arg_label: A label argument.
  arg_label_list: A list of labels argument.
  arg_license: A license argument.
  arg_output: An output argument.
  arg_output_list: A list of outputs argument.
  arg_string: A string argument.
  arg_string_dict: A dictionary mapping string to string argument.
  arg_string_list: A list of strings argument.
  arg_string_list_dict: A dictionary mapping string to list of string argument.
"""
