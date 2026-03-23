#!/usr/bin/bash

cd /workspaces/binaryneuralnet-asic-TTIHP26/test

# Run all the tests
make -B TOPLEVEL=tb COCOTB_TEST_MODULES=test
make -B TOPLEVEL=tb_counter4bit COCOTB_TEST_MODULES=test_counter4bit
make -B TOPLEVEL=tb_sram COCOTB_TEST_MODULES=test_sram
make -B TOPLEVEL=tb_mnist_loader COCOTB_TEST_MODULES=test_mnist_loader