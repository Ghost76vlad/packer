
source "proxmox-iso" "ubuntu26" {
  # Параметры подключения к Proxmox
  proxmox_url              = local.proxmox_api_url
  username                 = local.proxmox_api_token_id
  token                    = local.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  # Параметры создаваемой VM
  node                    = local.proxmox_node
  vm_id                   = 911
  vm_name                 = "ubuntu-26-template"
  template_description    = "Ubuntu 26 Template - Packer"
  memory                  = 2048
  cores                   = 2
  sockets                 = 1
  cpu_type                = "host"
  os                      = "l26"
  qemu_agent              = true
  numa                    = true
  bios                    = "ovmf"
  cloud_init              = true
  cloud_init_storage_pool = "data-4T"
  cloud_init_disk_type    = "sata"

  efi_config {
    efi_storage_pool = "data-4T"
    efi_format       = "raw" # Добавлено: чтобы EFI-диск был в qcow2 (для снапшотов)
    efi_type         = "4m"

  }

  # Диск
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "30G"
    storage_pool = "data-4T"
    type         = "scsi"
    io_thread    = true
    cache_mode   = "writeback"
  }

  # Сеть
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Подключение к локальному ISO
  boot_iso {
    type         = "ide"
    iso_file     = "ISO:iso/ubuntu-26.04.1-live-server-amd64.iso"
    unmount      = true
    iso_checksum = "none"
  }

  # Настройка HTTP-сервера для передачи preseed
  http_directory    = "http"
  http_bind_address = "0.0.0.0"
  http_port_min     = 8001
  http_port_max     = 8001

  # Параметры автоматической установки
  boot_command = [
    "<wait>",
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' --- quiet kho=off<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter><wait>"
  ]
  boot_wait         = "5s"
  boot_key_interval = "100ms"

  # Сетевые параметры для SSH
  ssh_username = local.user_uz
  ssh_password = local.user_pass
  ssh_timeout  = "30m"

}

build {
  sources = ["source.proxmox-iso.ubuntu26"]

  # 1. Подготовка: ожидание перезагрузки
  provisioner "shell" {
    inline = [
      "echo 'waiting for reboot...'",
      "sleep 30"
    ]
  }
  # 2. Очистка: выполнение скрипта cleanup.sh
  provisioner "shell" {
    script          = "scripts/cleanup.sh"
    execute_command = "sudo sh -eux '{{ .Path }}'" # Запускаем script с sudo
  }
  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
      source = "files/99-pve.cfg"
      destination = "/tmp/99-pve.cfg"
  }   
  provisioner "shell" {
      inline = [ "sudo mv /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
  }
}