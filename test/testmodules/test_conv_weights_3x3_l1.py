# Test for conv_weights_3x3_l1.
#
# For every output channel (co in 0..7) and a variety of random 18-bit input
# windows, the test drives the DUT and compares data_out_0..3 against a Python
# reference XNOR-popcount computed from the actual trained model weights.

import os
import sys
import random
import numpy as np
import torch

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

# ---------------------------------------------------------------------------
# Path setup
# ---------------------------------------------------------------------------
_BNN_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../bnn_mnist_training")
)
if _BNN_DIR not in sys.path:
    sys.path.insert(0, _BNN_DIR)

from Model_QuantizedAE import QuantizedAE  # noqa: E402

_AE_WEIGHTS = os.path.join(_BNN_DIR, "data/model_weights/QuantizedAE.pnn")

# ---------------------------------------------------------------------------
# Load and binarise weights once at module level
# ---------------------------------------------------------------------------
_model = QuantizedAE()
_model.load_state_dict(torch.load(_AE_WEIGHTS, map_location="cpu"))
_model.eval()

# weights_raw shape: (8, 1, 3, 3)
_weights_raw = _model.features[1].get_parameter("weights").detach().numpy()
# binarise: sign → {-1,+1} → {0,1}
WEIGHTS = np.where(np.sign(_weights_raw) > 0, 1, 0).astype(np.uint8)  # (8,1,3,3)


# ---------------------------------------------------------------------------
# Reference XNOR-popcount for one channel and one 3×6 window
# ---------------------------------------------------------------------------

def reference_data_out(co: int, data_in_int: int):
    """
    Compute the expected data_out_0..3 for channel co and an 18-bit data_in.

    data_in layout (MSB first):
      [17:12] = row0 col0..5
      [11:6]  = row1 col0..5
      [5:0]   = row2 col0..5

    For position j (0..3), the 3×3 window is:
      row0: bits [17-j], [16-j], [15-j]
      row1: bits [11-j], [10-j], [9-j]
      row2: bits [5-j],  [4-j],  [3-j]

    Returns list of 4 ints (popcount, range 0..9).
    """
    w = WEIGHTS[co, 0]  # (3,3)

    bits = [(data_in_int >> b) & 1 for b in range(18)]  # bit[i] = bit i

    results = []
    for j in range(4):
        window = np.array([
            [bits[17 - j], bits[16 - j], bits[15 - j]],
            [bits[11 - j], bits[10 - j], bits[ 9 - j]],
            [bits[ 5 - j], bits[ 4 - j], bits[ 3 - j]],
        ], dtype=np.uint8)
        xnor = 1 - (window ^ w)   # 1 where they agree
        results.append(int(xnor.sum()))
    return results  # [pop0, pop1, pop2, pop3]


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------

NUM_RANDOM_INPUTS = 32   # random data_in vectors per channel

@cocotb.test()
async def test_conv_weights_3x3_l1(dut):
    dut._log.info("=== test_conv_weights_3x3_l1 ===")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    dut.rst_n.value          = 0
    dut.select_channel_in.value  = 0
    dut.select_channel_out.value = 0
    dut.data_in.value        = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    total_checks = 0
    total_errors = 0

    rng = random.Random(42)

    for co in range(8):
        dut.select_channel_in.value  = 0
        dut.select_channel_out.value = co

        # Test all-zeros and all-ones, plus random inputs
        test_inputs = [0x000000, 0x3FFFF]
        test_inputs += [rng.randint(0, 0x3FFFF) for _ in range(NUM_RANDOM_INPUTS)]

        for data_in_val in test_inputs:
            dut.data_in.value = data_in_val
            # Combinational — settle after one clock edge
            await ClockCycles(dut.clk, 2)

            hw = [
                int(dut.data_out_0.value),
                int(dut.data_out_1.value),
                int(dut.data_out_2.value),
                int(dut.data_out_3.value),
            ]
            ref = reference_data_out(co, data_in_val)

            for j in range(4):
                total_checks += 1
                if hw[j] != ref[j]:
                    total_errors += 1
                    dut._log.error(
                        f"  co={co} data_in=0x{data_in_val:05x} pos={j}: "
                        f"hw={hw[j]} ref={ref[j]}"
                    )

        dut._log.info(
            f"  channel {co}: tested {len(test_inputs)} inputs — "
            f"{'OK' if total_errors == 0 else f'{total_errors} errors so far'}"
        )

    assert total_errors == 0, (
        f"conv_weights_3x3_l1: {total_errors}/{total_checks} checks failed"
    )
    dut._log.info(
        f"All {total_checks} checks passed — PASSED"
    )
