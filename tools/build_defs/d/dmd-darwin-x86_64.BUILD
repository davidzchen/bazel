package(default_visibility = ["//visibility:public"])

filegroup(
    name = "dmd",
    srcs = ["dmd2/osx/bin/dmd"],
)

filegroup(
    name = "libphobos2",
    srcs = ["dmd2/osx/lib/libphobos2.a"],
)

filegroup(
    name = "phobos-src",
    srcs = glob(["dmd2/src/phobos/**/*.*"]),
)

filegroup(
    name = "druntime-import-src",
    srcs = glob(["dmd2/src/druntime/import/**/*.*"]),
)
