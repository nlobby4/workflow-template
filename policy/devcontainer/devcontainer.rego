package main

import rego.v1

deny contains msg if {
  input.devcontainer.remoteUser == "root"
  msg := "remoteUser must be non-root"
}

deny contains msg if {
  input.devcontainer.init != true
  msg := "init must be enabled"
}

deny contains msg if {
  some mount in input.devcontainer.mounts
  mount_contains_docker_socket(mount)
  msg := "host Docker socket mounts are forbidden"
}

mount_contains_docker_socket(mount) if {
  is_string(mount)
  contains(lower(mount), "docker.sock")
}

mount_contains_docker_socket(mount) if {
  is_object(mount)
  some _, value in mount
  is_string(value)
  contains(lower(value), "docker.sock")
}

deny contains msg if {
  some feature, _ in input.devcontainer.features
  not regex.match(`^ghcr\.io/devcontainers/features/[a-z0-9-]+:[0-9]+\.[0-9]+\.[0-9]+$`, feature)
  msg := sprintf("feature must use an approved registry and exact version: %s", [feature])
}

deny contains msg if {
  some feature, _ in input.devcontainer.features
  not input.lock.features[feature]
  msg := sprintf("feature is absent from devcontainer-lock.json: %s", [feature])
}

deny contains msg if {
  some feature, locked in input.lock.features
  expected := trim_prefix(locked.resolved, sprintf("%s@", [split(feature, ":")[0]]))
  locked.integrity != expected
  msg := sprintf("feature integrity does not match its resolved digest: %s", [feature])
}
