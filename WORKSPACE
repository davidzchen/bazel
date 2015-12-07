load("/tools/build_defs/d/d", "d_repositories")
load("/tools/build_defs/dotnet/csharp", "csharp_repositories")
load("/tools/build_defs/jsonnet/jsonnet", "jsonnet_repositories")
load("/tools/build_defs/sass/sass", "sass_repositories")
load("/tools/build_rules/go/def", "go_repositories")
load("/tools/build_rules/rust/rust", "rust_repositories")
load("/third_party/mistune/mistune", "mistune_repositories")
load("/third_party/six/six", "six_repositories")

csharp_repositories()
d_repositories()
go_repositories()
jsonnet_repositories()
rust_repositories()
sass_repositories()

# Bind to dummy targets if no android SDK/NDK is present.
bind(
    name = "android_sdk_for_testing",
    actual = "//:dummy",
)

bind(
    name = "android_ndk_for_testing",
    actual = "//:dummy",
)

git_repository(
    name = "protobuf",
    remote = "https://github.com/google/protobuf.git",
    commit = "60a0d41a2988a40cf3a94a4cb602f5f1c94135e9",
)

bind(
    name = "python_headers",
    actual = "//:dummy",
)

# In order to run the Android integration tests, run
# scripts/workspace_user.sh and uncomment the next two lines.
# load("/WORKSPACE.user", "android_repositories")
# android_repositories()

# Used for skydoc
six_repositories()
mistune_repositories()
