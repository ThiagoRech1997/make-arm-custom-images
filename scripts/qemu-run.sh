#!/bin/bash

# =============================================================================
# Make ARM Custom Images - Script de Teste QEMU
# =============================================================================
# Este script executa a imagem gerada em QEMU para testes antes da gravação

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
# VARIÁVEIS LOCAIS
# =============================================================================

# Caminho da imagem
IMAGE_PATH="$OUTPUT_DIR/$OUTPUT_FILENAME"

# Arquivos temporários QEMU
QEMU_TEMP_DIR="$PROJECT_ROOT/qemu/temp"
QEMU_PID_FILE="$QEMU_TEMP_DIR/qemu.pid"
QEMU_SOCKET="$QEMU_TEMP_DIR/qemu.sock"

# =============================================================================
# FUNÇÕES PRINCIPAIS
# =============================================================================

# Função para exibir banner
show_banner() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Teste QEMU - Alpine Pi 3B                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos QEMU..."
    
    # Verificar se QEMU está instalado
    if ! command_exists qemu-system-arm; then
        log_error "QEMU não encontrado. Instale com:"
        log_info "sudo apt install -y qemu-system-arm"
        exit 1
    fi
    
    # Verificar se a imagem existe
    if [[ ! -f "$IMAGE_PATH" ]]; then
        log_error "Imagem não encontrada: $IMAGE_PATH"
        log_info "Execute primeiro: ./scripts/build.sh"
        exit 1
    fi
    
    # Verificar se imagem não está comprimida
    if [[ "$IMAGE_PATH" == *.gz ]]; then
        log_info "Descomprimindo imagem..."
        gunzip "$IMAGE_PATH"
        IMAGE_PATH="${IMAGE_PATH%.gz}"
    fi
    
    log_success "Pré-requisitos verificados"
}

# Função para preparar ambiente QEMU
prepare_qemu_environment() {
    log_info "Preparando ambiente QEMU..."
    
    # Criar diretório temporário
    mkdir -p "$QEMU_TEMP_DIR"
    
    # Baixar kernel e DTB se necessário
    download_qemu_assets
    
    log_success "Ambiente QEMU preparado"
}

# Função para baixar assets do QEMU
download_qemu_assets() {
    local kernel_url="https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster"
    local dtb_url="https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb.dtb"
    
    local kernel_file="$PROJECT_ROOT/qemu/kernel-qemu-4.19.50-buster"
    local dtb_file="$PROJECT_ROOT/qemu/versatile-pb.dtb"
    
    # Baixar kernel se não existir
    if [[ ! -f "$kernel_file" ]]; then
        log_info "Baixando kernel QEMU..."
        wget -q --show-progress -O "$kernel_file" "$kernel_url"
        chmod +x "$kernel_file"
    fi
    
    # Baixar DTB se não existir
    if [[ ! -f "$dtb_file" ]]; then
        log_info "Baixando DTB QEMU..."
        wget -q --show-progress -O "$dtb_file" "$dtb_url"
    fi
    
    # Atualizar variáveis se não estiverem definidas
    if [[ -z "${QEMU_KERNEL:-}" ]]; then
        QEMU_KERNEL="$kernel_file"
    fi
    
    if [[ -z "${QEMU_DTB:-}" ]]; then
        QEMU_DTB="$dtb_file"
    fi
}

# Função para montar imagem para QEMU
mount_image_for_qemu() {
    log_info "Montando imagem para QEMU..."
    
    # Encontrar loop device
    local loop_device=$(losetup --find --show "$IMAGE_PATH")
    log_info "Usando loop device: $loop_device"
    
    # Montar partição root
    local mount_point="$QEMU_TEMP_DIR/mount"
    mkdir -p "$mount_point"
    mount "${loop_device}p2" "$mount_point"
    
    # Configurar para QEMU (usar versatile-pb em vez de raspi2)
    cat > "$mount_point/etc/fstab" << EOF
/dev/sda1  /boot   vfat    defaults    0   0
/dev/sda2  /       ext4    defaults    0   0
EOF
    
    # Configurar cmdline.txt para QEMU
    mkdir -p "$mount_point/boot"
    mount "${loop_device}p1" "$mount_point/boot"
    
    cat > "$mount_point/boot/cmdline.txt" << EOF
root=/dev/sda2 panic=1 rootfstype=ext4 rw
EOF
    
    # Desmontar
    umount "$mount_point/boot"
    umount "$mount_point"
    losetup -d "$loop_device"
    
    log_success "Imagem preparada para QEMU"
}

