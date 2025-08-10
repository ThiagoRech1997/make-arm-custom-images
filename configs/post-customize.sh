#!/usr/bin/env bash
set -euo pipefail

echo "[post-customize] iniciando"

# Exemplos: ajustar timezone/locale, etc.
setup-timezone -z America/Sao_Paulo || true

echo "[post-customize] concluido" 