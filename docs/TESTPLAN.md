# I2C Verification Test Plan

## 1. Introduction

This document defines the verification strategy for the I2C (Inter-Integrated Circuit) UVM Verification IP (VIP) hosted in this workspace. The VIP is compliant with the **NXP I2C-bus specification (UM10204)** and now ships with two extensions whose correctness contracts are exercised under the same `i2c_env`:

- **Dual-role bus ownership** (published, IEEE Access 2026): single-agent role-flip with bus ownership invariants (BOIs).
- **Credit-based flow control** (submission, IEEE Access 2026): receiver-capacity contract enforced through six Transmit-Budget Invariants (TBI-1 through TBI-6) carried by a credit-aware UVM agent and a credit-aware RTL slave.

Source code, manuscripts, and the figure-generation scripts behind both extensions live at <https://github.com/tobliao/i2c_uvm>.

### 1.1 Scope

The verified feature set covers:

- **Roles**: Single Master, Single Slave, dual-role role-flip via the bus ownership invariant set.
- **Speeds**:
  - Standard-mode (Sm): 100 kbit/s.
  - Fast-mode (Fm): 400 kbit/s.
  - Fast-mode Plus (Fm+): 1 Mbit/s.
- **Addressing**: 7-bit and 10-bit addressing.
- **Protocol features**: Clock Stretching, Repeated Start, ACK/NACK handling, General Call.
- **Dual-role bus ownership extension**: BOI-1..BOI-N enforced by the dual-role monitor (see the dual-role manuscript at `paper/deterministic_dual_role_i2c_verification/access.tex`).
- **Credit-based flow control extension**: CBT credit-gated dispatch, CBR pipeline-delayed return, credit-aware monitor enforcing TBI-1 (non-negative balance), TBI-2 (capacity bound), TBI-3 (init-before-data ordering), TBI-4 (end-of-test balance), TBI-5 (bounded return latency), TBI-6 (phantom-credit rejection). Source-of-truth: `src/agent/i2c_credit_*.sv`, `rtl/i2c_credit_slave.sv`. Manuscript: `paper/credit_based_flow_control_verification/access.tex`.

### 1.2 Out of Scope (Future Work)

The following features are designed for, or proposed for, future revisions but are **not** currently verified in the active test suite:

- **Multi-Master Arbitration**: Logic for arbitration loss and back-off.
- **High-Speed Mode (Hs-mode)**: 3.4 Mbit/s signaling and master code logic.
- **Ultra Fast-mode (UFm)**: Unidirectional 5 Mbit/s.
- **Multi-receiver credit pools**: Per-endpoint credit pools for multi-receiver topologies. Today the credit extension verifies one CBR per `i2c_env`.
- **I3C dynamic address assignment**: ENTDAA / SETDASA / RSTDAA flows for an I3C extension of the credit framework.
- **Formal SVA proof of TBIs**: TBI-1..TBI-6 are enforced by the runtime credit monitor; a formal-proof companion using SystemVerilog Assertions is parked for a future revision.

---

## 2. Verification Strategy

Verification is performed using a **UVM-based constrained random environment**.

- **Stimulus**: UVM Sequences driving the Agent (acting as Master, Slave, or both via the dual-role role-flip). Credit-mode stimulus is driven by `i2c_credit_{base,burst,error}_sequence.sv`.
- **Checking**: Protocol Monitor for bus compliance checks; Scoreboard for data integrity; Credit Monitor (`src/agent/i2c_credit_monitor.sv`) for per-transaction TBI enforcement from a shadow counter reconstructed from the bus, independently of both drivers.
- **Coverage**:
  - **Functional Coverage**: Explicit covergroups for protocol states, address ranges, transaction types, credit frame types, credit FSM states, and credit FSM transitions.
  - **Code Coverage**: Line, Toggle, FSM, Condition, and Branch coverage enabled in simulation.
- **Mode selection**: Credit-mode is selected via `+CREDIT_MODE` on the simulator command line and `cfg.credit_mode_enable = 1`. Without the flag, the credit-aware drivers and monitor are not instantiated and the testbench behaves as the original dual-role VIP.

---

## 3. Test Cases

