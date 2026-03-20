from torch import nn

from func.model_main import model_main_classifier


# This model achieves with a training of 5 epochs
# a validation accuracy of 98%
# But it is huge. Now it's important to compress for silicon inference
class BasicCNN(nn.Module):

  def __init__(self):
    super().__init__()

    self.preprocess = nn.Sequential(
      nn.MaxPool2d(2, 2)
    )
    self.features = nn.Sequential(
      nn.Conv2d(1, 16, 3),
      nn.BatchNorm2d(16),
      nn.ReLU(),
      nn.Conv2d(16, 32, 3),
      nn.BatchNorm2d(32),
      nn.ReLU()
    )
    self.classifier = nn.Sequential(
      nn.Flatten(),
      nn.Dropout(),
      nn.Linear(32*10*10, 32),
      nn.ReLU(),
      nn.Dropout(),
      nn.Linear(32, 10),
    )

  def forward(self, x):
    x = self.preprocess(x)
    x = self.features(x)
    x = self.classifier(x)
    return x
  

if __name__ == "__main__":
  model_main_classifier(
    BasicCNN(),
    n_epochs=25,
    learning_rate=1e-3,
  )