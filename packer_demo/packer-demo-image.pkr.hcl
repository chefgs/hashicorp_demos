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
  default = env("DOCKER_USERNAME")
}

variable "docker_pwd" {
  type    = string
  default = env("DOCKER_PASSWORD")
}

# variable "docker_url" {
#   type    = string
#   default = "https://index.docker.io/v1/"
# }

variable "image_build_name" {
  type    = string
  default = "packer-demo-2"
}

source "docker" "ubuntu" {
  #  image  = "ubuntu:xenial"
  image  = "alpine"
  commit = true
  changes = [
    "ENTRYPOINT /bin/sh"
  ]
}

build {
  name = var.image_build_name
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
      repository = "${var.docker_username}/${var.image_build_name}"
      tags       = ["latest"]
    }

    post-processor "docker-push" {
      login          = true
      login_password = var.docker_pwd
      login_username = var.docker_username
      # login_server   = var.docker_url
    }
  }

}
