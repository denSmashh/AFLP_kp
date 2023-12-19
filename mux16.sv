module mux16
#(
    parameter DW = 32
)
(
    input  logic [DW-1:0] in_1,
    input  logic [DW-1:0] in_2,
    input  logic [DW-1:0] in_3,
    input  logic [DW-1:0] in_4,
    input  logic [DW-1:0] in_5,
    input  logic [DW-1:0] in_6,
    input  logic [DW-1:0] in_7,
    input  logic [DW-1:0] in_8,
    input  logic [DW-1:0] in_9,
    input  logic [DW-1:0] in_10,
    input  logic [DW-1:0] in_11,
    input  logic [DW-1:0] in_12,
    input  logic [DW-1:0] in_13,
    input  logic [DW-1:0] in_14,
    input  logic [DW-1:0] in_15,
    input  logic [DW-1:0] in_16,
    input  logic [3:0]    sel,
    output logic [DW-1:0] out
);

wire [DW-1:0] mux4_1_out;
wire [DW-1:0] mux4_2_out;
wire [DW-1:0] mux4_3_out;
wire [DW-1:0] mux4_4_out;

mux4 #(.DW(DW)) mux4_1 (.a(in_1),  .b(in_2),  .c(in_3),  .d(in_4),  .sel(sel[1:0]), .out(mux4_1_out));
mux4 #(.DW(DW)) mux4_2 (.a(in_5),  .b(in_6),  .c(in_7),  .d(in_8),  .sel(sel[1:0]), .out(mux4_2_out));
mux4 #(.DW(DW)) mux4_3 (.a(in_9),  .b(in_10), .c(in_11), .d(in_12), .sel(sel[1:0]), .out(mux4_3_out));
mux4 #(.DW(DW)) mux4_4 (.a(in_13), .b(in_14), .c(in_15), .d(in_16), .sel(sel[1:0]), .out(mux4_4_out));

mux4 #(.DW(DW)) mux4_5 (.a(mux4_1_out), .b(mux4_2_out), .c(mux4_3_out), .d(mux4_4_out), .sel(sel[3:2]), .out(out));

endmodule