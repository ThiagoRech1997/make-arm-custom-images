# Fluxo de Build

O processo de build segue uma sequência específica de etapas, cada uma executada por um script dedicado.

## Sequência de Execução

```
1. fetch_base.sh    → Download da base Alpine
2. mkimg.sh         → Criação da imagem
3. mount.sh         → Montagem das partições
4. customize.sh     → Aplicação de customizações
5. unmount.sh       → Desmontagem e finalização
```

## Etapa 1: fetch_base.sh

### O que faz:
- Cria diretórios `tmp/` e `output/`
- Baixa o tarball Alpine armv7
- Verifica se o download já existe

### Comando:
```bash
./scripts/fetch_base.sh
```

### Saída esperada:
```
[2024-01-15 10:30:00] Baixando alpine-rpi-3.20.3-armv7.tar.gz
[2024-01-15 10:30:45] OK
```

### Troubleshooting:
- **Erro de rede**: Verificar conectividade
- **Espaço insuficiente**: Verificar `df -h`
- **Permissões**: Executar com permissões adequadas

## Etapa 2: mkimg.sh

### O que faz:
- Cria imagem raw com tamanho especificado
- Particiona (boot FAT32 + root ext4)
- Extrai rootfs Alpine
- Prepara estrutura básica

### Comando:
```bash
sudo ./scripts/mkimg.sh
```

### Estrutura criada:
```
/dev/loopXp1  → boot (FAT32, 256MB)
/dev/loopXp2  → root (ext4, resto)
```

### Saída esperada:
```
[2024-01-15 10:31:00] Criando imagem output/alpine-rpi3-custom.img com 2G
[2024-01-15 10:31:15] Particionando (MBR: boot + root)
[2024-01-15 10:31:30] Extraindo rootfs Alpine
[2024-01-15 10:31:45] Imagem base criada
```

### Troubleshooting:
- **Erro de loop device**: Verificar se não há montagens pendentes
- **Espaço insuficiente**: Aumentar `IMG_SIZE_GB`
- **Permissões**: Executar como root

## Etapa 3: mount.sh

### O que faz:
- Mapeia imagem em loop device
- Monta partições boot e root
- Salva referência do loop device

### Comando:
```bash
sudo ./scripts/mount.sh
```

### Montagens criadas:
```
/tmp/boot  → /dev/loopXp1
/tmp/root  → /dev/loopXp2
```

### Saída esperada:
```
[2024-01-15 10:32:00] Montado em /tmp/root e /tmp/boot
```

### Troubleshooting:
- **Loop device ocupado**: Executar `unmount.sh` primeiro
- **Erro de montagem**: Verificar se imagem existe
- **Permissões**: Executar como root

## Etapa 4: customize.sh

### O que faz:
- Monta pseudo-FS (proc, sys, dev)
- Aplica configurações de rede
- Instala pacotes
- Configura serviços
- Executa hooks pós-instalação

### Comando:
```bash
sudo ./scripts/customize.sh
```

### Pseudo-FS montados:
```
/tmp/root/proc  → /proc
/tmp/root/sys   → /sys
/tmp/root/dev   → /dev
```

### Saída esperada:
```
[2024-01-15 10:33:00] Montando pseudo-FS
[2024-01-15 10:33:15] [post-customize] iniciando
[2024-01-15 10:33:30] [post-customize] concluido
[2024-01-15 10:33:45] Customização concluída
```

### Troubleshooting:
- **Erro de rede**: Verificar conectividade
- **Pacote não encontrado**: Verificar `packages.txt`
- **Erro de chroot**: Verificar se pseudo-FS está montado

## Etapa 5: unmount.sh

### O que faz:
- Desmonta pseudo-FS
- Desmonta partições
- Remove loop device
- Limpa arquivos temporários

### Comando:
```bash
sudo ./scripts/unmount.sh
```

### Saída esperada:
```
[2024-01-15 10:34:00] Desmontado
```

### Troubleshooting:
- **Erro de desmontagem**: Verificar processos usando os mounts
- **Loop device não removido**: Executar `losetup -d` manualmente

## Build Completo

### Comando:
```bash
./scripts/build.sh
```

### O que faz:
- Executa todas as etapas em sequência
- Valida permissões sudo
- Exibe progresso
- Trata erros

### Saída esperada:
```
[2024-01-15 10:30:00] === Build iniciado ===
[2024-01-15 10:30:45] Baixando alpine-rpi-3.20.3-armv7.tar.gz
[2024-01-15 10:31:45] Criando imagem output/alpine-rpi3-custom.img com 2G
[2024-01-15 10:32:00] Montado em /tmp/root e /tmp/boot
[2024-01-15 10:33:45] Customização concluída
[2024-01-15 10:34:00] Desmontado
[2024-01-15 10:34:00] Imagem pronta em output/alpine-rpi3-custom.img
[2024-01-15 10:34:00] Para testar em QEMU: ./scripts/qemu-run.sh
```

## Logs e Debugging

### Logs automáticos:
- Todos os scripts usam função `log()`
- Timestamps em todas as mensagens
- Saída para stdout/stderr

### Debug manual:
```bash
# Verificar montagens
mount | grep tmp

# Verificar loop devices
losetup -a

# Verificar espaço
df -h tmp/

# Verificar permissões
ls -la output/
```

### Limpeza em caso de erro:
```bash
# Desmontar tudo
sudo ./scripts/unmount.sh

# Limpar loop devices
sudo losetup -D

# Remover arquivos temporários
sudo rm -rf tmp/
```

## Otimizações

### Build incremental:
- `fetch_base.sh` não baixa se arquivo existe
- `customize.sh` é idempotente
- Pode executar etapas individualmente

### Cache:
- Tarball Alpine fica em `tmp/`
- Reutilizado em builds subsequentes
- Pode ser limpo manualmente

### Paralelização:
- Etapas são sequenciais por design
- Garante consistência
- Evita conflitos de montagem 