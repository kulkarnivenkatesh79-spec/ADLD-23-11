# ADLD-23-11
# ADLD-23-11: 24-Hour Digital Clock (ASIC RTL Design)

A 24-hour digital clock (**HH:MM:SS**) written in synthesizable Verilog, as a five-member team project for the Digital System Design / ASIC Design course.

**Faculty guide:** Prof. Ajaykumar Devarapalli, Assistant Professor, Department of Electronics and Communication Engineering, BMS College of Engineering, Bengaluru

---

## Specification

| Item | Value |
|---|---|
| Hours | 00 to 23 |
| Minutes / Seconds | 00 to 59 |
| Clock | One system clock (`clk`) |
| Reset | `rst_n`, active-low, asynchronous |
| Counter carries | One-cycle enable pulses (no generated clocks) |
| Output | Six 4-bit BCD digits |

## Repository structure

```
ADLD-23-11/
├── Member 1/   tick_gen.v            tb_tick_gen.v
├── Member 2/   seconds_counter.v     tb_seconds_counter.v
├── Member 3/   minutes_counter.v     tb_minutes_counter.v
├── Member 4/   hours_counter.v       tb_hours_counter.v
├── Member 5/   display_ctrl.v        tb_display_ctrl.v
│               digital_clock_top.v   tb_digital_clock_top.v
└── README.md
```

## Team and responsibilities

| Member | Name | Module | Responsibility |
|---|---|---|---|
| 1 | _your name_ | `tick_gen` | Clock divider, one-second tick |
| 2 | _your name_ | `seconds_counter` | Seconds 0 to 59, minute carry (`min_tick`) |
| 3 | _your name_ | `minutes_counter` | Minutes 0 to 59, hour carry (`hour_tick`) |
| 4 | _your name_ | `hours_counter` | Hours 0 to 23 |
| 5 | _your name_ | `display_ctrl`, `digital_clock_top` | Binary-to-BCD, top-level integration |

## Architecture

```
clk, rst_n
    |
[ tick_gen ] --tick_1s--> [ seconds_counter ] --min_tick--> [ minutes_counter ]
                                  |                                  |
                             sec_count                  --hour_tick--> [ hours_counter ]
                                  |                       min_count          |
                                  |                          |          hour_count
                                  +-----------+--------------+--------------+
                                              |
                                      [ display_ctrl ]
                                              |
                                   HH : MM : SS  (6 x BCD)
```

## Module interfaces (frozen)

| Module | Inputs | Outputs |
|---|---|---|
| `tick_gen` (param `CLK_FREQ_HZ`) | `clk`, `rst_n` | `tick_1s` |
| `seconds_counter` | `clk`, `rst_n`, `tick_1s` | `sec_count[5:0]`, `min_tick` |
| `minutes_counter` | `clk`, `rst_n`, `min_tick` | `min_count[5:0]`, `hour_tick` |
| `hours_counter` | `clk`, `rst_n`, `hour_tick` | `hour_count[4:0]` |
| `display_ctrl` | `hour_count[4:0]`, `min_count[5:0]`, `sec_count[5:0]` | `hour_tens`, `hour_ones`, `min_tens`, `min_ones`, `sec_tens`, `sec_ones` (each 4 bits) |
| `digital_clock_top` (param `CLK_FREQ_HZ`) | `clk`, `rst_n` | the six BCD digits |

**Change-control rule:** no one renames a port, changes a width, or alters an interface alone. Changes need team approval and must be applied to the module, the top level, and all affected testbenches.

## How to simulate

### EDA Playground (browser)

1. Open [edaplayground.com](https://www.edaplayground.com), choose **SystemVerilog/Verilog** and **Icarus Verilog 12.0**.
2. Paste all the RTL modules (every `.v` file that is not a `tb_`) into the **design** pane.
3. Paste one testbench into the **testbench** pane.
4. Tick **Open EPWave after run** and click **Run**.

A passing run prints `PASS: ...` (or `ALL TESTS PASSED: tb_digital_clock_top` for the full system).

### Icarus Verilog (local)

```bash
# Unit tests (run from the repository root)
iverilog -g2012 -o sim "Member 1/tick_gen.v"        "Member 1/tb_tick_gen.v"        && vvp sim
iverilog -g2012 -o sim "Member 2/seconds_counter.v" "Member 2/tb_seconds_counter.v" && vvp sim
iverilog -g2012 -o sim "Member 3/minutes_counter.v" "Member 3/tb_minutes_counter.v" && vvp sim
iverilog -g2012 -o sim "Member 4/hours_counter.v"   "Member 4/tb_hours_counter.v"   && vvp sim
iverilog -g2012 -o sim "Member 5/display_ctrl.v"    "Member 5/tb_display_ctrl.v"    && vvp sim

# Full system
iverilog -g2012 -o sim \
  "Member 1/tick_gen.v" "Member 2/seconds_counter.v" "Member 3/minutes_counter.v" \
  "Member 4/hours_counter.v" "Member 5/display_ctrl.v" "Member 5/digital_clock_top.v" \
  "Member 5/tb_digital_clock_top.v" && vvp sim

gtkwave dump.vcd   # view waveforms
```

In the testbenches, `CLK_FREQ_HZ` is overridden with a small value (a "second" is 4 to 10 clock cycles) so that simulation finishes quickly.

## Verification checklist

| Test | Expected result | Status |
|---|---|---|
| Apply reset | Counters initialise to 00:00:00 | Pass |
| Seconds increment | Seconds change only when `tick_1s` is high | Pass |
| Seconds rollover | 00:00:59 → 00:01:00 | Pass |
| Minutes rollover | 00:59:59 → 01:00:00 | Pass |
| Day rollover | 23:59:59 → 00:00:00 | Pass |
| Hour range | Hours never exceed 23 | Pass |
| Minute / second range | Never exceed 59 | Pass |
| BCD conversion | 14:35:48 → 1, 4, 3, 5, 4, 8 | Pass |
| Carry pulse width | `min_tick` and `hour_tick` are one clock wide | Pass |

## ASIC flow (next steps)

This repository contains the RTL and simulation only. The physical implementation uses an open-source flow:

1. Choose a PDK (for example Sky130) and record tool versions
2. Write timing constraints (SDC)
3. Synthesis with **Yosys**
4. Static timing analysis with **OpenSTA**
5. Floorplan, placement, CTS, and routing with **OpenLane / OpenROAD**
6. Layout inspection and physical verification with **Magic / KLayout**

## Notes

- The carry pulses are registered, so minutes and hours update 1 to 2 clock cycles after the seconds roll over. This causes brief intermediate display values (such as `00:59:00` between `00:59:59` and `01:00:00`), which is not visible at a 50 MHz clock.
- Default `CLK_FREQ_HZ` is `50000000` (50 MHz). Set it to match your board's clock.

## License

Academic project. Add a license of your choice before sharing outside the course.
