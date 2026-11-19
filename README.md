# BPC-NDI – Auxiliary Arithmetic Unit (AAU)

Semester project for the BPC-NDI course. The goal is to design an Auxiliary Arithmetic Unit in VHDL for a Xilinx Artix-7 FPGA. The unit communicates with a microcontroller through SPI, receives two 16-bit fixed-point numbers, and returns the addition and multiplication results in the following packet.

## Project Function

The AAU operates as an SPI slave and processes data in frames and packets:

1. the first frame contains the first operand,
2. the second frame contains the second operand,
3. after a valid packet is received, the sum and product are calculated,
4. the results are returned in the following packet:
   1. Sum
   2. Product

The number format is 16-bit signed fixed-point with 8 integer bits and 8 fractional bits (Q8.8).

## Main Requirements

### General Requirements

- target technology: Xilinx Artix-7,
- fully synchronous design with a single system clock,
- only rising_edge(clk) is used in the RTL design,
- output signals must be glitch-free,
- asynchronous inputs must be synchronized,
- the FSM must safely recover to a valid state.

### Arithmetic

- signed addition,
- signed multiplication,
- 16-bit Q8.8 fixed-point format,
- negative numbers represented in two's complement,
- floor rounding where rounding is required,
- overflow saturation:
  - maximum: 0x7FFF,
  - minimum: 0x8000.

### SPI Interface

- AAU operates as an SPI slave,
- supported SCLK frequencies: 10 kHz, 100 kHz and 1 MHz,
- LSb-first transmission,
- a frame with an incorrect number of bits must be ignored,
- reception of the second frame must start within 1 ms after the first frame is received,
- arithmetic results are transmitted in the following order:
  1. Sum
  2. Product

## Architecture

The design is divided into three main parts: spi_if, pkt_ctrl and arith_unit.

### spi_if

The spi_if block handles the SPI communication.

It synchronizes SCLK, CS_b and MOSI, detects signal edges, receives and transmits 16-bit frames and checks whether the frame contains the correct number of bits.

It also generates the signals fr_start, fr_end and fr_err for the packet controller.

### pkt_ctrl

The pkt_ctrl block controls the packet processing.

It uses four states:

- WAIT_FR1
- RECEIVE_FR1
- WAIT_FR2
- RECEIVE_FR2

The first received frame is stored as the first operand and the second frame as the second operand.

If the second frame does not start within 1 ms after the first frame is received, the packet is discarded.

The block also selects which arithmetic result is sent back through SPI. The sum is sent first and the product second.

### arith_unit

The arith_unit block performs the arithmetic operations.

The first and second operands are stored in registers. After the second operand is received, the unit calculates the sum and product.

The multiplication result is converted back to Q8.8 format using floor rounding.

If the result is outside the range of a signed 16-bit Q8.8 number, saturation is used.

The maximum value is 0x7FFF and the minimum value is 0x8000.

## Verification

The design is tested in Vivado using XSim.

The testbench contains a simple SPI master that sends data to the AAU and reads the results through MISO.

The tests use the complete design, including spi_if, pkt_ctrl and arith_unit.

### Verified Tests

| Test | Q8.8 Operands | Expected Sum | Expected Product | Status |
|---|---:|---:|---:|---|
| TC_BASIC | 2.0, 3.0 | 5.0 | 6.0 | PASS |
| TC_NEGATIVE | -2.0, 3.0 | 1.0 | -6.0 | PASS |
| TC_FLOOR | 300/256, -200/256 | 100/256 | -235/256 | PASS |
| TC_POS_SAT | 100.0, 100.0 | 0x7FFF | 0x7FFF | PASS |
| TC_NEG_SUM_SAT | -100.0, -100.0 | 0x8000 | 0x7FFF | PASS |
| TC_NEG_MUL_SAT | -100.0, 100.0 | 0.0 | 0x8000 | PASS |

All current arithmetic tests pass in XSim.

TC_BASIC checks normal addition and multiplication.

TC_NEGATIVE checks signed arithmetic with a negative operand.

TC_FLOOR checks the Q8.8 multiplication result and floor rounding.

TC_POS_SAT checks positive overflow.

TC_NEG_SUM_SAT checks negative overflow during addition.

TC_NEG_MUL_SAT checks negative overflow during multiplication.

## Requirement Status

| Requirement | Description | Status |
|---|---|---|
| REQ_AAU_G_001 | Xilinx Artix-7 target | implemented |
| REQ_AAU_G_002 | single synchronous clock | implemented |
| REQ_AAU_G_003 | glitch-free outputs | implemented, final check remaining |
| REQ_AAU_G_004 | asynchronous input synchronization | implemented |
| REQ_AAU_G_005 | safe FSM implementation | implemented |
| REQ_AAU_F_010 | signed addition and multiplication | verified |
| REQ_AAU_F_011 | 16-bit Q8.8 format | verified |
| REQ_AAU_F_012 | floor rounding | verified |
| REQ_AAU_F_013 | overflow saturation | verified |
| REQ_AAU_I_020 | SCLK 10 kHz, 100 kHz and 1 MHz | 1 MHz verified |
| REQ_AAU_I_021 | LSb-first transmission | implemented |
| REQ_AAU_I_022 | invalid frame must be ignored | test not finished |
| REQ_AAU_I_023 | 1 ms second-frame timeout | implemented, test not finished |
| REQ_AAU_I_024 | Sum followed by Product | verified |

## Remaining Work

The arithmetic part is implemented and tested.

The remaining work is mainly related to SPI verification, implementation results and final documentation.

Still to be done:

- test SPI communication at 100 kHz,
- test SPI communication at 10 kHz,
- test LSb-first transmission separately,
- test short and long invalid SPI frames,
- test the 1 ms timeout between frames,
- finish the verification matrix,
- run synthesis and implementation,
- check FPGA resource usage,
- determine the maximum operating frequency,
- determine MTBF,
- finish the final report.

## Project Deliverables

The final project should contain:

- RTL source code,
- verification environment,
- verification results,
- implementation results,
- final documentation.

The final report should include the development process, design description, verification plan, verification matrix, test descriptions and implementation results.

The implementation part should contain resource usage, maximum operating frequency and MTBF.

## Tools

- AMD Vivado 2026.1
- XSim
- VHDL
- Xilinx Artix-7
- target part xc7a35tcpg236-1

## Current Status

The main design is working.

SPI communication at 1 MHz works and the arithmetic unit correctly performs signed addition and multiplication in Q8.8 format.

Floor rounding and positive and negative saturation have also been tested successfully.

The next step is to finish the SPI interface verification and then run synthesis and implementation.
