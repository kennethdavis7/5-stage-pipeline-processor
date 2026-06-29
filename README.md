# 5 Stage Pipeline Processor

## Instruction Set Architecture (ISA)

The processor implements a custom 16-bit instruction set.

### Instruction Format

Each instruction is 16 bits wide.

| Bits  | Field                       |
| ----- | --------------------------- |
| 15–11 | Opcode                      |
| 10–8  | Destination Register (`rd`) |
| 7–5   | Source Register (`rs`)      |
| 4–0   | Unused                      |

Some instructions occupy **two words (32 bits)**. For these instructions, the second word stores a 16-bit immediate value or memory address.

### Supported Instructions

| Opcode | Instruction      | Description                                                              |
| :----: | ---------------- | ------------------------------------------------------------------------ |
|   0    | `MOV rd, rs`     | Copy `rs` into `rd`.                                                     |
|   1    | `CMP rd, rs`     | Compare `rd` and `rs`; updates status flags without modifying registers. |
|   2    | `ADD rd, rs`     | `rd = rd + rs`                                                           |
|   3    | `SUB rd, rs`     | `rd = rd - rs`                                                           |
|   4    | `LDI rd, imm16`  | Load a 16-bit immediate into `rd`. _(Two-word instruction)_              |
|   5    | `LDS rd, addr16` | Load a value from memory into `rd`. _(Two-word instruction)_             |
|   6    | `STS rd, addr16` | Store the value of `rd` into memory. _(Two-word instruction)_            |
|   7    | `JMP addr16`     | Unconditional jump. _(Two-word instruction)_                             |
|   8    | `BEQ addr16`     | Branch if Zero flag is set. _(Two-word instruction)_                     |
|   9    | `BNE addr16`     | Branch if Zero flag is clear. _(Two-word instruction)_                   |
|   10   | `BGT addr16`     | Branch if Greater Than. _(Two-word instruction)_                         |
|   11   | `BLT addr16`     | Branch if Less Than. _(Two-word instruction)_                            |
|   12   | `INC rd`         | Increment `rd` by 1.                                                     |
|   13   | `DEC rd`         | Decrement `rd` by 1.                                                     |
|   14   | `NEG rd`         | Two's complement negation of `rd`.                                       |
|   15   | `AND rd, rs`     | Bitwise AND.                                                             |
|   16   | `OR rd, rs`      | Bitwise OR.                                                              |

### Register File

- 8 general-purpose registers (`R0`–`R7`)
- 16-bit register width

### Status Flags

The processor maintains condition flags that are updated by arithmetic and comparison operations:

- **Z (Zero):** Result equals zero.
- **N (Negative):** Result is negative.
- **P (Positive):** Result is positive.

These flags are used by the conditional branch instructions (`BEQ`, `BNE`, `BGT`, and `BLT`).
