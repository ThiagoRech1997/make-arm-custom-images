# Testes em QEMU

O QEMU permite testar a imagem antes de gravar no SD card, mas com limitações significativas.

## Limitações Importantes

⚠️ **Aviso**: QEMU para Raspberry Pi não é 100% fiel ao hardware real:

- **Hardware limitado**: Nem todos os periféricos são emulados
- **Performance**: Muito mais lento que hardware real
- **Compatibilidade**: Alguns drivers podem não funcionar
- **Boot**: Usamos `-M raspi2` que é uma aproximação do Pi 3B
- **Rede**: Funcionalidade de rede limitada
- **Wi-Fi**: Não suportado em QEMU

## Executando o Teste

### Comando básico:
```bash
./scripts/qemu-run.sh
```

### Parâmetros QEMU usados:
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

## Interação com a VM

### Console:
- O console aparece diretamente no terminal
- Use `Ctrl+A` seguido de `X` para sair forçadamente
- Para desligar normalmente: `poweroff` dentro da VM

### Login:
```bash
# Login como root (sem senha)
login: root
```

### Comandos úteis para teste:
```bash
# Verificar sistema
uname -a
cat /etc/os-release
df -h

# Verificar rede
ip addr
ping -c 3 8.8.8.8

# Verificar serviços
rc-status

# Verificar pacotes
apk list --installed | grep docker
```

## Troubleshooting QEMU

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
- Considere reduzir `QEMU_RAM` se necessário

## Alternativas de Kernel

### Se kernel-nographic.elf não estiver disponível:

#### Opção 1: Usar kernel genérico
```bash
# Modificar qemu-run.sh
-kernel /usr/lib/qemu/arm/kernel.elf \
```

#### Opção 2: Baixar kernel específico
```bash
# Baixar kernel do Raspberry Pi
wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.19.50-buster
```

#### Opção 3: Usar imagem alternativa
```bash
# Usar imagem com kernel embutido
-drive file=output/alpine-rpi3-custom.img,format=raw,if=sd \
-device usb-net,netdev=net0 \
-netdev user,id=net0,hostfwd=tcp::2222-:22
```

## Configuração Avançada

### Redirecionamento de porta SSH:
```bash
# Adicionar ao qemu-run.sh
-netdev user,id=net0,hostfwd=tcp::2222-:22 \
-device usb-net,netdev=net0
```

### Acesso SSH:
```bash
# Conectar via SSH
ssh -p 2222 root@localhost
```

### Compartilhamento de arquivos:
```bash
# Adicionar ao qemu-run.sh
-fsdev local,id=fsdev0,path=/tmp/shared,security_model=none \
-device virtio-9p-device,fsdev=fsdev0,mount_tag=shared
```

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

1. **Gravar no SD card** (ver [05-gravacao-sdcard.md](05-gravacao-sdcard.md))
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