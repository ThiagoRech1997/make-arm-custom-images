# Alpine Linux Custom Images para Raspberry Pi 3B

Template para construir, customizar e exportar imagens bootáveis do Alpine Linux para Raspberry Pi 3B, com possibilidade de adaptação para outras distros/modelos no futuro.

## Objetivo

Pipeline local para:
- Baixar a base (Alpine armv7 para Pi 3B)
- Montar em loop device
- Aplicar customizações (Wi-Fi, Docker, Compose, pacotes)
- Testar em QEMU (emulação aproximada)
- Exportar .img final para gravar no SD (Balena Etcher)

## Pré-requisitos

- Ubuntu/Debian ou similar
- Acesso root (sudo)
- Conectividade com internet
- 4GB+ espaço livre

## Instalação das Dependências

```bash
sudo apt update
sudo apt install -y qemu qemu-system-arm qemu-utils parted kpartx dosfstools e2fsprogs \
  wget curl xz-utils tar git unzip coreutils util-linux binfmt-support
```

## Uso Rápido

1. **Configurar variáveis:**
```bash
cp .env.example .env
nano .env
```

2. **Executar build completo:**
```bash
./scripts/build.sh
```

3. **Testar em QEMU (opcional):**
```bash
./scripts/qemu-run.sh
```

## Fluxo de Build

```
fetch_base.sh → mkimg.sh → mount.sh → customize.sh → unmount.sh
```

1. **fetch_base.sh**: Baixa Alpine armv7 tarball
2. **mkimg.sh**: Cria imagem raw particionada (boot FAT32 + root ext4)
3. **mount.sh**: Monta partições em loop device
4. **customize.sh**: Aplica configs, pacotes e serviços
5. **unmount.sh**: Desmonta e finaliza imagem

## Configuração via .env

O arquivo `.env` controla todas as variáveis do build:
- Versão do Alpine
- Configurações de rede/Wi-Fi
- Pacotes a instalar
- Parâmetros QEMU
- Tamanho da imagem

## Testes em QEMU

⚠️ **Importante**: QEMU para Raspberry Pi não é 100% fiel ao hardware real. Usamos `-M raspi2` para smoke tests básicos. O teste final confiável é sempre no hardware real.

Para testar:
```bash
./scripts/qemu-run.sh
# Dentro da VM: poweroff
```

## Gravação no SD Card

1. Use [Balena Etcher](https://www.balena.io/etcher/)
2. Selecione `output/alpine-rpi3-custom.img`
3. Escolha o SD card
4. Grave

## Primeiro Boot no Hardware Real

1. Insira o SD no Pi 3B
2. Conecte teclado/monitor ou SSH
3. Login: `root` (sem senha inicial)
4. Configure rede se necessário: `setup-interfaces`
5. Atualize pacotes: `apk update && apk upgrade`

## Estrutura do Projeto

```
.
├── README.md              # Este arquivo
├── .env.example          # Template de variáveis
├── docs/                 # Documentação detalhada
├── configs/              # Configurações e templates
├── scripts/              # Scripts de build
├── qemu/                 # Arquivos QEMU
└── output/               # Imagens finais
```

## Próximos Passos

Para adaptar a outras distros/modelos:

1. **Outras distros**: Modifique `fetch_base.sh` e `customize.sh`
2. **Outros modelos Pi**: Ajuste `mkimg.sh` e parâmetros QEMU
3. **Arquiteturas diferentes**: Adapte scripts para arm64, x86, etc.

## Troubleshooting

- **Erro de permissão**: Execute scripts com `sudo`
- **Loop device ocupado**: Use `./scripts/unmount.sh` para limpar
- **QEMU não inicia**: Verifique dependências e kernel disponível
- **Imagem não boota**: Teste em hardware real, QEMU é limitado

## Licença

MIT License - veja [LICENSE](LICENSE) para detalhes. 