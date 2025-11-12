![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Single-Tile SRAM with 4-bit Words

A complete SRAM module designed for Tiny Tapeout, featuring a 64×64 bit array organized as 1024 words of 4 bits each.

- [Read the documentation for project](docs/info.md)
- [Component documentation](docs/SRAM_COMPONENTS.md)

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Set up your Verilog project

1. Add your Verilog files to the `src` folder.
2. Edit the [info.yaml](info.yaml) and update information about your project, paying special attention to the `source_files` and `top_module` properties. If you are upgrading an existing Tiny Tapeout project, check out our [online info.yaml migration tool](https://tinytapeout.github.io/tt-yaml-upgrade-tool/).
3. Edit [docs/info.md](docs/info.md) and add a description of your project.
4. Adapt the testbench to your design. See [test/README.md](test/README.md) for more information.

The GitHub action will automatically build the ASIC files using [LibreLane](https://www.zerotoasiccourse.com/terminology/librelane/).

## Enable GitHub actions to build the results page

- [Enabling GitHub Pages](https://tinytapeout.com/faq/#my-github-action-is-failing-on-the-pages-part)

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)

## Design Overview

### Architecture
- **Memory Array**: 64 rows × 64 columns (4096 bits total)
- **Organization**: 1024 words × 4 bits per word
- **Addressing**: 10-bit address (6 bits for row, 4 bits for column)
- **Operation**: 2-cycle read/write at 50MHz (40ns total latency)

### Components
1. **Row Decoder** (6:64): NOR-based predecoding with buffer chains
2. **Column Decoder** (4:16): Selects one of 16 4-bit words per row
3. **Column Mux** (64:4): 4 parallel 16:1 muxes for read path
4. **Write Drivers** (4→64): Differential bitline drivers with strong buffers
5. **Control FSM**: 2-cycle state machine for coordinating operations
6. **SRAM Core**: Top-level integration of all digital components

### Pin Mapping
- **Inputs** (16 pins total):
  - `ui_in[7:0]`, `uio_in[7:6]`: 10-bit address
  - `uio_in[3:0]`: 4-bit write data
  - `uio_in[4]`: ENABLE (chip select)
  - `uio_in[5]`: READ_NOT_WRITE (1=read, 0=write)
- **Outputs** (5 pins):
  - `uo_out[3:0]`: 4-bit read data
  - `uo_out[4]`: READY (operation complete)

### Operation
- **Write**: Address + data → 2 cycles → data stored, READY=1
- **Read**: Address → 2 cycles → data_out valid, READY=1
- **Throughput**: 25 million operations/second (50MHz ÷ 2 cycles)

## Testing

Run all tests:
```bash
cd test
make test_all  # Test all components
make           # Integration test
```

Test individual components:
```bash
make COMPONENT=row_decoder
make COMPONENT=column_decoder
make COMPONENT=column_mux
make COMPONENT=write_driver
```

View waveforms:
```bash
gtkwave waveforms/tb.vcd
```

## Test Results

✅ **All tests passing:**
- Row Decoder: PASS
- Column Decoder: PASS
- Column Mux: PASS
- Write Driver: PASS (with differential outputs)
- **Integration Test: PASS** (14 operations verified)

## For Tapeout

The design includes a behavioral memory model (`sram_array_stub`) for simulation. For tapeout, this should be replaced with:
- **Memory Array**: 64×64 6T SRAM cells (provided by analog team)
- **Sense Amplifiers**: 64 differential sense amps (provided by analog team)
- **Precharge/Equalization**: P/EQ circuitry for bitlines (provided by analog team)

Interface signals are already defined in `project.v` for easy integration.

## What next?

- [Submit your design to the next shuttle](https://app.tinytapeout.com/).
- Share your project on your social network of choice:
  - LinkedIn [#tinytapeout](https://www.linkedin.com/search/results/content/?keywords=%23tinytapeout) [@TinyTapeout](https://www.linkedin.com/company/100708654/)
  - Mastodon [#tinytapeout](https://chaos.social/tags/tinytapeout) [@matthewvenn](https://chaos.social/@matthewvenn)
  - X (formerly Twitter) [#tinytapeout](https://twitter.com/hashtag/tinytapeout) [@tinytapeout](https://twitter.com/tinytapeout)
  - Bluesky [@tinytapeout.com](https://bsky.app/profile/tinytapeout.com)
