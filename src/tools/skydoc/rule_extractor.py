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

import ast

from src.main.protobuf import build_pb2
from src.tools.skydoc import common
from src.tools.skydoc.stubs import attr, skylark_globals

SKYLARK_STUBS = {
    "attr": attr,
    "aspect": skylark_globals.aspect,
    "DATA_CFG": skylark_globals.DATA_CFG,
    "HOST_CFG": skylark_globals.HOST_CFG,
    "PACKAGE_NAME": skylark_globals.PACKAGE_NAME,
    "REPOSITORY_NAME": skylark_globals.REPOSITORY_NAME,
    "provider": skylark_globals.provider,
    "FileType": skylark_globals.FileType,
    "Label": skylark_globals.Label,
    "select": skylark_globals.select,
    "struct": skylark_globals.struct,
    "rule": skylark_globals.rule,
}

class RuleDocExtractor(object):
  """Extracts documentation for rules from a .bzl file."""

  def __init__(self):
    """Inits RuleDocExtractor with a new BuildLanguage proto"""
    self.__language = build_pb2.BuildLanguage()
    self.__extracted_rules = {}

  def _process_skylark(self, bzl_file):
    skylark_locals = {}
    compiled = compile(open(bzl_file).read(), bzl_file, "exec")
    exec(compiled) in SKYLARK_STUBS, skylark_locals

    for name, obj in skylark_locals.iteritems():
      if hasattr(obj, "is_rule") and not name.startswith("_"):
        obj.attrs["name"] = attr.AttrDescriptor(type=build_pb2.Attribute.NAME,
                                                mandatory=True, name="name")
        self.__extracted_rules[name] = obj

  def _add_rule_doc(self, name, doc):
    doc, attr_doc = common.parse_attribute_doc(doc)
    if name in self.__extracted_rules:
      rule = self.__extracted_rules[name]
      rule.doc = doc.strip()
      for attr_name, attr_doc in attr_doc.iteritems():
        if attr_name in rule.attrs:
          rule.attrs[attr_name].doc = attr_doc

  def _parse_docstrings(self, bzl_file):
    try:
      tree = ast.parse(open(bzl_file).read(), bzl_file)
      key = None
      for node in ast.iter_child_nodes(tree):
        if isinstance(node, ast.Assign):
          name = node.targets[0].id
          if not name.startswith("_"):
            key = name
          continue
        elif isinstance(node, ast.Expr) and key:
          self._add_rule_doc(key, node.value.s.strip())
        key = None
    except IOError:
      print("Failed to parse {0}: {1}".format(bzl_file, e.strerror))
      pass

  def _assemble_protos(self):
    rules = []
    for rule_name, rule_desc in self.__extracted_rules.iteritems():
      rule_desc.name = rule_name
      rules.append(rule_desc)
    rules = sorted(rules, key=lambda rule_desc: rule_desc.name)

    for rule_desc in rules:
      rule = self.__language.rule.add()
      rule.name = rule_desc.name
      rule.documentation = rule_desc.doc

      attrs = sorted(rule_desc.attrs.values(), cmp=attr.attr_compare)
      for attr_desc in attrs:
        if attr_desc.name.startswith("_"):
          continue
        attr_proto = rule.attribute.add()
        attr_proto.name = attr_desc.name
        attr_proto.documentation = attr_desc.doc
        attr_proto.type = attr_desc.type
        attr_proto.mandatory = attr_desc.mandatory
        # TODO(dzc): Save the default value of the attribute. This will require
        # adding a proto field to the AttributeDefinition proto, perhaps as a
        # oneof.

  def parse_bzl(self, bzl_file):
    """Extracts the documentation for all public rules from the given .bzl file.

    The Skylark code is first evaluated against stubs to extract rule and
    attributes with complete type information. Then, the .bzl file is parsed
    to extract the docstrings for each of the rules. Finally, the BuildLanguage
    proto is assembled with the extracted rule documentation.

    Args:
      bzl_file: The .bzl file to extract rule documentation from.
    """
    self._process_skylark(bzl_file)
    self._parse_docstrings(bzl_file)
    self._assemble_protos()

  def proto(self):
    """Returns the proto containing the macro documentation."""
    return self.__language

