## Build a custom image with HashiCorp Packer


## Introduction
We are in the era of evolving Infrastructure requirements and automating infrastructure of different sizes ranging from small to enterprise grade infrastructure.
All this infrastructure implementation is dependent on the virtual servers, and other infrastructure components. Operating system components play a major part for any virtual server on which we configure necessary changes and deploy our code. When it comes to cloud infrastructure, this concept is called “machine images” which is used for creating virtual servers. 

Machine image defined in [Packer docs](https://developer.hashicorp.com/packer/docs/intro) as below,
> A machine image is a static unit that contains a pre-configured operating system and installed software which is used to quickly create new running machines. Machine image formats change for each platform. Some examples include Amazon Machine Images (AMI) for EC2, VMDK/VMX files for VMware, OVF exports for VirtualBox, etc.

Every organization uses a certain standards for their server infrastructure to have the specific config and security standards implemented on the machine images, and it is called as Golden Images

Before cloud and automation came into picture, it was a manual process and took longer time to create a machine image from a running server. 
But nowadays with the concepts of Containerisation this becomes an easier task.

This is when the Packer (or similar kind of image packaging technologies) come into picture. 

Packer is a tool to create “image as code”, wherein we can write the image represented in Hashicorp language. So when we run `packer build` it generates the image and creates it in the way we want.
It is a lightweight tool that runs on multiple operating systems. It can be used to create multi platform images in parallel using a multi stage build process.
Packer allows us to create images that can be created  as “docker” images or AWS 

Since the majority of cloud deployments nowadays uses immutable infrastructure deployment, it becomes important to use tools like packer as part of landscape, which can be integrated into the deployment pipeline to create the specified images to deploy our application code.

## Advantages of using Packer
https://developer.hashicorp.com/packer/docs/intro/why

## Packer use-case
https://developer.hashicorp.com/packer/docs/intro/use-cases

## Packer versions
- Packer CLI is Open source version
- HCP Packer which is the enterprise version of packer available in HashiCorp Cloud Platform.

In this blog, we will be seeing how to use **Packer CLI** for creating our custom built images in Docker container and AWS ECR


## Concepts and Terminologies of Packer

### Concept of Template
Packer uses templates to define the Image as code. It contains a series of declarations for the packer to use for creating an image.

https://developer.hashicorp.com/packer/docs/templates

There are two types of templates available,
- HCL templates
- JSON templates

Learners Tip: If you’ve worked on Terraform HCL code, then learning packer HCL definitions are easy pick

### Terminologies
When we learn packer, we need to understand (few, yes few) handful of terminologies. Just for the purpose of co-related learning, we can relate the most of the terminologies are similar to container image and application packaging.

- `Artifacts` are the results of a single build, and are usually a set of IDs or files to represent a machine image. Every builder produces a single artifact

- `Builds` are a single task that eventually produces an image for a single platform. Multiple builds run in parallel.

- `Builders` are components of Packer that are able to create a machine image for a single platform.

- `Post-processors` are components of Packer that take the result of a builder or another post-processor and process that to create a new artifact.

- `Provisioners` are components of Packer that install and configure software within a running machine prior to that machine being turned into a static image. They perform the major work of making the image contain useful software.

Commands are sub-commands for the packer program that perform some job. An example command is "build", which is invoked as packer build. Packer ships with a set of commands out of the box in order to define its command-line interface.
Provisioners are components of Packer that install and configure software within a running machine prior to that machine being turned into a static image. They perform the major work of making the image contain useful software. Example provisioners include shell scripts, Chef, Puppet, etc.

We will explore further and see how we can create an Image using Packer build, provisioner and post-processor

## Pre-requisites

### Install packer
Operating system specific installation can be [found here](https://developer.hashicorp.com/packer/downloads). Select your appropriate Operating system and follow the provided instructions.

Since I'm using Ubuntu Linux, I've selected the Linux Installation method and installed Packer CLI
```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install packer
```

## Let us create Docker Image
- Packer documentation has of getting started tutorial [here](https://developer.hashicorp.com/packer/tutorials) 

- I'll take you through the docker image as code created using Packer.
- Source code for this demo project has been available in [GitHub](https://github.com/chefgs/hashicorp_demos/tree/main/packer_demo)


### Skeleton Structure of Packer HCL
- Packer HCL definition can consists of following blocks
- `packer` block - We can declare `required_plugins` block here
  - `required_plugins` are nothing but the type of image we will be used in the packer definition
- `source` block - Here we can declare the type of based image to be created as the outcome of the `packer build`
- `build` block - In this block we should define `sources` of base image in which the images will get build
  - `provisioner` - In this section we can define a set of scripts that will be running during the image creation. If we want to install a set of software and configuration during the boot up, we can utilise this section
  - `post_processors` - This is section, where can perform the image tagging and pushing to registry etc.
- `variable` block - If we want to templatise the packer build process, we can make use of vairable block, and add the common values that can be used across the HCL file. Like Terraform, packer also has `var-file` concept so we can override the variables, while invoking the `packer` CLI command. 


## Full Source of Docker Packer Build

```
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

```
