// Lesson 1: Hello, world — no C, no libc, pure syscalls.
//
// macOS on Apple Silicon uses the AArch64 (ARM64) instruction set and the
// Mach-O object format. This talks to the kernel directly via the BSD
// syscall table (different numbers from Linux!) using `svc #0x80`.
//
// Why "no libc"? Normally your code calls printf(), which is C library code
// that eventually calls write() on your behalf. Here we skip the middleman
// and ask the kernel to write bytes to a file descriptor ourselves. This is
// the actual mechanism every I/O call bottoms out in, on any OS.

.global _start   // Make the `_start` label visible to the linker. Without
                 // `.global`, a label is local to this file and the linker
                 // can't use it as the program's entry point.
.align 4         // Pad with zeros so the following code starts on a 4-byte
                 // boundary. ARM64 instructions are ALWAYS exactly 4 bytes,
                 // and the CPU requires instruction fetches to be aligned,
                 // so every function/label you jump to should be aligned.

.text            // Switch into the "text" section — the part of the binary
                 // that holds executable machine code (as opposed to
                 // `.data`, which holds mutable variables, discussed later).

_start:          // This label marks the very first instruction the CPU
                 // executes. We told the linker "entry point = _start" via
                 // `ld -e _start` in build.sh. There is no `main()`, no
                 // argc/argv setup, no stack frame — the kernel just jumps
                 // here with a mostly-empty stack.

    // --- Call 1: write(fd=1, buf=&msg, count=14) -----------------------
    //
    // On macOS/ARM64, a syscall is invoked exactly like a normal function
    // call, using the same argument registers as AAPCS64 (the standard
    // calling convention) — x0, x1, x2, ... for arg0, arg1, arg2, ...
    // The one extra rule: the syscall NUMBER goes in x16, and `svc #0x80`
    // is the actual instruction that traps into kernel mode. (On Linux
    // ARM64 the convention differs — syscall# goes in x8 and the trap is
    // `svc #0`. macOS keeps the old BSD/Mach convention, hence #0x80.)

    mov     x0, #1              // arg0 = file descriptor 1, which is
                                 // conventionally stdout (0=stdin, 1=stdout,
                                 // 2=stderr — these numbers are a Unix
                                 // convention, not something the CPU knows).

    adr     x1, msg             // arg1 = address of the `msg` bytes below.
                                 // `adr` computes a PC-relative address: it
                                 // takes "PC + (msg's offset from here)" and
                                 // puts the result in x1. It only reaches
                                 // labels within about ±1MB of the current
                                 // instruction — fine here since msg is a
                                 // few bytes away. For addresses further off
                                 // (e.g. across sections) you'd need the
                                 // two-instruction `adrp`/`add` pair instead,
                                 // which reaches the full 64-bit range.

    mov     x2, #14             // arg2 = number of bytes to write. This has
                                 // to match the literal byte length of the
                                 // string below (13 visible characters + the
                                 // \n newline = 14). Get this wrong and
                                 // you'll either truncate the message or
                                 // read past it into whatever bytes follow
                                 // in memory.

    mov     x16, #4             // Which syscall to make. Unlike x86 opcodes,
                                 // "write" isn't its own instruction — it's
                                 // just BSD syscall table entry #4. macOS
                                 // defines these numbers in
                                 // <sys/syscall.h>; every OS/ABI has its own
                                 // table and its own numbering.

    svc     #0x80               // "Supervisor Call": the one instruction
                                 // that actually crosses the user/kernel
                                 // boundary. Execution pauses, the CPU
                                 // switches to a privileged mode, the kernel
                                 // looks at x16 to see which syscall was
                                 // requested and x0-x2 for its arguments,
                                 // performs the write, and control returns
                                 // to the instruction right after this one.
                                 // The #0x80 is a legacy immediate value
                                 // inherited from Mach/BSD; the kernel
                                 // ignores it, but it's required syntax.

    // --- Call 2: exit(status=0) -----------------------------------------
    //
    // A program that "falls off the end" of _start with no exit syscall
    // will crash (there's no caller to return to — the return address is
    // garbage). You must exit explicitly.

    mov     x0, #0              // arg0 = exit status. 0 conventionally
                                 // means "success"; this is the value a
                                 // shell sees as `$?` after running you.

    mov     x16, #1             // BSD syscall number for exit == 1.

    svc     #0x80               // Trap into the kernel one more time. This
                                 // call never returns — the process ends
                                 // here.

// --- Data: the bytes we're writing out ---------------------------------
//
// This is still inside `.text` (we never switched sections), which is
// harmless for read-only bytes like a string literal, but mixing data into
// the code section is generally avoided in bigger programs — instructions
// and data end up interleaved in memory, which hurts instruction-cache
// behavior and makes disassembly confusing. Lesson 2+ will use a proper
// `.data`/`.const` section for this.

msg:
    .ascii "Hello, world!\n"   // `.ascii` emits these exact bytes with no
                                // implicit trailing NUL (compare `.asciz`,
                                // which appends one \0 — the C-string
                                // convention). We don't need a NUL here
                                // because we told write() the length
                                // explicitly (x2 above) instead of relying
                                // on the kernel to scan for a terminator.
