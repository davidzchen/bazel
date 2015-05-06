# Copyright 2014 Google Inc. All rights reserved.
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

rust_filetype = FileType([".rs"])

def rust_library_impl(ctx):
    # Find lib.rs
    srcs = ctx.files.srcs
    lib_rs = None
    for src in srcs:
        if src.path.endswith("lib.rs"):
            lib_rs = src.path

    # Dependencies
    deps_libs = []
    deps_flags = ""
    for dep in ctx.targets.deps:
        deps_libs += [dep.rust_lib]
        deps_flags += (
            " --extern " + dep.label.name + "=" + dep.rust_lib.path +
            " -L dependency=$(dirname " + dep.rust_lib.path + ")"
        )

    # Build rustc command
    rust_lib = ctx.outputs.rust_lib
    output_dir = "$(dirname " + rust_lib.path + ")"
    short_hash = "xxx"
    cmd = (
        "set -e;export PATH=/usr/bin:/usr/local/bin:$PATH;" +
        "rustc " + lib_rs +
        " --crate-name " + ctx.label.name +
        " --crate-type lib -g" +
        " -C metadata=" + short_hash +
        " -C extra-filename=-" + short_hash +
        " --out-dir " + output_dir +
        " --emit=dep-info,link" +
        deps_flags
    )

    # Compile action.
    ctx.action(
        inputs = srcs + deps_libs,
        outputs = [rust_lib],
        mnemonic = 'Rustc',
        command = cmd,
        use_default_shell_env = True
    )

    return struct(
        files = set([rust_lib]),
        rust_lib = rust_lib,
    )

def rust_binary_impl(ctx):
    # Find main.rs.
    srcs = ctx.files.srcs
    main_rs = None
    for src in srcs:
        if src.path.endswith("main.rs"):
            main_rs = src.path

    # Dependencies
    deps_flags = ""
    deps_libs = []
    for dep in ctx.targets.deps:
        deps_libs += [dep.rust_lib]
        deps_flags += (
            " --extern " + dep.label.name + "=" + dep.rust_lib.path +
            " -L dependency=$(dirname " + dep.rust_lib.path + ")"
        )

    # Build rustc command.
    rust_binary = ctx.outputs.executable
    output_dir = "$(dirname " + rust_binary.path + ")"
    cmd = (
        "set -e;export PATH=/usr/bin:/usr/local/bin:$PATH;" +
        "rustc " + main_rs +
        " --crate-name " + ctx.label.name +
        " --crate-type bin -g" +
        " --out-dir " + output_dir +
        " --emit=dep-info,link" +
        deps_flags
    )

    # Compile action.
    ctx.action(
        inputs = srcs + deps_libs,
        outputs = [rust_binary],
        mnemonic = 'Rustc',
        command = cmd,
        use_default_shell_env = True
    )

    return struct()

rust_library_attrs = {
    "srcs": attr.label_list(allow_files = rust_filetype),
    "deps": attr.label_list(
        allow_files = False,
        providers = [
            "rust_lib",
        ],
    ),
}

rust_library = rule(
    rust_library_impl,
    attrs = rust_library_attrs,
    outputs = {
        "rust_lib": "lib%{name}-xxx.rlib",
    },
)

rust_binary = rule(
    rust_binary_impl,
    executable = True,
    attrs = rust_library_attrs,
)

rust_test = rule(
    rust_binary_impl,
    executable = True,
    attrs = rust_library_attrs,
    test = True,
)
