# Notas e Dicas sobre QEMU

## Links Úteis

### Documentação Oficial
- [QEMU Documentation](https://qemu.readthedocs.io/)
- [QEMU User Documentation](https://qemu.readthedocs.io/en/latest/user/)
- [QEMU System Documentation](https://qemu.readthedocs.io/en/latest/system/)

### Raspberry Pi Específico
- [Raspberry Pi QEMU](https://www.raspberrypi.org/documentation/usage/qemu/)
- [QEMU Raspberry Pi Kernel](https://github.com/dhruvvyas90/qemu-rpi-kernel)
- [Raspberry Pi Firmware](https://github.com/raspberrypi/firmware)

### Alpine Linux
- [Alpine Linux QEMU](https://wiki.alpinelinux.org/wiki/QEMU)
- [Alpine Linux ARM](https://wiki.alpinelinux.org/wiki/ARM)

## Comandos Alternativos

### QEMU com rede avançada
```bash
qemu-system-arm \
  -M raspi2 \
  -cpu cortex-a7 \
  -m 1024 \
  -kernel /usr/lib/qemu/arm/kernel-nographic.elf \
  -drive file=output/alpine-rpi3-custom.img,format=raw,if=sd \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device usb-net,netdev=net0 \
  -serial stdio \
  -append "console=ttyAMA0 root=/dev/mmcblk0p2 rootwait rw"
```

### QEMU com compartilhamento de arquivos
```bash
qemu-system-arm \
  -M raspi2 \
  -cpu cortex-a7 \
  -m 1024 \
  -kernel /usr/lib/qemu/arm/kernel-nographic.elf \
  -drive file=output/alpine-rpi3-custom.img,format=raw,if=sd \
  -fsdev local,id=fsdev0,path=/tmp/shared,security_model=none \
  -device virtio-9p-device,fsdev=fsdev0,mount_tag=shared \
  -serial stdio \
  -append "console=ttyAMA0 root=/dev/mmcblk0p2 rootwait rw"
```

### QEMU com interface gráfica
```bash
qemu-system-arm \
  -M raspi2 \
  -cpu cortex-a7 \
  -m 1024 \
  -kernel /usr/lib/qemu/arm/kernel-nographic.elf \
  -drive file=output/alpine-rpi3-custom.img,format=raw,if=sd \
  -display gtk \
  -vga std \
  -append "console=ttyAMA0 root=/dev/mmcblk0p2 rootwait rw"
```

## Dicas de Performance

### Reduzir uso de RAM
```bash
# Para sistemas com pouca RAM
-m 512
```

### Usar KVM (se disponível)
```bash
# Para melhor performance (requer hardware compatível)
-enable-kvm
```

### Otimizar I/O
```bash
# Usar cache writeback para melhor performance
-drive file=output/alpine-rpi3-custom.img,format=raw,if=sd,cache=writeback
```

## Troubleshooting Avançado

### Debug detalhado
```bash
# Habilitar debug do QEMU
-d guest_errors,unimp
```

### Log de rede
```bash
# Log de rede detalhado
-netdev user,id=net0,hostfwd=tcp::2222-:22,logfile=net.log
```

### Monitor QEMU
```bash
# Acessar monitor QEMU
-monitor stdio
```

## Scripts Úteis

### Verificar disponibilidade de kernels
```bash
#!/bin/bash
echo "Kernels disponíveis:"
ls -la /usr/lib/qemu/arm/ | grep kernel
```

### Limpar processos QEMU
```bash
#!/bin/bash
echo "Processos QEMU ativos:"
ps aux | grep qemu-system-arm

echo "Matando processos QEMU..."
sudo pkill -f qemu-system-arm

echo "Verificando loop devices..."
losetup -a
```

### Backup de imagem
```bash
#!/bin/bash
if [ -f "output/alpine-rpi3-custom.img" ]; then
    echo "Criando backup..."
    cp output/alpine-rpi3-custom.img output/alpine-rpi3-custom.img.backup
    echo "Backup criado: output/alpine-rpi3-custom.img.backup"
else
    echo "Imagem não encontrada"
fi
```

## Configurações Específicas

### Para desenvolvimento
```bash
# Adicionar ao qemu-run.sh para desenvolvimento
-fsdev local,id=fsdev0,path=/home/user/dev,security_model=none \
-device virtio-9p-device,fsdev=fsdev0,mount_tag=dev \
```

### Para testes de rede
```bash
# Configuração de rede mais completa
-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 \
-device usb-net,netdev=net0 \
```

### Para testes de performance
```bash
# Configuração otimizada para performance
-cpu cortex-a7 \
-m 2048 \
-drive file=output/alpine-rpi3-custom.img,format=raw,if=sd,cache=writeback \
```

## Referências Adicionais

- [QEMU ARM Emulation](https://wiki.qemu.org/Documentation/Platforms/ARM)
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [Alpine Linux Documentation](https://docs.alpinelinux.org/)
- [ARM Architecture](https://developer.arm.com/documentation/) 