 import uvm_pkg::*;
`include "uvm_macros.svh"
`timescale 1ns/1ps

interface fifo_if(input bit clk);

logic rst_n;

logic wr_en;
logic rd_en;

logic [7:0] data_in;

logic [7:0] data_out;

logic full;
logic empty;

endinterface


class fifo_config extends uvm_object ;

  `uvm_object_utils(fifo_config)

 uvm_active_passive_enum is_active = UVM_ACTIVE ;

 function new(string name ="fifo_config");
   super.new(name);
 endfunction

endclass


class fifo_trans extends uvm_sequence_item;

rand bit wr_en;
rand bit rd_en;
rand bit rst_n;

rand bit [7:0] data_in;

bit [7:0] data_out;

bit full;
bit empty;

function new(string name = "fifo_trans");
   super.new(name);
endfunction

`uvm_object_utils_begin(fifo_trans)
        `uvm_field_int(wr_en,UVM_ALL_ON)
        `uvm_field_int(rd_en,UVM_ALL_ON)
        `uvm_field_int(rst_n,UVM_ALL_ON)

        `uvm_field_int(data_in,UVM_ALL_ON)

        `uvm_field_int(data_out,UVM_ALL_ON)

        `uvm_field_int(full,UVM_ALL_ON)
        `uvm_field_int(empty,UVM_ALL_ON)

`uvm_object_utils_end

endclass


class reset_seq extends uvm_sequence #(fifo_trans);

    `uvm_object_utils(reset_seq)

    fifo_trans tr;

    function new(string name="reset_seq");
        super.new(name);
    endfunction

    task body();

        tr = fifo_trans::type_id::create("tr");

        start_item(tr);

        tr.rst_n = 0;
        tr.wr_en = 0;
        tr.rd_en = 0;
        tr.data_in = 0;

        finish_item(tr);

    endtask

endclass


class write_seq extends uvm_sequence #(fifo_trans);

    `uvm_object_utils(write_seq)

    fifo_trans tr;
    
    int num_writes = 1;

    function new(string name="write_seq");
        super.new(name);
    endfunction

    task body();

        repeat(num_writes) begin

            tr = fifo_trans::type_id::create("tr");

            start_item(tr);

            if(!tr.randomize() with {
                rst_n == 1;
                wr_en == 1;
                rd_en == 0;
            })
                `uvm_fatal("WRITE_SEQ","Randomization Failed")

            finish_item(tr);

        end

    endtask

endclass


class read_seq extends uvm_sequence #(fifo_trans);

    `uvm_object_utils(read_seq)

    fifo_trans tr;
    int num_reads = 1;
    
    function new(string name="read_seq");
        super.new(name);
    endfunction

    task body();

        repeat(num_reads) begin

            tr = fifo_trans::type_id::create("tr");

            start_item(tr);

            tr.rst_n = 1;
            tr.wr_en = 0;
            tr.rd_en = 1;

            finish_item(tr);

        end

    endtask

endclass

class random_seq extends uvm_sequence #(fifo_trans);

  `uvm_object_utils(random_seq)

  fifo_trans tr;
  int num_transactions = 100;

  function new(string name="random_seq");
    super.new(name);
  endfunction

  task body();

    repeat(num_transactions) begin

      tr = fifo_trans::type_id::create("tr");

      start_item(tr);

      assert(tr.randomize() with {
        rst_n == 1;
      });

      finish_item(tr);

    end

  endtask

endclass


class sim_rw_seq extends uvm_sequence #(fifo_trans);

  `uvm_object_utils(sim_rw_seq)

  fifo_trans tr;

  function new(string name="sim_rw_seq");
    super.new(name);
  endfunction

  task body();

    repeat(20) begin

      tr = fifo_trans::type_id::create("tr");

      start_item(tr);

      assert(tr.randomize() with {
        rst_n == 1;
        wr_en == 1;
        rd_en == 1;
      });

      finish_item(tr);

    end

  endtask

