#!/usr/bin/env bash
# Paso 0 de la opcion 1 (GPL-3.0 de eSpeak NG): recompilar @diffusionstudio/piper-wasm 1.0.0 con la receta
# de su README (https://github.com/diffusionstudio/piper-wasm, "As of JUN 2024") y COMMITS FIJOS en vez de
# `--depth 1`, para ver si el codigo fuente identificado produce los MISMOS bytes que sirve produccion.
#
# Corre DENTRO de debian:11.3 con una carpeta temporal VACIA montada en /wasm, no el repo (la ruta importa: el .wasm de
# produccion trae "/wasm/modules/piper-phonemize/build/e/src/..." embebido).
#
# Salida: /wasm/salida/{piper_phonemize.wasm,piper_phonemize.data,piper_phonemize.js} + SHA256SUMS
set -euxo pipefail

EMSDK_TAG=3.1.47
EMSDK_COMMIT=37b85e9eaee5be090569d018cca77a15cacc11b7          # tag 3.1.47 del repo emsdk
ESPEAK_COMMIT=8593723f10cfd9befd50de447f14bf0a9d2a14a4          # rhasspy/espeak-ng: cabeza (archivado) -> datos
PHONEMIZE_COMMIT=cfff8e52ebaea37c7e953ae2d06b174acb827ac4       # wide-video/piper-phonemize: cabeza en jun-2024
# El codigo de eSpeak que entra al .wasm NO es ESPEAK_COMMIT: lo baja el CMake de piper-phonemize
# (rhasspy/espeak-ng/archive/0f65aa301e0d6bae5e172cc74197d32a6182200f.zip). Se deja tal cual, es la receta.

clonar() {  # repo commit destino -- sin --depth 1: commit exacto, verificado
  git init -q "$3"; git -C "$3" remote add origin "$1"
  git -C "$3" fetch -q --depth 1 origin "$2"; git -C "$3" checkout -q FETCH_HEAD
  test "$(git -C "$3" rev-parse HEAD)" = "$2"
}

# bullseye salio de soporte (LTS hasta 31-ago-2026): security.debian.org da 404 para todo (corrida 37793068942).
# Se usa el snapshot oficial de Debian del 4-jul-2024, vispera de la publicacion en npm (5-jul-2024): mismos
# paquetes que pudo tener el autor. http (la imagen no trae ca-certificates); apt verifica la firma del Release.
# Valid-Until vencido es esperable en un snapshot: solo se apaga ESE chequeo, no la firma.
SNAP=20240704T000000Z
cat > /etc/apt/sources.list <<FUENTES
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/$SNAP bullseye main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/$SNAP bullseye-updates main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/$SNAP bullseye-security main
FUENTES
apt-get update
apt-get install --yes --no-install-recommends build-essential cmake ca-certificates curl pkg-config git \
  python3 autogen automake autoconf libtool

# Emscripten
clonar https://github.com/emscripten-core/emsdk.git "$EMSDK_COMMIT" /wasm/modules/emsdk
cd /wasm/modules/emsdk
./emsdk install "$EMSDK_TAG"
./emsdk activate "$EMSDK_TAG"
source ./emsdk_env.sh
TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake
sed -i -E 's/int\s+(iswalnum|iswalpha|iswblank|iswcntrl|iswgraph|iswlower|iswprint|iswpunct|iswspace|iswupper|iswxdigit)\(wint_t\)/\/\/\0/g' ./upstream/emscripten/cache/sysroot/include/wchar.h

# espeak-ng (nativo: compila los diccionarios de espeak-ng-data)
clonar https://github.com/rhasspy/espeak-ng.git "$ESPEAK_COMMIT" /wasm/modules/espeak-ng
cd /wasm/modules/espeak-ng
./autogen.sh
./configure
make

# piper-phonemize (wasm)
clonar https://github.com/wide-video/piper-phonemize.git "$PHONEMIZE_COMMIT" /wasm/modules/piper-phonemize
cd /wasm/modules/piper-phonemize
emmake cmake -Bbuild -DCMAKE_INSTALL_PREFIX=install -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE -DBUILD_TESTING=OFF -G "Unix Makefiles" -DCMAKE_CXX_FLAGS="-O3 -s INVOKE_RUN=0 -s MODULARIZE=1 -s EXPORT_NAME='createPiperPhonemize' -s EXPORTED_FUNCTIONS='[_main]' -s EXPORTED_RUNTIME_METHODS='[callMain, FS]' --preload-file /wasm/modules/espeak-ng/espeak-ng-data@/espeak-ng-data"
emmake cmake --build build --config Release || true   # la receta dice: falla en "Compile intonations", seguir
sed -i 's+$(MAKE) $(MAKESILENT) -f CMakeFiles/data.dir/build.make CMakeFiles/data.dir/build+#\0+g' /wasm/modules/piper-phonemize/build/e/src/espeak_ng_external-build/CMakeFiles/Makefile2
sed -i 's/using namespace std/\/\/\0/g' /wasm/modules/piper-phonemize/build/e/src/espeak_ng_external/src/speechPlayer/src/speechWaveGenerator.cpp
emmake cmake --build build --config Release

mkdir -p /wasm/salida
for f in piper_phonemize.wasm piper_phonemize.data piper_phonemize.js; do
  cp "$(find /wasm/modules/piper-phonemize/build -maxdepth 1 -name "$f")" /wasm/salida/
done
cd /wasm/salida && sha256sum piper_phonemize.* | tee SHA256SUMS
