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


def _get_device():
  if torch.cuda.is_available():
    return torch.device('cuda')
  if torch.backends.mps.is_available():
    return torch.device('mps')
  return torch.device('cpu')


def model_main(
  model:nn.Module,
  n_epochs = 10,
  lr = 1e-6,
  lr_sched_step_epochs = 5,
  lr_sched_gamma = 1,
  continue_learning = False,
):
  device = _get_device()
  print(f"Using device: {device}")
  model = model.to(device)

  model_name = model.__class__.__name__
  model_save_path = f"data/model_weights/{model_name}.pnn"

  training_dataloader, validation_dataloader = load_mnist(pin_memory=device.type == 'cuda')

  if continue_learning:
    state_dict = torch.load(model_save_path)
    model.load_state_dict(state_dict)

  plot_preprocessed_image_table(
    model.preprocess,
    model_name=model_name,
    dataset_loader=training_dataloader
  )

  summary(model, input_size=(1, 1, 28, 28))

  criterion = nn.CrossEntropyLoss()
  optimizer = torch.optim.Adam(model.parameters(), lr=lr)
  scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=lr_sched_step_epochs, gamma=lr_sched_gamma)

  for epoch in range(n_epochs):
    train_epoch(model, optimizer, criterion, training_dataloader, device)
    validate_record = validate_model(model, criterion, validation_dataloader, device)

    print(f"Epoch {epoch+1}/{n_epochs}", validate_record)

    scheduler.step()

  # At the end store the trained model
  torch.save(model.state_dict(), model_save_path)

