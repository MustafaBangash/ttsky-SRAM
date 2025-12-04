# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, RisingEdge, FallingEdge


def set_pins(dut, addr, data_in, enable, read_not_write):
    """Helper function to set SRAM pins according to pinout."""
    dut.ui_in.value = addr & 0xFF
    uio_val = ((addr >> 8) << 6) | (read_not_write << 5) | (enable << 4) | (data_in & 0xF)
    dut.uio_in.value = uio_val


def get_data_out(dut):
    """Helper function to read data output."""
    return int(dut.uo_out.value) & 0xF


def get_ready(dut):
    """Helper function to read ready signal."""
    return (int(dut.uo_out.value) >> 4) & 0x1


@cocotb.test()
async def test_sram_basic(dut):
    """Test SRAM with proper timing for 3-cycle FSM.
    
    CRITICAL TIMING:
    - Write: 4 cycles needed (3 to reach SENSE, +1 for write to complete)
    - Read:  3 cycles needed (data valid once in SENSE)
    - Set inputs on falling edge to avoid clock-edge race conditions
    """
    
    dut._log.info("=" * 60)
    dut._log.info("SRAM Integration Test - 3-Cycle FSM @ 50MHz")
    dut._log.info("=" * 60)

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
    await FallingEdge(dut.clk)  # Setup on falling edge, stable for next rising
    dut._log.info("✓ Reset complete, FSM in IDLE state")

    # ==========================================================================
    # Test 1: Write to several addresses
    # ==========================================================================
    dut._log.info("\n[Test 1] Writing data to memory...")
    
    test_data = [
        (0x000, 0xA),
        (0x001, 0x5),
        (0x010, 0xC),
        (0x0FF, 0x3),
        (0x3FF, 0xF),
    ]
    
    for addr, data in test_data:
        dut._log.info(f"  Writing 0x{data:X} to address 0x{addr:03X}")

        # Set inputs on falling edge (setup time before rising edge)
        set_pins(dut, addr=addr, data_in=data, enable=1, read_not_write=0)
        
        # Wait 3 cycles to reach SENSE state
        await ClockCycles(dut.clk, 3)
        
        # Disable enable only (keep addr and data valid for the write edge!)
        # The write happens on the NEXT rising edge while we're in SENSE
        await FallingEdge(dut.clk)
        # Only clear the enable bit, keep addr and data as-is
        current_uio = int(dut.uio_in.value)
        dut.uio_in.value = current_uio & ~0x10  # Clear enable bit only
        
        # Wait for write edge (SENSE→IDLE, write completes)
        await ClockCycles(dut.clk, 1)
        
        # Now safe to clear address and data
        set_pins(dut, addr=0, data_in=0, enable=0, read_not_write=0)
    
    dut._log.info("✓ All writes complete\n")

    # ==========================================================================
    # Test 2: Read back and verify
    # ==========================================================================
    dut._log.info("[Test 2] Reading data from memory...")
    
    for addr, expected_data in test_data:
        # Set inputs on falling edge
        await FallingEdge(dut.clk)
        set_pins(dut, addr=addr, data_in=0, enable=1, read_not_write=1)
        
        # Wait 3 cycles to reach SENSE state:
        # Rising 1: IDLE→PRECHARGE
        # Rising 2: PRECHARGE→DEVELOP
        # Rising 3: DEVELOP→SENSE (data now valid!)
        await ClockCycles(dut.clk, 3)
        
        # Small delay to let combinational logic settle
        await Timer(1, unit='ns')
        
        # Read data (valid in SENSE state)
        data_out = get_data_out(dut)
        ready = get_ready(dut)
        
        dut._log.info(f"  Address 0x{addr:03X}: read 0x{data_out:X}, expected 0x{expected_data:X}")
        
        assert ready == 1, f"READY should be 1 in SENSE state, got {ready}"
        assert data_out == expected_data, f"Data mismatch at 0x{addr:03X}: got 0x{data_out:X}, expected 0x{expected_data:X}"
        
        # Disable enable IMMEDIATELY to prevent SENSE→PRECHARGE on next edge
        set_pins(dut, addr=0, data_in=0, enable=0, read_not_write=0)
        
        # Wait for FSM to return to IDLE (SENSE→IDLE since enable=0)
    await ClockCycles(dut.clk, 1)

    dut._log.info("✓ All reads verified\n")

    # ==========================================================================
    # Test 3: Overwrite and verify
    # ==========================================================================
    dut._log.info("[Test 3] Testing overwrite...")
    
    addr = 0x000
    new_data = 0x6
    
    # Write (same pattern as Test 1)
    dut._log.info(f"  Overwriting address 0x{addr:03X} with 0x{new_data:X}")
    await FallingEdge(dut.clk)
    set_pins(dut, addr=addr, data_in=new_data, enable=1, read_not_write=0)
    await ClockCycles(dut.clk, 3)  # Reach SENSE
    await FallingEdge(dut.clk)
    # Only clear enable, keep addr and data valid for write
    current_uio = int(dut.uio_in.value)
    dut.uio_in.value = current_uio & ~0x10
    await ClockCycles(dut.clk, 1)  # Write completes
    set_pins(dut, addr=0, data_in=0, enable=0, read_not_write=0)
    
    # Read back (same pattern as Test 2)
    await FallingEdge(dut.clk)
    set_pins(dut, addr=addr, data_in=0, enable=1, read_not_write=1)
    await ClockCycles(dut.clk, 3)
    await Timer(1, unit='ns')
    data_out = get_data_out(dut)
    ready = get_ready(dut)
    set_pins(dut, addr=0, data_in=0, enable=0, read_not_write=0)
    await ClockCycles(dut.clk, 1)  # Return to IDLE
    
    dut._log.info(f"  Read back: 0x{data_out:X}, ready={ready}")
    assert data_out == new_data, f"Overwrite failed: got 0x{data_out:X}, expected 0x{new_data:X}"
    dut._log.info(f"  ✓ Verified: 0x{data_out:X}")
    dut._log.info("✓ Overwrite verified\n")

    # ==========================================================================
    # Summary
    # ==========================================================================
    dut._log.info("=" * 60)
    dut._log.info("✅ ALL SRAM INTEGRATION TESTS PASSED")
    dut._log.info("=" * 60)
    dut._log.info("Timing summary:")
    dut._log.info("  - Write: 4 cycles (80ns @ 50MHz)")
    dut._log.info("  - Read:  3 cycles (60ns @ 50MHz)")
    dut._log.info("=" * 60)
