module mp4
`define USE_CACHE
import types::*;
(
    input   logic           clk,
    input   logic           rst,

    `ifndef USE_CACHE 
    // Use these for CP1 (magic memory)
    output  logic   [31:0]  imem_address,
    output  logic           imem_read,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,
    output  logic   [31:0]  dmem_address,
    output  logic           dmem_read,
    output  logic           dmem_write,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp
    `endif

    `ifdef USE_CACHE
    // Use these for CP2+ (with caches and burst memory)
    output  logic   [31:0]  bmem_address,
    output  logic           bmem_read,
    output  logic           bmem_write,
    input   logic   [63:0]  bmem_rdata,
    output  logic   [63:0]  bmem_wdata,
    input   logic           bmem_resp
    `endif
);

/*
    cpu [31:0] --> bus adapter i [255:0] --> i cache --> arbiter --> [255:0] cacheline adaptor [63:0] --> pmem
               --> bus adapter d [255:0] --> d cache --^
*/
/////////////////////////////////////////////////////////////////////////////
`ifdef USE_CACHE
    logic   [31:0]  imem_address; 
    logic           imem_read;    
    logic   [31:0]  imem_rdata; 
    logic           imem_resp; 
    logic   [31:0]  dmem_address; 
    logic           dmem_read;   
    logic           dmem_write;   
    logic   [3:0]   dmem_wmask;   
    logic   [31:0]  dmem_rdata;
    logic   [31:0]  dmem_wdata;  
    logic           dmem_resp;   
    logic   [31:0]  mem_address;
    logic   [31:0]  bus_mem_wdata;
    logic   [3:0]   bus_mem_byte_enable;
    logic   [31:0]  bus_mem_rdata;
    logic           mem_resp;
    logic           load_pipeline;

    logic   [31:0]  f_pc;

    logic   [255:0] imem_wdata256;
    logic   [255:0] dmem_wdata256;

    logic   [255:0] imem_rdata256;
    logic   [255:0] dmem_rdata256;

    logic   [31:0]  imem_byte_enable256;
    logic   [31:0]  dmem_byte_enable256;

    logic           mem_read;
    logic           mem_write;
    
    logic   [31:0]  ipmem_address;
    logic           ipmem_read;
    logic           ipmem_write;
    logic   [255:0] ipmem_rdata;
    logic   [255:0] ipmem_wdata;
    logic           ipmem_resp;

    logic   [31:0]  dpmem_address;
    logic           dpmem_read;
    logic           dpmem_write;
    logic   [255:0] dpmem_rdata;
    logic   [255:0] dpmem_wdata;
    logic           dpmem_resp;

    logic   [255:0] line_i;
    logic   [255:0] line_o;
    logic   [31:0]  address_i;
    logic           read_i;
    logic           write_i;
    logic           resp_o;
