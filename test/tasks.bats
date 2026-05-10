#!/usr/bin/env bats

setup() {
  load test_helper
}

@test "mise tasks shows the tutorial entrypoint but hides tutorial modules" {
  run mise -C "$REPO_ROOT" tasks

  [ "$status" -eq 0 ]
  [[ "$output" == *"tutorial"* ]]
  [[ "$output" != *"tutorial:intro"* ]]
  [[ "$output" != *"tutorial:config"* ]]
  [[ "$output" != *"tutorial:generate"* ]]
  [[ "$output" != *"tutorial:apply"* ]]
  [[ "$output" != *"tutorial:navigate"* ]]
  [[ "$output" != *"tutorial:summary"* ]]
}

@test "hidden tutorial modules remain visible with --hidden" {
  run mise -C "$REPO_ROOT" tasks --hidden

  [ "$status" -eq 0 ]
  [[ "$output" == *"tutorial:intro"* ]]
  [[ "$output" == *"tutorial:summary"* ]]
}
