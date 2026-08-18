# apple-assembly

Learning notes and examples for writing bare-metal ARM64 (AArch64) assembly
on Apple Silicon macOS — raw BSD syscalls, no libc, no C runtime.

## Layout

- `asm/01-hello` — hello world via a direct `write`/`exit` syscall, no libc.
- `asm/02-arithmetic` — registers, `mov`/`add`/`sub`/`mul`, w-registers, and
  building large constants with `movz`/`movk`.
- `c/` — the equivalent C hello world plus its compiler-generated assembly,
  for comparing hand-written asm against what a compiler emits.

Each `asm/*` lesson is a self-contained Mach-O ARM64 binary: assembled with
`as`, linked with `ld` against `libSystem`, entry point `_start` (no `main`,
no argc/argv, no stack frame).

## Requirements

- Apple Silicon Mac (arm64)
- Xcode command line tools (`xcode-select --install`) for `as`, `ld`, and
  the macOS SDK

## Building and running

```sh
cd asm/01-hello
./build.sh
```

Each `build.sh` assembles and links the binary, then the lesson's own build
script runs it. For `02-arithmetic`, the result is left in the process exit
status rather than printed — check it with:

```sh
./build.sh
echo $?
```

## Editor setup

This repo includes `.vscode/settings.json`, which forces `*.s` files to be
highlighted as ARM assembly (the [ARM
extension](https://marketplace.visualstudio.com/items?itemName=dan-c-underwood.arm))
instead of Go's Plan9 assembly, which also claims that extension.
