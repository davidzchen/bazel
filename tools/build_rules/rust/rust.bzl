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

RUST_FILETYPE = FileType([".rs"])
C_LIB_FILETYPE = FileType([".a"])

def _relative(src_path, dest_path):
  """
  Returns the relative path from src_path to dest_path
  """
  src_parts = src_path.split("/")
  dest_parts = dest_path.split("/")
  n = 0
  done = False
  for src_part, dest_part in zip(src_parts, dest_parts):
    if src_part != dest_part:
      break
    n += 1

  relative_path = ""
  for i in range(n, len(src_parts)):
    relative_path += "../"
  relative_path += "/".join(dest_parts[n:])

  return relative_path

def _create_setup_cmd(lib, deps_dir):
  """
  Helper function to construct a command for symlinking a library into the
  deps directory.
  """
  return (
      "ln -sf " + _relative(deps_dir, lib.path) + " " +
      deps_dir + "/" + lib.basename + "\n"
  )

# TODO(dzc): rust_binary should not be able to depend on cc_library
def _setup_deps(deps, name, working_dir):
  """
  Walks through dependencies and constructs the necessary commands for linking
  to all the necessary dependencies.
  """
  deps_dir = working_dir + "/" + name + ".deps"
  setup_cmd = ["rm -rf " + deps_dir + "; mkdir " + deps_dir + "\n"]

  has_rlib = False
  has_native = False

  libs = set()
  transitive_libs = set()
  symlinked_libs = set()
  link_flags = []
  for dep in deps:
    if hasattr(dep, "rust_lib"):
      libs += [dep.rust_lib]
      transitive_libs += [dep.rust_lib]
      symlinked_libs += [dep.rust_lib]
      link_flags += [(
          "--extern " + dep.label.name + "=" +
          deps_dir + "/" + dep.rust_lib.basename
      )]
      has_rlib = True

    if hasattr(dep, "transitive_libs"):
      transitive_libs += dep.transitive_libs
      symlinked_libs += dep.transitive_libs

    # If this rule depends on a cc_library
    if hasattr(dep, "cc"):
      native_libs = C_LIB_FILETYPE.filter(dep.cc.libs)
      libs += native_libs
      transitive_libs += native_libs
      symlinked_libs += native_libs
      link_flags += ["-l static=" + dep.label.name]
      has_native = True

  for symlinked_lib in symlinked_libs:
    setup_cmd += [_create_setup_cmd(symlinked_lib, deps_dir)]

  search_flags = []
  if has_rlib:
    search_flags += ["-L dependency=" + deps_dir]
  if has_native:
    search_flags += ["-L native=" + deps_dir]

  return struct(
      libs = list(libs),
      transitive_libs = list(transitive_libs),
      setup_cmd = setup_cmd,
      search_flags = search_flags,
      link_flags = link_flags,
  )

def _get_features_flags(features):
  """
  Constructs a string containing the feature flags from the features specified
  in the features attribute.
  """
  features_flags = []
  for feature in features:
    features_flags += [" --cfg feature=\\\"" + feature + "\\\""]
  return features_flags

def _rust_library_impl(ctx):
  """
  Implementation for rust_library Skylark rule.
  """

  # Find lib.rs
  srcs = ctx.files.srcs
  lib_rs = None
  crate_name_rs = ctx.label.name + ".rs"
  for src in srcs:
    if src.basename == "lib.rs" or src.basename == crate_name_rs:
      lib_rs = src.path

  if not lib_rs:
    fail("No lib.rs or source file matching crate name found.")

  # Output library
  rust_lib = ctx.outputs.rust_lib
  output_dir = rust_lib.dirname

  rust_compiler = ctx.file._rust_compiler
  #rust_runtime_lib = ctx.file._rust_lib
  #rust_runtime_rustlib = ctx.file._rust_rustlib

  print("rust_compiler.path " + rust_compiler.path)
  #print("rust_runtime_lib.path " + rust_runtime_lib.path)
  #print("rust_runtime_rustlib.path " + rust_runtime_rustlib.path)

  # Dependencies
  depinfo = _setup_deps(ctx.attr.deps, ctx.label.name, output_dir)
  features_flags = _get_features_flags(ctx.attr.features)

  # Build rustc command
  # TODO(dzc): There is a tools dependency on rustc. Use a remote repository
  # mechanism to fetch rustc.
  cmd = (
      "set -e;export PATH=/usr/bin:/usr/local/bin:$PATH;" +
      " " + " ".join(depinfo.setup_cmd) +
      "rustc " + lib_rs +
      " --crate-name " + ctx.label.name +
      " --crate-type lib -g" +
      " --codegen ar=/usr/bin/ar" +
      " --codegen cc=/usr/bin/cc" +
      " " + " ".join(features_flags) +
      " --out-dir " + output_dir +
      " --emit=dep-info,link" +
      " " + " ".join(depinfo.search_flags) +
      " " + " ".join(depinfo.link_flags) +
      " " + " ".join(ctx.attr.rustc_flags)
  )

  # Compile action.
  ctx.action(
      inputs = srcs + ctx.files.data + depinfo.libs,
      outputs = [rust_lib],
      mnemonic = 'Rustc',
      command = cmd,
      use_default_shell_env = True,
      progress_message = "Compiling Rust library " + ctx.label.name
  )

  return struct(
      files = set([rust_lib]),
      transitive_libs = depinfo.transitive_libs,
      rust_lib = rust_lib,
  )

