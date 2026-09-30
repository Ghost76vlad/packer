
source "proxmox-iso" "debian13" {
  # Параметры подключения к Proxmox
  proxmox_url              = local.proxmox_api_url
  username                 = local.proxmox_api_token_id
  token                    = local.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  # Параметры создаваемой VM
  node                    = local.proxmox_node
  vm_id                   = 910
  vm_name                 = "debian-13-template"
  template_description    = "Debian 13 (Trixie) Template - Packer"
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
    iso_file     = "ISO:iso/debian-13.4.0-amd64-DVD-1.iso"
    unmount      = true
    iso_checksum = "none"
  }

  # Настройка HTTP-сервера для передачи preseed
  http_directory    = "http"
  http_bind_address = "0.0.0.0"
  http_port_min     = 8000
  http_port_max     = 8000

  # Параметры автоматической установки
  boot_command = [
    "<wait10>",
    "<down><wait>",             # Выбираем "Install" вместо "Graphical install"
    "e<wait>",                  # Нажимаем 'e' для редактирования
    "<down><down><down><wait>", # Спускаемся к строке linux
    "<end><wait>",              # Переходим в конец строки
    " auto=true priority=critical preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<wait>",
    "<f10>"
  ]
  boot_wait         = "5s"
  boot_key_interval = "100ms"

  # Сетевые параметры для SSH
  ssh_username = local.user_uz
  ssh_password = local.user_pass
  ssh_timeout  = "30m"
}

build {
  sources = ["source.proxmox-iso.debian13"]

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
    execute_command = "sudo -E sh -eux '{{ .Path }}'" # Запускаем script с sudo
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