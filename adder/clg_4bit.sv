module clg_4bit
(
    input  logic [3:0]  p,
    input  logic [3:0]  g,
    input               cin,
    output logic [3:0]  cout,
    output logic        pg, 
    output logic        gg
); 

assign cout[0] = g[0] | cin & p[0];

assign cout[1] = g[1] | g[0] & p[1] | cin & p[0] & p[1];

assign cout[2] = g[2] | g[1] & p[2] | g[0] & p[1] & p[2] | cin & p[0] & p[1] & p[2];

assign cout[3] = g[3] | g[2] & p[3] | g[1] & p[2] & p[3] | g[0] & p[1] & p[2] & p[3] | cin & p[0] & p[1] & p[2] & p[3];

assign pg = p[0] & p[1] & p[2] & p[3];

assign gg = g[3] | p[3] & g[2] | p[3] & p[2] & g[1] | p[3] & p[2] & p[1] & g[0];

endmodule