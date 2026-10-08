# piper-wasm-fuente

**Código fuente correspondiente** (GPL-3.0, sección 6d) del fonetizador de la voz de respuesta
de MedChain: `piper_phonemize.wasm` y `piper_phonemize.data`, que se sirven en
`/static/vendor/piper-wasm-1.0.0/` de la aplicación.

> *English summary: Corresponding Source (GPL-3.0 §6d) for the `piper_phonemize.wasm` /
> `piper_phonemize.data` files served by MedChain. They are piper-phonemize compiled to
> WebAssembly together with eSpeak NG, so the combined work is GPL-3.0-or-later. Sources are
> pinned commits with SHA-256 below; `receta/reproducir.sh` rebuilds both files byte for byte.*

## Licencia

**GPL-3.0-or-later.** Texto completo en [`LICENSE`](LICENSE).

Los dos archivos son [piper-phonemize](https://github.com/rhasspy/piper-phonemize) (MIT)
compilado a WebAssembly **junto con** [eSpeak NG](https://github.com/espeak-ng/espeak-ng)
(GPL-3.0-or-later): el `.wasm` contiene el código de libespeak-ng y el `.data` son los 494
archivos de `espeak-ng-data`. Por eso el conjunto se distribuye bajo GPL-3.0-or-later.

El paquete de npm del que provienen originalmente (`@diffusionstudio/piper-wasm` 1.0.0) declara
"MIT". **Esa etiqueta es incorrecta** para estos archivos.

Las demás licencias de las piezas están en [`LICENSES/`](LICENSES):

| Archivo | Qué cubre |
|---|---|
| `piper-phonemize_LICENSE.md` | piper-phonemize (MIT) |
| `espeak-ng_COPYING.BSD2` | `getopt.c` de eSpeak NG (implementación de compatibilidad para Windows) |
| `espeak-ng_COPYING.UCD` | datos Unicode usados por `ucd-tools` de eSpeak NG |
| `espeak-ng_COPYING.APACHE` | el port de Android de eSpeak NG (no entra en el `.wasm`) |

## Qué archivos corresponden a este código fuente

| Archivo servido | SHA-256 |
|---|---|
| `piper_phonemize.wasm` | `b777cd107a91d2bcc6a1ea46f2c26a662a7407394fe84589198aeaa83dd7a9d6` |
| `piper_phonemize.data` | `a9879123581336fc36ae3706ae81c9e67becc388b80b8a4943cef2a78542e6aa` |

## Código fuente

| Archivo en `fuente/` | Commit | Qué produce |
|---|---|---|
| `rhasspy_espeak-ng_0f65aa30.zip` | [`rhasspy/espeak-ng@0f65aa30`](https://github.com/rhasspy/espeak-ng/tree/0f65aa301e0d6bae5e172cc74197d32a6182200f) | el código de eSpeak NG dentro del `.wasm` (es el zip que baja el CMake de piper-phonemize) |
| `rhasspy_espeak-ng_8593723f.tar.gz` | [`rhasspy/espeak-ng@8593723f`](https://github.com/rhasspy/espeak-ng/tree/8593723f10cfd9befd50de447f14bf0a9d2a14a4) | los diccionarios y datos del `.data` |
| `wide-video_piper-phonemize_cfff8e52.tar.gz` | [`wide-video/piper-phonemize@cfff8e52`](https://github.com/wide-video/piper-phonemize/tree/cfff8e52ebaea37c7e953ae2d06b174acb827ac4) | piper-phonemize, compilado a WebAssembly |

Son copias de los archivos que genera GitHub para esos commits; cada uno trae grabado el SHA
de su commit (comentario del zip o cabecera pax del tar). Sus SHA-256 están en `SHA256SUMS`.

Herramienta de compilación (no incluida: es de uso general y se baja por la receta):
[emsdk](https://github.com/emscripten-core/emsdk) 3.1.47 (`37b85e9e`). Sistema de compilación:
`debian:11.3` (por digest) con paquetes del snapshot de Debian del 4-jul-2024.

## Cómo recompilar

```sh
bash receta/reproducir.sh      # requiere Docker y red; sale 0 si los dos SHA-256 coinciden
```

[`receta/recompilar_piper_wasm.sh`](receta/recompilar_piper_wasm.sh) es la receta publicada por el
autor del paquete (README de `diffusionstudio/piper-wasm`, "As of JUN 2024"), con cada
`git clone --depth 1` reemplazado por un commit fijo. Incluye los dos parches `sed` de esa
receta. Se usó tal cual, byte a byte, en la verificación.

## Verificación

- Recompilado dos veces (8-oct-2026) con esta receta: los dos intentos dieron exactamente los SHA-256
  de arriba.
- El `.wasm` es además idéntico al del paquete de npm.
- El `.data` del paquete de npm (`29f1025e…`) **no** se pudo reproducir: difiere sólo en el
  orden de las reglas de un grupo de `th_dict` (tailandés), por una causa no identificada; los
  otros 493 archivos son idénticos. Por eso MedChain sirve el `.data` que sale de esta receta, y
  no el de npm.
