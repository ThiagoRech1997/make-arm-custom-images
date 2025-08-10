#!/bin/bash

# =============================================================================
# Make ARM Custom Images - Funções Utilitárias
# =============================================================================
# Este arquivo contém funções utilitárias usadas pelos scripts do projeto

# =============================================================================
# CONFIGURAÇÃO DE LOGGING
# =============================================================================

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Níveis de log
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Variável global para nível de log atual
CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

# =============================================================================
# FUNÇÕES DE LOGGING
# =============================================================================

# Função para inicializar sistema de logging
init_logging() {
    # Determinar nível de log baseado na variável de ambiente
    case "${LOG_LEVEL:-INFO}" in
        "DEBUG") CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        "INFO")  CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        "WARN")  CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
        "ERROR") CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        *)       CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
    esac
    
    # Criar arquivo de log se especificado
    if [[ -n "${LOG_FILE:-}" ]]; then
        touch "$LOG_FILE"
        log_info "Log iniciado em: $LOG_FILE"
    fi
}

# Função para escrever no log
write_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    
    # Escrever no arquivo de log se configurado
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

# Função para log de debug
log_debug() {
    if [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
        write_log "DEBUG" "$1"
    fi
}

# Função para log de informação
log_info() {
    if [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
        write_log "INFO" "$1"
    fi
}

# Função para log de aviso
log_warn() {
    if [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ]]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
        write_log "WARN" "$1"
    fi
}

# Função para log de erro
log_error() {
    if [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ]]; then
        echo -e "${RED}[ERROR]${NC} $1"
        write_log "ERROR" "$1"
    fi
}

# Função para log de sucesso
log_success() {
    if [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
        write_log "SUCCESS" "$1"
    fi
}

# =============================================================================
# FUNÇÕES DE VALIDAÇÃO
# =============================================================================

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se um arquivo existe
file_exists() {
    [[ -f "$1" ]]
}

# Função para verificar se um diretório existe
dir_exists() {
    [[ -d "$1" ]]
}

# Função para verificar se uma variável está definida e não vazia
is_set() {
    [[ -n "${!1:-}" ]]
}

# Função para verificar se uma variável está definida
is_defined() {
    [[ -v "$1" ]]
}

# =============================================================================
# FUNÇÕES DE SISTEMA
# =============================================================================

# Função para obter o sistema operacional
get_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# Função para obter a arquitetura do sistema
get_arch() {
    uname -m
}

# Função para verificar se é um sistema 64-bit
is_64bit() {
    [[ "$(get_arch)" == "x86_64" ]]
}

# Função para obter espaço livre em disco (em MB)
get_free_space() {
    df . | awk 'NR==2 {print int($4/1024)}'
}

# Função para obter memória total (em MB)
get_total_memory() {
    awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo
}

# =============================================================================
# FUNÇÕES DE REDE
# =============================================================================

# Função para verificar conectividade com internet
check_internet() {
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Função para obter IP local
get_local_ip() {
    ip route get 8.8.8.8 | awk '{print $7; exit}'
}

# Função para verificar se uma porta está em uso
port_in_use() {
    local port="$1"
    netstat -tuln | grep -q ":$port "
}

# =============================================================================
# FUNÇÕES DE ARQUIVO
# =============================================================================

# Função para criar backup de um arquivo
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file" ]]; then
        cp "$file" "$backup"
        log_info "Backup criado: $backup"
        return 0
    else
        log_warn "Arquivo não encontrado para backup: $file"
        return 1
    fi
}

# Função para restaurar backup de um arquivo
restore_file() {
    local file="$1"
    local backup="$2"
    
    if [[ -f "$backup" ]]; then
        cp "$backup" "$file"
        log_info "Arquivo restaurado: $file"
        return 0
    else
        log_error "Backup não encontrado: $backup"
        return 1
    fi
}

# Função para limpar arquivos temporários
cleanup_temp_files() {
    local pattern="$1"
    local count=0
    
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find . -name "$pattern" -print0 2>/dev/null)
    
    if [[ $count -gt 0 ]]; then
        log_info "Removidos $count arquivos temporários"
    fi
}

# =============================================================================
# FUNÇÕES DE PROCESSO
# =============================================================================

# Função para verificar se um processo está rodando
process_running() {
    local process_name="$1"
    pgrep -f "$process_name" >/dev/null
}

# Função para matar um processo
kill_process() {
    local process_name="$1"
    local signal="${2:-TERM}"
    
    if process_running "$process_name"; then
        pkill -f -"$signal" "$process_name"
        log_info "Processo $process_name terminado com sinal $signal"
        return 0
    else
        log_warn "Processo $process_name não estava rodando"
        return 1
    fi
}

