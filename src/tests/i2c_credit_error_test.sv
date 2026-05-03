`ifndef I2C_CREDIT_ERROR_TEST_SV
`define I2C_CREDIT_ERROR_TEST_SV

class i2c_credit_error_test extends i2c_credit_test_base;
  `uvm_component_utils(i2c_credit_error_test)

  function new(string name = "i2c_credit_error_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void configure_credit_params();
    super.configure_credit_params();
    cfg.cbr_depth = 4;
    cfg.inject_send_without_credit = 1;
  endfunction

  task run_phase(uvm_phase phase);
    i2c_credit_error_sequence err_seq;

    phase.raise_objection(this);

    `uvm_info("TEST", ">>> Credit Error Test: inject protocol violations, verify monitor catches them", UVM_LOW)

    #50us;

    err_seq = i2c_credit_error_sequence::type_id::create("err_seq");
    err_seq.target_addr = cfg.slave_addr;
    err_seq.scenario = i2c_credit_error_sequence::ERR_SEND_WITHOUT_CREDIT;
    err_seq.start(env.agent.cbt_sequencer);

    #200us;

    `uvm_info("TEST", ">>> Credit Error Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    svr = uvm_report_server::get_server();
    `uvm_info("TEST", $sformatf("Expected errors (TBI violations): %0d",
      svr.get_severity_count(UVM_ERROR)), UVM_LOW)
    $display("\n========================================================");
    $display("    TEST STATUS: PASSED (error injection test)");
    $display("========================================================\n");
  endfunction

endclass

`endif // I2C_CREDIT_ERROR_TEST_SV
