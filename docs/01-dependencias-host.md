# Dependências do Sistema Host

## Sistemas Suportados

Este template foi testado em:
- Ubuntu 20.04+
- Debian 11+
- Linux Mint 20+
- WSL2 (Windows Subsystem for Linux)

## Instalação das Dependências

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y \
  qemu \
  qemu-system-arm \
  qemu-utils \
  parted \
  kpartx \
  dosfstools \
  e2fsprogs \
  wget \
  curl \
  xz-utils \
  tar \
  git \
  unzip \
  coreutils \
  util-linux \
  binfmt-support
```

### Verificação da Instalação

```bash
# Verificar QEMU
qemu-system-arm --version

# Verificar ferramentas de partição
parted --version
kpartx --version

# Verificar ferramentas de sistema de arquivos
mkfs.vfat --version
mkfs.ext4 --version
```

## Dependências Opcionais

### Para Desenvolvimento
```bash
sudo apt install -y \
  vim \
  nano \
  tree \
  htop \
  ncdu
```

### Para Análise de Imagens
```bash
sudo apt install -y \
  fdisk \
  file \
  hexdump
```

## Uso em WSL2/VM

### WSL2 (Windows)
- Funciona bem para desenvolvimento
- Performance pode ser limitada
- Recomendado para testes básicos

### Máquina Virtual
- Use pelo menos 4GB RAM
- Aloque 20GB+ para armazenamento
- Habilite virtualização aninhada se necessário

## Troubleshooting

### QEMU não encontrado
```bash
# Verificar se QEMU está instalado
which qemu-system-arm

# Reinstalar se necessário
sudo apt remove --purge qemu qemu-system-arm qemu-utils
sudo apt install qemu qemu-system-arm qemu-utils
```

### Permissões de loop device
```bash
# Verificar se o usuário pode usar loop devices
ls -la /dev/loop*

# Adicionar usuário ao grupo disk se necessário
sudo usermod -a -G disk $USER
# (Requer logout/login)
```

### Espaço insuficiente
```bash
# Verificar espaço disponível
df -h

# Limpar cache se necessário
sudo apt clean
sudo apt autoremove
```

## Requisitos Mínimos

- **CPU**: 2 cores
- **RAM**: 4GB
- **Armazenamento**: 10GB livre
- **Rede**: Conexão com internet
- **Permissões**: Acesso sudo 