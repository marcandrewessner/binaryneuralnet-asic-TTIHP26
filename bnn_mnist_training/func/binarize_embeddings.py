import numpy as np


def binarize_embeddings(embeddings: np.ndarray) -> np.ndarray:
  """Collapse zeros to random ±1 and return as int8.

  Quantized activations may be 0 (dead neurons). This resolves
  ambiguous zeros to a random binary value so every embedding bit
  is strictly ±1, ready for binary decision-tree features.
  """
  embeddings = embeddings.copy()
  zero_mask = embeddings == 0
  embeddings[zero_mask] = np.random.choice([-1, 1], size=zero_mask.sum())
  return embeddings.astype(np.int8)