### 3.1 Basic Transport Tests (Sanity)

| Test ID | Test Name | Description | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- |
| **TP_001** | `sanity_wr_7bit` | Master writes 1 byte to a 7-bit Slave. Verify ACK and Stop. | **P0** | Basic Write, Addr Low Range |
| **TP_002** | `sanity_rd_7bit` | Master reads 1 byte from a 7-bit Slave. Verify ACK and Stop. | **P0** | Basic Read |
| **TP_003** | `sanity_wr_10bit` | Master writes 1 byte to a 10-bit Slave (2-byte address sequence). | **P1** | 10-bit Address |
| **TP_004** | `sanity_rd_10bit` | Master reads 1 byte from a 10-bit Slave (Write Address -> Sr -> Read). | **P1** | 10-bit Read path |

### 3.2 Transaction Types

| Test ID | Test Name | Description | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- |
| **TP_101** | `burst_write` | Master writes N bytes (random 2-128) in a single transaction. | **P1** | Burst Write, Size Bins |
| **TP_102** | `burst_read` | Master reads N bytes (random 2-128) in a single transaction. | **P1** | Burst Read |
| **TP_103** | `repeated_start` | Write transfer followed immediately by a Repeated Start (Sr) and another transfer. | **P1** | Repeated Start |
| **TP_104** | `mixed_transfers` | Random mix of Writes, Reads, and Repeated Starts without releasing the bus. | **P2** | Stress Test, Cross Coverage |

### 3.3 Protocol Features & Corner Cases

| Test ID | Test Name | Description | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- |
| **TP_201** | `clk_stretch_slave` | Slave holds SCL Low before ACK/Data. Master must wait indefinitely. | **P1** | Clock Synchronization |
| **TP_202** | `nack_addr` | Master addresses a non-existent Slave. Verify NACK on address byte and Stop generation. | **P1** | Address NACK, Status Bins |
| **TP_203** | `nack_data` | Slave NACKs a data byte (e.g., buffer full). Master must Abort or Stop. | **P2** | Data NACK flow |
| **TP_204** | `gen_call_req` | Master sends General Call address (`0000000`). Verify all capable slaves ACK. | **P2** | General Call Bin |
| **TP_205** | `zero_byte_seq` | Master sends Address + R/W bit, gets ACK, then immediately Stops. | **P3** | Empty Payload Bin |

### 3.4 Timing & Configuration

| Test ID | Test Name | Description | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- |
| **TP_301** | `speed_change` | Configure bus to Fm (400kHz) and Fm+ (1MHz). Verify timing parameters (tLOW, tHIGH). | **P2** | Speed Config Bins |
| **TP_302** | `min_timings` | Drive SCL/SDA with minimum allowed setup/hold times. Verify robustness. | **P3** | Timing Margin |

### 3.5 Credit-Based Flow Control Tests

These six scenarios drive the credit-aware testbench against `rtl/i2c_credit_slave.sv` (an 8-entry FIFO with a configurable pipeline delay) and exercise the TBIs through the per-transaction credit monitor. Each scenario is run with 15 random seeds, for a total of 90 runs reported in the credit-based flow control manuscript.

| Test ID | Test Name | Description | Primary TBIs | Priority | Coverage Goal |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TP_501** | `credit_sanity` | Nominal credit grant during init, happy-path burst at `cbr_depth = 8`, end-of-test balance equals initial budget. | TBI-1, TBI-3, TBI-4 | **P0** | Init waterfall, balance closure |
| **TP_502** | `credit_exhaustion` | Drive credit counter to zero, verify CBT enters bounded stall (`cfg.credit_stall_timeout_ns`), and recovers when CBR returns credits. | TBI-1, TBI-5 | **P0** | Exhaustion entry/exit, return latency bound |
| **TP_503** | `credit_burst` | Burst stress at $B \in \{1,4,8,16,32\}$ against `cbr_depth = 8`; verify shadow counter never crosses TBI-1 even when $B > D$. | TBI-1, TBI-2, TBI-5 | **P1** | Burst-length sweep, capacity bound |
| **TP_504** | `credit_error` | Fault injection (`cfg.inject_send_without_credit`, phantom-return injection) to validate monitor sensitivity. Each injection must produce a UVM error tagged with the violated TBI. | TBI-1, TBI-2, TBI-6 | **P1** | Error-injection coverage, monitor sensitivity |
| **TP_505** | `credit_dual_role` | Credit accounting interacting with role-flip from the dual-role extension; both BOIs and TBIs are enforced concurrently. | TBI-1..TBI-6 | **P2** | Cross-extension interaction |
| **TP_506** | `credit_random` | Randomized `cbr_depth`, `cbr_pipe_delay`, burst length, and direction over the full constraint envelope. | TBI-1..TBI-6 | **P2** | Constraint envelope coverage |

