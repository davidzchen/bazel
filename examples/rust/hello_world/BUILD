load("/tools/build_rules/rust", "rust_binary")

package(default_visibility = ["//visibility:public"])

rust_binary(
    name = "hello_world",
    srcs = ["src/main.rs"],
    deps = ["//examples/rust/hello_lib:hello_lib"],
)
