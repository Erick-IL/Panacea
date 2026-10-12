#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute este script com sudo: sudo ./fix-docker.sh"
  exit 1
fi

echo "==> 1. Fazendo backup do /etc/nixos/configuration.nix..."
cp -v /etc/nixos/configuration.nix "/etc/nixos/configuration.nix.bak-docker-$(date +%Y%m%d-%H%M%S)"

echo "==> 2. Adicionando o grupo 'docker' ao usuário levandoski..."
if grep -q '"docker"' /etc/nixos/configuration.nix; then
  echo "  Grupo 'docker' já existe na configuração."
else
  sed -i 's/"wheel" "i2c"/"wheel" "i2c" "docker"/g' /etc/nixos/configuration.nix
  if ! grep -q '"docker"' /etc/nixos/configuration.nix; then
    sed -i 's/"wheel"/"wheel" "docker"/g' /etc/nixos/configuration.nix
  fi
  echo "  Configuração atualizada com sucesso!"
fi

echo "==> 3. Aplicando alterações com nixos-rebuild switch..."
nixos-rebuild switch

echo "==> 4. Concedendo acesso imediato ao socket nesta sessão..."
chmod 666 /var/run/docker.sock 2>/dev/null || true

echo ""
echo "=================================================================="
echo "Sucesso! O Docker agora funcionará permanentemente sem pedir permissão,"
echo "inclusive após reiniciar o computador."
echo "=================================================================="
