`ifndef I2C_CREDIT_TEST_BASE_SV
`define I2C_CREDIT_TEST_BASE_SV

class i2c_credit_test_base extends i2c_test_base;
  `uvm_component_utils(i2c_credit_test_base)

  function new(string name = "i2c_credit_test_base", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Enable credit mode on the shared config
    cfg.credit_mode_enable = 1;
    configure_credit_params();

    // Re-propagate the updated config
    uvm_config_db#(i2c_config)::set(this, "env*", "cfg", cfg);
  endfunction

  virtual function void configure_credit_params();
    cfg.cbr_depth = I2C_CREDIT_DEFAULT_DEPTH;
    cfg.cbr_pipe_delay = I2C_CREDIT_DEFAULT_PIPE_DLY;
    cfg.cbt_pipe_delay = 0;
    cfg.cbr_return_burst = 1;
  endfunction

endclass

`endif // I2C_CREDIT_TEST_BASE_SV
