# Test for classification_tree.
#
# The module is purely combinational: set embedding_i, read number_o.
#
# Strategy:
#   1. Load N embeddings from the validation parquet (default 200).
#   2. For each embedding compute the reference prediction using the bare-metal
#      Python tree inference (same logic as Main_BareMetalTreeInference.py).
#   3. Drive embedding_i into the DUT and verify number_o matches.
#   4. Report overall accuracy vs. the Python reference and vs. ground-truth labels.

import os
import sys

import numpy as np
import pandas as pd
import xgboost as xgb

import cocotb
from cocotb.triggers import Timer

# ---------------------------------------------------------------------------
# Path setup — pull in the training repo
# ---------------------------------------------------------------------------
_BNN_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../bnn_mnist_training")
)
if _BNN_DIR not in sys.path:
    sys.path.insert(0, _BNN_DIR)

_TREE_WEIGHTS = os.path.join(_BNN_DIR, "data/model_weights/xgb_decision_tree.json")
_VAL_PARQUET  = os.path.join(_BNN_DIR, "data/embedding_table/val_embeddings.parquet")

# ---------------------------------------------------------------------------
# Reference tree inference (matches the generated hardware exactly)
# ---------------------------------------------------------------------------

# Leaf quantisation boundaries (from lab_baremetal_treeinference.ipynb)
_QUANT_BOUNDS = np.array([-0.78268069, -0.27526352, -0.08869842, 0.11034979, 3.03155756])

def _quantize_leaf(value: float) -> int:
    return int(np.digitize(value, _QUANT_BOUNDS[1:-1]))


def _build_reference(model: xgb.Booster, num_classes: int = 10):
    """Pre-build dicts for fast tree traversal."""
    df = model.trees_to_dataframe()
    node_index  = df.set_index("ID")
    feature_map = node_index["Feature"].to_dict()
    gain_map    = node_index["Gain"].to_dict()
    yes_map     = node_index["Yes"].to_dict()
    no_map      = node_index["No"].to_dict()

    num_rounds = model.num_boosted_rounds()
    root_ids = [
        [f"{r * num_classes + cl}-0" for r in range(num_rounds)]
        for cl in range(num_classes)
    ]
    return feature_map, gain_map, yes_map, no_map, root_ids


def _predict(embedding: np.ndarray, feature_map, gain_map, yes_map, no_map, root_ids) -> int:
    """Run one inference; returns predicted class (0-9)."""
    scores = []
    for roots in root_ids:
        total = 0
        for root in roots:
            node = root
            while True:
                feat = feature_map[node]
                if feat == "Leaf":
                    total += _quantize_leaf(gain_map[node])
                    break
                ex   = int(feat[1:])
                node = yes_map[node] if embedding[ex] == -1 else no_map[node]
        scores.append(total)
    return int(np.argmax(scores))


# ---------------------------------------------------------------------------
# Embedding conversion: ±1 numpy → 64-bit integer for the DUT
# ---------------------------------------------------------------------------

def embedding_to_int(embedding: np.ndarray) -> int:
    """Map e_i ∈ {-1,+1} → bit i ∈ {0,1}, pack into a 64-bit integer."""
    bits = np.where(embedding == 1, 1, 0).astype(np.uint8)
    result = 0
    for i, b in enumerate(bits):
        result |= (int(b) << i)
    return result


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------

NUM_SAMPLES = 200   # how many validation embeddings to test

@cocotb.test()
async def test_classification_tree(dut):
    dut._log.info("=== test_classification_tree ===")

    # ------------------------------------------------------------------
    # 1. Load model and validation data
    # ------------------------------------------------------------------
    xgb_model = xgb.Booster()
    xgb_model.load_model(_TREE_WEIGHTS)
    feature_map, gain_map, yes_map, no_map, root_ids = _build_reference(xgb_model)

    val_df       = pd.read_parquet(_VAL_PARQUET)
    feature_cols = [f"e{i}" for i in range(64)]
    embeddings   = val_df[feature_cols].to_numpy(dtype=np.int8)[:NUM_SAMPLES]
    labels       = val_df["label"].to_numpy()[:NUM_SAMPLES]

    dut._log.info(f"Testing {NUM_SAMPLES} validation embeddings")

    # ------------------------------------------------------------------
    # 2. Run each embedding through DUT and reference
    # ------------------------------------------------------------------
    hw_correct  = 0
    ref_correct = 0
    hw_ref_agree = 0

    for idx in range(NUM_SAMPLES):
        emb   = embeddings[idx]
        label = int(labels[idx])

        # Python reference prediction
        ref_pred = _predict(emb, feature_map, gain_map, yes_map, no_map, root_ids)

        # Drive DUT
        emb_int = embedding_to_int(emb)
        dut.embedding_i.value = emb_int
        await Timer(1, units="ns")   # propagate combinational logic

        hw_pred = int(dut.number_o.value)

        # Tally results
        ref_correct  += ref_pred == label
        hw_correct   += hw_pred  == label
        hw_ref_agree += hw_pred  == ref_pred

        if hw_pred != ref_pred:
            dut._log.error(
                f"  [{idx}] MISMATCH  label={label}  ref={ref_pred}  hw={hw_pred}"
                f"  emb_hex=0x{emb_int:016x}"
            )

    # ------------------------------------------------------------------
    # 3. Report
    # ------------------------------------------------------------------
    dut._log.info(
        f"Python reference accuracy : {ref_correct}/{NUM_SAMPLES} "
        f"({100*ref_correct/NUM_SAMPLES:.1f}%)"
    )
    dut._log.info(
        f"Hardware accuracy         : {hw_correct}/{NUM_SAMPLES} "
        f"({100*hw_correct/NUM_SAMPLES:.1f}%)"
    )
    dut._log.info(
        f"HW / reference agreement  : {hw_ref_agree}/{NUM_SAMPLES} "
        f"({100*hw_ref_agree/NUM_SAMPLES:.1f}%)"
    )

    mismatches = NUM_SAMPLES - hw_ref_agree
    assert mismatches == 0, (
        f"Hardware disagrees with Python reference on {mismatches}/{NUM_SAMPLES} samples"
    )
    dut._log.info("PASSED — hardware matches reference on all samples")
