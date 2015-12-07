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
from src.tools.skydoc import macro_extractor

TESTDATA_PATH = os.path.join(os.getcwd(), "src/tools/skydoc/testdata")

class MacroExtractorTest(unittest.TestCase):
  def check(self, expected, bzl_file):
    expected_proto = build_pb2.BuildLanguage()
    text_format.Merge(expected, expected_proto)

    extractor = macro_extractor.MacroDocExtractor()
    extractor.parse_bzl(os.path.join(TESTDATA_PATH, bzl_file))
    proto = extractor.proto()
    self.assertEqual(expected_proto, proto)

  def testMultiLineDescription(self):
    expected = (
        'rule {\n'
        '  name: "multiline"\n'
        '  documentation: "A rule with multiline documentation.\\n\\n'
        'Some more documentation about this rule here."\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: UNKNOWN\n'
        '    mandatory: true\n'
        '    documentation: "A unique name for this rule."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "foo"\n'
        '    type: UNKNOWN\n'
        '    mandatory: false\n'
        '    documentation: "A test argument.\\n\\n'
        'Documentation for foo continued here."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "visibility"\n'
        '    type: UNKNOWN\n'
        '    mandatory: false\n'
        '    documentation: "The visibility of this rule.\\n\\n'
        'Documentation for visibility continued here."\n'
        '  }\n'
        '}\n')
    self.check(expected, "macro_multi_line.bzl")

  def testUndocumented(self):
    expected = (
        'rule {\n'
        '  name: "undocumented"\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: UNKNOWN\n'
        '    mandatory: true\n'
        '  }\n'
        '  attribute {\n'
        '    name: "visibility"\n'
        '    type: UNKNOWN\n'
        '    mandatory: false\n'
        '  }\n'
        '}\n')
    self.check(expected, "macro_undocumented.bzl")

  def testPrivateMacrosSkipped(self):
    expected = (
        'rule {\n'
        '  name: "public"\n'
        '  documentation: "A public macro that should appear in docs."\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: UNKNOWN\n'
        '    mandatory: true\n'
        '    documentation: "A unique name for this rule."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "visibility"\n'
        '    type: UNKNOWN\n'
        '    mandatory: false\n'
        '    documentation: "The visibility of this rule."\n'
        '  }\n'
        '}\n')
    self.check(expected, "macro_private.bzl")

  def testRuleMacroMix(self):
    expected = (
        'rule {\n'
        '  name: "example_macro"\n'
        '  documentation: "An example macro."\n'
        '  attribute {\n'
        '    name: "name"\n'
        '    type: UNKNOWN\n'
        '    mandatory: true\n'
        '    documentation: "A unique name for this rule."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "foo"\n'
        '    type: UNKNOWN\n'
        '    mandatory: true\n'
        '    documentation: "A test argument."\n'
        '  }\n'
        '  attribute {\n'
        '    name: "visibility"\n'
        '    type: UNKNOWN\n'
        '    mandatory: false\n'
        '    documentation: "The visibility of this rule."\n'
        '  }\n'
        '}\n')
    self.check(expected, "rule_macro_mix.bzl")

if __name__ == '__main__':
  unittest.main()
