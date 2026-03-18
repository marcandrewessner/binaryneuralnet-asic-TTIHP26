
import torch
from torch import nn

class LearnableShift(nn.Module):
  def __init__(self, init=0.5):
    super().__init__()
    self.shift = nn.Parameter(torch.tensor(init))

  def forward(self, x):
    return x - self.shift