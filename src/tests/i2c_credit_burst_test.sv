`ifndef I2C_CREDIT_BURST_TEST_SV
`define I2C_CREDIT_BURST_TEST_SV

class i2c_credit_burst_test extends i2c_credit_test_base;
  `uvm_component_utils(i2c_credit_burst_test)

  function new(string name = "i2c_credit_burst_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void configure_credit_params();
    super.configure_credit_params();
    cfg.cbr_depth = 16;
    cfg.cbr_pipe_delay = 2;
  endfunction

  task run_phase(uvm_phase phase);
    i2c_credit_burst_sequence burst_seq;

    phase.raise_objection(this);

    `uvm_info("TEST", ">>> Credit Burst Test: large burst with varying FIFO depths", UVM_LOW)

    #50us;

    burst_seq = i2c_credit_burst_sequence::type_id::create("burst_seq");
    burst_seq.target_addr = cfg.slave_addr;
    if (!burst_seq.randomize() with {
      burst_count == 5;
      burst_size inside {[3:8]};
    }) `uvm_fatal("TEST", "Randomization failed")

    burst_seq.start(env.agent.cbt_sequencer);

    #(cfg.cbr_pipe_delay * cfg.cbr_depth * cfg.t_low_ns * 2ns);
    #200us;

    `uvm_info("TEST", ">>> Credit Burst Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_CREDIT_BURST_TEST_SV
