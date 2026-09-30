#!/bin/bash
set -e

echo "=== Очистка системы ==="
apt-get autoremove -y
apt-get clean

# Удаление временных файлов
rm -rf /tmp/* 2>/dev/null || true
rm -rf /var/tmp/* 2>/dev/null || true
rm -rf /var/cache/apt/archives/*.deb

# Очистка логов
find /var/log -type f -exec truncate -s 0 {} \;
rm -f /var/log/*.gz
rm -f /var/log/*.old
rm -f /var/log/*.1

# Очистка SSH ключей
rm -f /etc/ssh/ssh_host_*

# Очистка истории bash (файлы)
truncate -s 0 /root/.bash_history || true
truncate -s 0 /home/*/.bash_history || true

# Очистка machine-id
truncate -s 0 /etc/machine-id
truncate -s 0 /var/lib/dbus/machine-id

# Очистка cloud-init (если установлен)
cloud-init clean --logs --seed || true

echo "=== Очистка завершена ==="