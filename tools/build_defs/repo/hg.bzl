# Copyright 2015 The Bazel Authors. All rights reserved.
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
"""Rules for cloning external mercurial repositories."""

def _clone_or_update(repository_ctx):
  if ((ctx.attr.tag == "" and ctx.attr.commit == "") or
      (ctx.attr.tag != "" and ctx.attr.commit != "")):
    ctx.fail("Exactly one of commit and tag must be provided")

def _new_git_repository_impl(repository_ctx):
  if ((ctx.attr.build_file == None and ctx.attr.build_file_content == '') or
      (ctx.attr.build_file != None and ctx.attr.build_file_content != '')):
    ctx.fail("Exactly one of build_file and build_file_content must be provided.")
  _clone_or_update(ctx)
  ctx.file('WORKSPACE', "workspace(name = \"{name}\")\n".format(name=ctx.name))
  if ctx.attr.build_file:
    ctx.symlink(ctx.attr.build_file, 'BUILD')
  else:
    ctx.file('BUILD', ctx.attr.build_file_content)

def _hg_repository_impl(repository_ctx):
  _clone_or_update(repository_ctx)

_common_attrs = {
  "remote": attr.string(mandatory=True),
  "commit": attr.string(default=""),
  "tag": attr.string(default=""),
  "init_submodules": attr.bool(default=False),
}


new_hg_repository = repository_rule(
  implementation = _new_hg_repository_impl,
  attrs = _common_attrs + {
    "build_file": attr.label(),
    "build_file_content": attr.string(),
  }
)
"""Clone an external mercurial repository.

Clones a Mercurial repository, checks out the specified tag, or commit, and
makes its targets available for binding.

Args:
  name: A unique name for this rule.

  build_file: The file to use as the BUILD file for this repository.
    Either build_file or build_file_content must be specified.

    This attribute is a label relative to the main workspace. The file
    does not need to be named BUILD, but can be (something like
    BUILD.new-repo-name may work well for distinguishing it from the
    repository's actual BUILD files.

  build_file_content: The content for the BUILD file for this repository.
    Either build_file or build_file_content must be specified.

  init_submodules: Whether to clone submodules in the repository.

  remote: The URI of the remote mercurial repository.
"""

hg_repository = repository_rule(
  implementation = _hg_repository_impl,
  attrs = _common_attrs,
)
"""Clone an external mercurial repository.

Clones a mercurial repository, checks out the specified tag, or commit, and
makes its targets available for binding.

Args:
  name: A unique name for this rule.

  init_submodules: Whether to clone submodules in the repository.

  remote: The URI of the remote mercurial repository.
"""
