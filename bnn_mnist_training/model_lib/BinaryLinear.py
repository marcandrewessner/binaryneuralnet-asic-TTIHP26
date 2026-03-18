import torch
from torch import nn
import torch.nn.functional as F

from .QuantizeBinary import _QuantizeBinarySTE

class BinaryLinear(nn.Module):
    def __init__(self, in_features, out_features, bias=True):
        super().__init__()
        # Real-valued weights — these are what the optimizer actually updates
        self.weight = nn.Parameter(torch.empty(out_features, in_features))
        self.bias = nn.Parameter(torch.zeros(out_features)) if bias else None
        nn.init.kaiming_uniform_(self.weight)

    def forward(self, x):
        # Binarize weights on-the-fly using the same STE you already have
        w_binary = _QuantizeBinarySTE.apply(self.weight)
        return F.linear(x, w_binary, self.bias)