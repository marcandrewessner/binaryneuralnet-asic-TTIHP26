# this librariy is used to load the mnist dataset
# it creates the training and validation loaders

import torch
import torchvision

def load_mnist(dir_path="./data"):
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
    batch_size=64,
    shuffle=True,
    num_workers=2,
  )
  validation_loader = torch.utils.data.DataLoader(
    validation_dataset,
    batch_size=64,
    shuffle=True,
    num_workers=2,
  )

  return train_dataloader, validation_loader