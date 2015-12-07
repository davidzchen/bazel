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

import unittest

import os

from google.protobuf import text_format
from src.main.protobuf import build_pb2
from src.tools.skydoc import rule_extractor

TESTDATA_PATH = os.path.join(os.getcwd(), "src/tools/skydoc/testdata")

class RuleExtractorTest(unittest.TestCase):
  def check(self, expected, bzl_file):
    expected_proto = build_pb2.BuildLanguage()
    text_format.Merge(expected, expected_proto)

    extractor = rule_extractor.RuleDocExtractor()
    extractor.parse_bzl(os.path.join(TESTDATA_PATH, bzl_file))
    proto = extractor.proto()
    self.assertEqual(expected_proto, proto)

  def testAllTypes(self):
    expected = (
        'rule {\n'
        '  name: "all_types"\n'
        '  documentation: "Test rule with all types."\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: NAME\n'
        '    mandatory: true\n'
        '    documentation: "A unique name for this rule."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_bool"\n'
        '    type: BOOLEAN\n'
        '    mandatory: false\n'
        '    documentation: "A boolean argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_int"\n'
        '    type: INTEGER\n'
        '    mandatory: false\n'
        '    documentation: "An integer argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_int_list"\n'
        '    type: INTEGER_LIST\n'
        '    mandatory: false\n'
        '    documentation: "A list of integers argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_label"\n'
        '    type: LABEL\n'
        '    mandatory: false\n'
        '    documentation: "A label argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_label_list"\n'
        '    type: LABEL_LIST\n'
        '    mandatory: false\n'
        '    documentation: "A list of labels argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_license"\n'
        '    type: LICENSE\n'
        '    mandatory: false\n'
        '    documentation: "A license argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_output"\n'
        '    type: OUTPUT\n'
        '    mandatory: false\n'
        '    documentation: "An output argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_output_list"\n'
        '    type: OUTPUT_LIST\n'
        '    mandatory: false\n'
        '    documentation: "A list of outputs argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_string"\n'
        '    type: STRING\n'
        '    mandatory: false\n'
        '    documentation: "A string argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_string_dict"\n'
        '    type: STRING_DICT\n'
        '    mandatory: false\n'
        '    documentation: "A dictionary mapping string to string argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_string_list"\n'
        '    type: STRING_LIST\n'
        '    mandatory: false\n'
        '    documentation: "A list of strings argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_string_list_dict"\n'
        '    type: STRING_LIST_DICT\n'
        '    mandatory: false\n'
        '    documentation: "A dictionary mapping string to list of string '
        'argument."\n'
        '  }\n'
        '}\n')
    self.check(expected, "rule_all_types.bzl")

  def testUndocumented(self):
    expected = (
        'rule {\n'
        '  name: "undocumented"\n'
        '  documentation: ""\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: NAME\n'
        '    mandatory: true\n'
        '    documentation: ""\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_label"\n'
        '    type: LABEL\n'
        '    mandatory: false\n'
        '    documentation: ""\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_string"\n'
        '    type: STRING\n'
        '    mandatory: false\n'
        '    documentation: ""\n'
        '  }\n'
        '}\n')
    self.check(expected, "rule_undocumented.bzl")

  def testPrivateRulesSkipped(self):
    expected = (
        'rule {\n'
        '  name: "public"\n'
        '  documentation: "A public rule that should appear in '
        'documentation."\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: NAME\n'
        '    mandatory: true\n'
        '    documentation: "A unique name for this rule."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_label"\n'
        '    type: LABEL\n'
        '    mandatory: false\n'
        '    documentation: "A label argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_string"\n'
        '    type: STRING\n'
        '    mandatory: false\n'
        '    documentation: "A string argument."\n'
        '  }\n'
        '}\n')
    self.check(expected, "rule_private.bzl")

  def testMultiLineDescription(self):
    expected = (
        'rule {\n'
        '  name: "multiline"\n'
        '  documentation: "A rule with multiline documentation.\\n\\n'
        'Some more documentation about this rule here."\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: NAME\n'
        '    mandatory: true\n'
        '    documentation: "A unique name for this rule."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_bool"\n'
        '    type: BOOLEAN\n'
        '    mandatory: false\n'
        '    documentation: "A boolean argument.\\n\\n'
        'Documentation for arg_bool continued here."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_label"\n'
        '    type: LABEL\n'
        '    mandatory: false\n'
        '    documentation: "A label argument.\\n\\n'
        'Documentation for arg_label continued here."\n'
        '  }\n'
        '}\n')
    self.check(expected, "rule_multi_line.bzl")

  def testRuleMacroMix(self):
    expected = (
        'rule {\n'
        '  name: "example_rule"\n'
        '  documentation: "An example rule."\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: NAME\n'
        '    mandatory: true\n'
        '    documentation: "A unique name for this rule."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_label"\n'
        '    type: LABEL\n'
        '    mandatory: false\n'
        '    documentation: "A label argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "arg_string"\n'
        '    type: STRING\n'
        '    mandatory: false\n'
        '    documentation: "A string argument."\n'
        '  }\n'
        '}\n')
    self.check(expected, "rule_macro_mix.bzl")

if __name__ == '__main__':
  unittest.main()
