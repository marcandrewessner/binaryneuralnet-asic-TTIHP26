import os
import sys

import numpy as np
import torch
import xgboost as xgb

from jinja2 import Environment, FileSystemLoader

from IPython import embed

# ---------------------------------------------------------------------------
# Path setup — pull in the training repo
# ---------------------------------------------------------------------------
_BNN_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../bnn_mnist_training")
)
if _BNN_DIR not in sys.path:
    sys.path.insert(0, _BNN_DIR)

from Model_QuantizedAE import QuantizedAE   # noqa: E402  (after sys.path fix)

_AE_WEIGHTS  = os.path.join(_BNN_DIR, "data/model_weights/QuantizedAE.pnn")
_TREE_WEIGHTS = os.path.join(_BNN_DIR, "data/model_weights/xgb_decision_tree.json")
_MNIST_DIR   = os.path.join(_BNN_DIR, "data")

model:torch.nn.Module = QuantizedAE()
model.load_state_dict(torch.load(_AE_WEIGHTS, map_location="cpu"))
# ---------------------------------------------------------------------------


jinjaenv = env = Environment(loader=FileSystemLoader("."), trim_blocks=True, lstrip_blocks=True)


def main():
  # GENERATE THE WEIGHTS OF THE FIRST CONV LAYER
  print("GENERATE CONV LAYER 1")
  weights = model.features[1].get_parameter("weights")
  weights = quantize_weights(weights.detach().numpy())
  generate_conv_weights_3x3("conv_weights_3x3_l1", weights)
  print("GENERATE CONV LAYER 2")
  weights2 = model.features[4].get_parameter("weights")
  weights2 = quantize_weights(weights2.detach().numpy())
  generate_conv_weights_3x3("conv_weights_3x3_l2", weights2)
  print("GENERATE CONV LAYER 3 (2x2 kernel)")
  weights3 = model.features[7].get_parameter("weights")
  weights3 = quantize_weights(weights3.detach().numpy())
  generate_conv_weights_2x2("conv_weights_2x2_l3", weights3)
  print("GENERATE CLASSIFICATION TREE")
  generate_classification_tree()
  print("DONE")

def generate_conv_weights_2x2(module_name, weights):
  COUT, CIN, KH, KW = weights.shape
  assert KH == 2 and KW == 2
  # Threshold: N/2 + 1 where N = CIN * KH * KW = 16*4 = 64
  threshold = CIN * KH * KW // 2 + 1  # = 33
  template = jinjaenv.get_template("./conv_weights_2x2.sv.jinja")
  result = template.render(
    module_name  = module_name,
    channel_out  = COUT,
    channel_in   = CIN,
    weights      = weights,
    threshold    = threshold,
  )
  with open(f"../src/{module_name}.sv", "w") as f:
    f.write(result)
  print(f"  → wrote ../src/{module_name}.sv  ({COUT} outputs, {CIN} inputs, 2×2 kernel, threshold={threshold})")


def generate_conv_weights_3x3(module_name, weights):
  COUT,CIN,KH,KW = weights.shape
  assert KH==3 and KW==3
  template = jinjaenv.get_template("./conv_weights_3x3.sv.jinja")
  result = template.render(
    module_name = module_name,
    channel_out = COUT,
    channel_in = CIN,
    weights = weights,
  )
  with open(f"../src/{module_name}.sv", "w") as f:
    f.write(result)


def quantize_weights(weights):
  w = np.sign(weights).astype(int)
  w = np.where(w == -1, 0, 1)
  return w


# ---------------------------------------------------------------------------
# Classification tree generator
# ---------------------------------------------------------------------------

# Leaf quantization boundaries (from lab_baremetal_treeinference.ipynb)
# np.digitize(x, boundaries[1:-1]) → 0, 1, 2, or 3  (2-bit output)
_QUANT_BOUNDARIES = np.array([-0.78268069, -0.27526352, -0.08869842, 0.11034979, 3.03155756])


def _quantize_leaf(value: float) -> int:
  """Map a raw XGBoost leaf value to a 2-bit integer (0–3)."""
  return int(np.digitize(value, _QUANT_BOUNDARIES[1:-1]))


def _build_tree(tree_df) -> dict:
  """Recursively build a nested dict representing one XGBoost tree."""
  node_index = tree_df.set_index("Node")

  def recurse(node_id: int) -> dict:
    row = node_index.loc[node_id]
    if row["Feature"] == "Leaf":
      return {"type": "leaf", "value": _quantize_leaf(row["Gain"])}
    yes_id = int(row["Yes"].split("-")[1])
    no_id  = int(row["No"].split("-")[1])
    return {
      "type":    "split",
      "feature": int(row["Feature"][1:]),  # strip leading 'e'
      "yes":     recurse(yes_id),           # taken when embedding bit == 0 (-1)
      "no":      recurse(no_id),            # taken when embedding bit == 1 (+1)
    }

  return recurse(0)


def generate_classification_tree():
  """Load XGBoost model, extract all trees, render classification_tree.sv."""
  xgb_model = xgb.Booster()
  xgb_model.load_model(_TREE_WEIGHTS)

  model_df    = xgb_model.trees_to_dataframe()
  num_classes = 10
  num_rounds  = xgb_model.num_boosted_rounds()
  total_trees = num_classes * num_rounds

  trees = [
    _build_tree(model_df[model_df["Tree"] == tid])
    for tid in range(total_trees)
  ]

  template = jinjaenv.get_template("./classifiction_tree.sv.jinja")
  result = template.render(
    num_classes = num_classes,
    num_rounds  = num_rounds,
    trees       = trees,
  )

  out_path = "../src/classification_tree.sv"
  with open(out_path, "w") as f:
    f.write(result)
  print(f"  → wrote {out_path}  ({total_trees} trees, {num_classes} classes, {num_rounds} rounds)")


if __name__ == "__main__":
  main()
