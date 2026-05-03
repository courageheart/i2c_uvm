# I2C UVM Verification Project

**Repository:** <https://github.com/tobliao/i2c_uvm>

A SystemVerilog UVM verification IP for the I2C protocol, packaged with two reference behavioral RTL models (master and slave) and a credit-aware slave variant. The repository is the source-of-truth for two manuscripts:

1. **Deterministic Dual-Role I2C Verification** (IEEE Access, 2026): bus ownership invariants and mode-flip coverage for a dual-role master/slave VIP.
2. **Credit-Based Flow Control Verification for I2C** (IEEE Access submission, 2026): six Transmit-Budget Invariants (TBI-1 through TBI-6) and a credit-aware UVM agent that enforces them per transaction.

Both papers reference paths inside this repository in their *Code and Data Availability* sections; the artifact map below mirrors those references so a reviewer can land on either side and navigate to the other.

## Directory Structure

```
i2c_uvm/
├── docs/                       # Testplan and protocol notes
├── rtl/                        # Behavioral RTL models
│   ├── i2c_master.sv
│   ├── i2c_slave.sv
│   └── i2c_credit_slave.sv     # FIFO + credit-return path (credit paper)
├── sim/                        # Makefile and per-run logs
├── src/
│   ├── common/                 # Shared types, including i2c_credit_types.sv
│   ├── agent/                  # Driver, monitor, sequencer, and credit variants
│   │   ├── i2c_credit_master_driver.sv   # CBT (credit-gated dispatch)
│   │   ├── i2c_credit_slave_driver.sv    # CBR (pipeline-delayed return)
│   │   └── i2c_credit_monitor.sv         # Shadow-counter TBI enforcement
│   ├── env/                    # Environment, scoreboard, coverage
│   ├── seq/                    # Sequence library, including credit sequences
│   ├── tests/                  # Test library (flat structure)
│   ├── i2c_pkg.sv
│   ├── i2c_test_pkg.sv
│   └── i2c_if.sv
├── img/seaborn/                # Figure-generation scripts (Python + matplotlib)
└── paper/                      # Manuscript sources (LaTeX)
    ├── deterministic_dual_role_i2c_verification/
    └── credit_based_flow_control_verification/
```

## Prerequisites

* Synopsys VCS v2022.06-SP2-1 (or newer) with UVM 1.2 support
* Verdi (optional, for waveform viewing)
* Python 3.5 or newer with `matplotlib` (>= 2.0), `seaborn` (>= 0.9), `numpy`, and `pandas` for figure regeneration

## Quick Start

```bash
cd sim
make run                  # Sanity test (dual-role VIP)
make run_slave            # Slave-only test
make regr_paper           # 11 scenarios x 15 seeds, dual-role paper regression
make run_credit_sanity    # Single credit-mode smoke test
make regr_credit          # 6 scenarios x 15 seeds, credit paper regression
make regr_full            # Dual-role + credit, full sweep
make cov_rpt              # Generate URG coverage report into cov_report/
```

`+CREDIT_MODE` selects the credit-aware DUT path inside the testbench; the credit-mode `run_*` targets and `regr_credit` set this flag automatically.

## Reproducing the Credit-Based Flow Control Paper

The 90-run regression behind Table~II of the credit paper executes via:

```bash
cd sim
make regr_credit
```

Each per-run log records the auto-assigned random seed (`+ntb_random_seed_automatic`) and the credit monitor's per-transaction TBI verdict; the `regr_credit` target writes the per-test logs and coverage data into `sim/`.

The four numbered figures in Section~III of the credit paper regenerate from the regression artifacts via:

```bash
cd img/seaborn
python3 generate_credit_arch.py        # Fig. 1 (architecture diagram)
python3 generate_credit_plots.py       # Figs. 3, 4, 5, 6 (init, trace, latency, regression)
python3 generate_credit_overhead.py    # Fig. 7 (analytical overhead)
```

The overhead curve is analytical (closed-form, not measured); the other plots are pulled from the regression CSV emitted by `make regr_credit`.

## Paper Artifact Map (Credit Paper)

