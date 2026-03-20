from dataclasses import dataclass
from typing import Literal, Optional

import torch
from torch import nn

@dataclass
class ValidateModelRecord():
  normalized_loss: float
  total_accuracy: Optional[float]  # None for autoencoder mode

def validate_model(
  model: nn.Module,
  criterion: nn.Module,
  dataloader: torch.utils.data.DataLoader,
  device: torch.device,
  mode: Literal["classifier", "autoencoder"] = "classifier",
) -> ValidateModelRecord:
  model.eval()

  total_loss = 0
  total_corrects = 0

  with torch.no_grad():
    for batch_data, batch_labels in dataloader:
      batch_data, batch_labels = batch_data.to(device), batch_labels.to(device)
      inference = model(batch_data)
      target = batch_labels if mode == "classifier" else batch_data
      total_loss += criterion(inference, target).item()
      if mode == "classifier":
        total_corrects += (inference.argmax(dim=1) == batch_labels).sum().item()

  normalized_loss = total_loss / len(dataloader.dataset)
  total_accuracy = (total_corrects / len(dataloader.dataset)) if mode == "classifier" else None

  return ValidateModelRecord(
    normalized_loss=normalized_loss,
    total_accuracy=total_accuracy,
  )
