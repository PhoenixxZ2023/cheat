#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "O script deve ser executado como root. Utilize 'sudo' para executar o script."
  exit 1
fi

echo "Configurando limites de arquivos e ajustes adicionais..."

# Verificar e instalar pacotes necessários
if ! dpkg -l | grep -q wireguard; then
  sudo apt update && sudo apt install wireguard resolvconf curl -y
fi

# Captura do IP público
IP_PUBLICO=$(curl -4 -s ifconfig.me)

# Criação do diretório se não existir
if [ ! -d "/etc/wireguard" ]; then
  mkdir -p /etc/wireguard
fi

# Gerar o arquivo de configuração wg0.conf
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = OJ/ytNFUAEBcKSi8H7+7M/uk0lsLIjWdkj9Vxa6K6ks=
Address = 172.16.0.2/32
DNS = 1.1.1.1, 1.0.0.1
MTU = 1280
PostUp = ip rule add from $IP_PUBLICO lookup main
PostDown = ip rule delete from $IP_PUBLICO lookup main

[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = engage.cloudflareclient.com:2408
EOF

# Definir permissões adequadas
chmod 600 /etc/wireguard/wg0.conf

# Subir a interface WireGuard
sudo wg-quick up wg0

# Exibir status da interface WireGuard
sudo wg

# Habilitar WireGuard no boot
sudo systemctl enable wg-quick@wg0