| Manuscript artifact            | Source-of-truth path                                                  |
|--------------------------------|------------------------------------------------------------------------|
| Listing 1 (`lst:credit_if`)    | `src/common/i2c_credit_types.sv`                                       |
| Listings 2, 6 (CBT)            | `src/agent/i2c_credit_master_driver.sv`                                |
| Listing 3 (credit monitor)     | `src/agent/i2c_credit_monitor.sv`                                      |
| Listings 4, 5 (CBR init/return)| `src/agent/i2c_credit_slave_driver.sv`                                 |
| Listing 7 (anti-pattern)       | Illustrative only; not in the repository                               |
| Table II (regression results)  | `rtl/i2c_credit_slave.sv` exercised via `make regr_credit`             |
| Six test scenarios             | `src/tests/i2c_credit_{sanity,exhaustion,burst,error,dual_role,random}_test.sv` |
| Credit covergroups (Table III) | `src/env/i2c_coverage.sv`                                              |
| Stimulus library               | `src/seq/i2c_credit_{base,burst,error}_sequence.sv`                    |
| Regression entry point         | `sim/Makefile`, target `regr_credit`                                   |
| Fig. 1 (architecture)          | `img/seaborn/generate_credit_arch.py`                                  |
| Figs. 3-6 (regression plots)   | `img/seaborn/generate_credit_plots.py`                                 |
| Fig. 7 (analytical overhead)   | `img/seaborn/generate_credit_overhead.py`                              |

## Reproducing the Dual-Role Paper

```bash
cd sim
make regr_paper           # 11 scenarios x 15 seeds, recorded in regression_raw.csv
make cov_rpt              # URG coverage report under cov_report/
```

The bus-ownership invariants and mode-flip scoreboard are exercised by `i2c_slave_test`, `i2c_master_fsm_test`, and `i2c_random_test`; the dual-role paper's Table~I aggregates the per-test pass counts and CPU times from `regression_raw.csv`.

## Implemented Features

### Dual-Role VIP

* Master mode: Start/Stop generation, address and data drive, ACK/NACK handling, repeated start, 7-bit and 10-bit addressing, general call.
* Slave mode: Start detection, reactive byte response, configurable ACK/NACK injection.
* Bus ownership invariants and mode-flip coverage in `src/env/`.
* Behavioral RTL master and slave under `rtl/` for closed-loop simulation.

### Credit-Based Flow Control Extension

* Frame-type encoding (INIT, DATA, RETURN) reserves bits [7:6] of the first data byte; see `src/common/i2c_credit_types.sv`.
* CBT (credit-based transmitter) gates dispatch on the shadow counter and stalls with a bounded `cfg.credit_stall_timeout_ns` window.
* CBR (credit-based receiver) initializes the counter to `cfg.cbr_depth` and returns credits with a configurable pipeline delay.
* Six Transmit-Budget Invariants enforced per transaction by the credit monitor:
  * **TBI-1** non-negative shadow balance (no transmit without credit).
  * **TBI-2** balance bounded above by `cbr_depth` (no phantom credits).
  * **TBI-3** initialization-before-data ordering.
  * **TBI-4** end-of-test balance equals initial budget (no leaks).
  * **TBI-5** bounded credit-return latency.
  * **TBI-6** rejection of out-of-band or duplicate returns.

## Future Work

* Per-endpoint credit pools for multi-receiver topologies.
* I3C extension with in-band interrupt and dynamic address assignment.
* Formal verification of TBI properties via SystemVerilog Assertions.
* LLM-assisted assertion synthesis from natural-language credit specifications.

## Citation

```bibtex
@article{i2c_dual_role_2026,
  author  = {Liao, Tob and others},
  title   = {Deterministic Dual-Role {I}\textsuperscript{2}{C} Verification with Bus Ownership Invariants},
  journal = {IEEE Access},
  year    = {2026},
  note    = {to appear}
}

@article{i2c_credit_2026,
  author  = {Liao, Tob and others},
  title   = {Credit-Based Flow Control Verification for {I}\textsuperscript{2}{C} with Transmit-Budget Invariants},
  journal = {IEEE Access},
  year    = {2026},
  note    = {submitted}
}
```

## License

Released for academic reproduction. Please cite the manuscripts above when reusing the verification IP, the RTL models, or the figure-generation scripts in derivative work.
