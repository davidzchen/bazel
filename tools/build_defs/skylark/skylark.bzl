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

"""Skylark rules"""

_SKYLARK_FILETYPE = FileType([".bzl"])

ZIP_PATH = "/usr/bin/zip"

def _get_transitive_sources(deps):
  """Collects source files of transitive dependencies."

  Args:
    deps: List of deps labels from ctx.attr.deps.

  Returns:
    Returns a list of Files containing sources of transitive dependencies.
  """
  transitive_sources = set(order="compile")
  for dep in deps:
    transitive_sources += dep.transitive_bzl_files
  return transitive_sources

def _skylark_library_impl(ctx):
  """Implementation of the skylark_library rule."""
  sources = _get_transitive_sources(ctx.attr.deps) + ctx.files.srcs
  return struct(files = set(),
                transitive_bzl_files = sources)

def _skydoc(ctx):
  for f in ctx.files._skydoc:
    if not f.path.endswith(".py"):
      return f

def _skylark_doc_impl(ctx):
  skylark_doc_zip = ctx.outputs.skylark_doc_zip
  docs_dir = skylark_doc_zip.dirname + "/_skylark_docs"
  inputs = _get_transitive_sources(ctx.attr.deps) + ctx.files.srcs
  sources = [source.path for source in inputs]
  skydoc = _skydoc(ctx)
  cmd = " ".join(
      [
          "set -e;",
          "rm -rf %s;" % docs_dir,
          "mkdir %s;" % docs_dir,
          skydoc.path,
          "--output_dir=%s" % docs_dir,
      ] + sources + [
          "&&",
          "(cd %s" % docs_dir,
          "&&",
          ZIP_PATH,
          "-qR",
          skylark_doc_zip.basename,
          "$(find . -type f) )",
          "&&",
          "mv %s/%s %s" % (docs_dir, skylark_doc_zip.basename,
                           skylark_doc_zip.path),
      ])
  ctx.action(
      inputs = list(inputs) + [skydoc],
      outputs = [skylark_doc_zip],
      mnemonic = "Skydoc",
      command = cmd,
      use_default_shell_env = True,
      progress_message = ("Generating Skylark doc for %s (%d files)"
                          % (ctx.label.name, len(sources))))

_skylark_common_attrs = {
    "srcs": attr.label_list(allow_files = _SKYLARK_FILETYPE),
    "deps": attr.label_list(providers = ["transitive_bzl_files"],
                            allow_files = False),
}

skylark_library = rule(
    _skylark_library_impl,
    attrs = _skylark_common_attrs,
)
"""Creates a logical collection of Skylark .bzl files.

Args:
  srcs: List of `.bzl` files that are processed to create this target.
  deps: List of other `skylark_library` targets that are required by the Skylark
    files listed in `srcs`.
"""

_skylark_doc_attrs = {
    "output": attr.string(default = "markdown"),
    "_skydoc": attr.label(
        default = Label("//src/tools/skydoc:skydoc"),
        cfg = HOST_CFG,
        executable = True),
}

skylark_doc = rule(
    _skylark_doc_impl,
    attrs = dict(_skylark_common_attrs.items() + _skylark_doc_attrs.items()),
    outputs = {
        "skylark_doc_zip": "%{name}-docs.zip",
    },
)
"""Generates Skylark rule documentation.

Args:
  srcs: List of `.bzl` files that are processed to create this target.
  deps: List of other `skylark_library` targets that are required by the Skylark
    files listed in `srcs.
  output: The type of output to generate. Possible values are `"markdown"` and
    `"html"`.
"""
