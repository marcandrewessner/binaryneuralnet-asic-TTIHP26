# this librariy is used to load the mnist dataset
# it creates the training and validation loaders

import torch
import torchvision

def load_mnist(dir_path="./data", pin_memory=False):
  train_dataset = torchvision.datasets.MNIST(
    dir_path,
    transform=torchvision.transforms.ToTensor(),
    train=True,
    download=True,
  )
  validation_dataset = torchvision.datasets.MNIST(
    dir_path,
    transform=torchvision.transforms.ToTensor(),
    train=False,
    download=True,
  )
  train_dataloader = torch.utils.data.DataLoader(
    train_dataset,
    batch_size=2048,
    shuffle=True,
    num_workers=4,
    pin_memory=pin_memory,
    persistent_workers=True,
  )
  validation_loader = torch.utils.data.DataLoader(
    validation_dataset,
    batch_size=2048,
    shuffle=True,
    num_workers=4,
    pin_memory=pin_memory,
    persistent_workers=True,
  )

  return train_dataloader, validation_loader