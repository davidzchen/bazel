package(default_visibility = ["//visibility:public"])

load("/tools/build_defs/d/d", "d_library", "d_test")

d_library(
    name = "hello_lib",
    srcs = ["greeter.d"],
)

d_test(
    name = "hello_lib_test",
    deps = [":hello_lib"],
)
