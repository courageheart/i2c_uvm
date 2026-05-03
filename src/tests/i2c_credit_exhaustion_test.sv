`ifndef I2C_CREDIT_EXHAUSTION_TEST_SV
`define I2C_CREDIT_EXHAUSTION_TEST_SV

class i2c_credit_exhaustion_test extends i2c_credit_test_base;
  `uvm_component_utils(i2c_credit_exhaustion_test)

  function new(string name = "i2c_credit_exhaustion_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void configure_credit_params();
    super.configure_credit_params();
    cfg.cbr_depth = 4;
    cfg.cbr_pipe_delay = 3;
  endfunction

  task run_phase(uvm_phase phase);
    i2c_credit_exhaustion_sequence exhaust_seq;

    phase.raise_objection(this);

    `uvm_info("TEST", ">>> Credit Exhaustion Test: send until credits run out, verify stall and recovery", UVM_LOW)

    #50us;

    exhaust_seq = i2c_credit_exhaustion_sequence::type_id::create("exhaust_seq");
    exhaust_seq.target_addr = cfg.slave_addr;
    exhaust_seq.start(env.agent.cbt_sequencer);

    #(cfg.cbr_pipe_delay * cfg.cbr_depth * cfg.t_low_ns * 2ns);
    #200us;

    `uvm_info("TEST", ">>> Credit Exhaustion Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_CREDIT_EXHAUSTION_TEST_SV
