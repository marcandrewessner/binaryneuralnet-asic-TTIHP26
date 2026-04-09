# MNIST Binary Neural Network — Inference ASIC

> **Deprecated.** This repository is archived. Development continues at: **[NEXTGIT]**

---

**Author:** Marc-Andre Wessner | **Shuttle:** Tiny Tapeout IHP26 | **Tiles:** 6×4 | **Tech:** IHP SG13G2 130 nm

Classifies handwritten MNIST digits (0–9) entirely on-chip. No external memory, no peripherals — just clock, reset, and 98 bytes of pixel data in.

---

## Project Overview

Full MNIST inference in silicon via two complementary ML approaches trained in Python and compiled to RTL:

**1. Binary CNN (Encoder)**
A PyTorch autoencoder (`QuantizedAE`) with three binary convolutional layers and two max-pool layers. All weights and activations are quantized to ±1. The encoder compresses a 14×14 binary image down to a 64-bit embedding vector.

**2. XGBoost Decision Tree (Classifier)**
An XGBoost ensemble (10 classes × 10 boosting rounds = 100 trees) trained on the 64-bit embeddings. The trained trees are compiled to a purely combinational nested `if-else` tree in SystemVerilog — zero-cycle classification.

---

## Hardware Pipeline

```
ui[7:0] ──► mnist_loader ──► Conv1 (1→8ch, 3×3) ──► MaxPool1
                                                           │
uo[3:0] ◄── XGBoost Tree ◄── Conv3 (16→64ch, 2×2) ◄── Conv2 (8→16ch, 3×3) ◄── MaxPool2
```

All intermediate feature maps share a single on-chip **256×8 SRAM** (IHP macro). A 7-state FSM in `main.sv` sequences each stage and muxes the shared bus — one stage active at a time.

| Stage     | Transform                      | SRAM bytes  | ~Cycles |
|-----------|--------------------------------|-------------|---------|
| Load      | 98 packets → 14×14 binary      | 0–24        | 400     |
| Conv1     | 14×14 (1ch) → 12×12 (8ch)     | 25–168      | 1512    |
| MaxPool1  | 12×12 → 6×6                    | 169–204     | 288     |
| Conv2     | 6×6 (8ch) → 4×4 (16ch)        | 205–236     | 1088    |
| MaxPool2  | 4×4 → 2×2                      | 237–244     | 64      |
| Conv3     | 2×2 (16ch) → 64-bit embedding  | 245–252     | 20      |
| Tree      | 64-bit → digit 0–9             | —           | 0 (comb)|

**Total: ~3400 cycles to result.**

---

## Binary Convolution

All weights and activations are in {0, 1} (representing {−1, +1}). Multiply-accumulate reduces to XNOR-popcount:

```
output_bit = (popcount(XNOR(weights, activations)) ≥ threshold)
```

Thresholds: **5/9** (L1 · 3×3 kernel) | **37/72** (L2 · 3×3) | **33/64** (L3 · 2×2)

Each convolution layer loads a **3×6 pixel window** from SRAM once, then slides a 3×3 kernel across 4 column positions in the same pass — amortizing the SRAM read cost 4×.

---

## Weight Code Generation (`codegen/`)

Trained PyTorch weights are extracted, sign-quantized (`np.sign → {0,1}`), and rendered into SystemVerilog via Jinja2 templates:

- `conv_weights_3x3.sv.jinja` → `conv_weights_3x3_l1.sv`, `conv_weights_3x3_l2.sv`
- `conv_weights_2x2.sv.jinja` → `conv_weights_2x2_l3.sv`
- `classifiction_tree.sv.jinja` → `classification_tree.sv`

Each weight module is a combinational `case` statement keyed on `{channel_out, channel_in}` that drives the kernel bits. The XNOR-popcount logic is statically unrolled — no multipliers, no adder trees beyond simple popcount chains. The XGBoost trees are walked recursively and emitted as nested `if-else` blocks; leaf values are 2-bit quantized.

---

## IHP SRAM Macro

The design uses the IHP SG13G2 foundry SRAM macro: **`RM_IHPSG13_1P_256x8_c3_bm_bist`**

- Single-port, 256 words × 8 bits = 2 KB
- Byte-mask (`A_BM`) support — used to write individual bits within a byte
- BIST pins present but tied off (`A_BIST_EN = 0`)
- Wrapped in `sram_256x8_bm` (`src/sram.sv`) behind a `sram_req_t / sram_rsp_t` struct interface

Full macro collateral in `macros/SRAM/`: `.v`, `.lef`, `.gds`, `.cdl`, and three `.lib` corners (fast / typ / slow).

---

## Source Files

| File | Role |
|------|------|
| `src/project.v` | Tiny Tapeout top wrapper |
| `src/main.sv` | Pipeline sequencer FSM + SRAM mux |
| `src/sram.sv` | IHP SRAM macro wrapper |
| `src/mnist_loader.sv` | Serial pixel input → SRAM |
| `src/load_conv_op_3x6.sv` | 3×6 window loader from SRAM |
| `src/conv_layer{1,2,3}.sv` | Conv stage FSMs |
| `src/conv_weights_*.sv` | **Generated** weight ROMs |
| `src/classification_tree.sv` | **Generated** XGBoost tree (combinational) |
| `src/maxpool_2x2.sv` | Parametric 2×2 max-pool |
| `codegen/main.py` | Weight extraction + Jinja2 code generation |
| `bnn_mnist_training/` | PyTorch training notebooks + model definitions |

---

## Pin Interface

| Pin | Dir | Description |
|-----|-----|-------------|
| `ui[7:0]` | In | 8-bit pixel packet (two 2×2 OR-pooled blocks per byte) |
| `uio[0]` | In | `data_in_clk` — rising edge latches each packet |
| `uo[3:0]` | Out | Predicted digit 0–9 |
| `uo[4]` | Out | `inference_done` — held high until next reset |

**Sending an image:**
1. Assert `rst_n = 0` for ≥ 3 cycles, then release.
2. Stream **98 packets** on `ui[7:0]`, toggling `uio[0]` high then low for 2 cycles each.
3. Poll `uo[4]` — when high, read the digit from `uo[3:0]`.

Binarization threshold: `pixel ← (pixel > 0.66677) ? 1 : 0`

---

## Simulation

```bash
cd test && ./run_tests        # RTL sim (cocotb + Icarus Verilog)
make GATES=yes                # gate-level sim
```

Ten prebaked MNIST images are embedded directly in the testbench — no dataset files or ML libraries required.
