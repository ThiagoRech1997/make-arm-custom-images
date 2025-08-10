# Variáveis de Ambiente (.env)

O arquivo `.env` controla todas as configurações do build. Copie de `env.example` e ajuste conforme necessário.

## Seção: Imagem Base Alpine

### ALPINE_VERSION
**Padrão**: `3.20.3`
**Descrição**: Versão do Alpine Linux a usar
**Exemplo**: `3.19.4`, `3.20.3`, `edge`

### ALPINE_BASE_URL
**Padrão**: `https://dl-cdn.alpinelinux.org/alpine`
**Descrição**: URL base para download do Alpine
**Alternativas**: 
- `https://mirror.alpinelinux.org/alpine`
- `https://alpine.mirror.wearetriple.com/alpine`

### ALPINE_FLAVOR
**Padrão**: `alpine-rpi`
**Descrição**: Sabor da imagem Alpine
**Alternativas**: `alpine-minirootfs`, `alpine-standard`

### ALPINE_ARCH
**Padrão**: `armv7`
**Descrição**: Arquitetura do processador
**Alternativas**: `aarch64` (para Pi 4), `x86_64`

### ALPINE_TARBALL
**Padrão**: `${ALPINE_FLAVOR}-${ALPINE_VERSION}-${ALPINE_ARCH}.tar.gz`
**Descrição**: Nome do arquivo tarball (calculado automaticamente)

## Seção: Caminhos

### WORK_DIR
**Padrão**: `$(pwd)`
**Descrição**: Diretório de trabalho (raiz do projeto)

### OUTPUT_DIR
**Padrão**: `${WORK_DIR}/output`
**Descrição**: Diretório para imagens finais

### TMP_DIR
**Padrão**: `${WORK_DIR}/tmp`
**Descrição**: Diretório para arquivos temporários

### IMG_NAME
**Padrão**: `alpine-rpi3-custom.img`
**Descrição**: Nome da imagem final

### IMG_SIZE_GB
**Padrão**: `2`
**Descrição**: Tamanho da imagem em GB
**Recomendação**: Mínimo 2GB para Alpine básico

## Seção: Rede/Wi-Fi

### WIFI_SSID
**Padrão**: `MinhaRede`
**Descrição**: Nome da rede Wi-Fi

### WIFI_PSK
**Padrão**: `SenhaSecreta`
**Descrição**: Senha da rede Wi-Fi

### WIFI_COUNTRY
**Padrão**: `BR`
**Descrição**: Código do país para configuração Wi-Fi
**Exemplos**: `US`, `GB`, `DE`, `JP`

## Seção: Hostname e SSH

### HOSTNAME
**Padrão**: `rpi3-alpine`
**Descrição**: Nome do host na rede

### ENABLE_SSH
**Padrão**: `true`
**Descrição**: Habilitar servidor SSH no boot
**Valores**: `true`, `false`

## Seção: Pacotes

### INSTALL_DOCKER
**Padrão**: `true`
**Descrição**: Instalar Docker
**Valores**: `true`, `false`

### INSTALL_DOCKER_COMPOSE
**Padrão**: `true`
**Descrição**: Instalar Docker Compose
**Valores**: `true`, `false`
**Nota**: Requer `INSTALL_DOCKER=true`

## Seção: QEMU

### QEMU_MACHINE
**Padrão**: `raspi2`
**Descrição**: Tipo de máquina QEMU
**Alternativas**: `raspi3`, `virt` (para arm64)

### QEMU_CPU
**Padrão**: `cortex-a7`
**Descrição**: Tipo de CPU para emulação
**Alternativas**: `cortex-a53`, `cortex-a72`

### QEMU_RAM
**Padrão**: `1024`
**Descrição**: RAM em MB para QEMU
**Recomendação**: 512-2048 MB

## Seção: Mirrors Alpine

### ALPINE_MIRROR
**Padrão**: `${ALPINE_BASE_URL}`
**Descrição**: Mirror para repositórios Alpine
**Alternativas**: 
- `https://mirror.alpinelinux.org/alpine`
- `https://alpine.mirror.wearetriple.com/alpine`

## Exemplos de Configuração

### Configuração Mínima
```bash
ALPINE_VERSION=3.19.4
IMG_SIZE_GB=1
ENABLE_SSH=false
INSTALL_DOCKER=false
```

### Configuração para Pi 4 (arm64)
```bash
ALPINE_ARCH=aarch64
QEMU_MACHINE=virt
QEMU_CPU=cortex-a53
IMG_SIZE_GB=4
```

### Configuração com Rede Personalizada
```bash
WIFI_SSID=MinhaCasa
WIFI_PSK=MinhaSenha123
WIFI_COUNTRY=BR
HOSTNAME=pi-casa
```

## Validação

O script `utils.sh` valida as variáveis essenciais:
- Existência do arquivo `.env`
- Variáveis obrigatórias definidas
- Valores válidos para booleanos

## Troubleshooting

### Variável não encontrada
```bash
# Verificar se .env existe
ls -la .env

# Verificar sintaxe
cat .env | grep -v '^#' | grep -v '^$'
```

### Valores incorretos
```bash
# Verificar booleanos
echo $INSTALL_DOCKER
echo $ENABLE_SSH

# Verificar caminhos
echo $OUTPUT_DIR
echo $TMP_DIR
``` 