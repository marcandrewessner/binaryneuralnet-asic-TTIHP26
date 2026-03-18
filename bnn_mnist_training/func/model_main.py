# The goal of this project is to build a machine learning project,
# that is able to classify the mnist numbers on an ASIC ~1000 gates available
# lets see how this goes.

import torch
from torch import nn
from torchinfo import summary

from matplotlib import pyplot as plt

from func.load_mnist import load_mnist
from func.plot_preprocessed_image_table import plot_preprocessed_image_table
from func.train_epoch import train_epoch
from func.validate_model import validate_model



def model_main(
  model:nn.Module,
  learning_rate = 1e-6,
  n_epochs = 5,
):
  model_name = model.__class__.__name__
  training_dataloader, validation_dataloader = load_mnist()

  plot_preprocessed_image_table(
    model.preprocess,
    model_name=model_name,
    dataset_loader=training_dataloader
  )

  summary(model, input_size=(1, 1, 28, 28))

  criterion = nn.CrossEntropyLoss()
  optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)

  for epoch in range(n_epochs):
    train_epoch(model, optimizer, criterion, training_dataloader)
    train_record = validate_model(model, criterion, training_dataloader)
    validate_record = validate_model(model, criterion, validation_dataloader)

    print(f"Epoch {epoch+1}/{n_epochs}",train_record, validate_record)

  # At the end store the trained model
  torch.save(model.state_dict(), f"data/model_weights/{model_name}.pnn")

