# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_column_decoder_simple(dut):
    """Simple test with 3 addresses for easy waveform viewing"""
    dut._log.info("Start - Simple column decoder test")

    # Initialize - everything off
    dut.enable.value = 0
    dut.addr.value = 0
    await Timer(10, unit='ns')
    dut._log.info("Initial state: enable=0")

    # Test 1: Address 3 with enable LOW (should see no output)
    dut.addr.value = 3
    await Timer(10, unit='ns')
    assert dut.col_select.value == 0, "Enable=0 should produce no output"
    dut._log.info("✓ Test 1: Enable=0, addr=3, no columns selected")

    # Test 2: Address 3 with enable HIGH (should select column 3)
    dut.enable.value = 1
    await Timer(10, unit='ns')
    expected = 1 << 3  # Column 3 = bit 3 = 0x08
    assert int(dut.col_select.value) == expected, f"Expected col 3, got {hex(dut.col_select.value)}"
    dut._log.info(f"✓ Test 2: Enable=1, addr=3, col_select=0x{expected:04x}")

    # Test 3: Address 7 with enable HIGH (should select column 7)
    dut.addr.value = 7
    await Timer(10, unit='ns')
    expected = 1 << 7  # Column 7 = bit 7 = 0x80
    assert int(dut.col_select.value) == expected, f"Expected col 7, got {hex(dut.col_select.value)}"
    dut._log.info(f"✓ Test 3: Enable=1, addr=7, col_select=0x{expected:04x}")

    # Test 4: Address 15 with enable HIGH (should select column 15 - last column)
    dut.addr.value = 15
    await Timer(10, unit='ns')
    expected = 1 << 15  # Column 15 = bit 15 = 0x8000
    assert int(dut.col_select.value) == expected, f"Expected col 15, got {hex(dut.col_select.value)}"
    dut._log.info(f"✓ Test 4: Enable=1, addr=15, col_select=0x{expected:04x}")

    # Test 5: Disable again
    dut.enable.value = 0
    await Timer(10, unit='ns')
    assert dut.col_select.value == 0, "Enable=0 should produce no output"
    dut._log.info("✓ Test 5: Enable=0, all columns deselected")

    dut._log.info("All tests passed!")

