terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

resource "docker_network" "nginx" {
  name = "course_tf_nginx_net"
}

resource "docker_volume" "nginx_html" {
  name = "course_tf_nginx_html"
}

resource "docker_image" "nginx" {
  name = "nginx:stable-alpine"
}

resource "docker_container" "nginx" {
  name         = "course_tf_nginx"
  image        = docker_image.nginx.image_id
  network_mode = docker_network.nginx.name

  mounts {
    type   = "volume"
    source = docker_volume.nginx_html.name
    target = "/usr/share/nginx/html"
  }

  ports {
    internal = 80
    external = 8081
    ip       = "127.0.0.1"
  }
}

