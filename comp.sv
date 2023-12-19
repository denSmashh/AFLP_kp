module comp
#(
    parameter DW = 32
)
(
    input  logic [DW-1:0] a,
    input  logic [DW-1:0] b,
    output logic          eq
);

// assign eq = (a == b);

logic [DW-1:0] xnor_wire;

always_comb begin
    for (int i = 0; i < DW; i = i + 1) begin
        xnor_wire[i] = (a[i] & b[i]) | (~a[i] & ~b[i]);
    end
end

assign eq = &(xnor_wire);


endmodule