endclass


class fifo_sequencer extends uvm_sequencer #(fifo_trans);

    `uvm_component_utils(fifo_sequencer)

    function new(string name="fifo_sequencer", uvm_component parent);
        super.new(name,parent);
    endfunction

endclass


class fifo_driver extends uvm_driver #(fifo_trans);

    `uvm_component_utils(fifo_driver)

    virtual fifo_if inf;

    fifo_trans req;

    function new(string name="fifo_driver", uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(virtual fifo_if)::get(this,"","vif",inf))
            `uvm_fatal("DRV","Unable to access Interface");
    endfunction

    virtual task run_phase(uvm_phase phase);

        forever begin

            seq_item_port.get_next_item(req);

            drive(req);

            seq_item_port.item_done();

        end

    endtask

    task drive(fifo_trans req);

        inf.rst_n   <= req.rst_n;
        inf.wr_en   <= req.wr_en;
        inf.rd_en   <= req.rd_en;
        inf.data_in <= req.data_in;

        @(posedge inf.clk);

            inf.wr_en <= 0;
            inf.rd_en <= 0;

        @(posedge inf.clk);

    endtask

endclass


class fifo_monitor extends uvm_monitor;

    `uvm_component_utils(fifo_monitor)

    virtual fifo_if inf;

    fifo_trans tr;

    uvm_analysis_port #(fifo_trans) send;

    function new(string name="fifo_monitor",
                 uvm_component parent);

        super.new(name,parent);

        send = new("send",this);

    endfunction

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db #(virtual fifo_if)::get(this,"","vif",inf))
            `uvm_fatal("MON","Cannot access interface");

    endfunction

    virtual task run_phase(uvm_phase phase);

        forever begin

            @(posedge inf.clk);

            tr = fifo_trans::type_id::create("tr");

            tr.rst_n = inf.rst_n;

            tr.wr_en = inf.wr_en;
            tr.rd_en = inf.rd_en;

            tr.data_in = inf.data_in;

            tr.data_out = inf.data_out;

            tr.full = inf.full;
            tr.empty = inf.empty;
            
          `uvm_info("MON",$sformatf("wr=%0b rd=%0b full=%0b                  empty=%0b",
          tr.wr_en,
          tr.rd_en,
          tr.full,
          tr.empty),UVM_LOW)
          
            send.write(tr);

        end

    endtask

