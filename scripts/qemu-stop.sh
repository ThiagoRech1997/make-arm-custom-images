#!/bin/bash

# =============================================================================
# Make ARM Custom Images - Script para Parar QEMU
# =============================================================================
# Este script para o QEMU de forma segura

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

QEMU_TEMP_DIR="$PROJECT_ROOT/qemu/temp"
QEMU_PID_FILE="$QEMU_TEMP_DIR/qemu.pid"

# =============================================================================
# FUNÇÕES PRINCIPAIS
# =============================================================================

# Função para parar QEMU
stop_qemu() {
    if [[ -f "$QEMU_PID_FILE" ]]; then
        local qemu_pid=$(cat "$QEMU_PID_FILE")
        
        if kill -0 "$qemu_pid" 2>/dev/null; then
            log_info "Parando QEMU (PID: $qemu_pid)..."
            
            # Tentar parada graciosa
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
                sleep 2
            fi
            
            # Verificar se parou
            if kill -0 "$qemu_pid" 2>/dev/null; then
                log_error "Falha ao parar QEMU"
                return 1
            else
                log_success "QEMU parado com sucesso"
            fi
        else
            log_warn "QEMU não estava rodando (PID: $qemu_pid)"
        fi
        
        # Remover arquivo PID
        rm -f "$QEMU_PID_FILE"
    else
        log_warn "Arquivo PID não encontrado: $QEMU_PID_FILE"
        
        # Tentar encontrar processo QEMU por nome
        local qemu_processes=$(pgrep -f "qemu-system-arm.*$(basename "$OUTPUT_FILENAME")" || true)
        
        if [[ -n "$qemu_processes" ]]; then
            log_info "Encontrados processos QEMU: $qemu_processes"
            
            for pid in $qemu_processes; do
                log_info "Parando processo QEMU: $pid"
                kill "$pid"
            done
            
            log_success "Processos QEMU parados"
        else
            log_info "Nenhum processo QEMU encontrado"
        fi
    fi
}

# Função para limpeza
cleanup() {
    log_info "Limpando arquivos temporários..."
    
    # Remover arquivos temporários
    if [[ -d "$QEMU_TEMP_DIR" ]]; then
        rm -rf "$QEMU_TEMP_DIR"
        log_success "Arquivos temporários removidos"
    fi
}

# Função para mostrar status
show_status() {
    echo "=== Status do QEMU ==="
    
    if [[ -f "$QEMU_PID_FILE" ]]; then
        local qemu_pid=$(cat "$QEMU_PID_FILE")
        
        if kill -0 "$qemu_pid" 2>/dev/null; then
            echo "✅ QEMU está rodando (PID: $qemu_pid)"
            echo "📁 PID File: $QEMU_PID_FILE"
            
            # Mostrar informações do processo
            if command_exists ps; then
                echo ""
                echo "📊 Informações do processo:"
                ps -p "$qemu_pid" -o pid,ppid,cmd,etime
            fi
        else
            echo "❌ QEMU não está rodando (PID inválido: $qemu_pid)"
            echo "🧹 Execute: $0 --clean"
        fi
    else
        echo "❌ QEMU não está rodando (PID file não encontrado)"
        
        # Verificar se há processos QEMU órfãos
        local qemu_processes=$(pgrep -f "qemu-system-arm" || true)
        
        if [[ -n "$qemu_processes" ]]; then
            echo "⚠️  Encontrados processos QEMU órfãos:"
            for pid in $qemu_processes; do
                echo "   PID: $pid"
            done
            echo "🧹 Execute: $0 --force"
        fi
    fi
    
    echo "====================="
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -h, --help     Mostrar esta ajuda"
    echo "  -s, --status   Mostrar status do QEMU"
    echo "  -f, --force    Forçar parada (SIGKILL)"
    echo "  -c, --clean    Limpar arquivos temporários"
    echo ""
    echo "Exemplos:"
    echo "  $0              # Parar QEMU graciosamente"
    echo "  $0 --status     # Mostrar status"
    echo "  $0 --force      # Forçar parada"
    echo "  $0 --clean      # Limpar arquivos temporários"
    echo ""
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Inicializar logging
    init_logging
    
    # Processar argumentos
    local status_flag=false
    local force_flag=false
    local clean_flag=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--status)
                status_flag=true
                shift
                ;;
            -f|--force)
                force_flag=true
                shift
                ;;
            -c|--clean)
                clean_flag=true
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
    if [[ "$status_flag" == "true" ]]; then
        show_status
        exit 0
    fi
    
    if [[ "$clean_flag" == "true" ]]; then
        cleanup
        exit 0
    fi
    
    if [[ "$force_flag" == "true" ]]; then
        log_info "Forçando parada do QEMU..."
        
        if [[ -f "$QEMU_PID_FILE" ]]; then
            local qemu_pid=$(cat "$QEMU_PID_FILE")
            kill -9 "$qemu_pid" 2>/dev/null || true
            rm -f "$QEMU_PID_FILE"
        fi
        
        # Matar todos os processos QEMU
        pkill -9 -f "qemu-system-arm" 2>/dev/null || true
        log_success "QEMU forçado a parar"
        exit 0
    fi
    
    # Parar QEMU normalmente
    stop_qemu
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Executar função principal
main "$@" 