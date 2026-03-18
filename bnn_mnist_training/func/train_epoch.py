from dataclasses import dataclass

import torch
from torch import nn

@dataclass
class TrainEpochRecod():
  normalized_loss:float
  total_accuracy:float

def train_epoch(model:nn.Module, optimizer:torch.optim.Optimizer, criterion:nn.Module, dataloader:torch.utils.data.DataLoader):
  model.train()

  for batch_data, batch_labels in dataloader:
    optimizer.zero_grad()
    inference = model(batch_data)
    loss = criterion(inference, batch_labels)
    loss.backward()
    optimizer.step()
