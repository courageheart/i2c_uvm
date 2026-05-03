`ifndef I2C_AGENT_SV
`define I2C_AGENT_SV

class i2c_agent extends uvm_agent;
  `uvm_component_utils(i2c_agent)

  // Standard components (always built for non-credit mode)
  i2c_driver    driver;
  i2c_monitor   monitor;
  i2c_sequencer sequencer;

  // Credit-mode components (built only when cfg.credit_mode_enable)
  i2c_credit_master_driver cbt_driver;
  i2c_credit_slave_driver  cbr_driver;
  i2c_credit_monitor       credit_monitor;
  i2c_sequencer            cbt_sequencer;
  i2c_sequencer            cbr_sequencer;
  
  i2c_config    cfg;
  virtual i2c_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(i2c_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info("AGENT", "Config not found in DB, creating default", UVM_LOW)
      cfg = i2c_config::type_id::create("cfg");
    end

    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("AGENT", "Virtual interface 'vif' not found in config_db")
    end

    // Propagate config to children
    uvm_config_db#(i2c_config)::set(this, "*", "cfg", cfg);

    // Bus monitor is always present
    monitor = i2c_monitor::type_id::create("monitor", this);
    
    if (cfg.is_active == UVM_ACTIVE) begin
      if (cfg.credit_mode_enable) begin
        // Credit mode: dual drivers + credit monitor
        cbt_driver    = i2c_credit_master_driver::type_id::create("cbt_driver", this);
        cbt_sequencer = i2c_sequencer::type_id::create("cbt_sequencer", this);
        cbr_driver    = i2c_credit_slave_driver::type_id::create("cbr_driver", this);
        cbr_sequencer = i2c_sequencer::type_id::create("cbr_sequencer", this);
        credit_monitor = i2c_credit_monitor::type_id::create("credit_monitor", this);
        `uvm_info("AGENT", "Credit-mode agent built (CBT + CBR drivers, credit monitor)", UVM_LOW)
      end else begin
        // Standard mode: single driver
        driver    = i2c_driver::type_id::create("driver", this);
        sequencer = i2c_sequencer::type_id::create("sequencer", this);
      end
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    monitor.vif = vif;
    monitor.cfg = cfg;
    
    if (cfg.is_active == UVM_ACTIVE) begin
      if (cfg.credit_mode_enable) begin
        cbt_driver.seq_item_port.connect(cbt_sequencer.seq_item_export);
        cbt_driver.vif = vif;
        cbt_driver.cfg = cfg;

        cbr_driver.seq_item_port.connect(cbr_sequencer.seq_item_export);
        cbr_driver.vif = vif;
        cbr_driver.cfg = cfg;

        credit_monitor.vif = vif;
      end else begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
        driver.vif = vif;
        driver.cfg = cfg;
      end
    end
  endfunction

endclass

`endif // I2C_AGENT_SV
