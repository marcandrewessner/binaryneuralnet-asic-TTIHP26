
# Bare-metal XGBoost tree inference — no XGBoost runtime needed at inference time.
# Reads the trained model, parses it into plain dicts, and walks the trees manually.

import numpy as np
import pandas as pd
import xgboost as xgb


def build_tree_maps(model: xgb.Booster):
  """Parse the booster into plain dicts for fast, dependency-free traversal."""
  model_df    = model.trees_to_dataframe()
  node_index  = model_df.set_index("ID")
  feature_map = node_index["Feature"].to_dict()
  gain_map    = node_index["Gain"].to_dict()
  yes_map     = node_index["Yes"].to_dict()
  no_map      = node_index["No"].to_dict()
  return feature_map, gain_map, yes_map, no_map


def build_root_ids(num_classes: int, num_rounds: int) -> list[list[str]]:
  """Pre-compute root node IDs grouped by class then round."""
  return [
    [f"{r * num_classes + cl}-0" for r in range(num_rounds)]
    for cl in range(num_classes)
  ]


def quantize_leaf(leaf_value: float) -> float:
  return leaf_value


def calculate_tree(
  root_id: str,
  embedding: np.ndarray,
  feature_map: dict,
  gain_map: dict,
  yes_map: dict,
  no_map: dict,
) -> float:
  """Iterative tree walk. Follows 'Yes' branch when feature == -1."""
  node = root_id
  while True:
    feature = feature_map[node]
    if feature == "Leaf":
      return quantize_leaf(gain_map[node])
    ex   = int(feature[1:])  # strip leading 'e'
    node = yes_map[node] if embedding[ex] == -1 else no_map[node]


def make_decision(
  embedding: np.ndarray,
  root_ids: list[list[str]],
  feature_map: dict,
  gain_map: dict,
  yes_map: dict,
  no_map: dict,
) -> np.ndarray:
  """Sum leaf scores across all rounds for each class and return raw logits."""
  return np.array([
    sum(
      calculate_tree(root, embedding, feature_map, gain_map, yes_map, no_map)
      for root in roots
    )
    for roots in root_ids
  ])


def run_validation(
  val_parquet_path: str,
  root_ids: list[list[str]],
  feature_map: dict,
  gain_map: dict,
  yes_map: dict,
  no_map: dict,
):
  validation_dataset = pd.read_parquet(val_parquet_path)
  feature_cols = [f"e{i}" for i in range(64)]
  embeddings   = validation_dataset[feature_cols].to_numpy(dtype=np.int8)
  labels       = validation_dataset["label"].to_numpy()
  dataset_size = len(labels)

  corrects = 0
  for idx in range(dataset_size):
    activation  = make_decision(embeddings[idx], root_ids, feature_map, gain_map, yes_map, no_map)
    corrects   += np.argmax(activation) == labels[idx]

    if idx % 2000 == 0:
      print(f"Progress: {idx / dataset_size * 100:.1f}%")

  print(f"Accuracy: {corrects / dataset_size:.4f}")


def main():
  model_path   = "data/model_weights/xgb_decision_tree.json"
  val_path     = "data/embedding_table/val_embeddings.parquet"
  num_classes  = 10

  model = xgb.Booster()
  model.load_model(model_path)

  feature_map, gain_map, yes_map, no_map = build_tree_maps(model)
  root_ids = build_root_ids(num_classes, model.num_boosted_rounds())

  run_validation(val_path, root_ids, feature_map, gain_map, yes_map, no_map)


if __name__ == "__main__":
  main()
