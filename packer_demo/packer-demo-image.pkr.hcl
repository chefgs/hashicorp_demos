packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubuntu" {
#  image  = "ubuntu:xenial"
  image  = "alpine"
  commit = true
}

build {
  name = "packer-demo"
  sources = [
    "source.docker.ubuntu"
  ]
}
