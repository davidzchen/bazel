#!/usr/bin/env python
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

import os
import sys

from external.mistune_archive import mistune
from google.protobuf import text_format
from src.main.protobuf import build_pb2
from src.tools.skydoc import macro_extractor, rule_extractor
from third_party.py import gflags

gflags.DEFINE_string("output_dir", ".", "The directory to write the output to")
gflags.DEFINE_string("output", "markdown",
    "The output format. Possible values are markdown and proto")
FLAGS = gflags.FLAGS

def merge_languages(macro_language, rule_language):
  for rule in rule_language.rule:
    new_rule = macro_language.rule.add()
    new_rule.CopyFrom(rule)
  return macro_language

class ProtoWriter(object):
  def write(self, output_dir, ruleset, language):
    output_file = "%s/%s.pb" % (output_dir, ruleset)
    content = text_format.MessageToString(language)
    open(output_file, "w").write(content)

class MarkdownWriter(object):
  TOC_BEGIN = (
      '<div class="toc">\n'
      '  <h2>Rules</h2>\n'
      '  <ul>\n')

  TOC_END = (
      '  </ul>\n'
      '</div>\n')

  ATTR_TABLE_BEGIN = (
      '<table class="table table-condensed table-bordered table-params">\n'
      '  <colgroup>\n'
      '    <col class="col-param" />\n'
      '    <col class="param-description" />\n'
      '  </colgroup>\n'
      '  <thead>\n'
      '    <tr>\n'
      '      <th colspan="2">Attributes</th>\n'
      '    </tr>\n'
      '  </thead>\n'
      '  <tbody>\n')

  ATTR_TABLE_END = (
      '  </tbody>\n'
      '</table>\n')

  NAME_LINK = '<a href="http://bazel.io/docs/build-ref.html#name">Name</a>'
  LABEL_LINK = '<a href="http://bazel.io/docs/build-ref.html#labels">Label</a>'
  LABELS_LINK = (
      '<a href="http://bazel.io/docs/build-ref.html#labels">labels</a>')

  def write_heading(self, f, ruleset):
    f.write("<h1>%s Rules</h1>\n" % ruleset)

  def write_toc(self, f, language):
    f.write(self.TOC_BEGIN)
    for rule in language.rule:
      f.write('<li><a href="#%s">%s</a></li>\n' % (rule.name, rule.name))
    f.write(self.TOC_END)

  def rule_signature(self, rule):
    signature = rule.name + "("
    for i in range(len(rule.attribute)):
      attr = rule.attribute[i]
      signature += '<a href="#%s.%s">%s</a>' % (rule.name, attr.name, attr.name)
      if i < len(rule.attribute) - 1:
        signature += ', '
    signature += ")"
    return signature

  def write_attr_type(self, attr):
    type_str = ""
    if attr.type == build_pb2.Attribute.INTEGER:
      type_str = "Integer"
    elif attr.type == build_pb2.Attribute.STRING:
      type_str = "String"
    elif attr.type == build_pb2.Attribute.LABEL:
      type_str = self.LABEL_LINK
    elif attr.type == build_pb2.Attribute.OUTPUT:
      type_str = "Output"
    elif attr.type == build_pb2.Attribute.STRING_LIST:
      type_str = "List of strings"
    elif attr.type == build_pb2.Attribute.LABEL_LIST:
      type_str = "List of %s" % self.LABELS_LINK
    elif attr.type == build_pb2.Attribute.OUTPUT_LIST:
      type_str = "List of outputs"
    elif attr.type == build_pb2.Attribute.DISTRIBUTION_SET:
      type_str = "Distribution Set"
    elif attr.type == build_pb2.Attribute.LICENSE:
      type_str = "License"
    elif attr.type == build_pb2.Attribute.STRING_DICT:
      type_str = "Dictionary mapping strings to string"
    elif attr.type == build_pb2.Attribute.FILESET_ENTRY_LIST:
      type_str = "List of FilesetEntry"
    elif attr.type == build_pb2.Attribute.LABEL_LIST_DICT:
      type_str = "Dictionary mapping strings to lists of %s" % self.LABELS_LINK
    elif attr.type == build_pb2.Attribute.STRING_LIST_DICT:
      type_str = "Dictionary mapping strings to lists of strings"
    elif attr.type == build_pb2.Attribute.BOOLEAN:
      type_str = "Boolean"
    elif attr.type == build_pb2.Attribute.TRISTATE:
      type_str = "Tristate"
    elif attr.type == build_pb2.Attribute.INTEGER_LIST:
      type_str = "List of integers"
    elif attr.type == build_pb2.Attribute.STRING_DICT_UNARY:
      type_str = "String Dict Unary"
    elif attr.type == build_pb2.Attribute.UNKNOWN:
      type_str = "Unknown"
    elif attr.type == build_pb2.Attribute.LABEL_DICT_UNARY:
      type_str = "Label Dict Unary"
    elif attr.type == build_pb2.Attribute.SELECTOR_LIST:
      type_str = "Selector List"
    elif attr.type == build_pb2.Attribute.NAME:
      type_str = self.NAME_LINK
    else:
      print("Unknown type %d" % attr.type)
      type_str = "Unknown"
    type_str += "; Required" if attr.mandatory else "; Optional"
    return type_str

  def write_rule(self, f, rule):
    f.write('\n<h2 id="#%s">%s</h2>\n\n' % (rule.name, rule.name))
    f.write('<pre>\n')
    f.write(self.rule_signature(rule) + "\n")
    f.write("</pre>\n\n")
    f.write(rule.documentation + "\n\n")
    if len(rule.attribute) > 0:
      f.write(self.ATTR_TABLE_BEGIN)
      for attr in rule.attribute:
        f.write('<tr id="#%s.%s">\n' % (rule.name, attr.name))
        f.write('<td><code>%s</code></td>\n' % attr.name)
        f.write('<td>')
        f.write('<p><code>%s</code></p>\n' % self.write_attr_type(attr))
        f.write(mistune.markdown(attr.documentation))
        f.write('</td>\n')
      f.write(self.ATTR_TABLE_END)

  def write(self, output_dir, ruleset, language):
    output_file = "%s/%s.md" % (output_dir, ruleset)
    with open(output_file, "w") as f:
      self.write_heading(f, ruleset)
      self.write_toc(f, language)
      for rule in language.rule:
        self.write_rule(f, rule)

def main(argv):
  language_map = {}
  for bzl_file in argv[1:]:
    macro = macro_extractor.MacroDocExtractor()
    rule = rule_extractor.RuleDocExtractor()
    macro.parse_bzl(bzl_file)
    rule.parse_bzl(bzl_file)
    merged_language = merge_languages(macro.proto(), rule.proto())
    file_basename = os.path.basename(bzl_file)
    language_map[file_basename.replace(".bzl", "")] = merged_language

  if FLAGS.output == "proto":
    for ruleset, language in language_map.iteritems():
      proto_writer = ProtoWriter();
      proto_writer.write(FLAGS.output_dir, ruleset, language)
  elif FLAGS.output == "markdown":
    for ruleset, language in language_map.iteritems():
      markdown_writer = MarkdownWriter()
      markdown_writer.write(FLAGS.output_dir, ruleset, language)
  else:
    sys.stderr.write(
        'Invalid output format: %s. Possible values are proto and markdown.'
        % FLAGS.output)

if __name__ == '__main__':
  main(FLAGS(sys.argv))
