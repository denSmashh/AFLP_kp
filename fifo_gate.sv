// simple synchronous FIFO

`define READ_FIFO_COMB_OUT
//`define READ_FIFO_REG_OUT

module fifo_gate
#(
    parameter DW = 32,
    parameter FIFO_DEPTH = 5'd16
)
(
    input  logic             clk,
    input  logic             rstn,
    input  logic             wr_en,
    input  logic             rd_en,
    input  logic [DW-1:0]    data_in,
    output logic [DW-1:0]    data_out,
    output logic             empty,
    output logic             full
);
    
localparam AW = $clog2(FIFO_DEPTH);

logic [DW-1:0] ram_fifo [0:FIFO_DEPTH-1];

logic [DW-1:0] ram_fifo_mux;
logic [AW-1:0] write_ptr;   
logic [AW-1:0] read_ptr;
logic [AW:0] status_counter;

logic write_ptr_eq;
logic [AW-1:0] write_ptr_mux;
logic [AW-1:0] write_ptr_incr;

logic read_ptr_eq;
logic [AW-1:0] read_ptr_mux;
logic [AW-1:0] read_ptr_incr;

logic [AW:0] status_cnt_incr;
logic [AW:0] status_cnt_decr;

logic empty_eq;
logic full_eq;

// update write pointer
comp #(.DW(AW)) wr_ptr_eq (.a(write_ptr), .b(FIFO_DEPTH-1), .eq(write_ptr_eq));
adder #(.DW(AW)) incr_wr_ptr (.a(write_ptr), .b(4'b1), .cin('b0), .sum(write_ptr_incr), .cout());
mux2 #(.DW(AW)) mux2_wr_ptr (.a(write_ptr_incr), .b('b0), .sel(write_ptr_eq), .out(write_ptr_mux));

always_ff @(posedge clk) begin : WRITE_FIFO
    if(~rstn) write_ptr <= 0;
    else if (wr_en) begin
        ram_fifo[write_ptr] <= data_in;
        write_ptr <= write_ptr_mux;
    end
end

// update read pointer
comp #(.DW(AW)) rd_tr_eq (.a(read_ptr), .b(FIFO_DEPTH-1), .eq(read_ptr_eq));
adder #(.DW(AW)) incr_rd_ptr (.a(read_ptr), .b(4'b1), .cin('b0), .sum(read_ptr_incr), .cout());
mux2 #(.DW(AW)) mux2_rd_ptr (.a(read_ptr_incr), .b('b0), .sel(read_ptr_eq), .out(read_ptr_mux));

mux16 #(.DW(DW)) i_mux16 (
    .in_1(ram_fifo[0]),   .in_2(ram_fifo[1]),   .in_3(ram_fifo[2]),   .in_4(ram_fifo[3]),
    .in_5(ram_fifo[4]),   .in_6(ram_fifo[5]),   .in_7(ram_fifo[6]),   .in_8(ram_fifo[7]),
    .in_9(ram_fifo[8]),   .in_10(ram_fifo[9]),  .in_11(ram_fifo[10]), .in_12(ram_fifo[11]),
    .in_13(ram_fifo[12]), .in_14(ram_fifo[13]), .in_15(ram_fifo[14]), .in_16(ram_fifo[15]),
    .sel(read_ptr), 
    .out(ram_fifo_mux)
);

`ifdef READ_FIFO_REG_OUT
    always_ff @(posedge clk) begin : READ_FIFO_REG_OUT
        if(~rstn) read_ptr <= 0;
        else if (rd_en) begin
            data_out <= ram_fifo_mux;
            read_ptr <= read_ptr_mux;
        end
    end

`elsif READ_FIFO_COMB_OUT
    always_ff @(posedge clk) begin : READ_FIFO_COMB_OUT
        if(~rstn) read_ptr <= 0;
        else if (rd_en) begin
            read_ptr <= read_ptr_mux;
        end
    end

    assign data_out = ram_fifo_mux;
`endif  

// update status counter
adder #(.DW(AW+4)) incr_status_cnt (.a({3'b0,status_counter}), .b(8'b1), .cin('b0), .sum(status_cnt_incr), .cout());
// A-B = A+(-B) = A+(~B)+1
adder #(.DW(AW+4)) decr_status_cnt (.a({3'b0,status_counter}), .b((~(8'b1) | 8'b1)), .cin('b0), .sum(status_cnt_decr), .cout());

always_ff @(posedge clk) begin : FIFO_CTRL
    if(~rstn) status_counter <= 0;
    else if (wr_en && !rd_en)
        status_counter <= status_cnt_incr;
    else if (!wr_en && rd_en)
        status_counter <= status_cnt_decr;
end

// fifo control signals
comp #(.DW(AW+1)) empty_equal (.a(status_counter), .b('b0), .eq(empty_eq));
comp #(.DW(AW+1)) full_equal (.a(status_counter), .b(FIFO_DEPTH), .eq(full_eq));

assign empty = empty_eq;
assign full = full_eq;

endmodule