endclass

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp #(fifo_trans, fifo_scoreboard) receive;

  // Reference FIFO
  bit [7:0] ref_fifo[$];

  // Expected data for next read comparison
  bit [7:0] expected_data;
  bit compare_pending;

  function new(string name="fifo_scoreboard",
               uvm_component parent);

    super.new(name,parent);

    receive = new("receive",this);

    compare_pending = 0;

  endfunction
  
  virtual function void write(fifo_trans tr);

    //--------------------------------------------------
    // Compare pending read from previous cycle
    //--------------------------------------------------

    if(compare_pending) begin
  
      if(tr.data_out == expected_data)
        `uvm_info("SB",
          $sformatf("READ PASS : Expected=%0d Actual=%0d",
          expected_data,tr.data_out),UVM_LOW)

      else
        `uvm_error("SB",
          $sformatf("READ FAIL : Expected=%0d Actual=%0d",
          expected_data,tr.data_out))

      compare_pending = 0;

    end

    //--------------------------------------------------
    // RESET
    //--------------------------------------------------

    if(!tr.rst_n) begin

      ref_fifo.delete();

      compare_pending = 0;

      `uvm_info("SB","FIFO Reset",UVM_LOW)

      return;

    end

    //--------------------------------------------------
    // WRITE
    //--------------------------------------------------

    if(tr.wr_en && !tr.full) begin

      ref_fifo.push_back(tr.data_in);

      `uvm_info("SB",
        $sformatf("WRITE : %0d",tr.data_in),
        UVM_LOW);

    end

    //--------------------------------------------------
    // READ
    //--------------------------------------------------

    if(tr.rd_en && !tr.empty) begin

      if(ref_fifo.size()==0)

        `uvm_error("SB","Reference FIFO Empty!")

      else begin

        expected_data = ref_fifo.pop_front();

        compare_pending = 1;

      end

    end

  endfunction

endclass


class fifo_coverage extends uvm_subscriber #(fifo_trans);

  `uvm_component_utils(fifo_coverage)

  fifo_trans tr;

  // ---------------------------------------------------
  // COVERGROUP
  // ---------------------------------------------------
  covergroup fifo_cg;

    option.per_instance = 1;
    option.comment = "Synchronous FIFO Functional Coverage";

    // Inputs
    cp_wr : coverpoint tr.wr_en;
    cp_rd : coverpoint tr.rd_en;

    cp_rst : coverpoint tr.rst_n {
      bins reset_asserted   = {0};
      bins reset_deasserted = {1};
    }

    // Outputs
    cp_full  : coverpoint tr.full;
    cp_empty : coverpoint tr.empty;

    // Optional: Data values
   // cp_data : coverpoint tr.data_in;

    // ---------------------------------------------------
    // Cross Coverage
    // ---------------------------------------------------

    // Write / Read combinations
    cross_rw : cross cp_wr, cp_rd;

    // Overflow attempt
    cross_wr_full : cross cp_wr, cp_full;

    // Underflow attempt
    cross_rd_empty : cross cp_rd, cp_empty;

    // Reset during write
   // cross_rst_wr : cross cp_rst, cp_wr; 

    // Reset during read
    // cross_rst_rd : cross cp_rst, cp_rd;

  endgroup


  // ---------------------------------------------------
  // Constructor
  // ---------------------------------------------------

  function new(string name = "fifo_coverage",
               uvm_component parent);

    super.new(name,parent);

    fifo_cg = new();

  endfunction


  // ---------------------------------------------------
  // Receive Transaction
  // ---------------------------------------------------

  virtual function void write(fifo_trans t);

    this.tr = t;

    fifo_cg.sample();

  endfunction


  // ---------------------------------------------------
  // Coverage Report
  // ---------------------------------------------------

  virtual function void report_phase(uvm_phase phase);

    `uvm_info("COV",
      $sformatf("Final FIFO Coverage : %0.2f%%",
      fifo_cg.get_coverage()),
      UVM_LOW)

  endfunction

endclass


class fifo_agent extends uvm_agent;

  `uvm_component_utils(fifo_agent)

  fifo_driver      drv;
  fifo_monitor     mon;
  fifo_sequencer   seqr;

  fifo_config cfg;

  function new(string name="fifo_agent",
               uvm_component parent);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if(!uvm_config_db #(fifo_config)::get(this,"","cfg",cfg))
      `uvm_fatal("AGENT","Cannot get configuration")

    mon = fifo_monitor::type_id::create("mon",this);

    if(cfg.is_active == UVM_ACTIVE) begin
      drv  = fifo_driver::type_id::create("drv",this);
      seqr = fifo_sequencer::type_id::create("seqr",this);
    end

  endfunction


  virtual function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    if(cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);

  endfunction

endclass


class fifo_env extends uvm_env;

  `uvm_component_utils(fifo_env)

  fifo_agent       agt;
  fifo_scoreboard  sb;
  fifo_coverage    cov;

  function new(string name="fifo_env",
               uvm_component parent);

    super.new(name,parent);

  endfunction


  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    agt = fifo_agent::type_id::create("agt",this);

    sb  = fifo_scoreboard::type_id::create("sb",this);

    cov = fifo_coverage::type_id::create("cov",this);

  endfunction


  virtual function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    agt.mon.send.connect(sb.receive);

    agt.mon.send.connect(cov.analysis_export);

  endfunction

endclass


class fifo_test extends uvm_test;

  `uvm_component_utils(fifo_test)

  fifo_env env;

  fifo_config cfg;

  reset_seq rst;
  write_seq wr;
  read_seq rd;
  random_seq rand_seq ;

  function new(string name="fifo_test",
               uvm_component parent);

    super.new(name,parent);

  endfunction


  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    cfg = fifo_config::type_id::create("cfg");

    uvm_config_db #(fifo_config)::set(this,
                                      "*",
                                      "cfg",
                                      cfg);

    env = fifo_env::type_id::create("env",this);

  endfunction

 virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);
   
    rst      = reset_seq::type_id::create("rst");
    wr       = write_seq::type_id::create("wr");
    rd       = read_seq::type_id::create("rd");
    rand_seq = random_seq::type_id::create("rand_seq");

    // Reset
    rst.start(env.agt.seqr);

    // Basic Write Read
    wr.num_writes = 8;
    wr.start(env.agt.seqr);

    rd.num_reads = 8;
    rd.start(env.agt.seqr);

    // Reset
    rst.start(env.agt.seqr);

    // Overflow
    wr.num_writes = 8;
    wr.start(env.agt.seqr);

    wr.num_writes = 1;
    wr.start(env.agt.seqr);

    // Reset
    rst.start(env.agt.seqr);

    // Underflow
    rd.num_reads = 1;
    rd.start(env.agt.seqr);

    // Reset
    rst.start(env.agt.seqr);

    // Random
    rand_seq.num_transactions = 200;
    rand_seq.start(env.agt.seqr);

    phase.drop_objection(this);

endtask

endclass


class overflow_test extends fifo_test;

  `uvm_component_utils(overflow_test)

  function new(string name="overflow_test",
               uvm_component parent);

    super.new(name,parent);

  endfunction


  virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    rst = reset_seq::type_id::create("rst");
    wr  = write_seq::type_id::create("wr");

    rst.start(env.agt.seqr);

    wr.num_writes = 8;
    wr.start(env.agt.seqr);

    wr.num_writes = 1;
    wr.start(env.agt.seqr);

    phase.drop_objection(this);

  endtask

endclass


class underflow_test extends fifo_test;

  `uvm_component_utils(underflow_test)

  function new(string name="underflow_test",
               uvm_component parent);

    super.new(name,parent);

  endfunction

  virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    rst = reset_seq::type_id::create("rst");
    rd  = read_seq::type_id::create("rd");

   rst.start(env.agt.seqr);

   rd.num_reads = 1;

   rd.start(env.agt.seqr);

   phase.drop_objection(this);

  endtask

endclass

class random_test extends fifo_test;

  `uvm_component_utils(random_test)

  function new(string name="random_test",
               uvm_component parent);

    super.new(name,parent);

  endfunction

  virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    rst      = reset_seq::type_id::create("rst");
    rand_seq = random_seq::type_id::create("rand_seq");

    rst.start(env.agt.seqr);

    rand_seq.num_transactions = 200;

    rand_seq.start(env.agt.seqr);
    
    phase.drop_objection(this);

  endtask

endclass


module tb;

  // Clock
  bit clk = 0;

  always #5 clk = ~clk;

  // Interface
  fifo_if inf(clk);

  // DUT
  synch_fifo_bram #(
      .DATA_WIDTH(8),
      .FIFO_DEPTH(8)
  ) dut (
      .clk      (clk),
      .rst_n    (inf.rst_n),
      .wr_en    (inf.wr_en),
      .rd_en    (inf.rd_en),
      .data_in  (inf.data_in),
      .full     (inf.full),
      .empty    (inf.empty),
      .data_out (inf.data_out)
  );

  // Start UVM
  initial begin

    // Give interface to Driver and Monitor
    uvm_config_db #(virtual fifo_if)::set(
        null,
        "*",
        "vif",
        inf
    );

    // Choose the test to run
    run_test("fifo_test");

    // Examples:
   // run_test("overflow_test");
  //  run_test("underflow_test");
   // run_test("random_test");

  end

endmodule
