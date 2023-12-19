module cla_4bit 
(
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,
    output logic [3:0] s,
    output logic       cout
);

logic [3:0] carry_out;
logic [3:0] prop;
logic [3:0] gen;

rfa i_rfa_0 (.a(a[0]), .b(b[0]), .cin(cin),          .s(s[0]), .p(prop[0]), .g(gen[0]));
rfa i_rfa_1 (.a(a[1]), .b(b[1]), .cin(carry_out[0]), .s(s[1]), .p(prop[1]), .g(gen[1]));
rfa i_rfa_2 (.a(a[2]), .b(b[2]), .cin(carry_out[1]), .s(s[2]), .p(prop[2]), .g(gen[2]));
rfa i_rfa_3 (.a(a[3]), .b(b[3]), .cin(carry_out[2]), .s(s[3]), .p(prop[3]), .g(gen[3]));

clg_4bit i_clg_4bit (.p(prop), .g(gen), .cin(cin), .cout(carry_out), .pg(), .gg()); 

assign cout = carry_out[3];

endmodule