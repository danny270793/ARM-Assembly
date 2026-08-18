#!/bin/zsh
# Assemble + link a bare (no-libc) ARM64 Mach-O binary.
set -e
SDK=$(xcrun --sdk macosx --show-sdk-path)
as -o arithmetic.o arithmetic.s
ld -o arithmetic arithmetic.o -lSystem -syslibroot "$SDK" -e _start -arch arm64
echo "built ./arithmetic"
