# QEMU para Raspberry Pi

## Limitações Importantes

O QEMU para Raspberry Pi tem limitações significativas que devem ser consideradas:

### Hardware Limitado
- **GPIO**: Não emulado
- **Camera**: Não suportada
- **Audio**: Funcionalidade limitada
- **Bluetooth**: Não emulado
- **Wi-Fi específico**: Não funciona corretamente

### Performance
- **Muito mais lento** que hardware real
- **Emulação de CPU** em vez de execução nativa
- **I/O limitado** para SD card e rede

### Compatibilidade
- **Drivers específicos** podem não funcionar
- **Kernel customizado** pode ter problemas
- **Firmware do Pi** não é emulado

## Configuração Atual

Usamos a seguinte configuração para smoke tests:

```bash
qemu-system-arm \
  -M raspi2 \
  -cpu cortex-a7 \
  -m 1024 \
  -kernel /usr/lib/qemu/arm/kernel-nographic.elf \
  -drive file=output/alpine-rpi3-custom.img,format=raw,if=sd \
  -serial stdio \
  -append "console=ttyAMA0 root=/dev/mmcblk0p2 rootwait rw"
```

### Parâmetros Explicados

- **`-M raspi2`**: Máquina Raspberry Pi 2 (aproximação do Pi 3B)
- **`-cpu cortex-a7`**: CPU ARM Cortex-A7
- **`-m 1024`**: 1GB RAM
- **`-kernel`**: Kernel genérico ARM
- **`-drive`**: Imagem como SD card
- **`-serial stdio`**: Console no terminal
- **`-append`**: Parâmetros do kernel

## Alternativas de Kernel

### Se kernel-nographic.elf não estiver disponível:

#### Opção 1: Kernel genérico
```bash
-kernel /usr/lib/qemu/arm/kernel.elf \
```

#### Opção 2: Baixar kernel específico
```bash
# Baixar kernel do Raspberry Pi
wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster
```

#### Opção 3: Usar imagem com kernel embutido
```bash
# Usar imagem que já contém kernel
-drive file=output/alpine-rpi3-custom.img,format=raw,if=sd \
```

## Instalação de Pacotes QEMU

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y qemu qemu-system-arm qemu-utils
```

### Verificar instalação
```bash
qemu-system-arm --version
ls -la /usr/lib/qemu/arm/
```

## Configurações Avançadas

### Rede com redirecionamento de porta
```bash
-netdev user,id=net0,hostfwd=tcp::2222-:22 \
-device usb-net,netdev=net0
```

### Compartilhamento de arquivos
```bash
-fsdev local,id=fsdev0,path=/tmp/shared,security_model=none \
-device virtio-9p-device,fsdev=fsdev0,mount_tag=shared
```

### Acesso gráfico (se necessário)
```bash
-display gtk \
-vga std
```

## Troubleshooting

### Erro: kernel não encontrado
```bash
# Verificar se kernel existe
ls -la /usr/lib/qemu/arm/kernel-nographic.elf

# Instalar pacote se necessário
sudo apt install qemu-system-arm
```

### Erro: imagem não encontrada
```bash
# Verificar se imagem existe
ls -la output/alpine-rpi3-custom.img

# Executar build primeiro
./scripts/build.sh
```

### VM não inicia
```bash
# Verificar dependências
qemu-system-arm --version

# Verificar espaço
df -h

# Verificar permissões
ls -la output/
```

### Performance muito lenta
- Normal em QEMU
- Hardware real será muito mais rápido
- Considere reduzir RAM se necessário

## Testes Recomendados

### Testes básicos:
- [ ] Sistema inicia
- [ ] Login funciona
- [ ] Comandos básicos funcionam
- [ ] Rede básica funciona

### Testes de serviços:
- [ ] SSH inicia (se habilitado)
- [ ] Docker funciona (se instalado)
- [ ] Serviços configurados estão ativos

### Testes de rede:
- [ ] Interface de rede aparece
- [ ] DNS funciona
- [ ] Ping externo funciona

## Limitações Conhecidas

### Hardware não emulado:
- GPIO
- Camera
- Audio
- Bluetooth
- Wi-Fi específico do Pi

### Funcionalidades limitadas:
- Performance de rede
- Acesso a dispositivos USB
- Hardware específico do Pi

## Próximos Passos

Após testes em QEMU:

1. **Gravar no SD card** (ver [05-gravacao-sdcard.md](../docs/05-gravacao-sdcard.md))
2. **Testar no hardware real**
3. **Configurar rede se necessário**
4. **Instalar aplicações específicas**

## Comandos Úteis

### Parar QEMU:
```bash
# Dentro da VM
poweroff

# Forçadamente (Ctrl+A, X)
# Ou
pkill qemu-system-arm
```

### Verificar processos QEMU:
```bash
ps aux | grep qemu
```

### Limpar processos órfãos:
```bash
sudo pkill -f qemu-system-arm
```

## Referências

- [QEMU Documentation](https://qemu.readthedocs.io/)
- [Raspberry Pi QEMU](https://www.raspberrypi.org/documentation/usage/qemu/)
- [Alpine Linux QEMU](https://wiki.alpinelinux.org/wiki/QEMU) 