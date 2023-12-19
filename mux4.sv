module mux4
#(
    parameter DW = 32
)
(
    input  logic [DW-1:0] a,
    input  logic [DW-1:0] b,
    input  logic [DW-1:0] c,
    input  logic [DW-1:0] d,
    input  logic [1:0]    sel,
    output logic [DW-1:0] out
);

// assign out = (sel[1]) ? (sel[0] ? d : c) : (sel[0] ? b : a);

wire [DW-1:0] mux2_1_out;
wire [DW-1:0] mux2_2_out;

mux2 #(.DW(DW)) i_mux2_1 (.a(a), .b(b), .sel(sel[0]), .out(mux2_1_out));
mux2 #(.DW(DW)) i_mux2_2 (.a(c), .b(d), .sel(sel[0]), .out(mux2_2_out));

mux2 #(.DW(DW)) i_mux2_3 (.a(mux2_1_out), .b(mux2_2_out), .sel(sel[1]), .out(out));

endmodule