# Copyright 2015 Google Inc. All rights reserved.
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

"""Jsonnet rules for Bazel."""

JSONNET_FILETYPE = FileType([".jsonnet"])

def _collect_transitive_sources(deps):
  """Collects all source files of the target and transitive dependencies."""
  source_files = set(order="compile")
  for dep in deps:
    source_files += dep.transitive_jsonnet_files
  return source_files

def _jsonnet_library_impl(ctx):
  """Implementation of the jsonnet_library rule."""
  sources = _collect_transitive_sources(ctx.attr.deps) + ctx.files.srcs
  return struct(files = set(),
                transitive_jsonnet_files = sources)

def _jsonnet_toolchain(ctx):
  return struct(
      jsonnet_path = ctx.file._jsonnet.path,
      lib_search_flags = ["-J %s" % ctx.file._std.dirname])

def _jsonnet_to_json_impl(ctx):
  """Implementation of the jsonnet_to_json rule."""
  transitive_sources = _collect_transitive_sources(ctx.attr.deps)
  toolchain = _jsonnet_toolchain(ctx)
  compiled_json = ctx.outputs.compiled_json
  command = (
      [
          "set -e;",
          toolchain.jsonnet_path,
      ] + toolchain.lib_search_flags + [
          "-J .",
          ctx.file.src.path,
          "> %s" % compiled_json.path
      ])

  compile_inputs = (
      [
          ctx.file.src,
          ctx.file._jsonnet,
          ctx.file._std
      ] + list(transitive_sources))

  ctx.action(
      inputs = compile_inputs,
      outputs = [compiled_json],
      mnemonic = "Jsonnet",
      command = " ".join(command),
      use_default_shell_env = True,
      progress_message = "Compiling Jsonnet to JSON for " + ctx.label.name);

_jsonnet_common_attrs = {
    "src": attr.label(allow_files = JSONNET_FILETYPE,
                      single_file = True),
    "deps": attr.label_list(providers = ["transitive_jsonnet_files"],
                            allow_files = False),
    "_jsonnet": attr.label(
        default = Label("//tools/build_defs/jsonnet:jsonnet"),
        executable = True,
        single_file = True),
    "_std": attr.label(default = Label("//tools/build_defs/jsonnet:std"),
                       single_file = True),
}

jsonnet_library = rule(
    _jsonnet_library_impl,
    attrs = _jsonnet_common_attrs,
)

jsonnet_to_json = rule(
    _jsonnet_to_json_impl,
    attrs = _jsonnet_common_attrs,
    outputs = {
        "compiled_json": "%{name}.json",
    },
)
