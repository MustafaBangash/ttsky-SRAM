# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_row_decoder_simple(dut):
    """Simple test with just 3 addresses for easy waveform viewing"""
    dut._log.info("Start - Simple row decoder test")

    # Initialize - everything off
    dut.enable.value = 0
    dut.addr.value = 0
    await Timer(10, unit='ns')
    dut._log.info("Initial state: enable=0")

    # Test 1: Address 5 with enable LOW (should see no output)
    dut.addr.value = 5
    await Timer(10, unit='ns')
    assert dut.row_select.value == 0, "Enable=0 should produce no output"
    dut._log.info("✓ Test 1: Enable=0, addr=5, no rows selected")

    # Test 2: Address 5 with enable HIGH (should select row 5)
    dut.enable.value = 1
    await Timer(10, unit='ns')
    expected = 1 << 5  # Row 5 = bit 5 = 0x20
    assert int(dut.row_select.value) == expected, f"Expected row 5, got {hex(dut.row_select.value)}"
    dut._log.info(f"✓ Test 2: Enable=1, addr=5, row_select=0x{expected:016x}")

    # Test 3: Address 15 with enable HIGH (should select row 15)
    dut.addr.value = 15
    await Timer(10, unit='ns')
    expected = 1 << 15  # Row 15 = bit 15 = 0x8000
    assert int(dut.row_select.value) == expected, f"Expected row 15, got {hex(dut.row_select.value)}"
    dut._log.info(f"✓ Test 3: Enable=1, addr=15, row_select=0x{expected:016x}")

    # Test 4: Address 63 with enable HIGH (should select row 63 - last row)
    dut.addr.value = 63
    await Timer(10, unit='ns')
    expected = 1 << 63  # Row 63 = bit 63 (MSB)
    assert int(dut.row_select.value) == expected, f"Expected row 63, got {hex(dut.row_select.value)}"
    dut._log.info(f"✓ Test 4: Enable=1, addr=63, row_select=0x{expected:016x}")

    # Test 5: Disable again
    dut.enable.value = 0
    await Timer(10, unit='ns')
    assert dut.row_select.value == 0, "Enable=0 should produce no output"
    dut._log.info("✓ Test 5: Enable=0, all rows deselected")

    dut._log.info("All tests passed!")

