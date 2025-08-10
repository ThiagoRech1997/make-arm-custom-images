# Gravação no SD Card

Após o build e testes em QEMU, a imagem está pronta para ser gravada no SD card.

## Pré-requisitos

- SD card de pelo menos 4GB (recomendado 8GB+)
- Adaptador SD card (se necessário)
- Ferramenta de gravação

## Ferramentas de Gravação

### Balena Etcher (Recomendado)
- **Download**: https://www.balena.io/etcher/
- **Plataformas**: Windows, macOS, Linux
- **Interface**: Gráfica, amigável
- **Validação**: Automática após gravação

### dd (Linux/macOS)
```bash
# Identificar dispositivo SD
lsblk

# Gravar imagem (CUIDADO: substitua sdX pelo dispositivo correto)
sudo dd if=output/alpine-rpi3-custom.img of=/dev/sdX bs=4M status=progress conv=fsync
```

### Win32 Disk Imager (Windows)
- **Download**: https://sourceforge.net/projects/win32diskimager/
- **Interface**: Gráfica
- **Validação**: Opcional

## Processo de Gravação

### 1. Preparação
```bash
# Verificar se imagem existe
ls -la output/alpine-rpi3-custom.img

# Verificar tamanho
du -h output/alpine-rpi3-custom.img
```

### 2. Identificar SD Card
```bash
# Listar dispositivos
lsblk

# Exemplo de saída:
# sda      8:0    0 465.8G  0 disk
# ├─sda1   8:1    0   512M  0 part
# └─sda2   8:2    0 465.3G  0 part
# sdb      8:16   0  14.9G  0 disk  ← SD card
# ├─sdb1   8:17   0  256M  0 part
# └─sdb2   8:18   0  14.6G  0 part
```

### 3. Desmontar SD Card (se necessário)
```bash
# Desmontar todas as partições
sudo umount /dev/sdX1 /dev/sdX2 2>/dev/null || true
```

### 4. Gravar com Balena Etcher
1. Abrir Balena Etcher
2. Clicar em "Select image"
3. Escolher `output/alpine-rpi3-custom.img`
4. Clicar em "Select target"
5. Escolher o SD card
6. Clicar em "Flash!"
7. Aguardar gravação e validação

### 5. Gravar com dd (Linux)
```bash
# GRAVAR (substitua sdX pelo dispositivo correto)
sudo dd if=output/alpine-rpi3-custom.img of=/dev/sdX bs=4M status=progress conv=fsync

# Verificar gravação
sudo sync
```

## Verificação da Gravação

### Verificar partições:
```bash
# Listar partições no SD
sudo fdisk -l /dev/sdX

# Esperado:
# /dev/sdX1  256M  FAT32  boot
# /dev/sdX2  resto ext4   root
```

### Verificar conteúdo:
```bash
# Montar boot
sudo mount /dev/sdX1 /mnt
ls -la /mnt/
sudo umount /mnt

# Montar root
sudo mount /dev/sdX2 /mnt
ls -la /mnt/
sudo umount /mnt
```

## Primeiro Boot no Hardware Real

### 1. Preparação
- SD card gravado
- Raspberry Pi 3B
- Fonte de alimentação 5V/2.5A
- Teclado e monitor (opcional)
- Cabo de rede (opcional)

### 2. Montagem
1. Inserir SD card no Pi
2. Conectar fonte de alimentação
3. Conectar teclado/monitor (se disponível)
4. Conectar cabo de rede (se disponível)

### 3. Boot
- LED vermelho: alimentação
- LED verde: atividade SD
- Aguardar 30-60 segundos para primeiro boot

### 4. Login
```bash
# Login como root (sem senha)
login: root

# Verificar sistema
uname -a
cat /etc/os-release
```

## Configuração Pós-Boot

### 1. Configurar rede (se necessário)
```bash
# Configurar interfaces
setup-interfaces

# Ou editar manualmente
nano /etc/network/interfaces
```

### 2. Atualizar sistema
```bash
# Atualizar repositórios
apk update

# Atualizar pacotes
apk upgrade
```

### 3. Configurar SSH (se habilitado)
```bash
# Verificar se SSH está rodando
rc-status | grep sshd

# Conectar via SSH (se rede configurada)
ssh root@IP_DO_PI
```

### 4. Configurar senha root
```bash
# Definir senha para root
passwd
```

## Troubleshooting

### SD card não é reconhecido
```bash
# Verificar se SD está sendo detectado
dmesg | tail

# Verificar dispositivos
lsblk
```

### Pi não inicia
- Verificar fonte de alimentação
- Verificar SD card
- Verificar conexões
- Verificar LEDs

### Boot falha
```bash
# Verificar logs (se possível)
dmesg

# Verificar partições
fdisk -l /dev/mmcblk0
```

### Rede não funciona
```bash
# Verificar interfaces
ip addr

# Verificar configuração
cat /etc/network/interfaces

# Configurar manualmente
setup-interfaces
```

### SSH não funciona
```bash
# Verificar se SSH está ativo
rc-status | grep sshd

# Iniciar SSH manualmente
rc-service sshd start

# Verificar logs
tail -f /var/log/messages
```

## Otimizações

### Expandir partição root
```bash
# Após primeiro boot
apk add parted

# Expandir partição
parted /dev/mmcblk0 resizepart 2 100%
resize2fs /dev/mmcblk0p2
```

### Configurar swap
```bash
# Criar arquivo swap
dd if=/dev/zero of=/swapfile bs=1M count=512
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Adicionar ao fstab
echo "/swapfile none swap sw 0 0" >> /etc/fstab
```

### Configurar timezone
```bash
# Configurar timezone
setup-timezone -z America/Sao_Paulo
```

## Backup e Restauração

### Backup da imagem
```bash
# Criar backup
sudo dd if=/dev/sdX of=backup.img bs=4M status=progress

# Comprimir backup
gzip backup.img
```

### Restaurar backup
```bash
# Descomprimir
gunzip backup.img.gz

# Restaurar
sudo dd if=backup.img of=/dev/sdX bs=4M status=progress
```

## Próximos Passos

Após o primeiro boot bem-sucedido:

1. **Configurar rede** (se necessário)
2. **Atualizar sistema**
3. **Instalar aplicações específicas**
4. **Configurar serviços**
5. **Configurar monitoramento**
6. **Fazer backup da configuração** 