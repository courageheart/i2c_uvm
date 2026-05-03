`ifndef I2C_TEST_PKG_SV
`define I2C_TEST_PKG_SV

package i2c_test_pkg;
  import uvm_pkg::*;
  import i2c_pkg::*;
  
  `include "uvm_macros.svh"

  // Test Base
  `include "tests/i2c_test_base.sv"

  // Test Library
  `include "tests/i2c_sanity_test.sv"
  `include "tests/i2c_slave_test.sv"
  `include "tests/i2c_burst_test.sv"
  `include "tests/i2c_nack_test.sv"
  `include "tests/i2c_10bit_test.sv"
  `include "tests/i2c_restart_test.sv"
  `include "tests/i2c_gen_call_test.sv"
  `include "tests/i2c_speed_test.sv"
  `include "tests/i2c_random_test.sv"
  `include "tests/i2c_slave_read_test.sv"
  `include "tests/i2c_master_fsm_test.sv"

  // Credit-Based Test Library
  `include "tests/i2c_credit_test_base.sv"
  `include "tests/i2c_credit_sanity_test.sv"
  `include "tests/i2c_credit_exhaustion_test.sv"
  `include "tests/i2c_credit_burst_test.sv"
  `include "tests/i2c_credit_error_test.sv"
  `include "tests/i2c_credit_dual_role_test.sv"
  `include "tests/i2c_credit_random_test.sv"

endpackage

`endif // I2C_TEST_PKG_SV
