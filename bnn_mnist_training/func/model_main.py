# The goal of this project is to build a machine learning project,
# that is able to classify the mnist numbers on an ASIC ~1000 gates available
# lets see how this goes.

import torch
from torch import nn
from torchinfo import summary

from func.load_mnist import load_mnist
from func.plot_preprocessed_image_table import plot_preprocessed_image_table
from func.train_epoch import train_epoch
from func.validate_model import validate_model


def _get_device():
  if torch.cuda.is_available():
    return torch.device('cuda')
  # SKIP MPS FOR NOW!
  #if torch.backends.mps.is_available():
  #  return torch.device('mps')
  return torch.device('cpu')


def _model_main_core(
  model: nn.Module,
  criterion: nn.Module,
  mode,
  n_epochs: int,
  lr: float,
  lr_sched_step_epochs: int,
  lr_sched_gamma: float,
  continue_learning: bool,
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

  if hasattr(model, 'preprocess'):
    plot_preprocessed_image_table(
      model.preprocess,
      model_name=model_name,
      dataset_loader=training_dataloader
    )

  summary(model, input_size=(1, 1, 28, 28))

  optimizer = torch.optim.Adam(model.parameters(), lr=lr)
  scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=lr_sched_step_epochs, gamma=lr_sched_gamma)

  for epoch in range(n_epochs):
    train_record = train_epoch(model, optimizer, criterion, training_dataloader, device, mode=mode)
    validate_record = validate_model(model, criterion, validation_dataloader, device, mode=mode)

    print(f"Epoch {epoch+1}/{n_epochs}", train_record, validate_record)

    scheduler.step()

  torch.save(model.state_dict(), model_save_path)


def model_main_classifier(
  model: nn.Module,
  n_epochs = 10,
  lr = 1e-6,
  lr_sched_step_epochs = 5,
  lr_sched_gamma = 1,
  continue_learning = False,
):
  _model_main_core(
    model=model,
    criterion=nn.CrossEntropyLoss(),
    mode="classifier",
    n_epochs=n_epochs,
    lr=lr,
    lr_sched_step_epochs=lr_sched_step_epochs,
    lr_sched_gamma=lr_sched_gamma,
    continue_learning=continue_learning,
  )


def model_main_autoencoder(
  model: nn.Module,
  n_epochs = 10,
  lr = 1e-6,
  lr_sched_step_epochs = 5,
  lr_sched_gamma = 1,
  continue_learning = False,
):
  _model_main_core(
    model=model,
    criterion=nn.MSELoss(),
    mode="autoencoder",
    n_epochs=n_epochs,
    lr=lr,
    lr_sched_step_epochs=lr_sched_step_epochs,
    lr_sched_gamma=lr_sched_gamma,
    continue_learning=continue_learning,
  )
