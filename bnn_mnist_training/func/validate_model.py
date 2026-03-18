from dataclasses import dataclass

import torch
from torch import nn

@dataclass
class ValidateModelRecord():
  normalized_loss:float
  total_accuracy:float

def validate_model(model:nn.Module, criterion:nn.Module, dataloader:torch.utils.data.DataLoader):
  model.eval()

  total_loss = 0
  total_corrects = 0

  with torch.no_grad():
    for batch_data, batch_labels in dataloader:
      inference = model(batch_data)
      total_loss += criterion(inference, batch_labels).item()
      total_corrects += (inference.argmax(dim=1) == batch_labels).sum().item()

  normalized_loss = total_loss / len(dataloader.dataset)
  total_accuracy = total_corrects / len(dataloader.dataset)

  return ValidateModelRecord(
    normalized_loss=normalized_loss,
    total_accuracy=total_accuracy,
  )