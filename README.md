# Make ARM Custom Images

Projeto para compilar, personalizar e gerar imagens bootáveis de sistemas operacionais para Raspberry Pi, começando com Alpine Linux para Pi 3B.

## 🎯 Objetivo

Criar uma pipeline local que produza imagens personalizadas para Raspberry Pi 3B a partir de Alpine Linux, testadas em QEMU e prontas para replicação em várias placas.

## 📁 Estrutura do Projeto

```
make-arm-custom-images/
├── docs/           # Documentação de uso e customização
├── scripts/        # Scripts de build, configuração e testes
├── configs/        # Arquivos de configuração de rede, pacotes e serviços
├── output/         # Onde a imagem final .img será salva
└── qemu/          # Configurações para teste da imagem em QEMU
```

## 🚀 Funcionalidades

- ✅ Download automático da imagem base Alpine ARMv7 para Pi 3B
- ✅ Montagem e personalização da imagem
- ✅ Configuração automática de Wi-Fi
- ✅ Instalação de pacotes adicionais (Docker, Docker Compose, etc.)
- ✅ Configuração de serviços para iniciar no boot
- ✅ Teste em emulação com QEMU
- ✅ Geração de imagem final para gravação

## 📋 Pré-requisitos

### Dependências do Sistema
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y wget curl qemu-system-arm qemu-user-static \
    parted dosfstools mtools squashfs-tools \
    build-essential git
```

### Permissões
```bash
# Adicionar usuário ao grupo sudo (se necessário)
sudo usermod -aG sudo $USER
```

## 🛠️ Uso Rápido

1. **Clone o repositório:**
```bash
git clone <repository-url>
cd make-arm-custom-images
```

2. **Configure as variáveis de ambiente:**
```bash
cp env.example .env
# Edite o arquivo .env com suas configurações
```

3. **Execute o build:**
```bash
./scripts/build.sh
```

4. **Teste a imagem em QEMU:**
```bash
./scripts/qemu-run.sh
```

5. **Grave no SD Card:**
```bash
# Use BalenaEtcher ou dd para gravar output/alpine-pi3b-custom.img
```

## 📖 Documentação

- [Visão Geral](docs/00-visao-geral.md)
- [Dependências do Host](docs/01-dependencias-host.md)
- [Variáveis de Ambiente](docs/02-variaveis-env.md)
- [Fluxo de Build](docs/03-fluxo-de-build.md)
- [Testes em QEMU](docs/04-testes-em-qemu.md)
- [Gravação no SD Card](docs/05-gravacao-sdcard.md)

## 🔧 Customização

### Pacotes Adicionais
Edite `configs/packages.txt` para adicionar/remover pacotes.

### Configurações de Rede
Configure Wi-Fi em `configs/wpa_supplicant.conf.tmpl`.

### Serviços
Adicione serviços em `configs/services-openrc.txt`.

## 🧪 Testes

O projeto inclui suporte completo para testes em QEMU:

- Emulação do Raspberry Pi 3B
- Teste de login e rede
- Verificação de serviços
- Debug de problemas antes da gravação

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor, leia as diretrizes de contribuição antes de submeter pull requests.

## 📞 Suporte

Para dúvidas e problemas, abra uma issue no repositório do projeto. 