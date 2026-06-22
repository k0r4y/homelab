# =============================================================================
# Ubuntu 24.04 Hyper-V Golden Image (cloud-config-url)
# =============================================================================

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/noble/ubuntu-24.04.4-live-server-amd64.iso"
}

variable "switch_name" {
  type = string
}

variable "output_dir" {
  type    = string
  default = "output-ubuntu"
}

variable "host_ip" {
  type = string
}

packer {
  required_plugins {
    hyperv = {
      source  = "github.com/hashicorp/hyperv"
      version = ">= 1.0.0"
    }
  }
}

source "hyperv-iso" "ubuntu" {

  vm_name = "packer-ubuntu-24-04"

  iso_url      = var.iso_url
  iso_checksum = "file:https://releases.ubuntu.com/noble/SHA256SUMS"

  generation = 2
  cpus       = 2
  memory     = 4096
  disk_size  = 20480

  switch_name        = var.switch_name
  enable_secure_boot = false

  output_directory = var.output_dir

  # HTTP server
  http_directory    = "http"
  http_port_min     = 8100
  http_port_max     = 8100
  http_bind_address = var.host_ip

  # SSH - static IP
  ssh_host     = "192.168.178.100"
  ssh_port     = 22
  communicator = "ssh"
  ssh_username = "ansible"
  ssh_password = "ansible"
  ssh_timeout  = "60m"

  # Boot command - uses cloud-config-url (replaces deprecated url)
  boot_wait = "10s"
  boot_command = [
    "e<wait3>",
    "<down><down><down><end>",
    " autoinstall cloud-config-url=http://${var.host_ip}:8100/user-data ip=192.168.178.100::192.168.178.1:255.255.255.0::: net.ifnames=0 biosdevname=0 cloud-init.network.wait=1",
    "<f10>"
  ]

  shutdown_command = "echo 'ansible' | sudo -S shutdown -P now"
}

build {
  sources = ["source.hyperv-iso.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -qq",
      "sudo apt-get upgrade -y -qq",
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo systemctl enable ssh",
      "sudo dd if=/dev/zero of=/tmp/zeros bs=1M || true",
      "sudo rm -f /tmp/zeros"
    ]
  }
}