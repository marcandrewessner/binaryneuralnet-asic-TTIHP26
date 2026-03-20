
# Here we use xgboost to create a decision tree from
# the quantized autoencoder

import pandas as pd
import torch
import xgboost as xgb

from sklearn.metrics import accuracy_score

from func.binarize_embeddings import binarize_embeddings
from func.load_mnist import load_mnist
from Model_QuantizedAE import QuantizedAE


def main():
  embedding_train_path = "data/embedding_table/train_embeddings.parquet"
  embedding_val_path   = "data/embedding_table/val_embeddings.parquet"
  model_save_path      = "data/model_weights/xgb_decision_tree.json"
  ae_weights_path      = "data/model_weights/QuantizedAE.pnn"

  train_dl, val_dl = load_mnist()

  train_df = build_embedding_table(train_dl, ae_weights_path)
  val_df   = build_embedding_table(val_dl,   ae_weights_path)

  train_df.to_parquet(embedding_train_path, index=False)
  val_df.to_parquet(embedding_val_path,     index=False)
  print(f"[train] saved {len(train_df)} rows → {embedding_train_path}")
  print(f"[val]   saved {len(val_df)} rows → {embedding_val_path}")

  train_decision_tree(train_df, val_df, model_save_path)


def build_embedding_table(dataloader, ae_weights_path):
  state_dict = torch.load(ae_weights_path)
  model = QuantizedAE()
  model.load_state_dict(state_dict)
  model.eval()

  encoder = torch.nn.Sequential(
    model.preprocess,
    model.features,
    torch.nn.Flatten(),
  )

  rows = []
  with torch.no_grad():
    for batch_img, batch_label in dataloader:
      embeddings = binarize_embeddings(encoder(batch_img).numpy())  # (B, 64), values in {-1, 1}

      labels   = batch_label.numpy()                # (B,)
      batch_df = pd.DataFrame(
        embeddings,
        columns=[f"e{i}" for i in range(embeddings.shape[1])]
      )
      batch_df["label"] = labels
      rows.append(batch_df)

  return pd.concat(rows, ignore_index=True)


def train_decision_tree(train_df, val_df, model_save_path):
  feature_cols = [c for c in train_df.columns if c != "label"]

  X_train = train_df[feature_cols].values
  y_train = train_df["label"].values
  X_val   = val_df[feature_cols].values
  y_val   = val_df["label"].values

  dtrain = xgb.DMatrix(X_train, label=y_train)
  dval   = xgb.DMatrix(X_val,   label=y_val)

  params = {
    "objective":        "multi:softmax",
    "num_class":        10,
    "tree_method":      "hist",
    "max_depth":        6,
    "eta":              0.1,
    "subsample":        0.8,
    "eval_metric":      "merror",
  }

  evals = [(dtrain, "train"), (dval, "val")]
  booster = xgb.train(
    params,
    dtrain,
    num_boost_round=200,
    evals=evals,
    early_stopping_rounds=20,
    verbose_eval=10,
  )

  booster.save_model(model_save_path)
  print(f"Model saved → {model_save_path}")

  preds = booster.predict(dval).astype(int)
  acc   = accuracy_score(y_val, preds)
  print(f"Validation accuracy: {acc:.4f}")


if __name__ == "__main__":
  main()
