module pipelined_rcache #(
    parameter       s_offset = 5,
    parameter       s_index  = 4,
    parameter       s_tag    = 32 - s_offset - s_index,
    parameter       s_mask   = 2**s_offset,
    parameter       s_line   = 8*s_mask,
    parameter       num_sets = 2**s_index
)(
    input                   clk,
    input                   rst,

    /* CPU memory signals */
    input   logic   [31:0]  mem_address,
    output  logic   [255:0] mem_rdata,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read,
    input   logic   [255:0] pmem_rdata,
    input   logic           pmem_resp,

    /* CPU datapath signals */
    input   logic   [31:0]  pc_out,
    input   logic           load_pipeline
);
logic [22:0] tag;
logic [3:0] set;
logic [31:0] cache_address;
logic [22:0] tag_reg_out;
logic [3:0] set_reg_out;
logic [255:0] data_in;
logic [22:0] tag_in;
logic [255:0] data_out;
logic [22:0] tag_out;
logic valid_out;
logic hit;

logic read_in_progress;

mp3_data_array data_array (
    .clk0       (clk),
    .csb0       (1'b0),
    .web0       (!pmem_resp),
    .wmask0     (32'hffffffff),
    .addr0      (set),
    .din0       (pmem_rdata),
    .dout0      (data_out)
);

mp3_tag_array tag_array (
    .clk0       (clk),
    .csb0       (1'b0),
    .web0       (!pmem_resp),
    .addr0      (set),
    .din0       (tag),
    .dout0      (tag_out)
);

ff_array #(.s_index(4), .width(1)) valid_array
(
    .clk0(clk),
    .rst0(rst),
    .csb0(1'b0),
    .web0(!pmem_resp),
    .addr0(set),
    .din0(1'b1),
    .dout0(valid_out)
);

always_comb begin
    hit = 1'b0;
    if (((tag_out == tag_reg_out) && valid_out) && !read_in_progress) begin
        hit = 1'b1;
    end   
end

logic mem_ready;
assign cache_address = (!read_in_progress && load_pipeline) ? mem_address : pc_out;
assign tag = cache_address[31:9];
assign set = cache_address[8:5];
assign pmem_address = {tag_reg_out,set_reg_out,5'b00000};
assign pmem_read = !hit;
assign mem_rdata = mem_ready ? pmem_rdata : data_out;
assign mem_resp = mem_ready ? pmem_resp : hit;

always_ff@(posedge clk) begin
    if(hit || rst || !read_in_progress) begin
        set_reg_out <= set;
        tag_reg_out <= tag;
    end

    if (~pmem_resp && pmem_read) begin
        read_in_progress <= 1'b1;
    end else begin
        read_in_progress <= 1'b0;
    end

    if (pmem_resp && pmem_read) begin
        mem_ready <= 1'b1;
    end else begin
        mem_ready <= 1'b0;
    end
end

endmodule : pipelined_rcache