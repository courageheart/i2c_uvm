`timescale 1ns/1ps

`ifndef I2C_PKG_SV
`define I2C_PKG_SV

package i2c_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  //============================================================================
  // Common Types and Events
  //============================================================================
  `include "common/i2c_types.sv"
  `include "common/i2c_credit_types.sv"
  `include "common/i2c_events.sv"

  //============================================================================
  // Agent Configuration and Transaction
  //============================================================================
  `include "agent/i2c_config.sv"
  `include "agent/i2c_transaction.sv"
  
  //============================================================================
  // Agent Components
  //============================================================================
  `include "agent/i2c_sequencer.sv"
  `include "agent/i2c_driver.sv"
  `include "agent/i2c_credit_master_driver.sv"
  `include "agent/i2c_credit_slave_driver.sv"
  `include "agent/i2c_monitor.sv"
  `include "agent/i2c_credit_monitor.sv"
  `include "agent/i2c_agent.sv"
  `include "agent/i2c_callbacks.sv"
  `include "agent/i2c_virtual_sequencer.sv"
  
  //============================================================================
  // Environment Components
  //============================================================================
  `include "env/i2c_scoreboard.sv"
  `include "env/i2c_coverage.sv"
  `include "env/i2c_env.sv"
  
  //============================================================================
  // Sequences
  //============================================================================
  `include "seq/i2c_base_sequence.sv"
  `include "seq/i2c_mixed_sequence.sv"
  `include "seq/i2c_virtual_sequence.sv"
  `include "seq/i2c_credit_base_sequence.sv"
  `include "seq/i2c_credit_burst_sequence.sv"
  `include "seq/i2c_credit_error_sequence.sv"

endpackage

`endif // I2C_PKG_SV
