def mistune_repositories():
  native.new_http_archive(
      name = "mistune_archive",
      url = "https://pypi.python.org/packages/source/m/mistune/mistune-0.7.1.tar.gz#md5=057bc28bf629d6a1283d680a34ed9d0f",
      sha256 = "6076dedf768348927d991f4371e5a799c6a0158b16091df08ee85ee231d929a7",
      build_file = "third_party/mistune/mistune.BUILD",
      strip_prefix = "mistune-0.7.1",
  )

  native.bind(
      name = "mistune",
      actual = "@mistune_archive//:mistune",
  )