def _rust_binary_impl_common(ctx, extra_flags = []):
  """
  Implementation for rust_binary Skylark rule.
  """

  # Find main.rs.
  srcs = ctx.files.srcs
  main_rs = None
  crate_name_rs = ctx.label.name + ".rs"
  for src in srcs:
    if src.basename == "main.rs" or src.basename == crate_name_rs:
      main_rs = src.path

  if not main_rs:
    fail("No main.rs or source file matching crate name found.")

  # Output binary
  rust_binary = ctx.outputs.executable
  output_dir = rust_binary.dirname

  # Dependencies
  depinfo = _setup_deps(ctx.attr.deps, ctx.label.name, output_dir)
  features_flags = _get_features_flags(ctx.attr.features)

  # Build rustc command.
  # TODO(dzc): There is a tools dependency on rustc. Use a remote repository
  # mechanism to fetch rustc.
  cmd = (
      "set -e;export PATH=/usr/bin:/usr/local/bin:$PATH;" +
      " " + " ".join(depinfo.setup_cmd) +
      "rustc " + main_rs +
      " --crate-name " + ctx.label.name +
      " --crate-type bin -g" +
      " " + " ".join(extra_flags) +
      " " + " ".join(features_flags) +
      " --out-dir " + output_dir +
      " --emit=dep-info,link" +
      " " + " ".join(depinfo.search_flags) +
      " " + " ".join(depinfo.link_flags) +
      " " + " ".join(ctx.attr.rustc_flags)
  )

  # Compile action.
  ctx.action(
      inputs = srcs + ctx.files.data + depinfo.libs,
      outputs = [rust_binary],
      mnemonic = 'Rustc',
      command = cmd,
      use_default_shell_env = True,
      progress_message = "Compiling Rust binary " + ctx.label.name
  )

def _rust_binary_impl(ctx):
  """
  Implementation for rust_binary Skylark rule.
  """
  return _rust_binary_impl_common(ctx)

def _rust_test_impl(ctx):
  """
  Implementation for rust_test Skylark rule.
  """
  return _rust_binary_impl_common(ctx, ["--test"])

_rust_common_attrs = {
    "srcs": attr.label_list(allow_files = RUST_FILETYPE),
    "data": attr.label_list(allow_files = True, cfg = DATA_CFG),
    "deps": attr.label_list(),
    "features": attr.string_list(),
    "rustc_flags": attr.string_list(),
    "_rust_compiler": attr.label(
        default = Label("//tools/rust:rustc"),
        executable = True,
        single_file = True),
    "_rust_lib": attr.label(default = Label("//tools/rust:rust-lib")),
    "_rust_rustlib": attr.label(default = Label("//tools/rust:rust-rustlib")),
}

rust_library = rule(
    _rust_library_impl,
    attrs = _rust_common_attrs,
    outputs = {
        "rust_lib": "lib%{name}.rlib",
    },
)

rust_binary = rule(
    _rust_binary_impl,
    executable = True,
    attrs = _rust_common_attrs,
)

rust_test = rule(
    _rust_test_impl,
    executable = True,
    attrs = _rust_common_attrs,
    test = True,
)
