# MNIST Binary Neural Network — Inference ASIC

**Author:** Marc-Andre Wessner | **Shuttle:** TT IHP26 | **Tiles:** 3×2

Classifies handwritten MNIST digits (0–9) entirely in hardware. No external memory, no external hardware — just clock, reset, and 98 bytes of pixel data in.

---

## How it works

```
ui_in[7:0] ──► mnist_loader ──► Conv1 (1→8ch, 3×3) ──► MaxPool
                                                              │
uo_out[3:0] ◄── XGBoost Tree ◄── Conv3 (16→64ch, 2×2) ◄── Conv2 (8→16ch, 3×3) ◄── MaxPool
```

All intermediate feature maps live in a single on-chip **256×8 SRAM** (IHP SG13G2 macro). A 7-state FSM (`main.sv`) sequences each stage and muxes the shared SRAM bus.

| Stage | Transform | ~Cycles |
|---|---|---|
| MNIST Load | 98 packets → 14×14 binary | 400 |
| Conv1 | 14×14 (1ch) → 12×12 (8ch) | 1512 |
| MaxPool1 | 12×12 → 6×6 | 288 |
| Conv2 | 6×6 (8ch) → 4×4 (16ch) | 1088 |
| MaxPool2 | 4×4 → 2×2 | 64 |
| Conv3 | 2×2 (16ch) → 64-bit embedding | 20 |
| Tree | 64-bit embedding → digit 0–9 | 0 (combinational) |

**Total: ~3400 cycles to result.**

### Binary convolution

Weights and activations are quantized to **±1**. Convolution reduces to XNOR-popcount:

```
output = sign( Σ w_i · x_i )  ≡  majority( XNOR(w, x) )
```

Thresholds: 5/9 (L1 · 3×3), 37/72 (L2 · 3×3), 33/64 (L3 · 2×2).

### Weights & classifier

All weight ROM modules (`conv_weights_*.sv`) and the decision tree (`classification_tree.sv`) are **code-generated** via Jinja2 (`codegen/`) from a trained PyTorch model. The final classifier is an XGBoost ensemble (10 classes × 10 boosting rounds) compiled to a purely combinational nested `if-else` tree.

---

## How to test

### Pin interface

| Pin | Dir | Description |
|---|---|---|
| `ui[7:0]` | In | 8-bit pixel packet |
| `uio[0]` | In | `data_in_clk` — rising edge latches each packet |
| `uo[3:0]` | Out | Predicted digit 0–9 (valid when `uo[4]=1`) |
| `uo[4]` | Out | `inference_done` — held high until next reset |

### Sending an image

1. Assert `rst_n = 0` for ≥ 3 cycles, then release.
2. Stream **98 packets** on `ui[7:0]`, toggling `uio[0]` high for 2 cycles then low for 2 cycles per packet.
3. Poll `uo[4]` — when high, read the digit from `uo[3:0]`.

Each packet encodes two 2×2 pixel blocks as nibbles (`low` = first block, `high` = second), scanning the 28×28 image row-major across 14 block-rows × 7 byte-columns.

**Preprocessing:** binarize with learned shift — `pixel ← (pixel > 0.66677) ? 1 : 0`

### Simulation

```bash
cd test && ./run_tests   # RTL sim (cocotb + Icarus)
make GATES=yes           # gate-level sim
```

Ten 28×28 MNIST images are prebaked directly into `test/testmodules/test_cloud.py` — **no dataset files or ML libraries required** to run the tests.

---

## External hardware

None. The design is fully self-contained on-chip.
