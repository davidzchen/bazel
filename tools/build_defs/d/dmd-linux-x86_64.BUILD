package(default_visibility = ["//visibility:public"])

filegroup(
    name = "dmd",
    srcs = ["dmd2/linux/bin64/dmd"],
)

filegroup(
    name = "libphobos2",
    srcs = [
        "dmd2/linux/lib64/libphobos2.a",
        "dmd2/linux/lib64/libphobos2.so"
    ],
)

filegroup(
    name = "phobos-src",
    srcs = glob(["dmd2/src/phobos/**/*.*"]),
)

filegroup(
    name = "druntime-import-src",
    srcs = glob(["dmd2/src/druntime/import/**/*.*"]),
)
