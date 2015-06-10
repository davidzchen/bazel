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

package com.google.devtools.build.lib.bazel.rules.workspace;

import static com.google.devtools.build.lib.packages.Attribute.attr;
import static com.google.devtools.build.lib.packages.Type.STRING;
import static com.google.devtools.build.lib.packages.Type.BOOLEAN;

import com.google.devtools.build.lib.analysis.RuleDefinition;
import com.google.devtools.build.lib.analysis.RuleDefinitionEnvironment;
import com.google.devtools.build.lib.packages.RuleClass;

public class GitRepositoryRule implements RuleDefinition {
  public static final String NAME = "git_repository";

  @Override
  public RuleClass build(RuleClass.Builder builder, RuleDefinitionEnvironment environment) {
    return builder
        .add(attr("remote", STRING).mandatory())
        .add(attr("checkout", STRING).mandatory())
        .add(attr("init_submodules", BOOLEAN).value(false))
        .setWorkspaceOnly()
        .build();
  }

  @Override
  public Metadata getMetadata() {
    return RuleDefinition.Metadata.builder()
        .name(GitRepositoryRule.NAME)
        .type(RuleClass.Builder.RuleClassType.WORKSPACE)
        .ancestors(WorkspaceBaseRule.class)
        .factoryClass(WorkspaceConfiguredTargetFactory.class)
        .build();
  }
}
