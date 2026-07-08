# UVM Verification and Synthesis of a Parameterized Synchronous FIFO

A complete RTL-to-GDS verification project implementing a parameterized **Synchronous FIFO** in Verilog and verifying its functionality using a reusable **SystemVerilog UVM Testbench**. The verified RTL is synthesized using **Yosys**, mapped to the **Sky130 HD Standard Cell Library**, and analyzed using **OpenSTA** for timing and power estimation.Then Using OpenROAD and KLayout final GDS file is created and Post layout STA is done to verify its functionality.

---

## Project Overview

This project demonstrates a complete front-end ASIC design flow:


RTL Design (Verilog)
        │
        ▼
UVM Verification
        │
        ▼
Functional Coverage
        │
        ▼
Logic Synthesis (Yosys)
        │
        ▼
Sky130 Standard Cell Mapping
        │
        ▼
Static Timing Analysis (OpenSTA)


---

# Design Specifications

| Feature | Value |
|----------|-------|
| Design | Synchronous FIFO |
| Language | Verilog HDL |
| Data Width | 8 bits |
| FIFO Depth | 8 Entries |
| Reset | Active-Low Asynchronous |
| Memory | Register Array |
| Read Type | Registered Read |
| Parameterized | Yes |

---

# UVM Verification Environment

The verification environment was developed completely from scratch using **UVM 1.2**.

## Testbench Architecture

``
                    +------------------+
                    |    fifo_test     |
                    +---------+--------+
                              |
                    +---------v--------+
                    |     fifo_env     |
                    +---------+--------+
                              |
                +-------------+-------------+
                |                           |
         +------v------+            +-------v--------+
         | fifo_agent  |            | fifo_scoreboard|
         +------+------|            +-------+--------+
                |                           ^
        +-------+--------+                  |
        |                |                  |
+-------v------+  +------v------+           |
| Sequencer    |  |  Monitor    +-----------+
+-------+------+  +------+------+
        |                |
+-------v------+         |
|   Driver     |---------+
+-------+------+
        |
        ▼
      FIFO DUT


---

# UVM Components

### Transaction (`fifo_trans`)

Contains:

- Reset
- Write Enable
- Read Enable
- Input Data
- Output Data
- Full Flag
- Empty Flag

---

### Sequences

Implemented verification sequences include:

- Reset Sequence
- Write Sequence
- Read Sequence
- Overflow Sequence
- Underflow Sequence
- Random Sequence
- Simultaneous Read/Write Sequence

---

### Driver

- Receives transactions from the sequencer
- Drives DUT inputs through a virtual interface
- Synchronizes all transactions with the system clock

---

### Monitor

- Samples DUT interface every clock cycle
- Converts signal activity into transactions
- Broadcasts transactions using an Analysis Port

---

### Scoreboard

A self-checking reference model implemented using a SystemVerilog queue.

Functions:

- Reference FIFO Modeling
- FIFO Ordering Verification
- Automatic Data Comparison
- Reset Handling
- PASS/FAIL Reporting

---

### Functional Coverage

Coverpoints:

- Write Enable
- Read Enable
- Reset
- Full Flag
- Empty Flag

Cross Coverage:

- Read × Write
- Write × Full (Overflow)
- Read × Empty (Underflow)

Achieved Functional Coverage:


96.88%


---

# Verification Scenarios

## Basic FIFO Operation

- Reset FIFO
- Write Data
- Read Data
- Verify FIFO Ordering

---

## Overflow Test

- Fill FIFO completely
- Attempt an additional write
- Verify write is blocked while Full remains asserted

---

## Underflow Test

- Reset FIFO
- Attempt read on Empty FIFO
- Verify FIFO contents remain unchanged

---

## Simultaneous Read / Write

- Read and Write enabled together
- Verify simultaneous operation

---

## Random Verification

Constrained-random stimulus including:

- Random Writes
- Random Reads
- Idle Cycles
- Simultaneous Transactions

---

# Logic Synthesis

RTL synthesis was performed using **Yosys**.

### Technology Library


SkyWater SKY130 HD Standard Cell Library
sky130_fd_sc_hd__tt_025C_1v80.lib


### Synthesis Flow

read_verilog
hierarchy
proc
opt
fsm
memory
techmap
abc
clean
stat
write_verilog



## Synthesized Design Statistics

| Metric | Value |
|---------|-------|
| Wires | 170 |
| Wire Bits | 248 |
| Cells | 236 |
| D Flip-Flops | 75 |
| Multiplexers | 64 |
| Logic Gates | NAND, NOR, XOR, AOI, OAI, MUX |
| Memories | 0 (mapped to registers) |

### Chip Area


2926.56 µm²




# Static Timing Analysis

Timing analysis performed using **OpenSTA**.

Clock Constraint:


Clock Period : 10 ns
Frequency    : 100 MHz


### Setup Analysis


Worst Setup Slack

+6.08 ns

Status : PASSED


### Hold Analysis

