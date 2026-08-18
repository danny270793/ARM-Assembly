// Lesson 2: registers and arithmetic.
//
// No I/O this time — printing a *number* requires converting it to ASCII
// digits first, which is its own lesson. Instead we compute a value and
// exit with it as the process's exit status, so you can inspect the result
// from the shell with `echo $?` (status codes are only 0-255, so keep the
// final result in that range).

.global _start
.align 4

.text
_start:
    // ---- mov: loading immediate (literal) values into registers -------
    //
    // `mov` with a `#` immediate just writes that constant into a register.
    // Nothing is "computed" here, it's a plain load.

    mov     x0, #5              // x0 = 5
    mov     x1, #3              // x1 = 3

    // ---- add: register + register -> register --------------------------
    //
    // ARM64 is a "load/store" architecture: arithmetic instructions only
    // ever operate on registers (or a register + a small immediate), never
    // directly on memory. If a value lives in memory you must `ldr` it into
    // a register first, compute, then `str` it back if needed. This is
    // unlike x86, where `add [mem], reg` is legal.
    //
    // Syntax is destination-first: `add Xd, Xn, Xm` means Xd = Xn + Xm.

    add     x2, x0, x1          // x2 = x0 + x1 = 5 + 3 = 8

    // ---- sub: register - register, or register - immediate -------------

    sub     x2, x2, #2          // x2 = x2 - 2 = 8 - 2 = 6
                                 // Immediates (the `#2`) are baked directly
                                 // into the instruction's bits, so they're
                                 // limited in size (12 bits here, optionally
                                 // shifted) — you can't `add` an arbitrary
                                 // 64-bit constant this way. Big constants
                                 // need `mov`/`movk` sequences (see below).

    // ---- mul: register * register ----------------------------------------
    //
    // Unlike add/sub, `mul` has no immediate form — both operands must be
    // registers. If you need to multiply by a literal, load it into a
    // register first.

    mov     x3, #4
    mul     x4, x2, x3          // x4 = x2 * x3 = 6 * 4 = 24

    // ---- w-registers: the 32-bit lower half of x-registers --------------
    //
    // Every 64-bit register x0-x30 has a 32-bit alias w0-w30 that refers to
    // its bottom 32 bits. Operating on wN automatically zeroes the top 32
    // bits of the matching xN (this is an ARM64 guarantee — there's no
    // "leftover garbage" like you'd worry about on x86). Useful when you
    // know a value fits in 32 bits and want smaller/simpler code.

    mov     w5, #1000
    add     w5, w5, #24         // w5 = 1024. (x5's upper 32 bits are now
                                 // guaranteed zero because we wrote w5.)

    // ---- movz / movk: building a constant too big for one `mov` ---------
    //
    // `mov` with a plain immediate is really an assembler convenience that
    // expands to one of these underneath. A 64-bit register can't be filled
    // from a single instruction's immediate field (not enough bits), so
    // large constants are built 16 bits at a time:
    //   movz sets a 16-bit chunk and zeroes everything else.
    //   movk sets a 16-bit chunk and keeps the rest of the register intact.
    // `lsl #N` picks which 16-bit chunk (bits N..N+15) you're writing.

    movz    x6, #0x1234                // x6 = 0x0000000000001234
    movk    x6, #0x5678, lsl #16       // x6 = 0x0000000056781234
                                        // (movk only touched bits 16-31,
                                        // leaving the 0x1234 from before)

    // ---- exit(status = x4 = 24) ------------------------------------------
    //
    // We computed x4 = 24 above; use it as the exit code so the result is
    // observable from outside the program. x6 was just a demonstration of
    // movz/movk and isn't used further (real code would do something with
    // it, e.g. print it, once we cover ASCII conversion).

    mov     x0, x4              // arg0 for exit = our computed value
    mov     x16, #1             // BSD syscall number for exit
    svc     #0x80
