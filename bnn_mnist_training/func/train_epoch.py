from dataclasses import dataclass
from typing import Literal

import torch
from torch import nn

@dataclass
class TrainEpochRecord():
  normalized_loss: float

def train_epoch(
  model: nn.Module,
  optimizer: torch.optim.Optimizer,
  criterion: nn.Module,
  dataloader: torch.utils.data.DataLoader,
  device: torch.device,
  mode: Literal["classifier", "autoencoder"] = "classifier",
) -> TrainEpochRecord:
  model.train()

  total_loss = 0

  for batch_data, batch_labels in dataloader:
    batch_data, batch_labels = batch_data.to(device), batch_labels.to(device)
    optimizer.zero_grad()
    inference = model(batch_data)
    target = batch_labels if mode == "classifier" else batch_data
    loss = criterion(inference, target)
    loss.backward()
    optimizer.step()
    total_loss += loss.item()

  return TrainEpochRecord(normalized_loss=total_loss / len(dataloader.dataset))
