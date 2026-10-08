#!/usr/bin/env bash
# Recompila piper_phonemize.wasm / .data desde los commits fijos y comprueba que salen los MISMOS
# bytes que sirve MedChain. Requiere Docker y red (baja emsdk y los commits desde GitHub, y los
# paquetes de Debian desde snapshot.debian.org). Sale 0 solo si los dos SHA-256 coinciden.
#
# Uso: bash receta/reproducir.sh
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
TRABAJO="$(mktemp -d)"            # vacio: se monta como /wasm, la misma ruta que quedo grabada en el .wasm
cp "$AQUI/recompilar_piper_wasm.sh" "$TRABAJO/"

docker run --rm -v "$TRABAJO:/wasm" -w /wasm \
  debian:11.3@sha256:859ea45db307402ee024b153c7a63ad4888eb4751921abbef68679fc73c4c739 \
  bash /wasm/recompilar_piper_wasm.sh

cd "$TRABAJO/salida"
sha256sum -c - <<'ESPERADO'
b777cd107a91d2bcc6a1ea46f2c26a662a7407394fe84589198aeaa83dd7a9d6  piper_phonemize.wasm
a9879123581336fc36ae3706ae81c9e67becc388b80b8a4943cef2a78542e6aa  piper_phonemize.data
ESPERADO
echo "Reproducido: $TRABAJO/salida"
