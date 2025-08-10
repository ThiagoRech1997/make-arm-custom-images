#!/bin/bash

# =============================================================================
# Make ARM Custom Images - Script Principal de Build
# =============================================================================
# Este script orquestra todo o processo de criação de imagens personalizadas
# para Raspberry Pi a partir do Alpine Linux.

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO E INICIALIZAÇÃO
# =============================================================================

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Carregar configurações
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
else
    echo "❌ Arquivo .env não encontrado!"
    echo "   Copie env.example para .env e configure as variáveis."
    exit 1
fi

# Carregar funções utilitárias
source "$SCRIPT_DIR/utils.sh"

# =============================================================================
# FUNÇÕES PRINCIPAIS
# =============================================================================

# Função para exibir banner de início
show_banner() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Make ARM Custom Images                    ║"
    echo "║              Alpine Linux para Raspberry Pi 3B              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Iniciando processo de build..."
    log_info "Versão Alpine: $ALPINE_VERSION"
    log_info "Arquitetura: $ALPINE_ARCH"
    log_info "Hostname: $HOSTNAME"
    echo ""
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar se executando como root ou com sudo
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado como root ou com sudo"
        exit 1
    fi
    
    # Verificar dependências do sistema
    local deps=("wget" "curl" "qemu-system-arm" "parted" "mount")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Dependência não encontrada: $dep"
            log_info "Execute: sudo apt install -y wget curl qemu-system-arm parted dosfstools"
            exit 1
        fi
    done
    
    # Verificar dosfstools especificamente
    if ! command -v "mkfs.fat" &> /dev/null; then
        log_error "Dependência não encontrada: dosfstools (mkfs.fat)"
        log_info "Execute: sudo apt install -y dosfstools"
        exit 1
    fi
    
    # Verificar espaço em disco
    local required_space=$((IMAGE_SIZE_MB * 3))  # 3x o tamanho da imagem
    local available_space=$(df . | awk 'NR==2 {print $4}')
    available_space=$((available_space / 1024))  # Converter para MB
    
    if [[ $available_space -lt $required_space ]]; then
        log_error "Espaço insuficiente em disco"
        log_info "Necessário: ${required_space}MB, Disponível: ${available_space}MB"
        exit 1
    fi
    
    log_success "Pré-requisitos verificados com sucesso"
}

# Função para preparar diretórios
prepare_directories() {
    log_info "Preparando diretórios de trabalho..."
    
    # Criar diretórios se não existirem
    mkdir -p "$WORK_DIR"
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$WORK_DIR/mount"
    mkdir -p "$WORK_DIR/rootfs"
    
    # Limpar diretórios se existirem
    if [[ -d "$WORK_DIR/mount" ]]; then
        umount -f "$WORK_DIR/mount" 2>/dev/null || true
    fi
    
    log_success "Diretórios preparados"
}

# Função para baixar imagem base
download_base_image() {
    log_info "Baixando imagem base Alpine Linux..."
    
    local tarball_name="${ALPINE_VARIANT}-${ALPINE_VERSION}.1-${ALPINE_ARCH}.tar.gz"
    local download_url="${ALPINE_BASE_URL}/${tarball_name}"
    local local_path="$WORK_DIR/$tarball_name"
    
    if [[ -f "$local_path" && "$USE_PACKAGE_CACHE" == "true" ]]; then
        log_info "Usando cache local: $tarball_name"
    else
        log_info "Baixando de: $download_url"
        wget -q --show-progress -O "$local_path" "$download_url"
        
        if [[ "$VERIFY_CHECKSUMS" == "true" ]]; then
            log_info "Verificando checksum..."
            local sha256_url="${download_url}.sha256"
            local sha256_file="$WORK_DIR/${tarball_name}.sha256"
            wget -q -O "$sha256_file" "$sha256_url"
            
            if ! (cd "$WORK_DIR" && sha256sum -c "$sha256_file"); then
                log_error "Falha na verificação do checksum"
                exit 1
            fi
        fi
    fi
    
    log_success "Imagem base baixada: $tarball_name"
}

# Função para criar imagem particionada
create_partitioned_image() {
    log_info "Criando imagem particionada..."
    
    local img_path="$OUTPUT_DIR/$OUTPUT_FILENAME"
    local size_mb=$IMAGE_SIZE_MB
    
    # Remover imagem existente
    rm -f "$img_path"
    
    # Criar arquivo de imagem
    log_info "Criando arquivo de imagem (${size_mb}MB)..."
    dd if=/dev/zero of="$img_path" bs=1M count="$size_mb" status=progress
    
    # Criar tabela de partições
    parted "$img_path" mklabel msdos
    
    # Criar partição boot (FAT32, 256MB)
    parted "$img_path" mkpart primary fat32 1MiB 257MiB
    parted "$img_path" set 1 boot on
    
    # Criar partição root (ext4, resto do espaço)
    parted "$img_path" mkpart primary ext4 257MiB 100%
    
    # Encontrar loop device para formatação
    local loop_device=$(losetup --find --show "$img_path")
    log_info "Formatando partições usando loop device: $loop_device"
    
    # Atualizar tabela de partições
    partprobe "$loop_device"
    sleep 2
    
    # Formatar partições
    mkfs.vfat -F32 "${loop_device}p1"  # Partição boot
    mkfs.ext4 -F "${loop_device}p2"    # Partição root
    
    # Desconectar loop device
    losetup -d "$loop_device"
    
    log_success "Imagem particionada criada"
}

