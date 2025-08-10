# Visão Geral do Projeto

## Objetivo

Este template permite criar imagens customizadas do Alpine Linux para Raspberry Pi 3B de forma automatizada e reproduzível. O processo é modular e pode ser adaptado para outras distribuições e modelos de hardware.

## Limitações do QEMU

⚠️ **Importante**: A emulação do Raspberry Pi no QEMU tem limitações significativas:

- **Hardware limitado**: Nem todos os periféricos são emulados corretamente
- **Performance**: Muito mais lento que o hardware real
- **Compatibilidade**: Alguns drivers podem não funcionar
- **Boot**: Usamos `-M raspi2` que é uma aproximação do Pi 3B

O QEMU serve apenas para **smoke tests** básicos. O teste final confiável é sempre no hardware real.

## Fluxo Geral

```
1. Download da base Alpine armv7
   ↓
2. Criação de imagem raw particionada
   ↓
3. Montagem em loop device
   ↓
4. Aplicação de customizações
   ↓
5. Desmontagem e finalização
   ↓
6. Teste em QEMU (opcional)
   ↓
7. Gravação no SD card
```

## Componentes Principais

### Scripts de Build
- `fetch_base.sh`: Download da base Alpine
- `mkimg.sh`: Criação e particionamento da imagem
- `mount.sh`: Montagem das partições
- `customize.sh`: Aplicação de customizações
- `unmount.sh`: Desmontagem e limpeza

### Configurações
- `packages.txt`: Lista de pacotes a instalar
- `services-openrc.txt`: Serviços para habilitar no boot
- `wpa_supplicant.conf.tmpl`: Configuração Wi-Fi
- `interfaces.rpi3.tmpl`: Configuração de rede

### Testes
- `qemu-run.sh`: Execução em QEMU
- `qemu-stop.sh`: Documentação para parar QEMU

## Parametrização

Todas as configurações são controladas via arquivo `.env`:
- Versões e URLs
- Configurações de rede
- Pacotes e serviços
- Parâmetros QEMU
- Tamanhos e caminhos

## Extensibilidade

O template foi projetado para ser facilmente adaptável:

- **Outras distros**: Modificar scripts de download e customização
- **Outros modelos Pi**: Ajustar particionamento e parâmetros QEMU
- **Arquiteturas diferentes**: Adaptar para arm64, x86, etc.
- **Customizações específicas**: Adicionar scripts de pós-instalação 