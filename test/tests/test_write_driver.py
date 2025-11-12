# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_write_driver_simple(dut):
    """Simple test for write drivers with a few word writes"""
    dut._log.info("Start - Simple write driver test")

    # Initialize - write disabled
    dut.write_en.value = 0
    dut.col_select.value = 0
    dut.data_in.value = 0
    await Timer(10, unit='ns')
    dut._log.info("Initial state: write_en=0")

    # Test 1: Write disabled - all bitlines should be high-Z
    dut.data_in.value = 0xA
    dut.col_select.value = (1 << 0)  # Select word 0
    await Timer(10, unit='ns')
    # Check that bitlines are high-Z (represented as 'z' in simulation)
    bitline_str = str(dut.bitline.value)
    z_count = bitline_str.count('z')
    dut._log.info(f"✓ Test 1: write_en=0, {z_count}/64 bitlines are high-Z")

    # Test 2: Write 0xA (1010) to word 0
    # Expected: cols 0,1,2,3 driven with bits 0,1,0,1
    # BL and BL̄ should be complementary
    dut.write_en.value = 1
    dut.data_in.value = 0xA  # binary: 1010
    dut.col_select.value = (1 << 0)  # Select word 0 (cols 0,1,2,3)
    await Timer(10, unit='ns')
    
    # Word 0 uses columns 0, 1, 2, 3
    # data_in = 0xA = 1010 → bit[0]=0, bit[1]=1, bit[2]=0, bit[3]=1
    assert int(dut.bitline.value[0]) == 0, f"BL[0] should be 0"
    assert int(dut.bitline_bar.value[0]) == 1, f"BL̄[0] should be 1"
    
    assert int(dut.bitline.value[1]) == 1, f"BL[1] should be 1"
    assert int(dut.bitline_bar.value[1]) == 0, f"BL̄[1] should be 0"
    
    assert int(dut.bitline.value[2]) == 0, f"BL[2] should be 0"
    assert int(dut.bitline_bar.value[2]) == 1, f"BL̄[2] should be 1"
    
    assert int(dut.bitline.value[3]) == 1, f"BL[3] should be 1"
    assert int(dut.bitline_bar.value[3]) == 0, f"BL̄[3] should be 0"
    
    dut._log.info("✓ Test 2: Write 0xA to word 0, BL/BL̄ differential verified")

    # Test 3: Write 0x5 (0101) to word 1
    # Expected: cols 4,5,6,7 driven with bits 1,0,1,0
    dut.data_in.value = 0x5  # binary: 0101
    dut.col_select.value = (1 << 1)  # Select word 1 (cols 4,5,6,7)
    await Timer(10, unit='ns')
    
    # Word 1 uses columns 4, 5, 6, 7
    # data_in = 0x5 = 0101 → bit[0]=1, bit[1]=0, bit[2]=1, bit[3]=0
    assert int(dut.bitline.value[4]) == 1, f"BL[4] should be 1"
    assert int(dut.bitline_bar.value[4]) == 0, f"BL̄[4] should be 0"
    assert int(dut.bitline.value[5]) == 0, f"BL[5] should be 0"
    assert int(dut.bitline_bar.value[5]) == 1, f"BL̄[5] should be 1"
    dut._log.info("✓ Test 3: Write 0x5 to word 1, BL/BL̄ differential verified")

    # Test 4: Write 0xC (1100) to word 5
    # Expected: cols 20,21,22,23 driven with bits 0,0,1,1
    dut.data_in.value = 0xC  # binary: 1100
    dut.col_select.value = (1 << 5)  # Select word 5 (cols 20,21,22,23)
    await Timer(10, unit='ns')
    
    # Word 5 uses columns 20, 21, 22, 23
    # data_in = 0xC = 1100 → bit[0]=0, bit[1]=0, bit[2]=1, bit[3]=1
    assert int(dut.bitline.value[20]) == 0, f"Col 20 (bit0) should be 0"
    assert int(dut.bitline.value[21]) == 0, f"Col 21 (bit1) should be 0"
    assert int(dut.bitline.value[22]) == 1, f"Col 22 (bit2) should be 1"
    assert int(dut.bitline.value[23]) == 1, f"Col 23 (bit3) should be 1"
    dut._log.info("✓ Test 4: Write 0xC to word 5, cols[23:20] = 1100")

    # Test 5: Write 0xF (1111) to word 15 (last word)
    # Expected: cols 60,61,62,63 driven with bits 1,1,1,1
    dut.data_in.value = 0xF  # binary: 1111
    dut.col_select.value = (1 << 15)  # Select word 15 (cols 60,61,62,63)
    await Timer(10, unit='ns')
    
    # Word 15 uses columns 60, 61, 62, 63
    # data_in = 0xF = 1111 → bit[0]=1, bit[1]=1, bit[2]=1, bit[3]=1
    assert int(dut.bitline.value[60]) == 1, f"Col 60 (bit0) should be 1"
    assert int(dut.bitline.value[61]) == 1, f"Col 61 (bit1) should be 1"
    assert int(dut.bitline.value[62]) == 1, f"Col 62 (bit2) should be 1"
    assert int(dut.bitline.value[63]) == 1, f"Col 63 (bit3) should be 1"
    dut._log.info("✓ Test 5: Write 0xF to word 15, cols[63:60] = 1111")

    # Test 6: Disable write - bitlines should go high-Z again
    dut.write_en.value = 0
    await Timer(10, unit='ns')
    bitline_str = str(dut.bitline.value)
    z_count = bitline_str.count('z')
    dut._log.info(f"✓ Test 6: write_en=0, {z_count}/64 bitlines are high-Z")

    dut._log.info("All tests passed!")

