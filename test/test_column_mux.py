# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_column_mux_simple(dut):
    """Simple test for column mux with a few word selections"""
    dut._log.info("Start - Simple column mux test")

    # Initialize - no column selected
    dut.col_select.value = 0
    dut.col_data.value = 0
    await Timer(10, unit='ns')
    dut._log.info("Initial state: no column selected")

    # Set up test data in columns
    # Word 0 (cols 3:0)   = 0xA
    # Word 1 (cols 7:4)   = 0x5
    # Word 5 (cols 23:20) = 0xC
    # Word 15 (cols 63:60) = 0xF
    test_data = 0
    test_data |= (0xA << 0)   # Word 0
    test_data |= (0x5 << 4)   # Word 1
    test_data |= (0xC << 20)  # Word 5
    test_data |= (0xF << 60)  # Word 15
    
    dut.col_data.value = test_data
    await Timer(10, unit='ns')

    # Test 1: Select word 0 (should output 0xA)
    dut.col_select.value = (1 << 0)
    await Timer(10, unit='ns')
    assert int(dut.data_out.value) == 0xA, f"Expected 0xA, got 0x{int(dut.data_out.value):x}"
    dut._log.info("✓ Test 1: Word 0 selected, data_out=0xA")

    # Test 2: Select word 1 (should output 0x5)
    dut.col_select.value = (1 << 1)
    await Timer(10, unit='ns')
    assert int(dut.data_out.value) == 0x5, f"Expected 0x5, got 0x{int(dut.data_out.value):x}"
    dut._log.info("✓ Test 2: Word 1 selected, data_out=0x5")

    # Test 3: Select word 5 (should output 0xC)
    dut.col_select.value = (1 << 5)
    await Timer(10, unit='ns')
    assert int(dut.data_out.value) == 0xC, f"Expected 0xC, got 0x{int(dut.data_out.value):x}"
    dut._log.info("✓ Test 3: Word 5 selected, data_out=0xC")

    # Test 4: Select word 15 (should output 0xF)
    dut.col_select.value = (1 << 15)
    await Timer(10, unit='ns')
    assert int(dut.data_out.value) == 0xF, f"Expected 0xF, got 0x{int(dut.data_out.value):x}"
    dut._log.info("✓ Test 4: Word 15 selected, data_out=0xF")

    # Test 5: No selection (should output 0)
    dut.col_select.value = 0
    await Timer(10, unit='ns')
    assert int(dut.data_out.value) == 0, f"Expected 0x0, got 0x{int(dut.data_out.value):x}"
    dut._log.info("✓ Test 5: No word selected, data_out=0x0")

    dut._log.info("All tests passed!")

