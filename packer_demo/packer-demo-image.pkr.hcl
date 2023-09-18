packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "docker_username" {
  type    = string
  default = "gsdockit"
}

variable "docker_pwd" {
  type    = string
  default = env("DOCKER_PASSWORD")
}

variable "docker_url" {
  type    = string
  default = "https://registry.hub.docker.com/v2/"
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

  provisioner "shell" {
    environment_vars = [
      "message=My First Packer Build",
    ]
    inline = [
      "echo Adding file to Docker Container",
      "echo \"Message is $message\" > example.txt",
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "gsdockit/packer-demo"
      tags       = ["0.1", "latest"]
    }

    post-processor "docker-push" {
      login          = true
      login_password = var.docker_pwd
      login_username = var.docker_username
      login_server   = var.docker_url
    }
  }

}
