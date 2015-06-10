// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.google.devtools.build.lib.bazel.repository;

import com.google.common.base.Preconditions;
import com.google.devtools.build.lib.vfs.Path;
import com.google.devtools.build.skyframe.SkyValue;

public class GitRepositoryValue implements SkyValue {
  private final Path path;

  public GitRepositoryValue(Path path) {
    Preconditions.checkNotNull(path);
    this.path = path;
  }

  public Path getPath() {
    return path;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    if (other == null || !(other instanceof GitRepositoryValue)) {
      return false;
    }
    GitRepositoryValue otherValue = (GitRepositoryValue) other;
    return this.path.equals(otherValue.path);
  }

  @Override
  public int hashCode() {
    return path.hashCode();
  }
}