# Função para montar e preparar sistema de arquivos
mount_and_prepare_filesystem() {
    log_info "Montando e preparando sistema de arquivos..."
    
    local img_path="$OUTPUT_DIR/$OUTPUT_FILENAME"
    local mount_point="$WORK_DIR/mount"
    local rootfs_dir="$WORK_DIR/rootfs"
    
    # Encontrar loop device
    local loop_device=$(losetup --find --show "$img_path")
    log_info "Usando loop device: $loop_device"
    
    # Atualizar tabela de partições
    partprobe "$loop_device"
    sleep 2  # Aguardar criação dos dispositivos de partição
    
    # Montar partições
    mkdir -p "$mount_point"
    mount "${loop_device}p2" "$mount_point"  # Partição root
    
    # Extrair Alpine para rootfs
    local tarball_name="${ALPINE_VARIANT}-${ALPINE_VERSION}.1-${ALPINE_ARCH}.tar.gz"
    local tarball_path="$WORK_DIR/$tarball_name"
    
    log_info "Extraindo Alpine Linux..."
    tar -xzf "$tarball_path" -C "$mount_point"
    
    # Montar partição boot
    mkdir -p "$mount_point/boot"
    mount "${loop_device}p1" "$mount_point/boot"  # Partição boot
    
    # Configurar fstab
    cat > "$mount_point/etc/fstab" << EOF
/dev/mmcblk0p1  /boot   vfat    defaults    0   0
/dev/mmcblk0p2  /       ext4    defaults    0   0
EOF
    
    log_success "Sistema de arquivos preparado"
}

# Função para aplicar customizações
apply_customizations() {
    log_info "Aplicando customizações..."
    
    local mount_point="$WORK_DIR/mount"
    
    # Configurar hostname
    echo "$HOSTNAME" > "$mount_point/etc/hostname"
    
    # Configurar timezone
    if [[ -n "$TIMEZONE" ]]; then
        ln -sf "/usr/share/zoneinfo/$TIMEZONE" "$mount_point/etc/localtime"
    fi
    
    # Configurar locale
    if [[ -n "$LOCALE" ]]; then
        mkdir -p "$mount_point/etc/env.d"
        echo "LANG=$LOCALE" > "$mount_point/etc/env.d/99locale"
    fi
    
    # Configurar rede
    setup_network_config "$mount_point"
    
    # Instalar pacotes
    install_packages "$mount_point"
    
    # Configurar serviços
    setup_services "$mount_point"
    
    # Configurar SSH
    setup_ssh "$mount_point"
    
    log_success "Customizações aplicadas"
}

# Função para configurar rede
setup_network_config() {
    local mount_point="$1"
    
    log_info "Configurando rede..."
    
    # Configurar interfaces
    cat > "$mount_point/etc/network/interfaces" << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF
    
    # Configurar Wi-Fi se especificado
    if [[ -n "$WIFI_SSID" && -n "$WIFI_PASSWORD" ]]; then
        log_info "Configurando Wi-Fi: $WIFI_SSID"
        
        mkdir -p "$mount_point/etc/wpa_supplicant"
        cat > "$mount_point/etc/wpa_supplicant/wpa_supplicant.conf" << EOF
country=$WIFI_COUNTRY
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
    key_mgmt=WPA-PSK
}
EOF
        chmod 600 "$mount_point/etc/wpa_supplicant/wpa_supplicant.conf"
    fi
}

# Função para instalar pacotes
install_packages() {
    local mount_point="$1"
    
    log_info "Instalando pacotes..."
    
    # Configurar repositórios Alpine
    cat > "$mount_point/etc/apk/repositories" << EOF
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community
EOF
    
    # Montar proc, sys, dev para chroot
    mount --bind /proc "$mount_point/proc"
    mount --bind /sys "$mount_point/sys"
    mount --bind /dev "$mount_point/dev"
    
    # Atualizar índice de pacotes
    chroot "$mount_point" apk update
    
    # Instalar pacotes essenciais
    if [[ -n "$ESSENTIAL_PACKAGES" ]]; then
        log_info "Instalando pacotes essenciais: $ESSENTIAL_PACKAGES"
        chroot "$mount_point" apk add --no-cache $ESSENTIAL_PACKAGES
    fi
    
    # Instalar pacotes opcionais
    if [[ -n "$OPTIONAL_PACKAGES" ]]; then
        log_info "Instalando pacotes opcionais: $OPTIONAL_PACKAGES"
        chroot "$mount_point" apk add --no-cache $OPTIONAL_PACKAGES
    fi
    
    # Desmontar sistemas de arquivos especiais
    umount "$mount_point/proc"
    umount "$mount_point/sys"
    umount "$mount_point/dev"
    
    log_success "Pacotes instalados"
}

