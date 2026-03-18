
import torch
from torch import nn


class _QuantizeBinarySTE(torch.autograd.Function):

  @staticmethod
  def forward(ctx, x):
    ctx.save_for_backward(x)
    return torch.sign(x)
  
  @staticmethod
  def backward(ctx, grad):
    x, = ctx.saved_tensors
    grad_mask = (x.abs() <= 1).float()
    return grad * grad_mask


class QuantizeBinary(nn.Module):

  def __init__(self):
    super().__init__()

  def forward(self, x):
    return _QuantizeBinarySTE.apply(x)
