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

D_FILETYPE = FileType([".d"])

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

def _paths(srcs):
  paths = []
  for src in srcs:
    paths += [src.path]
  return paths

def _common_compile_flags(ctx):
    return [
        "-debug",
        "-w",
        "-I" + ctx.attr.import_path,
    ]

def _create_version_flags(versions):
  version_flags = []
  for version in versions:
    version_flags += ["-version=%s" % version]
  return version_flags

def _create_include_flags(includes):
  include_flags = []
  for include in includes:
    include_flags += ["-I%s" % include]
  return include_flags

def _create_link_flags(depinfo):
  link_flags = []
  for name in depinfo.lib_names:
    link_flags += ["-L-l%s" % name]
  return link_flags

def _compile_command(ctx, srcs, out, depinfo, flags=[]):
  d_compiler_path = ctx.file._d_compiler.path
  d_stdlib_path = ctx.files._d_stdlib[0].dirname
  d_stdlib_src_path = ctx.files._d_stdlib_src[0].dirname
  d_runtime_import_src_path = ctx.files._d_runtime_import_src[0].dirname

  cmd = [
      "set -e;",
  ] + depinfo.setup_cmd + [
      d_compiler_path,
      "-of" + out.path,
  ] + flags + [
      "-I.",
  ] + _create_include_flags(ctx.attr.includes) + [
      "-I%@P%" + d_stdlib_src_path,
      "-I%@P%" + d_runtime_import_src_path,
      "-L-L%@P%" + d_stdlib_path,
  ] + depinfo.link_flags + [
      "-g",
      "-version=Have_%s" % ctx.label.name,
  ] + _create_version_flags(depinfo.versions) + srcs

  return " ".join(cmd)

def _setup_deps(deps, name, working_dir):
  deps_dir = working_dir + "/" + name + ".deps"
  setup_cmd = ["rm -rf " + deps_dir + "; mkdir " + deps_dir + "\n"]

  transitive_libs = set()
  symlinked_libs = set()
  versions = set()
  lib_names = set()
  for dep in deps:
    if hasattr(dep, "d_lib"):
      transitive_libs += [dep.d_lib]
      symlinked_libs += [dep.d_lib]
      versions += dep.versions
      lib_names += [dep.label.name]

    if hasattr(dep, "transitive_libs"):
      transitive_libs += dep.transitive_libs
      symlinked_libs += dep.transitive_libs

  for symlinked_libs in symlinked_libs:
    setup_cmd += [_create_setup_cmd(symlinked_libs, deps_dir)]

  return struct(
      transitive_libs = list(transitive_libs),
      versions = versions,
      setup_cmd = setup_cmd,
      lib_names = lib_names,
      link_flags = ["-L-L%s" % deps_dir])

def _d_library_impl(ctx):
  d_library = ctx.outputs.d_lib

  # Dependencies
  depinfo = _setup_deps(ctx.attr.deps, ctx.label.name, d_library.dirname)

  cmd = _compile_command(
      ctx = ctx,
      srcs = _paths(ctx.files.srcs),
      out = d_library,
      depinfo = depinfo,
      flags = ["-lib"] + _common_compile_flags(ctx))

  ctx.action(inputs = ctx.files.srcs,
             outputs = [d_library],
             mnemonic = "Dcompile",
             command = cmd,
             use_default_shell_env = True,
             progress_message = "Compiling D library " + ctx.label.name)

  return struct(files = set([d_library]),
                transitive_libs = [],
                versions = ctx.attr.versions,
                d_lib = d_library)

def _d_binary_impl(ctx):
  d_binary = ctx.outputs.executable
  d_obj = ctx.new_file(ctx.configuration.bin_dir,
                       d_binary.basename + ".o")
  depinfo = _setup_deps(ctx.attr.deps, ctx.label.name, d_binary.dirname)
  compile_cmd = _compile_command(
      ctx = ctx,
      srcs = _paths(ctx.files.srcs),
      depinfo = depinfo,
      out = d_obj,
      flags = ["-c"] + _common_compile_flags(ctx))

  ctx.action(inputs = ctx.files.srcs,
             outputs = [d_obj],
             mnemonic = "Dcompile",
             command = compile_cmd,
             use_default_shell_env = True,
             progress_message = "Compiling D binary " + ctx.label.name)

  link_cmd = _compile_command(
      ctx = ctx,
      srcs = [d_obj.path],
      depinfo = depinfo,
      out = d_binary,
      flags = _create_link_flags(depinfo))

  ctx.action(inputs = [d_obj],
             outputs = [d_binary],
             mnemonic = "Dlink",
             command = link_cmd,
             use_default_shell_env = True,
             progress_message = "Linking D binary " + ctx.label.name)

def _d_test_impl(ctx):
  """
  d_test_binary = ctx.outputs.executable
  cmd = _build_compile_command(ctx, BUILD_TEST, d_test_binary.path)

  ctx.action(inputs = ctx.files.srcs,
             outputs = [d_test_binary],
             mnemonic = "Dcompile",
             command = cmd,
             use_default_shell_env = True,
             progress_message = "Compiling D test binary " + ctx.label.name)
  """
  return struct()

_d_common_attrs = {
    "srcs": attr.label_list(allow_files = D_FILETYPE),
    "deps": attr.label_list(),
    "import_path": attr.string(default = "."),
    "includes": attr.string_list(),
    "versions": attr.string_list(),
    "_d_compiler": attr.label(
        default = Label("//tools/build_defs/d:dmd"),
        executable = True,
        single_file = True),
    "_d_stdlib": attr.label(
        default = Label("//tools/build_defs/d:libphobos2")),
    "_d_stdlib_src": attr.label(
        default = Label("//tools/build_defs/d:phobos-src")),
    "_d_runtime_import_src": attr.label(
        default = Label("//tools/build_defs/d:druntime-import-src")),
}

d_library = rule(
    _d_library_impl,
    attrs = _d_common_attrs,
    outputs = {
        "d_lib": "lib%{name}.a",
    },
)

d_binary = rule(
    _d_binary_impl,
    executable = True,
    attrs = _d_common_attrs,
)

d_test = rule(
    _d_test_impl,
    executable = True,
    attrs = _d_common_attrs,
    test = True,
)
