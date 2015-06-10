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

import com.google.devtools.build.lib.bazel.repository.RepositoryFunction.RepositoryFunctionException;
import com.google.devtools.build.lib.packages.AggregatingAttributeMapper;
import com.google.devtools.build.lib.packages.Rule;
import com.google.devtools.build.lib.packages.Type;
import com.google.devtools.build.lib.vfs.Path;
import com.google.devtools.build.skyframe.SkyFunction;
import com.google.devtools.build.skyframe.SkyFunctionException;
import com.google.devtools.build.skyframe.SkyFunctionException.Transience;
import com.google.devtools.build.skyframe.SkyFunctionName;
import com.google.devtools.build.skyframe.SkyKey;
import com.google.devtools.build.skyframe.SkyValue;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.eclipse.jgit.api.errors.InvalidRefNameException;
import org.eclipse.jgit.api.errors.InvalidRemoteException;
import org.eclipse.jgit.api.errors.RefNotFoundException;

import java.io.File;
import java.io.IOException;
import java.util.Objects;

import javax.annotation.Nullable;

/**
 * Clones a Git repository
 */
public class GitCloneFunction implements SkyFunction {
  public static final String NAME = "GIT_CLONE";

  @Nullable
  @Override
  public SkyValue compute(SkyKey skyKey, Environment env) throws RepositoryFunctionException {
    GitRepositoryDescriptor descriptor = (GitRepositoryDescriptor) skyKey.argument();
    String outputDirectory = descriptor.directory.toString();

    Git git = null;
    try {
      git = Git.cloneRepository()
          .setURI(descriptor.remote)
          .setDirectory(new File(outputDirectory))
          .setCloneSubmodules(false)
          .call();
      git.checkout()
          .setCreateBranch(true)
          .setName("bazel-checkout")
          .setStartPoint(descriptor.checkout)
          .call();

      // Using CloneCommand.setCloneSubmodules() results in SubmoduleInitCommand and
      // SubmoduleUpdateCommand to be called recursively for all submodules. This is not
      // desirable for repositories, such as https://github.com/rust-lang/rust-installer,
      // which recursively includes itself as a submodule, which would result in an
      // infinite loop if submodules are cloned recursively. For now, limit submodules to
      // only the first level.
      if (descriptor.initSubmodules) {
        if (!git.submoduleInit().call().isEmpty()) {
          git.submoduleUpdate().call();
        }
      }
    } catch (InvalidRemoteException e) {
      throw new RepositoryFunctionException(
          new IOException("Invalid Git repository URI: " + e.getMessage()),
          Transience.PERSISTENT);
    } catch (RefNotFoundException|InvalidRefNameException e) {
      throw new RepositoryFunctionException(
          new IOException("Invalid branch, tag, or commit: " + e.getMessage()),
          Transience.PERSISTENT);
    } catch (GitAPIException e) {
      throw new RepositoryFunctionException(
          new IOException(e.getMessage()), Transience.TRANSIENT);
    } finally {
      if (git != null) {
        git.close();
      }
    }
    return new GitRepositoryValue(descriptor.directory);
  }

  @Nullable
  @Override
  public String extractTag(SkyKey skyKey) {
    return null;
  }

  public static SkyKey key(Rule rule, Path outputDirectory)
      throws RepositoryFunction.RepositoryFunctionException {
    AggregatingAttributeMapper mapper = AggregatingAttributeMapper.of(rule);
    return new SkyKey(
        SkyFunctionName.create(NAME),
        new GitCloneFunction.GitRepositoryDescriptor(
            mapper.get("remote", Type.STRING),
            mapper.get("checkout", Type.STRING),
            mapper.get("init_submodules", Type.BOOLEAN),
            outputDirectory));
  }

  static final class GitRepositoryDescriptor {
    private String remote;
    private String checkout;
    private boolean initSubmodules;
    private Path directory;

    public GitRepositoryDescriptor(String remote, String checkout, boolean initSubmodules,
        Path directory) {
      this.remote = remote;
      this.checkout = checkout;
      this.initSubmodules = initSubmodules;
      this.directory = directory;
    }

    @Override
    public String toString() {
      return remote + " -> " + directory + " (" + remote + ") submodules: "
          + initSubmodules;
    }

    @Override
    public boolean equals(Object obj) {
      if (obj == this) {
        return true;
      }
      if (obj == null || !(obj instanceof GitRepositoryDescriptor)) {
        return false;
      }
      GitRepositoryDescriptor other = (GitRepositoryDescriptor) obj;
      return Objects.equals(remote, other.remote)
          && Objects.equals(checkout, other.checkout)
          && Objects.equals(initSubmodules, other.initSubmodules)
          && Objects.equals(directory, other.directory);
    }

    @Override
    public int hashCode() {
      return Objects.hash(remote, checkout, initSubmodules, directory);
    }
  }
}
