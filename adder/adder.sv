module adder
#(
    parameter DW = 32       // must be divisible on 4 (4, 8, 12, 16, 20, ... 32, ...)
)
(
    input  logic [DW-1:0] a,
    input  logic [DW-1:0] b,
    input  logic          cin,
    output logic [DW-1:0] sum,
    output logic          cout
);

localparam NUM_CLA_4BIT = DW / 4;

logic [NUM_CLA_4BIT-1:0] carry_in;
logic [NUM_CLA_4BIT-1:0] carry_out;

genvar i;
generate
    for (i = 0; i < NUM_CLA_4BIT; i = i + 1) begin : gen_cla_4bit
        if (i == 0) begin
            assign carry_in[0] = cin;
        end else begin
            assign carry_in[i] = carry_out[i-1];
        end 
        
        cla_4bit cla_4bit_gen
        (
            .a(a[i*4+:4]),
            .b(b[i*4+:4]),
            .cin(carry_in[i]),
            .s(sum[i*4+:4]),
            .cout(carry_out[i])
        );
    end
    assign cout = carry_out[NUM_CLA_4BIT-1];
endgenerate

endmodule