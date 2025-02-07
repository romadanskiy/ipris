terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = "b1g0r2kida4942eldbsv"
  folder_id                = "b1g4th38ssc087e4o7l7"
  zone                     = "ru-central1-b"
}

resource "yandex_vpc_network" "task4" {
  name = "task4"
}

resource "yandex_vpc_subnet" "sub4" {
  name           = "sub4"
  v4_cidr_blocks = ["192.168.0.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.task4.id
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${pathexpand("~")}/.ssh/task4_key"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${pathexpand("~")}/.ssh/task4_key.pub"
}

resource "local_file" "metadata4" {
  content  = <<-EOT
    #cloud-config
    users:
      - name: ipiris
        shell: /bin/bash
        sudo: 'ALL=(ALL) NOPASSWD:ALL'
        ssh_authorized_keys:
          - ${tls_private_key.ssh_key.public_key_openssh}
  EOT
  filename = "${path.module}/metadata4.yaml"
}

resource "yandex_compute_disk" "task4_disk" {
  name     = "task4_disk"
  type     = "network-ssd"
  zone     = "ru-central1-b"
  size     = 20
  image_id = "fd833ivvmqp6cuq7shpc"
}

resource "yandex_compute_instance" "task4_vm" {
  name        = "task4_vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    disk_id = yandex_compute_disk.task4_disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.sub4.id
    nat       = true
  }

  metadata = {
    user-data = local_file.metadata4.content
  }
}

resource "null_resource" "setup_docker" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo docker run -d --rm --name task4-app -p 80:8080 jmix/jmix-bookstore"
    ]

    connection {
      type        = "ssh"
      user        = "ipiris"
      private_key = tls_private_key.ssh_key.private_key_openssh
      host        = yandex_compute_instance.task4_vm.network_interface[0].nat_ip_address
    }
  }
}

output "ssh_connection_string" {
  value = "ssh -i task4_key ipiris@${yandex_compute_instance.task4_vm.network_interface[0].nat_ip_address}"
}

output "web_app_url" {
  value = "http://${yandex_compute_instance.task4_vm.network_interface[0].nat_ip_address}"
}
