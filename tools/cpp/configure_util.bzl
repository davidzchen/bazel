# Copyright 2016 The Bazel Authors. All rights reserved.
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
"""Utility functions for working with the host system."""

def find_cc(repository_ctx):
  """Find the C++ compiler."""
  cc_name = "gcc"
  if "CC" in repository_ctx.os.environ:
    cc_name = repository_ctx.os.environ["CC"].strip()
    if not cc_name:
      cc_name = "gcc"
  if cc_name.startswith("/"):
    # Absolute path, maybe we should make this suported by our which function.
    return cc_name
  cc = repository_ctx.which(cc_name)
  if cc == None:
    fail(
        "Cannot find gcc, either correct your path or set the CC" +
        " environment variable")
  return cc

_INC_DIR_MARKER_BEGIN = "#include <...>"

# OSX add " (framework directory)" at the end of line, strip it.
_OSX_FRAMEWORK_SUFFIX = " (framework directory)"
_OSX_FRAMEWORK_SUFFIX_LEN =  len(_OSX_FRAMEWORK_SUFFIX)
def _cxx_inc_convert(path):
  """Convert path returned by cc -E xc++ in a complete path."""
  path = path.strip()
  if path.endswith(_OSX_FRAMEWORK_SUFFIX):
    path = path[:-_OSX_FRAMEWORK_SUFFIX_LEN].strip()
  return path

def get_cxx_inc_directories(repository_ctx, cc):
  """Compute the list of default C++ include directories."""
  result = repository_ctx.execute([cc, "-E", "-xc++", "-", "-v"])
  index1 = result.stderr.find(_INC_DIR_MARKER_BEGIN)
  if index1 == -1:
    return []
  index1 = result.stderr.find("\n", index1)
  if index1 == -1:
    return []
  index2 = result.stderr.rfind("\n ")
  if index2 == -1 or index2 < index1:
    return []
  index2 = result.stderr.find("\n", index2 + 1)
  if index2 == -1:
    inc_dirs = result.stderr[index1 + 1:]
  else:
    inc_dirs = result.stderr[index1 + 1:index2].strip()

  return [repository_ctx.path(_cxx_inc_convert(p))
          for p in inc_dirs.split("\n")]