Acceptance criteria for the credit suite: 100% pass rate, zero TBI violations on non-error tests, zero stall timeouts, and end-of-test credit delta of zero on every non-error seed.

---

## 4. Coverage Model (Implemented)

The `i2c_coverage` class in `src/env/i2c_coverage.sv` implements the following covergroups.

### 4.1 `i2c_protocol_cg`

- **Address 7-bit**: Bins for `0` (General Call), Low `[1:15]`, Mid `[16:111]`, High `[112:126]`, Max `127`.
- **Direction**: `Write`, `Read`.
- **Status**: `OK`, `ADDR_NACK`, `DATA_NACK`.
- **Payload Size**: `1`, `Small Burst [2:8]`, `Large Burst [9:128]`.
- **Repeated Start**: Toggle coverage for Stop vs Repeated Start.
- **Cross Coverage**:
  - Direction x Status
  - Direction x Size
  - Direction x Repeated Start

### 4.2 `i2c_config_cg`

- **Speed Modes**: `Standard`, `Fast`, `Fast+`.

### 4.3 `credit_protocol_cg` (credit-mode only)

Sampled when `cfg.credit_mode_enable = 1`. Source: `src/env/i2c_coverage.sv` lines 73-110.

- **Frame type** (`cp_frame_type`): `data_frame`, `init_frame`, `return_frame`, `status_frame`.
- **Credit FSM state** (`cp_credit_state`): `reset`, `init`, `ready`, `active`, `exhausted`, `error`.
- **Credit counter** (`cp_credit_counter`): `zero`, `low [1:2]`, `mid [3:6]`, `high [7:15]`, `full [16:256]`. The `negative [-256:-1]` bin is marked `illegal_bins`, providing a coverage-side enforcement of TBI-1 in addition to the monitor-side check.
- **Data size** (`cp_data_size`): `single`, `small [2:4]`, `medium [5:16]`, `large [17:128]`.
- **Cross Coverage**:
  - `cross_frame_state`: frame type x credit state
  - `cross_frame_counter`: frame type x credit counter

### 4.4 `credit_transition_cg` (credit-mode only)

FSM transition coverage at `src/env/i2c_coverage.sv` lines 112-122:

- `init_to_ready`: `CREDIT_STATE_INIT => CREDIT_STATE_READY`
- `ready_to_active`: `CREDIT_STATE_READY => CREDIT_STATE_ACTIVE`
- `active_to_exhaust`: `CREDIT_STATE_ACTIVE => CREDIT_STATE_EXHAUSTED`
- `exhaust_to_active`: `CREDIT_STATE_EXHAUSTED => CREDIT_STATE_ACTIVE`
- `active_to_ready`: `CREDIT_STATE_ACTIVE => CREDIT_STATE_READY`

---

## 5. Directory Structure

