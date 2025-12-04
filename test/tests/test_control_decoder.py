"""
Simple test for 3:8 control decoder
"""
import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_control_decoder(dut):
    """Test all 8 outputs of 3:8 decoder"""
    
    dut._log.info("Testing 3:8 Control Decoder")
    dut._log.info("=" * 60)
    
    # Test all 8 address combinations
    for addr in range(8):
        dut.enable.value = 1
        dut.addr.value = addr
        
        await Timer(1, units='ns')  # Let combinational logic settle
        
        out = int(dut.out.value)
        
        # Check that only the correct bit is high (one-hot)
        expected = 1 << addr
        
        dut._log.info(f"addr={addr:03b} → out={out:08b} (expected {expected:08b})")
        
        assert out == expected, f"Expected out[{addr}]=1 only, got {out:08b}"
    
    # Test with enable = 0
    dut.enable.value = 0
    dut.addr.value = 0b101
    await Timer(1, units='ns')
    
    out = int(dut.out.value)
    dut._log.info(f"enable=0 → out={out:08b} (expected 00000000)")
    assert out == 0, f"When enable=0, all outputs should be 0, got {out:08b}"
    
    dut._log.info("✅ All decoder tests passed!")

