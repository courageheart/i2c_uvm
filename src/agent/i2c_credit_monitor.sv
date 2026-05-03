`ifndef I2C_CREDIT_MONITOR_SV
`define I2C_CREDIT_MONITOR_SV

class i2c_credit_monitor extends uvm_monitor;
  `uvm_component_utils(i2c_credit_monitor)

  virtual i2c_if vif;
  i2c_config cfg;

  int shadow_credit_counter;
  i2c_credit_state_e shadow_state;

  uvm_analysis_port #(i2c_transaction) credit_ap;

  int unsigned tbi1_violations;
  int unsigned tbi2_violations;
  int unsigned tbi3_violations;
  int unsigned tbi4_balance_delta;
  int unsigned tbi5_violations;
  int unsigned tbi6_violations;

  int unsigned total_credits_init;
  int unsigned total_credits_consumed;
  int unsigned total_credits_returned;
  bit init_complete;

  int credit_history[$];
  time credit_history_time[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    credit_ap = new("credit_ap", this);
    shadow_credit_counter = 0;
    shadow_state = CREDIT_STATE_RESET;
    init_complete = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(i2c_config)::get(this, "", "cfg", cfg)) begin
      cfg = i2c_config::type_id::create("cfg");
    end
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("CREDIT_MON", "Virtual interface 'vif' not found")
    end
  endfunction

  task run_phase(uvm_phase phase);
    if (!cfg.credit_mode_enable) return;

    fork
      monitor_credit_init();
      monitor_credit_flow();
      record_credit_history();
    join
  endtask

  task monitor_credit_init();
    bit timed_out;
    i2c_event_pool::wait_for_event_timeout(
      "credit_init_done", cfg.credit_init_timeout_ns * 1ns, timed_out);

    if (timed_out) begin
      `uvm_error("CREDIT_MON", "Credit init not observed within timeout")
      tbi3_violations++;
    end else begin
      shadow_credit_counter = cfg.cbr_depth;
      total_credits_init = cfg.cbr_depth;
      init_complete = 1;
      shadow_state = CREDIT_STATE_READY;
      `uvm_info("CREDIT_MON", $sformatf("Init observed: shadow_counter=%0d", shadow_credit_counter), UVM_MEDIUM)
    end
  endtask

  task monitor_credit_flow();
    forever begin
      fork
        begin : watch_data_sent
          uvm_object data;
          i2c_event_pool::wait_for_event(i2c_event_pool::TRANS_COMPLETE, data);
          if (init_complete) begin
            shadow_credit_counter--;
            total_credits_consumed++;
            check_tbi1();
            check_tbi2();
          end else begin
            tbi3_violations++;
            `uvm_error("CREDIT_MON", "TBI-3: Data transfer before credit init complete")
          end
        end
        begin : watch_credit_return
          uvm_object data;
          i2c_event_pool::wait_for_event("credit_returned", data);
          shadow_credit_counter++;
          total_credits_returned++;
          check_tbi2();
          check_tbi6();
        end
      join_any
      disable fork;
    end
  endtask

  task record_credit_history();
    forever begin
      credit_history.push_back(shadow_credit_counter);
      credit_history_time.push_back($time);
      #(cfg.t_low_ns * 1ns);
    end
  endtask

  function void check_tbi1();
    if (shadow_credit_counter < 0) begin
      tbi1_violations++;
      `uvm_error("CREDIT_MON", $sformatf(
        "TBI-1 VIOLATION: shadow_credit_counter=%0d (negative)", shadow_credit_counter))
    end
  endfunction

  function void check_tbi2();
    if (shadow_credit_counter > int'(cfg.cbr_depth)) begin
      tbi2_violations++;
      `uvm_error("CREDIT_MON", $sformatf(
        "TBI-2 VIOLATION: shadow_credit_counter=%0d > cbr_depth=%0d",
        shadow_credit_counter, cfg.cbr_depth))
    end
  endfunction

  function void check_tbi6();
    if (total_credits_returned > total_credits_consumed) begin
      tbi6_violations++;
      `uvm_error("CREDIT_MON", $sformatf(
        "TBI-6 VIOLATION: credits_returned=%0d > credits_consumed=%0d",
        total_credits_returned, total_credits_consumed))
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (!cfg.credit_mode_enable) return;

    tbi4_balance_delta = shadow_credit_counter +
                         total_credits_consumed -
                         total_credits_init -
                         total_credits_returned;

    if (shadow_credit_counter != int'(cfg.cbr_depth) &&
        !cfg.inject_send_without_credit &&
        !cfg.inject_phantom_credit &&
        !cfg.inject_init_glitch) begin
      `uvm_error("CREDIT_MON", $sformatf(
        "TBI-4: End-of-test credit balance mismatch: counter=%0d expected=%0d (init=%0d consumed=%0d returned=%0d)",
        shadow_credit_counter, cfg.cbr_depth,
        total_credits_init, total_credits_consumed, total_credits_returned))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    if (!cfg.credit_mode_enable) return;

    `uvm_info("CREDIT_MON", "╔════════════════════════════════════════╗", UVM_NONE)
    `uvm_info("CREDIT_MON", "║     CREDIT MONITOR REPORT              ║", UVM_NONE)
    `uvm_info("CREDIT_MON", "╠════════════════════════════════════════╣", UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ Credits Initialized : %8d         ║", total_credits_init), UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ Credits Consumed    : %8d         ║", total_credits_consumed), UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ Credits Returned    : %8d         ║", total_credits_returned), UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ Final Counter       : %8d         ║", shadow_credit_counter), UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ TBI-1 Violations    : %8d         ║", tbi1_violations), UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ TBI-2 Violations    : %8d         ║", tbi2_violations), UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ TBI-3 Violations    : %8d         ║", tbi3_violations), UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ TBI-5 Violations    : %8d         ║", tbi5_violations), UVM_NONE)
    `uvm_info("CREDIT_MON", $sformatf("║ TBI-6 Violations    : %8d         ║", tbi6_violations), UVM_NONE)
    `uvm_info("CREDIT_MON", "╚════════════════════════════════════════╝", UVM_NONE)
  endfunction

endclass

`endif // I2C_CREDIT_MONITOR_SV