# Função para iniciar QEMU
start_qemu() {
    log_info "Iniciando QEMU..."
    
    # Parâmetros QEMU
    local qemu_args=(
        -M versatilepb
        -cpu arm1176
        -m "$QEMU_MEMORY"
        -kernel "$QEMU_KERNEL"
        -dtb "$QEMU_DTB"
        -drive file="$IMAGE_PATH",format=raw,index=0,media=disk
        -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw"
        -net nic
        -net user,hostfwd=tcp::"$QEMU_SSH_PORT"-:22
        -serial stdio
        -nographic
        -pidfile "$QEMU_PID_FILE"
    )
    
    # Adicionar opções extras se especificadas
    if [[ -n "${QEMU_EXTRA_ARGS:-}" ]]; then
        qemu_args+=($QEMU_EXTRA_ARGS)
    fi
    
    log_info "Comando QEMU:"
    log_info "qemu-system-arm ${qemu_args[*]}"
    echo ""
    
    # Executar QEMU
    qemu-system-arm "${qemu_args[@]}" &
    local qemu_pid=$!
    
    # Salvar PID
    echo "$qemu_pid" > "$QEMU_PID_FILE"
    
    log_success "QEMU iniciado com PID: $qemu_pid"
    log_info "Para conectar via SSH: ssh -p $QEMU_SSH_PORT root@localhost"
    log_info "Para parar QEMU: ./scripts/qemu-stop.sh"
    
    # Aguardar QEMU terminar
    wait "$qemu_pid"
}

# Função para parar QEMU
stop_qemu() {
    if [[ -f "$QEMU_PID_FILE" ]]; then
        local qemu_pid=$(cat "$QEMU_PID_FILE")
        
        if kill -0 "$qemu_pid" 2>/dev/null; then
            log_info "Parando QEMU (PID: $qemu_pid)..."
            kill "$qemu_pid"
            
            # Aguardar processo terminar
            local count=0
            while kill -0 "$qemu_pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                sleep 1
                ((count++))
            done
            
            # Forçar parada se necessário
            if kill -0 "$qemu_pid" 2>/dev/null; then
                log_warn "Forçando parada do QEMU..."
                kill -9 "$qemu_pid"
            fi
            
            log_success "QEMU parado"
        else
            log_warn "QEMU não estava rodando"
        fi
        
        rm -f "$QEMU_PID_FILE"
    else
        log_warn "Arquivo PID não encontrado"
    fi
}

# Função para limpeza
cleanup() {
    log_info "Limpando arquivos temporários..."
    
    # Parar QEMU se estiver rodando
    stop_qemu
    
    # Remover arquivos temporários
    rm -rf "$QEMU_TEMP_DIR"
    
    log_success "Limpeza concluída"
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -h, --help     Mostrar esta ajuda"
    echo "  -s, --stop     Parar QEMU se estiver rodando"
    echo "  -c, --clean    Limpar arquivos temporários"
    echo "  --no-mount     Não montar imagem (usar imagem já preparada)"
    echo ""
    echo "Exemplos:"
    echo "  $0              # Iniciar QEMU"
    echo "  $0 --stop       # Parar QEMU"
    echo "  $0 --clean      # Limpar arquivos temporários"
    echo ""
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Configurar trap para limpeza
    trap 'log_error "Script interrompido"; cleanup; exit 1' ERR
    trap 'log_info "Script interrompido pelo usuário"; cleanup; exit 1' INT TERM
    
    # Inicializar logging
    init_logging
    
    # Processar argumentos
    local stop_qemu_flag=false
    local clean_flag=false
    local no_mount_flag=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--stop)
                stop_qemu_flag=true
                shift
                ;;
            -c|--clean)
                clean_flag=true
                shift
                ;;
            --no-mount)
                no_mount_flag=true
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Executar ações baseadas nas flags
    if [[ "$stop_qemu_flag" == "true" ]]; then
        stop_qemu
        exit 0
    fi
    
    if [[ "$clean_flag" == "true" ]]; then
        cleanup
        exit 0
    fi
    
    # Executar QEMU
    show_banner
    check_prerequisites
    prepare_qemu_environment
    
    if [[ "$no_mount_flag" != "true" ]]; then
        mount_image_for_qemu
    fi
    
    start_qemu
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Executar função principal
main "$@" 