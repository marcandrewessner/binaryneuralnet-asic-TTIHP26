from torch import nn

from func.model_main import model_main_classifier

from model_lib.LearnableShift import LearnableShift
from model_lib.QuantizeBinary import QuantizeBinary

# This model achieves with a training of 5 epochs
# a validation accuracy of 98%
# But it is huge. Now it's important to compress for silicon inference
class TowardsBNN(nn.Module):

  def __init__(self):
    super().__init__()

    self.preprocess = nn.Sequential(
      LearnableShift(),
      QuantizeBinary(),
    )
    self.features = nn.Sequential(
      nn.MaxPool2d(2,2),
      nn.Conv2d(
        in_channels=1,
        out_channels=8,
        kernel_size=3,
        stride=1
      ),
      QuantizeBinary(),
      nn.MaxPool2d(2,2),
      nn.Conv2d(
        in_channels=8,
        out_channels=16,
        kernel_size=3,
        stride=1
      ),
      QuantizeBinary(),
      nn.MaxPool2d(2,2),
    )
    self.classifier = nn.Sequential(
      nn.Flatten(),
      nn.Dropout(),
      nn.LazyLinear(10),
    )

  def forward(self, x):
    x = self.preprocess(x)
    x = self.features(x)
    x = self.classifier(x)
    return x
  

if __name__ == "__main__":
  model_main_classifier(
    TowardsBNN(),
    n_epochs=15,
    learning_rate=1e-3,
  )