`endif
///////////////////////////////////////////////////////////////////////////
    cpu CPU
    (
        .clk         (clk),
        .rst         (rst),
        .f_pc         (f_pc),
        .load_pipeline (load_pipeline),

        .imem_address(imem_address), // going to icache
        .imem_read   (imem_read), // going to icache
        .imem_rdata  (imem_rdata), // coming from icache
        .imem_resp   (imem_resp), // coming from icache
        .dmem_address(dmem_address), // going to dcache
        .dmem_read   (dmem_read), // going to dcache
        .dmem_write  (dmem_write), // going to dcache
        .dmem_wmask  (dmem_wmask), // going to dcache
        .dmem_rdata  (dmem_rdata), // coming from dcache
        .dmem_wdata  (dmem_wdata), // going to dcache
        .dmem_resp   (dmem_resp)  // coming from dcache
    );

`ifdef USE_CACHE
////////////////////////////////////////////////////////////////////////////////////////////////////
    bus_adapter BUS_ADAPTOR_I
    (
        .address            (f_pc), //!!!!!!!!!!! THIS NEEDS TO BE PC FROM CPU, !NOT! pcmux_out!
        .mem_wdata256       (imem_wdata256), // going to icache -- unused
        .mem_rdata256       (imem_rdata256), // coming from icache
        .mem_wdata          (32'b0), // coming from cpu
        .mem_rdata          (imem_rdata), // going to cpu
        .mem_byte_enable    (4'b0), // coming from cpu
        .mem_byte_enable256 (imem_byte_enable256)  // going to icache -- unused
    );

    bus_adapter BUS_ADAPTOR_D
    (
        .address            (dmem_address), // coming from cpu
        .mem_wdata256       (dmem_wdata256), // going to dcache
        .mem_rdata256       (dmem_rdata256), // coming from dcache
        .mem_wdata          (dmem_wdata), // coming from cpu
        .mem_rdata          (dmem_rdata), // going to cpu
        .mem_byte_enable    (dmem_wmask), // coming from cpu
        .mem_byte_enable256 (dmem_byte_enable256)  // going to dcache
    );

    `define USE_PIPELINE_CACHE
    `ifdef USE_PIPELINE_CACHE
        pipelined_rcache I_CACHE
        (
            .clk                (clk),
            .rst                (rst),
            .pc_out             (f_pc),
            .load_pipeline      (load_pipeline),
            .mem_address        (imem_address), // coming from cpu
            .mem_rdata          (imem_rdata256), // going to bus adaptor
            .mem_resp           (imem_resp), // going to cpu
            .pmem_address       (ipmem_address), // going to arbiter
            .pmem_read          (ipmem_read), // going to arbiter
            .pmem_rdata         (ipmem_rdata), // coming from arbiter
            .pmem_resp          (ipmem_resp)  // coming from arbiter
        );
    `else
        cache I_CACHE
        (
            .clk                (clk),
            .rst                (rst),
            .mem_address        (imem_address), // coming from cpu
            .mem_read           (imem_read), // coming from cpu
            .mem_write          (1'b0), // coming from cpu -- never write to icache
            .mem_byte_enable    (32'b0), // coming from bus adaptor -- never write to icache
            .mem_rdata          (imem_rdata256), // going to bus adaptor
            .mem_wdata          (256'b0), // coming from bus adaptor
            .mem_resp           (imem_resp), // going to cpu
            .pmem_address       (ipmem_address), // going to arbiter
            .pmem_read          (ipmem_read), // going to arbiter
            .pmem_write         (ipmem_write), // going to arbiter
            .pmem_rdata         (ipmem_rdata), // coming from arbiter
            .pmem_wdata         (ipmem_wdata), // going to arbiter
            .pmem_resp          (ipmem_resp)  // coming from arbiter
        );
    `endif

    dcache D_CACHE
    (
        .clk                (clk),
        .rst                (rst),
        .mem_address        (dmem_address), // coming from arbiter
        .mem_read           (dmem_read), // coming from arbiter
        .mem_write          (dmem_write), // coming from arbiter
        .mem_byte_enable    (dmem_byte_enable256), // coming from bus adaptor
        .mem_rdata          (dmem_rdata256), // going to bus adaptor
        .mem_wdata          (dmem_wdata256), // coming from bus adaptor
        .mem_resp           (dmem_resp), // going to cache
        .pmem_address       (dpmem_address), // going to cacheline adaptor
        .pmem_read          (dpmem_read), // going to cacheline adpator
        .pmem_write         (dpmem_write), // going to cacheline adaptor
        .pmem_rdata         (dpmem_rdata), // coming from cacheline adaptor
        .pmem_wdata         (dpmem_wdata), // going to cacheline adaptor
        .pmem_resp          (dpmem_resp)  // coming from cacheline adaptor
    );

    `define PREFETCH
    `ifdef  PREFETCH 
        prefetch_arbiter ARBITER
    `else 
        arbiter ARBITER
    `endif 
    (
        .clk                 (clk),
        .rst                 (rst),
        .ipmem_address       (ipmem_address), // from icache
        .ipmem_read          (ipmem_read), // from icache
        .ipmem_rdata         (ipmem_rdata), // to icache
        .ipmem_resp          (ipmem_resp), // to icache
        .dpmem_address       (dpmem_address), // from dcache
        .dpmem_read          (dpmem_read), // from dcache
        .dpmem_write         (dpmem_write), // from dcache
        .dpmem_rdata         (dpmem_rdata), // to dcache
        .dpmem_wdata         (dpmem_wdata), // from dcache
        .dpmem_resp          (dpmem_resp), // to dcache
        .line_i              (line_i), // output (from i/d cache to cacheline adaptor)
        .line_o              (line_o), // input (from cacheline adaptor to i/d cache)
        .address_i           (address_i), // output (from i/d cache to cacheline adaptor)
        .read_i              (read_i), // output (from i/d cache to cacheline adaptor)
        .write_i             (write_i), // output (from i/d cache to cacheline adaptor)
        .resp_o              (resp_o) // input (from cacheline adaptor to i/d cache)
    );

    cacheline_adaptor CACHELINE_ADAPTOR
    (
        .clk        (clk),
        .reset_n    (~rst), // !!! ACTIVE LOW !!!

        .line_i     (line_i), // coming from arbiter -- wdata
        .line_o     (line_o), // going to arbiter -- rdata
        .address_i  (address_i), // coming from arbiter
        .read_i     (read_i), // coming from arbiter
        .write_i    (write_i), // coming from arbiter
        .resp_o     (resp_o), // going to arbiter

        .burst_i    (bmem_rdata), //bmem_rdata
        .burst_o    (bmem_wdata), //bmem_wdata
        .address_o  (bmem_address), //bmem_address
        .read_o     (bmem_read), // bmem_read
        .write_o    (bmem_write), //bmem_write
        .resp_i     (bmem_resp) //bmem_resp
    );
`endif
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    logic   [0:0]   monitor_valid;
    logic   [63:0]  monitor_order;
    logic   [31:0]  monitor_inst;
    logic   [4:0]   monitor_rs1_addr;
    logic   [4:0]   monitor_rs2_addr;
    logic   [31:0]  monitor_rs1_rdata;
    logic   [31:0]  monitor_rs2_rdata;
    logic   [4:0]   monitor_rd_addr;
    logic   [31:0]  monitor_rd_wdata;
    logic   [31:0]  monitor_pc_rdata;
    logic   [31:0]  monitor_pc_wdata;
    logic   [31:0]  monitor_mem_addr;
    logic   [3:0]   monitor_mem_rmask;
    logic   [3:0]   monitor_mem_wmask;
    logic   [31:0]  monitor_mem_rdata;
    logic   [31:0]  monitor_mem_wdata;

    // Fill this out
    // Only use hierarchical references here for verification
    // **DO NOT** use hierarchical references in the actual design!
    assign monitor_valid     = CPU.valid;   // valid and order still come from writeback stage
    assign monitor_order     = CPU.order;
    assign monitor_inst      = CPU.mem_wb.ir; // equivalent of IR register
    assign monitor_rs1_addr  = CPU.mem_wb.instr.rs1;
    assign monitor_rs2_addr  = CPU.mem_wb.instr.rs2;
    assign monitor_rs1_rdata = CPU.mem_wb.reg_out.rs1_data;
    assign monitor_rs2_rdata = CPU.mem_wb.reg_out.rs2_data;
    assign monitor_rd_addr   = CPU.mem_wb.instr.rd;
    assign monitor_rd_wdata  = CPU.wb_regfilemux_out;
    assign monitor_pc_rdata  = CPU.mem_wb.reg_out.pc_out;
    assign monitor_pc_wdata  = CPU.mem_wb.reg_out.pcmux_out;
    assign monitor_mem_addr  = CPU.mem_wb.dmem_all.dmem_address;
    assign monitor_mem_rmask = CPU.mem_wb.dmem_all.dmem_read ? CPU.mem_wb.dmem_all.dmem_rmask : '0;
    assign monitor_mem_wmask = CPU.mem_wb.dmem_all.dmem_write ? CPU.mem_wb.dmem_all.dmem_wmask : '0;
    assign monitor_mem_rdata = (CPU.mem_wb.dmem_all.dmem_read & CPU.mem_wb.dmem_all.dmem_resp) ? CPU.wb_mem_rdata : '0; // CPU.mem_wb.dmem_all.dmem_rdata;
    assign monitor_mem_wdata = (CPU.mem_wb.dmem_all.dmem_write & CPU.mem_wb.dmem_all.dmem_resp) ? CPU.mem_wb.dmem_all.dmem_wdata : '0;

endmodule : mp4
