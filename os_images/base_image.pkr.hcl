source "qemu" "base" {
  iso_url           = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  iso_checksum      = "file:https://cloud-images.ubuntu.com/focal/current/SHA256SUMS"

  accelerator       = "kvm"
  vm_name           = "base"
  headless          = true
  disk_image        = true

  output_directory  = "base"
  format            = "raw"

  disk_size         = "5000M"
  memory            = 1024
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"

  ssh_username      = "ubuntu"
  ssh_timeout       = "3m"
  qemuargs          = [["-cdrom", "cloud-init.img"], ["-serial", "mon:stdio"]]

  disk_interface    = "virtio"
  boot_wait         = "10s"

  ssh_private_key_file = "~/.ssh/id_rsa"
}

build {
  sources = ["source.qemu.base"]

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = [
      "sudo useradd -m -s /bin/bash efthymios -G adm,sudo",
      "echo 'efthymios:testicle' | sudo chpasswd",
     ]
    remote_folder   = "/tmp"
  }

  provisioner "ansible" {
    playbook_file = "../ansible/provision.yml"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = [
      "/usr/bin/apt-get clean",
     ]
    remote_folder   = "/tmp"
  }
}
