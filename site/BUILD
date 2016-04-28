load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

exports_files(
    ["docs/bazel-user-manual.html"],
)

filegroup(
    name = "srcs",
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)

filegroup(
    name = "jekyll-srcs",
    srcs = glob(
        ["**/*"],
        exclude = [
            "BUILD",
            "jekyll-tree.sh",
            "*.swp",
        ],
    ),
)

pkg_tar(
    name = "jekyll-base",
    files = [":jekyll-srcs"],
    strip_prefix = ".",
)

pkg_tar(
    name = "bootstrap-css",
    files = ["//third_party/css/bootstrap:bootstrap_css"],
    strip_prefix = "/third_party/css/bootstrap",
    package_dir = "assets",
)

pkg_tar(
    name = "bootstrap-images",
    files = ["//third_party/css/bootstrap:bootstrap_images"],
    strip_prefix = "/third_party/css/bootstrap",
    package_dir = "assets",
)

pkg_tar(
    name = "font-awesome-css",
    files = ["//third_party/css/font_awesome:font_awesome_css"],
    strip_prefix = "/third_party/css/font_awesome",
    package_dir = "assets",
)

pkg_tar(
    name = "font-awesome-font",
    files = ["//third_party/css/font_awesome:font_awesome_font"],
    strip_prefix = "/third_party/css/font_awesome",
    package_dir = "assets",
)

pkg_tar(
    name = "bootstrap-js",
    files = ["//third_party/javascript/bootstrap:bootstrap_js"],
    strip_prefix = "/third_party/javascript/bootstrap",
    package_dir = "assets",
)

pkg_tar(
    name = "jekyll-tree",
    deps = [
        ":bootstrap-css",
        ":bootstrap-images",
        ":font-awesome-css",
        ":font-awesome-font",
        ":bootstrap-js",
        ":jekyll-base",
    ],
)