```text
i2c_uvm/
├── docs/                          # This testplan and protocol notes
├── rtl/
│   ├── i2c_master.sv              # Behavioral Master
│   ├── i2c_slave.sv               # Behavioral Slave (SLAVE_ADDR=0x55)
│   └── i2c_credit_slave.sv        # FIFO + credit-return path (credit extension)
├── sim/                           # Makefile and per-run logs
├── src/
│   ├── common/
│   │   ├── i2c_types.sv
│   │   ├── i2c_events.sv
│   │   └── i2c_credit_types.sv    # Credit frame-type enum, FSM state enum, defaults
│   ├── agent/
│   │   ├── i2c_driver.sv          # Base driver (master + slave modes)
│   │   ├── i2c_monitor.sv
│   │   ├── i2c_credit_master_driver.sv  # CBT (credit-gated dispatch)
│   │   ├── i2c_credit_slave_driver.sv   # CBR (pipeline-delayed return)
│   │   ├── i2c_credit_monitor.sv        # Shadow-counter TBI enforcement
│   │   ├── i2c_config.sv          # Config (incl. credit knobs)
│   │   ├── i2c_sequencer.sv
│   │   └── i2c_agent.sv
│   ├── env/
│   │   ├── i2c_env.sv
│   │   ├── i2c_scoreboard.sv
│   │   └── i2c_coverage.sv        # Hosts both base and credit covergroups
│   ├── seq/
│   │   ├── i2c_base_sequence.sv
│   │   ├── i2c_mixed_sequence.sv
│   │   ├── i2c_credit_base_sequence.sv
│   │   ├── i2c_credit_burst_sequence.sv
│   │   └── i2c_credit_error_sequence.sv
│   ├── tests/
│   │   ├── i2c_test_base.sv
│   │   ├── i2c_sanity_test.sv     # ... and the rest of the dual-role suite
│   │   ├── i2c_credit_test_base.sv
│   │   ├── i2c_credit_sanity_test.sv
│   │   ├── i2c_credit_exhaustion_test.sv
│   │   ├── i2c_credit_burst_test.sv
│   │   ├── i2c_credit_error_test.sv
│   │   ├── i2c_credit_dual_role_test.sv
│   │   └── i2c_credit_random_test.sv
│   ├── i2c_pkg.sv
│   ├── i2c_test_pkg.sv
│   └── i2c_if.sv
├── img/seaborn/                   # Figure-generation scripts (matplotlib + seaborn)
└── paper/                         # Manuscript sources (LaTeX, gitignored)
    ├── deterministic_dual_role_i2c_verification/
    └── credit_based_flow_control_verification/
```

---

## 6. TBI Reference

| TBI | Property | Source-of-truth |
| :--- | :--- | :--- |
| **TBI-1** | Shadow credit balance is non-negative at every sample point (no transmit without credit). | `src/agent/i2c_credit_monitor.sv` |
| **TBI-2** | Shadow credit balance is bounded above by `cfg.cbr_depth` (no phantom credits). | `src/agent/i2c_credit_monitor.sv` |
| **TBI-3** | Initialization completes before the first data frame is dispatched. | `src/agent/i2c_credit_monitor.sv` |
| **TBI-4** | End-of-test credit balance equals the initial budget (no credit leaks, no surplus). | `src/agent/i2c_credit_monitor.sv` |
| **TBI-5** | Credit-return latency is bounded by the configured pipeline depth and `cfg.credit_stall_timeout_ns`. | `src/agent/i2c_credit_monitor.sv` |
| **TBI-6** | Out-of-band or duplicate returns are rejected as protocol errors. | `src/agent/i2c_credit_monitor.sv` |

A violation of any TBI is reported by the monitor with the offending transaction, the shadow-counter value at the failing sample, and the named TBI, so that the test log alone is sufficient to triage the failure without waveform forensics.

---

## 7. Reproduction

The 90-run credit suite that backs Table II of the credit-based flow control manuscript executes via:

```bash
cd sim
make regr_credit
```

The target runs the six `TP_5xx` scenarios above with auto-assigned random seeds (`+ntb_random_seed_automatic`) and writes per-run logs into `sim/`. Per-scenario smoke tests are available as `make run_credit_{sanity,exhaustion,burst,error,dual_role,random}`. The full sweep across the dual-role suite plus the credit suite is `make regr_full`.

Tool versions used to produce the published numbers: Synopsys VCS v2022.06-SP2-1 with UVM 1.2; Python 3.5 or later with Matplotlib 2.x and Seaborn 0.9.x for figure regeneration.

The full artifact map (listings, figures, tables) for the credit manuscript is given in the `Code and Data Availability` subsection of `paper/credit_based_flow_control_verification/access.tex` and mirrored in the repository-root [README.md](../README.md). The public repository is <https://github.com/tobliao/i2c_uvm>.
