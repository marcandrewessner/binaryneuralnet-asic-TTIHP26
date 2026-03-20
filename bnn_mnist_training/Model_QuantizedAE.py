from torch import nn

from model_lib import LearnableShift, QuantizeBinary, BinaryConv2d

from func.model_main import model_main_autoencoder


# This model achieves with a training of 5 epochs
# a validation accuracy of 98%
# But it is huge. Now it's important to compress for silicon inference
class QuantizedAE(nn.Module):

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
      QuantizeBinary(),
      BinaryConv2d(
        in_channels=16,
        out_channels=64,
        kernel_size=2,
        stride=1
      ),
      QuantizeBinary(),
    )
    self.upsampler = nn.Sequential(
      # 1×1 → 7×7  (kernel fills the whole spatial dim)
      nn.ConvTranspose2d(64, 32, kernel_size=7, stride=1, padding=0, bias=False),
      nn.BatchNorm2d(32),
      nn.ReLU(inplace=True),

      # 7×7 → 14×14
      nn.ConvTranspose2d(32, 16, kernel_size=4, stride=2, padding=1, bias=False),
      nn.BatchNorm2d(16),
      nn.ReLU(inplace=True),

      # 14×14 → 28×28
      nn.ConvTranspose2d(16, 1, kernel_size=4, stride=2, padding=1, bias=False),
      nn.BatchNorm2d(1),
      nn.Sigmoid(),
    )

  def forward(self, x):
    x = self.preprocess(x)
    x = self.features(x)
    x = self.upsampler(x)
    return x
  

if __name__ == "__main__":
  model_main_autoencoder(
    QuantizedAE(),
    n_epochs=100,
    lr=1e-3,
    lr_sched_step_epochs=50,
    lr_sched_gamma=0.1,
  )