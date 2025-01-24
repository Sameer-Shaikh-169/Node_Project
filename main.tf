terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2" # Check for the latest version at https://registry.terraform.io/providers/kreuzwerker/docker/latest
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock" # Adjust for Windows if necessary
}

# Create a Docker network for app and cAdvisor
resource "docker_network" "app_network" {
  name = "app_network"
}

# Build and run the Node.js application container
resource "docker_image" "app_image" {
  name = "my-node-app:latest"
  build {
    context    = "${path.module}"
    dockerfile = "${path.module}/Dockerfile"
  }
}

resource "docker_container" "app_container" {
  name  = "my-node-app"
  image = docker_image.app_image.name
  ports {
    internal = 3000
    external = 3000
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Run the cAdvisor container
resource "docker_container" "cadvisor" {
  name  = "cadvisor"
  image = "gcr.io/cadvisor/cadvisor:latest"
  ports {
    internal = 8080
    external = 8080
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }
  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = true
  }
  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }
  volumes {
    host_path      = "/var/lib/docker"
    container_path = "/var/lib/docker"
    read_only      = true
  }
}