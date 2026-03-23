#!/usr/bin/bash

cd /workspaces/binaryneuralnet-asic-TTIHP26/test

# Run all the tests
make -B TOPLEVEL=tb COCOTB_TEST_MODULES=test
make -B TOPLEVEL=tb_counter4bit COCOTB_TEST_MODULES=test_counter4bit
make -B TOPLEVEL=tb_sram COCOTB_TEST_MODULES=test_sram
make -B TOPLEVEL=tb_mnist_loader COCOTB_TEST_MODULES=test_mnist_loader
make -B TOPLEVEL=tb_load_conv_op COCOTB_TEST_MODULES=test_load_conv_op
make -B TOPLEVEL=tb_conv_weights_3x3_l1 COCOTB_TEST_MODULES=test_conv_weights_3x3_l1
make -B TOPLEVEL=tb_conv_layer1 COCOTB_TEST_MODULES=test_conv_layer1
make -B TOPLEVEL=tb_maxpool_layer1 COCOTB_TEST_MODULES=test_maxpool_layer1
make -B TOPLEVEL=tb_classification_tree COCOTB_TEST_MODULES=test_classification_tree
make -B TOPLEVEL=tb_main_full COCOTB_TEST_MODULES=test_full_pipeline