Worst Hold Slack

+0.41 ns

Status : PASSED


# Power Estimation

| Category | Percentage |
|----------|------------|
| Sequential | 55.5 % |
| Combinational | 44.5 % |

### Total Estimated Power

964 µW

# ⚙️ Physical Design Flow (RTL-to-GDSII)

The physical implementation of the synchronous FIFO is carried out using the **OpenROAD-flow-scripts** framework targeting the **SkyWater SKY130 High Density (sky130_fd_sc_hd)** technology library. The complete RTL-to-GDSII flow includes synthesis, floorplanning, placement, clock tree synthesis, routing, timing analysis, and GDSII generation.

---

# 🏗️ Physical Design Flow

## 1. RTL Synthesis (Yosys)

The Verilog RTL is synthesized into a technology-mapped gate-level netlist using **Yosys**.

---

## 2. Floorplanning

The floorplan initializes the core dimensions and placement rows while targeting approximately **40% core utilization**.

Operations performed:

- Core area initialization
- Aspect ratio selection
- Standard cell row generation
- Tap cell insertion for latch-up prevention


## 3. Power Distribution Network (PDN)

A power delivery network is automatically generated.

Power routing includes:

- Metal1 horizontal power rails
- Metal4 power straps
- Metal5 global power routing

This ensures robust VDD/GND connectivity throughout the design.

## 4. Placement

Global placement is performed using the **Nesterov analytical placer**, followed by legalization to align standard cells with placement rows.

## 5. Clock Tree Synthesis (CTS)

A balanced clock distribution network is synthesized using dedicated clock buffer cells.

CTS minimizes:

- Clock Skew
- Clock Latency
- Clock Slew

while satisfying timing constraints.

---

## 6. Routing

Signal routing is completed using **TritonRoute**.

Routing stages include:

- Global Routing
- Detailed Routing
- DRC-aware optimization

The final routed DEF contains all signal interconnections.

---

## 7. Chip Finishing

Final physical cleanup includes:

- Removal of temporary filler cells
- Filler cell insertion
- Row continuity restoration

# 📉 Post-Layout Static Timing Analysis (STA)

Timing verification is performed using **OpenSTA** integrated within the OpenROAD flow.

Physical timing analysis is performed using:

- Technology LEF
- Cell LEF
- Liberty Timing Library
- Synthesized Netlist
- Routed DEF
- Timing Constraints (SDC)


## 📜 STA Verification Script


read_lef "flow/platforms/sky130hd/tech.lef"

read_lef "flow/platforms/sky130hd/sky130_fd_sc_hd_merged.lef"

read_liberty \
"flow/platforms/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_verilog \
"flow/results/sky130hd/synch_fifo/1_synth.v"

read_def "synch_fifo_layout.def"

link_design "synch_fifo_bram"

read_sdc "./synch_fifo.sdc"

set_propagated_clock [all_clocks]

report_checks \
-path_delay max \
-fields {slew cap input_pin incr delay} \
-digits 3

report_wns

report_tns

# 📊 Timing Results

Timing was analyzed for a **100 MHz clock**.

| Metric | Result |
|---------|---------|
| Clock Period | **10 ns** |
| Worst Negative Slack (WNS) | **0.000 ns** |
| Total Negative Slack (TNS) | **0.000 ns** |
| Setup Slack | **+6.118 ns** |
| Hold Slack | **+0.385 ns** |

The design successfully meets all setup and hold timing requirements under the specified timing constraints.

---

# 🔬 GDSII Generation

The routing stage generates a **DEF** file containing physical placement and routing information.

To create the final fabrication layout, the DEF database is merged with the Sky130 standard-cell GDS database using **KLayout**.


## 🛠️ Layout Merge Script


import pya

layout = pya.Layout()

layout.read("synch_fifo_layout.def")

layout.read(
"/flow/platforms/sky130hd/gds/sky130_fd_sc_hd.gds"
)

layout.write("synch_fifo_merged_final.gds")

print("Generated: synch_fifo_merged_final.gds")


Execute:

klayout -b -r merge_layout.py


# 👁️ Layout Visualization

Open the merged GDSII database using **KLayout**.


klayout synch_fifo_merged_final.gds

Recommended viewing settings:

- **Shift + O**
- Disable **Show Instance Names**
- Increase hierarchy depth (Up Arrow or Cell View Depth) for detailed inspection


# ✅ Project Status

- ✔ RTL Design Completed
- ✔ UVM Verification Completed
- ✔ Functional Coverage Achieved (~96.88%)
- ✔ Logic Synthesis (Yosys)
- ✔ Static Timing Analysis (OpenSTA)
- ✔ Physical Design (OpenROAD)
- ✔ GDSII Generation (KLayout)

# Tools Used

- Verilog HDL
- SystemVerilog
- UVM 1.2
- Yosys
- OpenSTA
- SkyWater SKY130 PDK
- GTKWave
- EDA Playground
- OpenROAD
- KLayout
