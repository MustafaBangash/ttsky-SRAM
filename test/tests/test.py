# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


def set_pins(dut, addr, data_in, enable, read_not_write):
    """Helper function to set SRAM pins according to pinout."""
    # ui_in[7:0] = ADDR[7:0]
    dut.ui_in.value = addr & 0xFF
    
    # uio_in[7:6] = ADDR[9:8]
    # uio_in[5] = READ_NOT_WRITE
    # uio_in[4] = ENABLE
    # uio_in[3:0] = DATA_IN[3:0]
    uio_val = ((addr >> 8) << 6) | (read_not_write << 5) | (enable << 4) | (data_in & 0xF)
    dut.uio_in.value = uio_val


def get_data_out(dut):
    """Helper function to read data output."""
    # uo_out[3:0] = DATA_OUT[3:0]
    return int(dut.uo_out.value) & 0xF


def get_ready(dut):
    """Helper function to read ready signal."""
    # uo_out[4] = READY
    return (int(dut.uo_out.value) >> 4) & 0x1


@cocotb.test()
async def test_sram_basic(dut):
    """Test basic SRAM write and read operations."""
    
    dut._log.info("=" * 60)
    dut._log.info("SRAM Integration Test - 2-Cycle @ 50MHz")
    dut._log.info("=" * 60)

    # Set the clock period to 20 ns (50 MHz)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Applying reset...")
    dut.ena.value = 1
    set_pins(dut, addr=0, data_in=0, enable=0, read_not_write=0)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    dut._log.info("✓ Reset complete")

    # ==========================================================================
    # Test 1: Write to several addresses
    # ==========================================================================
    dut._log.info("\n[Test 1] Writing data to memory...")
    
    test_data = [
        (0x000, 0xA),  # Address 0x000 → data 0xA (1010)
        (0x001, 0x5),  # Address 0x001 → data 0x5 (0101)
        (0x010, 0xC),  # Address 0x010 → data 0xC (1100)
        (0x0FF, 0x3),  # Address 0x0FF → data 0x3 (0011)
        (0x3FF, 0xF),  # Address 0x3FF → data 0xF (1111)
    ]
    
    for addr, data in test_data:
        dut._log.info(f"  Writing 0x{data:X} to address 0x{addr:03X}")
        set_pins(dut, addr=addr, data_in=data, enable=1, read_not_write=0)
        
        # Write takes 2 cycles, wait one more to sample outputs
        await ClockCycles(dut.clk, 3)
        
        # Check READY signal (should be high at end of CYCLE2)
        ready = get_ready(dut)
        assert ready == 1, f"READY should be 1 after write, got {ready}"
        
        # Disable after operation
        set_pins(dut, addr=0, data_in=0, enable=0, read_not_write=0)
        await ClockCycles(dut.clk, 1)
    
    dut._log.info("✓ All writes complete\n")

    # ==========================================================================
    # Test 2: Read back and verify
    # ==========================================================================
    dut._log.info("[Test 2] Reading data from memory...")
    
    for addr, expected_data in test_data:
        set_pins(dut, addr=addr, data_in=0, enable=1, read_not_write=1)
        
        # Read takes 2 cycles, wait one more to sample outputs
        await ClockCycles(dut.clk, 3)
        
        # Check READY and data
        ready = get_ready(dut)
        data_out = get_data_out(dut)
        
        dut._log.info(f"  Address 0x{addr:03X}: read 0x{data_out:X}, expected 0x{expected_data:X}")
        
        assert ready == 1, f"READY should be 1 after read, got {ready}"
        assert data_out == expected_data, f"Data mismatch at 0x{addr:03X}: got 0x{data_out:X}, expected 0x{expected_data:X}"
        
        # Disable after operation
        set_pins(dut, addr=0, data_in=0, enable=0, read_not_write=0)
        await ClockCycles(dut.clk, 1)
    
    dut._log.info("✓ All reads verified\n")

    # ==========================================================================
    # Test 3: Overwrite and verify
    # ==========================================================================
    dut._log.info("[Test 3] Testing overwrite...")
    
    addr = 0x000
    original_data = 0xA
    new_data = 0x6
    
    # Write new data
    dut._log.info(f"  Overwriting address 0x{addr:03X}: 0x{original_data:X} → 0x{new_data:X}")
    set_pins(dut, addr=addr, data_in=new_data, enable=1, read_not_write=0)
    await ClockCycles(dut.clk, 3)
    set_pins(dut, addr=0, data_in=0, enable=0, read_not_write=0)
    await ClockCycles(dut.clk, 1)
    
    # Read back
    set_pins(dut, addr=addr, data_in=0, enable=1, read_not_write=1)
    await ClockCycles(dut.clk, 3)
    data_out = get_data_out(dut)
    
    assert data_out == new_data, f"Overwrite failed: got 0x{data_out:X}, expected 0x{new_data:X}"
    dut._log.info(f"  Verified: 0x{data_out:X} = 0x{new_data:X}")
    dut._log.info("✓ Overwrite verified\n")

    # ==========================================================================
    # Test 4: Back-to-back operations
    # ==========================================================================
    dut._log.info("[Test 4] Testing back-to-back operations...")
    
    # Write
    set_pins(dut, addr=0x100, data_in=0x9, enable=1, read_not_write=0)
    await ClockCycles(dut.clk, 3)
    
    # Immediately start read (no idle cycle)
    set_pins(dut, addr=0x100, data_in=0, enable=1, read_not_write=1)
    await ClockCycles(dut.clk, 3)
    data_out = get_data_out(dut)
    
    assert data_out == 0x9, f"Back-to-back failed: got 0x{data_out:X}, expected 0x9"
    dut._log.info("✓ Back-to-back operations work\n")

    # ==========================================================================
    # Summary
    # ==========================================================================
    dut._log.info("=" * 60)
    dut._log.info("✅ ALL SRAM INTEGRATION TESTS PASSED")
    dut._log.info("=" * 60)
    dut._log.info(f"Total operations: {len(test_data) * 2 + 4}")
    dut._log.info("SRAM is fully functional!")
    dut._log.info("=" * 60)