# Função para aguardar um processo terminar
wait_for_process() {
    local process_name="$1"
    local timeout="${2:-30}"
    local count=0
    
    log_info "Aguardando processo $process_name terminar (timeout: ${timeout}s)..."
    
    while process_running "$process_name" && [[ $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done
    
    if process_running "$process_name"; then
        log_warn "Timeout aguardando processo $process_name"
        return 1
    else
        log_success "Processo $process_name terminou"
        return 0
    fi
}

# =============================================================================
# FUNÇÕES DE STRING
# =============================================================================

# Função para capitalizar primeira letra
capitalize() {
    echo "$1" | sed 's/^./\U&/'
}

# Função para converter para minúsculas
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Função para converter para maiúsculas
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Função para remover espaços em branco
trim() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Função para verificar se string contém substring
contains() {
    local string="$1"
    local substring="$2"
    [[ "$string" == *"$substring"* ]]
}

# =============================================================================
# FUNÇÕES DE VALIDAÇÃO DE ENTRADA
# =============================================================================

# Função para validar endereço IP
is_valid_ip() {
    local ip="$1"
    local IFS='.'
    read -ra ADDR <<< "$ip"
    
    if [[ ${#ADDR[@]} -ne 4 ]]; then
        return 1
    fi
    
    for i in "${ADDR[@]}"; do
        if ! [[ "$i" =~ ^[0-9]+$ ]] || [[ "$i" -lt 0 ]] || [[ "$i" -gt 255 ]]; then
            return 1
        fi
    done
    
    return 0
}

# Função para validar MAC address
is_valid_mac() {
    local mac="$1"
    [[ "$mac" =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]
}

# Função para validar nome de host
is_valid_hostname() {
    local hostname="$1"
    [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]
}

# =============================================================================
# FUNÇÕES DE CONVERSÃO
# =============================================================================

# Função para converter bytes para formato legível
bytes_to_human() {
    local bytes="$1"
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [[ $bytes -ge 1024 ]] && [[ $unit -lt ${#units[@]}-1 ]]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done
    
    echo "${bytes}${units[$unit]}"
}

# Função para converter segundos para formato legível
seconds_to_human() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" "$hours" "$minutes" "$secs"
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" "$minutes" "$secs"
    else
        printf "%ds" "$secs"
    fi
}

# =============================================================================
# FUNÇÕES DE PROGRESSO
# =============================================================================

# Função para mostrar barra de progresso
show_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Função para spinner de carregamento
spinner() {
    local pid="$1"
    local delay=0.1
    local spinstr='|/-\'
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# =============================================================================
# FUNÇÕES DE CONFIGURAÇÃO
# =============================================================================

# Função para carregar variáveis de ambiente de um arquivo
load_env_file() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        log_debug "Carregando variáveis de ambiente de: $file"
        set -a
        source "$file"
        set +a
        return 0
    else
        log_warn "Arquivo de ambiente não encontrado: $file"
        return 1
    fi
}

# Função para validar variáveis de ambiente obrigatórias
validate_required_env() {
    local missing_vars=()
    
    for var in "$@"; do
        if ! is_set "$var"; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Variáveis de ambiente obrigatórias não definidas:"
        printf '  - %s\n' "${missing_vars[@]}"
        return 1
    fi
    
    return 0
}

# =============================================================================
# FUNÇÕES DE SEGURANÇA
# =============================================================================

# Função para gerar senha aleatória
generate_password() {
    local length="${1:-12}"
    tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c "$length"
}

# Função para gerar chave SSH
generate_ssh_key() {
    local key_file="$1"
    local comment="${2:-$(whoami)@$(hostname)}"
    
    if [[ ! -f "$key_file" ]]; then
        ssh-keygen -t rsa -b 4096 -f "$key_file" -N "" -C "$comment"
        log_info "Chave SSH gerada: $key_file"
        return 0
    else
        log_warn "Chave SSH já existe: $key_file"
        return 1
    fi
}

# =============================================================================
# FUNÇÕES DE DEBUG
# =============================================================================

# Função para mostrar informações do sistema
show_system_info() {
    echo "=== Informações do Sistema ==="
    echo "Sistema Operacional: $(get_os)"
    echo "Arquitetura: $(get_arch)"
    echo "Memória Total: $(get_total_memory)MB"
    echo "Espaço Livre: $(get_free_space)MB"
    echo "Conectividade: $(check_internet && echo "OK" || echo "FALHA")"
    echo "================================"
}

# Função para mostrar variáveis de ambiente
show_env_vars() {
    local prefix="${1:-}"
    
    echo "=== Variáveis de Ambiente ==="
    if [[ -n "$prefix" ]]; then
        env | grep "^${prefix}" | sort
    else
        env | sort
    fi
    echo "=============================="
} 