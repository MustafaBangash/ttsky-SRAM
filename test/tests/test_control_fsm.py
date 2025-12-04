# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

"""
Test for SRAM Control FSM
Shows continuous operation - enable stays HIGH to see repeated 2-cycle operations
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


def log_state(dut, cycle_num, op_type=""):
    """Log current FSM state and all outputs"""
    state_names = {0: "IDLE", 1: "PRECH", 2: "DEVLP", 3: "SENSE"}
    state = int(dut.state.value)
    state_name = state_names.get(state, "?")
    
    op = f" ({op_type})" if op_type else ""
    
    dut._log.info(
        f"Clk {cycle_num:2d} | {state_name:5s}{op:6s} | "
        f"pre={int(dut.precharge_enable.value)} row={int(dut.row_enable.value)} "
        f"rd={int(dut.read_enable.value)} wr={int(dut.write_enable.value)} "
        f"rdy={int(dut.ready.value)}"
    )


@cocotb.test()
async def test_control_fsm_waveforms(dut):
    """
    FSM test: Robust 3-cycle timing for reliable SRAM operation.
    
    Each operation = 3 cycles:
      PRECHARGE: Bitlines equalize
      DEVELOP:   Wordline ON, ΔV develops
      SENSE:     Sense amp fires / write drivers active
    """
    
    dut._log.info("=" * 70)
    dut._log.info("SRAM Control FSM - Robust 3-Cycle Design")
    dut._log.info("=" * 70)
    dut._log.info("Each operation takes 3 clock cycles:")
    dut._log.info("  PRECHARGE: pre=1, row=0 (bitlines equalize)")
    dut._log.info("  DEVELOP:   pre=0, row=1 (ΔV develops on bitlines)")
    dut._log.info("  SENSE:     pre=0, row=1, rd=1 (sense amp fires)")
    dut._log.info("=" * 70)
    
    # 50MHz clock
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())
    
    cycle = 0
    
    # Quick reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.read_not_write.value = 1  # Start with READ
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    cycle = 1
    
    dut._log.info("\n--- After reset (IDLE) ---")
    await Timer(1, unit="ns")
    log_state(dut, cycle)
    
    # =========================================================================
    # READ operations (2 reads)
    # =========================================================================
    dut._log.info("\n--- 2 READs (3 cycles each) ---")
    dut.enable.value = 1
    dut.read_not_write.value = 1  # READ
    
    for read_num in range(2):
        # PRECHARGE
        await ClockCycles(dut.clk, 1)
        cycle += 1
        await Timer(1, unit="ns")
        log_state(dut, cycle, f"RD{read_num+1}")
        
        # DEVELOP - ΔV develops
        await ClockCycles(dut.clk, 1)
        cycle += 1
        await Timer(1, unit="ns")
        log_state(dut, cycle, f"RD{read_num+1}")
        
        # SENSE - data valid!
        await ClockCycles(dut.clk, 1)
        cycle += 1
        await Timer(1, unit="ns")
        log_state(dut, cycle, f"RD{read_num+1}")
    
    # =========================================================================
    # Switch to WRITE
    # =========================================================================
    dut._log.info("\n--- 2 WRITEs (3 cycles each) ---")
    dut.read_not_write.value = 0  # WRITE
    
    for write_num in range(2):
        # PRECHARGE
        await ClockCycles(dut.clk, 1)
        cycle += 1
        await Timer(1, unit="ns")
        log_state(dut, cycle, f"WR{write_num+1}")
        
        # DEVELOP
        await ClockCycles(dut.clk, 1)
        cycle += 1
        await Timer(1, unit="ns")
        log_state(dut, cycle, f"WR{write_num+1}")
        
        # SENSE/WRITE - write happens!
        await ClockCycles(dut.clk, 1)
        cycle += 1
        await Timer(1, unit="ns")
        log_state(dut, cycle, f"WR{write_num+1}")
    
    # =========================================================================
    # Disable - return to IDLE
    # =========================================================================
    dut._log.info("\n--- Disable (return to IDLE) ---")
    dut.enable.value = 0
    
    await ClockCycles(dut.clk, 1)
    cycle += 1
    await Timer(1, unit="ns")
    log_state(dut, cycle)
    
    # =========================================================================
    # Summary
    # =========================================================================
    dut._log.info("\n" + "=" * 70)
    dut._log.info("✅ FSM TEST COMPLETE")
    dut._log.info("=" * 70)
    dut._log.info("Robust 3-cycle timing:")
    dut._log.info("  • PRECHARGE: pre=1, row=0 (20ns to equalize)")
    dut._log.info("  • DEVELOP:   pre=0, row=1 (20ns for ΔV)")
    dut._log.info("  • SENSE:     pre=0, row=1, rd=1 (20ns to sense)")
    dut._log.info("  • Total: 60ns per operation @ 50MHz")
    dut._log.info("=" * 70)

