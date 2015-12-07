package(default_visibility = ["//visibility:public"])

py_library(
    name = "common",
    srcs = ["common.py"],
    deps = [
        "//src/main/protobuf:build_pb_py",
    ],
)

py_test(
    name = "common_test",
    srcs = ["common_test.py"],
    deps = [
        ":common",
    ],
)

py_library(
    name = "macro_extractor",
    srcs = ["macro_extractor.py"],
    deps = [":common"],
)

filegroup(
    name = "macro_extractor_testdata",
    srcs = [
        "testdata/macro_undocumented.bzl",
        "testdata/macro_private.bzl",
        "testdata/macro_multi_line.bzl",
        "testdata/rule_macro_mix.bzl",
    ],
)

py_test(
    name = "macro_extractor_test",
    srcs = ["macro_extractor_test.py"],
    deps = [
        ":macro_extractor",
        "//src/main/protobuf:build_pb_py",
    ],
    data = [":macro_extractor_testdata"],
)

py_library(
    name = "rule_extractor",
    srcs = ["rule_extractor.py"],
    deps = [
        ":common",
        "//src/tools/skydoc/stubs",
    ],
)

filegroup(
    name = "rule_extractor_testdata",
    srcs = [
        "testdata/rule_all_types.bzl",
        "testdata/rule_undocumented.bzl",
        "testdata/rule_private.bzl",
        "testdata/rule_multi_line.bzl",
        "testdata/rule_macro_mix.bzl",
    ],
)

py_test(
    name = "rule_extractor_test",
    srcs = ["rule_extractor_test.py"],
    deps = [
        ":rule_extractor",
        "//src/main/protobuf:build_pb_py",
    ],
    data = [":rule_extractor_testdata"],
)

py_binary(
    name = "skydoc",
    srcs = ["skydoc.py"],
    deps = [
        ":macro_extractor",
        ":rule_extractor",
        "//external:mistune",
        "//third_party/py/gflags",
    ],
)
