BASE_DIR = "rust-1.1.0-x86_64-unknown-linux-gnu/"

filegroup(
    name = "rustc",
    srcs = [BASE_DIR + "rustc/bin/rustc"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "rustdoc",
    srcs = [BASE_DIR + "rustc/bin/rustdoc"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "rust-lib",
    srcs = glob([BASE_DIR + "rustc/lib/*.so"]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "rust-rustlib",
    srcs = glob([
        BASE_DIR + "rustc/lib/rustlib/x86_64-unknown-linux-gnu/lib/*.rlib",
        BASE_DIR + "rustc/lib/rustlib/x86_64-unknown-linux-gnu/lib/*.so",
        BASE_DIR + "rustc/lib/rustlib/x86_64-unknown-linux-gnu/lib/*.a",
    ]),
    visibility = ["//visibility:public"],
)
