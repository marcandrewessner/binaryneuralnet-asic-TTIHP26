
import torch
from torch import nn

from .QuantizeBinary import _QuantizeBinarySTE

class BinaryConv2d(nn.Module):

  def __init__(
    self,
    in_channels:int,
    out_channels:int,
    kernel_size:int,
    stride=1,
    #bias=True,
  ):
    super().__init__()
    self._in_channels=in_channels
    self._out_channels=out_channels
    self._kernel_size=kernel_size
    self._stride=stride
    # Now initialize the weights and the bias
    w = torch.empty(self._out_channels, self._in_channels, self._kernel_size, self._kernel_size)
    nn.init.kaiming_uniform_(w)
    self.weights = nn.Parameter(w)
    #self.bias = nn.Parameter(torch.empty(out_channels)) if bias else None
  
  def forward(self, x):
    quantized_weights = _QuantizeBinarySTE.apply(self.weights)
    return nn.functional.conv2d(
      x,
      quantized_weights,
      bias=None,
      stride=self._stride,
    )