# Visão Geral do Projeto

## 🎯 Objetivo

O **Make ARM Custom Images** é um projeto completo para criar imagens personalizadas de sistemas operacionais para Raspberry Pi, começando com Alpine Linux para o modelo Pi 3B. O projeto oferece uma pipeline automatizada que permite:

- Baixar imagens base de distribuições Linux
- Personalizar configurações de rede, pacotes e serviços
- Testar as imagens em emulação antes da gravação
- Gerar imagens finais prontas para uso

## 🏗️ Arquitetura do Projeto

### Estrutura de Diretórios

```
make-arm-custom-images/
├── docs/                    # Documentação completa
│   ├── 00-visao-geral.md   # Este arquivo
│   ├── 01-dependencias-host.md
│   ├── 02-variaveis-env.md
│   ├── 03-fluxo-de-build.md
│   ├── 04-testes-em-qemu.md
│   └── 05-gravacao-sdcard.md
├── scripts/                 # Scripts de automação
│   ├── build.sh            # Script principal de build
│   ├── utils.sh            # Funções utilitárias
│   ├── qemu-run.sh         # Executar testes em QEMU
│   └── qemu-stop.sh        # Parar QEMU
├── configs/                 # Arquivos de configuração
│   ├── packages.txt        # Lista de pacotes
│   ├── wpa_supplicant.conf.tmpl  # Template Wi-Fi
│   └── services-openrc.txt # Serviços do sistema
├── output/                  # Imagens geradas
├── qemu/                   # Arquivos QEMU
├── env.example             # Template de variáveis
└── README.md               # Documentação principal
```

### Componentes Principais

#### 1. Scripts de Automação (`/scripts/`)

- **`build.sh`**: Script principal que orquestra todo o processo
- **`utils.sh`**: Funções utilitárias para logging, validação e operações comuns
- **`qemu-run.sh`**: Executa a imagem em QEMU para testes
- **`qemu-stop.sh`**: Para o QEMU de forma segura

#### 2. Configurações (`/configs/`)

- **`packages.txt`**: Lista de pacotes para instalar
- **`wpa_supplicant.conf.tmpl`**: Template para configuração Wi-Fi
- **`services-openrc.txt`**: Serviços para iniciar no boot

#### 3. Documentação (`/docs/`)

Documentação completa dividida em seções específicas para facilitar a consulta.

## 🔄 Fluxo de Trabalho

### 1. Preparação
```bash
# Clone o repositório
git clone <repository-url>
cd make-arm-custom-images

# Configure as variáveis
cp env.example .env
# Edite .env com suas configurações
```

### 2. Build da Imagem
```bash
# Execute o build completo
sudo ./scripts/build.sh
```

### 3. Teste em QEMU
```bash
# Teste a imagem antes da gravação
./scripts/qemu-run.sh
```

### 4. Gravação no SD Card
```bash
# Use BalenaEtcher ou dd para gravar
# output/alpine-pi3b-custom.img
```

## 🎛️ Configuração

### Variáveis de Ambiente

O projeto usa um arquivo `.env` para todas as configurações:

- **Configurações da imagem**: versão Alpine, arquitetura, tamanho
- **Configurações de rede**: Wi-Fi, IP estático, hostname
- **Configurações de sistema**: timezone, locale, senhas
- **Configurações QEMU**: memória, porta SSH, parâmetros extras

### Personalização

#### Pacotes
Edite `configs/packages.txt` para adicionar/remover pacotes.

#### Wi-Fi
Configure as variáveis `WIFI_SSID` e `WIFI_PASSWORD` no `.env`.

#### Serviços
Edite `configs/services-openrc.txt` para habilitar/desabilitar serviços.

## 🧪 Testes

### Emulação QEMU

O projeto inclui suporte completo para testes em QEMU:

- **Emulação do Raspberry Pi 3B** usando versatile-pb
- **Rede funcional** com port forwarding para SSH
- **Teste de login** e comandos básicos
- **Verificação de serviços** e configurações

### Limitações do QEMU

⚠️ **Importante**: QEMU para Raspberry Pi não é 100% fiel ao hardware real:

