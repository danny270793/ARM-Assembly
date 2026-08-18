#!/bin/zsh
# Assemble + link a bare (no-libc) ARM64 Mach-O binary.
set -e
SDK=$(xcrun --sdk macosx --show-sdk-path)
as -o hello.o hello.s
ld -o hello hello.o -lSystem -syslibroot "$SDK" -e _start -arch arm64
echo "built ./hello"

./hello