# Função para configurar serviços
setup_services() {
    local mount_point="$1"
    
    log_info "Configurando serviços..."
    
    # Habilitar serviços de boot
    if [[ -n "$BOOT_SERVICES" ]]; then
        for service in $BOOT_SERVICES; do
            if [[ -f "$mount_point/etc/init.d/$service" ]]; then
                chroot "$mount_point" rc-update add "$service" default
                log_info "Serviço habilitado: $service"
            fi
        done
    fi
    
    # Habilitar serviços opcionais
    if [[ -n "$OPTIONAL_SERVICES" ]]; then
        for service in $OPTIONAL_SERVICES; do
            if [[ -f "$mount_point/etc/init.d/$service" ]]; then
                chroot "$mount_point" rc-update add "$service" default
                log_info "Serviço opcional habilitado: $service"
            fi
        done
    fi
}

# Função para configurar SSH
setup_ssh() {
    local mount_point="$1"
    
    if [[ "$ENABLE_SSH" == "true" ]]; then
        log_info "Configurando SSH..."
        
        # Instalar OpenSSH se não estiver instalado
        if ! chroot "$mount_point" apk info openssh-server &>/dev/null; then
            chroot "$mount_point" apk add --no-cache openssh-server
        fi
        
        # Configurar SSH
        cat > "$mount_point/etc/ssh/sshd_config" << EOF
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin $ALLOW_ROOT_SSH
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM no
EOF
        
        # Gerar chaves SSH se não existirem
        if [[ ! -f "$mount_point/etc/ssh/ssh_host_rsa_key" ]]; then
            chroot "$mount_point" ssh-keygen -A
        fi
        
        # Adicionar chave SSH pública se especificada
        if [[ -n "$SSH_PUBLIC_KEY" ]]; then
            mkdir -p "$mount_point/root/.ssh"
            echo "$SSH_PUBLIC_KEY" > "$mount_point/root/.ssh/authorized_keys"
            chmod 700 "$mount_point/root/.ssh"
            chmod 600 "$mount_point/root/.ssh/authorized_keys"
        fi
        
        log_success "SSH configurado"
    fi
}

# Função para finalizar imagem
finalize_image() {
    log_info "Finalizando imagem..."
    
    local mount_point="$WORK_DIR/mount"
    local img_path="$OUTPUT_DIR/$OUTPUT_FILENAME"
    
    # Desmontar partições
    umount "$mount_point/boot"
    umount "$mount_point"
    
    # Remover loop device
    losetup -d "$(losetup -j "$img_path" | cut -d: -f1)" 2>/dev/null || true
    
    # Comprimir se solicitado
    if [[ "$COMPRESS_OUTPUT" == "true" ]]; then
        log_info "Comprimindo imagem..."
        gzip "$img_path"
        log_success "Imagem comprimida: ${img_path}.gz"
    fi
    
    log_success "Imagem finalizada: $img_path"
}

# Função para limpeza
cleanup() {
    if [[ "$CLEANUP_AFTER_BUILD" == "true" ]]; then
        log_info "Limpando arquivos temporários..."
        
        # Desmontar qualquer coisa que possa estar montada
        umount -f "$WORK_DIR/mount/boot" 2>/dev/null || true
        umount -f "$WORK_DIR/mount" 2>/dev/null || true
        
        # Remover diretórios temporários
        rm -rf "$WORK_DIR"
        
        log_success "Limpeza concluída"
    fi
}

# Função para exibir resumo final
show_summary() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        BUILD CONCLUÍDO                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Imagem criada com sucesso!"
    echo ""
    echo "📁 Arquivo de saída: $OUTPUT_DIR/$OUTPUT_FILENAME"
    echo "📏 Tamanho: $(du -h "$OUTPUT_DIR/$OUTPUT_FILENAME" | cut -f1)"
    echo ""
    echo "🧪 Para testar a imagem:"
    echo "   ./scripts/qemu-run.sh"
    echo ""
    echo "💾 Para gravar no SD Card:"
    echo "   Use BalenaEtcher ou dd para gravar $OUTPUT_DIR/$OUTPUT_FILENAME"
    echo ""
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Configurar trap para limpeza em caso de erro
    trap 'log_error "Build interrompido por erro"; cleanup; exit 1' ERR
    trap 'log_info "Build interrompido pelo usuário"; cleanup; exit 1' INT TERM
    
    # Inicializar logging
    init_logging
    
    # Executar etapas do build
    show_banner
    check_prerequisites
    prepare_directories
    download_base_image
    create_partitioned_image
    mount_and_prepare_filesystem
    apply_customizations
    finalize_image
    cleanup
    show_summary
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Executar função principal
main "$@" 