- Usa emulação versatile-pb em vez de raspi2/raspi3
- Alguns recursos específicos do Pi podem não funcionar
- Performance pode ser diferente do hardware real
- O teste final confiável é sempre no hardware real

## 🔧 Extensibilidade

### Suporte a Outras Distribuições

O projeto foi projetado para ser facilmente adaptável:

1. **Outras distros**: Modifique `build.sh` para usar diferentes bases
2. **Outros modelos Pi**: Ajuste parâmetros QEMU e configurações
3. **Arquiteturas diferentes**: Adapte scripts para arm64, x86, etc.

### Exemplo de Adaptação

Para Ubuntu ARM:

```bash
# Modificar env.example
UBUNTU_VERSION="20.04"
UBUNTU_ARCH="arm64"
UBUNTU_BASE_URL="https://cdimage.ubuntu.com/ubuntu/releases"

# Adaptar build.sh para usar debootstrap
# Modificar configurações de rede para systemd
# Ajustar instalação de pacotes para apt
```

## 🚀 Casos de Uso

### 1. Servidor Web
- Nginx/Apache
- MySQL/PostgreSQL
- SSL/TLS
- Backup automático

### 2. Servidor de Containers
- Docker
- Docker Compose
- Registry local
- Monitoramento

### 3. Servidor de Monitoramento
- Prometheus
- Grafana
- Alertmanager
- Node Exporter

### 4. Gateway de Rede
- Firewall (ufw/iptables)
- DHCP server
- DNS resolver
- VPN server

### 5. Media Center
- Plex/Emby
- Transmission
- Sonarr/Radarr
- Storage NAS

## 📊 Métricas do Projeto

### Tamanho da Imagem
- **Base Alpine**: ~50MB
- **Com Docker**: ~200MB
- **Com ferramentas completas**: ~500MB
- **Com aplicações**: 1-2GB

### Tempo de Build
- **Download base**: 1-5 minutos
- **Criação imagem**: 2-3 minutos
- **Instalação pacotes**: 5-15 minutos
- **Teste QEMU**: 1-2 minutos
- **Total**: 10-25 minutos

### Recursos Necessários
- **Espaço em disco**: 3x tamanho da imagem final
- **RAM**: 2GB mínimo, 4GB recomendado
- **CPU**: 2 cores mínimo, 4 cores recomendado
- **Rede**: Conexão estável para downloads

## 🔒 Segurança

### Boas Práticas Implementadas

1. **Senhas**: Configuração via variáveis de ambiente
2. **SSH**: Chaves públicas opcionais
3. **Firewall**: Configuração básica incluída
4. **Updates**: Scripts para atualização automática
5. **Logs**: Sistema de logging configurado

### Recomendações

1. **Sempre altere senhas padrão**
2. **Use chaves SSH em vez de senhas**
3. **Configure firewall adequadamente**
4. **Mantenha o sistema atualizado**
5. **Monitore logs regularmente**

## 🤝 Contribuição

### Como Contribuir

1. **Fork** o repositório
2. **Crie** uma branch para sua feature
3. **Implemente** suas mudanças
4. **Teste** extensivamente
5. **Documente** suas alterações
6. **Submeta** um pull request

### Áreas para Contribuição

- **Suporte a outras distros** (Ubuntu, Debian, etc.)
- **Suporte a outros modelos Pi** (Pi 4, Pi Zero, etc.)
- **Melhorias no QEMU** (emulação mais precisa)
- **Scripts de deploy** (Ansible, Terraform)
- **Documentação** (tutoriais, troubleshooting)
- **Testes automatizados** (CI/CD)

## 📞 Suporte

### Recursos de Ajuda

- **Documentação**: `/docs/` - Guias detalhados
- **Issues**: GitHub Issues para bugs e feature requests
- **Discussions**: GitHub Discussions para dúvidas
- **Wiki**: Documentação adicional e exemplos

### Troubleshooting Comum

- **Build falha**: Verificar dependências e espaço em disco
- **QEMU não inicia**: Verificar kernel e DTB
- **Rede não funciona**: Verificar configurações Wi-Fi
- **Imagem não boota**: Testar em hardware real

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](../LICENSE) para detalhes.

---

**Próximo**: [Dependências do Host](01-dependencias-host.md) 