#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "O script deve ser executado como root. Utilize 'sudo' para executar o script."
  exit 1
fi

echo "Configurando limites de arquivos e ajustes adicionais..."

# Detectar se o sistema é Ubuntu ou Debian
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
  VERSION_ID=$(echo "$VERSION_ID" | cut -d'.' -f1)
else
  echo "Sistema operacional não suportado."
  exit 1
fi

# Função para instalar o WireGuard no Ubuntu (usando PPA)
instalar_wireguard_ubuntu() {
  sudo apt install software-properties-common -y
  sudo add-apt-repository ppa:wireguard/wireguard -y
  sudo apt install wireguard resolvconf curl -y
}

# Função para instalar o WireGuard no Debian (usando Backports)
instalar_wireguard_debian() {
  echo "deb http://deb.debian.org/debian $(lsb_release -cs)-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
  sudo apt install wireguard resolvconf curl -y
}

# Verificar se é Ubuntu 20 ou 22
if [ "$OS" = "ubuntu" ] && { [ "$VERSION_ID" -eq 20 ] || [ "$VERSION_ID" -eq 22 ]; }; then
  instalar_wireguard_ubuntu

# Verificar se é Debian 10 ou 11 ou superior
elif [ "$OS" = "debian" ] && { [ "$VERSION_ID" -ge 10 ]; }; then
  instalar_wireguard_debian

else
  echo "Este script suporta apenas Ubuntu 20, 22 e Debian 10 ou superior."
  exit 1
fi

# Captura do IP público
IP_PUBLICO=$(curl -4 -s ifconfig.me)

# Criação do diretório se não existir
if [ ! -d "/etc/wireguard" ]; then
  mkdir -p /etc/wireguard
fi

# Gerar o arquivo de configuração wg0.conf (apenas IPv4)
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = OJ/ytNFUAEBcKSi8H7+7M/uk0lsLIjWdkj9Vxa6K6ks=
Address = 172.16.0.2/32  # Endereço IPv4
DNS = 1.1.1.1, 1.0.0.1   # DNS IPv4
MTU = 1450
PostUp = ip rule add from $IP_PUBLICO lookup main
PostDown = ip rule delete from $IP_PUBLICO lookup main

[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
AllowedIPs = 0.0.0.0/0  # Apenas IPv4 permitido
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
