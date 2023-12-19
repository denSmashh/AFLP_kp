module mux2
#(
    parameter DW = 32
)
(
    input  logic [DW-1:0] a,
    input  logic [DW-1:0] b,
    input  logic          sel,
    output logic [DW-1:0] out
);

 //assign out = (sel) ? b : a;

always_comb begin
    for (int i = 0; i < DW; i = i + 1) begin
        out[i] = (a[i] & ~sel) | (b[i] & sel);
    end
end

endmodule