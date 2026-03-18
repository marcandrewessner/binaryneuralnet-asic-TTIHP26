from torch import nn

from func.model_main import model_main

from model_lib.LearnableShift import LearnableShift
from model_lib.QuantizeBinary import QuantizeBinary
from model_lib.BinaryConv2d import BinaryConv2d
from model_lib.BinaryLinear import BinaryLinear

# This model achieves with a training of 5 epochs
# a validation accuracy of 98%
# But it is huge. Now it's important to compress for silicon inference
class FullBNN(nn.Module):

  def __init__(self):
    super().__init__()

    self.preprocess = nn.Sequential(
      LearnableShift(),
      QuantizeBinary(),
    )
    self.features = nn.Sequential(
      nn.MaxPool2d(2,2),
      BinaryConv2d(
        in_channels=1,
        out_channels=8,
        kernel_size=3,
        stride=1
      ),
      nn.MaxPool2d(2,2),
      QuantizeBinary(),
      BinaryConv2d(
        in_channels=8,
        out_channels=16,
        kernel_size=3,
        stride=1
      ),
      nn.MaxPool2d(2,2),
    )
    fully_binaryclassifier = nn.Sequential(
      nn.Flatten(),
      nn.Dropout(),
      BinaryLinear(16*2*2, 16),
      nn.Dropout(),
      BinaryLinear(16, 10),
    )
    classic_classifier = nn.Sequential(
      nn.Flatten(),
      nn.Dropout(),
      nn.LazyLinear(32),
      nn.ReLU(),
      nn.Dropout(),
      nn.LazyLinear(10),
    )
    self.classifier = fully_binaryclassifier

  def forward(self, x):
    x = self.preprocess(x)
    x = self.features(x)
    x = self.classifier(x)
    return x
  

if __name__ == "__main__":
  model_main(
    FullBNN(),
    n_epochs=20,
    learning_rate=1e-4,
  )
