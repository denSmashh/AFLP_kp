`timescale 1ns/1ns

module network_router_fsm_tb();

// PACKET: {Destination_IP[DEST_IP_LEN-1:0] , Payload[PAYLOAD_LEN-1:0] , CRC[CRC_LEN-1:0]}
localparam DEST_IP_LEN = 32;         
localparam PAYLOAD_LEN = 32;
localparam CRC_LEN = (DEST_IP_LEN > PAYLOAD_LEN) ? (DEST_IP_LEN) :
                     (DEST_IP_LEN < PAYLOAD_LEN) ? (PAYLOAD_LEN) : (DEST_IP_LEN + 1);
localparam PKT_LEN = DEST_IP_LEN + PAYLOAD_LEN + CRC_LEN;

logic clk;
logic rstn;   
logic port_wan_vld;
logic [PKT_LEN-1:0] port_wan;         
logic port_1_en;          
logic [DEST_IP_LEN-1:0] port_1_ip;
logic [PKT_LEN-1:0] port_1;          
logic port_2_en;          
logic [DEST_IP_LEN-1:0] port_2_ip;          
logic [PKT_LEN-1:0] port_2;          
logic port_3_en;          
logic [DEST_IP_LEN-1:0] port_3_ip;          
logic [PKT_LEN-1:0] port_3;          
logic port_4_en;          
logic [DEST_IP_LEN-1:0] port_4_ip;          
logic [PKT_LEN-1:0] port_4;          
logic congestion;         
logic pkt_drop;         
logic crc_error;         
logic link_down;          
logic pkt_tx_vld;          

network_router_fsm dut_network_router_fsm
(
    .clk(clk),
    .rstn(rstn),
    .port_wan_vld(port_wan_vld),
    .port_wan(port_wan),
    .port_1_en(port_1_en),          
    .port_1_ip(port_1_ip),          
    .port_1(port_1),             
    .port_2_en(port_2_en),          
    .port_2_ip(port_2_ip),          
    .port_2(port_2),             
    .port_3_en(port_3_en),          
    .port_3_ip(port_3_ip),          
    .port_3(port_3),             
    .port_4_en(port_4_en),         
    .port_4_ip(port_4_ip),          
    .port_4(port_4),             
    .congestion(congestion),
    .pkt_drop(pkt_drop),           
    .crc_error(crc_error),          
    .link_down(link_down),          
    .pkt_tx_vld(pkt_tx_vld)
);


task  enable_port_1;
    //input logic [DEST_IP_LEN-1:0] port_ip;
    @(posedge clk);
    port_1_en <= 1'b1;
    //port_1_ip <= port_ip;
    port_1_ip <= $urandom();
endtask

task  disable_port_1;
    @(posedge clk);
    port_1_en <= 1'b0;
endtask

task  enable_port_2;
    //input logic [DEST_IP_LEN-1:0] port_ip;
    @(posedge clk);
    port_2_en <= 1'b1;
    //port_2_ip <= port_ip;
    port_2_ip <= $urandom();
endtask

task  disable_port_2;
    @(posedge clk);
    port_2_en <= 1'b0;
endtask

task  enable_port_3;
    //input logic [DEST_IP_LEN-1:0] port_ip;
    @(posedge clk);
    port_3_en <= 1'b1;
    //port_3_ip <= port_ip;
    port_3_ip <= $urandom();
endtask

task  disable_port_3;
    @(posedge clk);
    port_3_en <= 1'b0;
endtask

task  enable_port_4;
    //input logic [DEST_IP_LEN-1:0] port_ip;
    @(posedge clk);
    port_4_en <= 1'b1;
    //port_4_ip <= port_ip;
    port_4_ip <= $urandom();
endtask

task  disable_port_4;
    @(posedge clk);
    port_4_en <= 1'b0;
endtask

task  disable_all_ports;
    @(posedge clk);
    port_1_en <= 1'b0;
    port_2_en <= 1'b0;
    port_3_en <= 1'b0;
    port_4_en <= 1'b0;
endtask

task  enable_all_ports;
    @(posedge clk);
    port_1_en <= 1'b1;
    port_2_en <= 1'b1;
    port_3_en <= 1'b1;
    port_4_en <= 1'b1;
endtask

task  gen_rand_wan_pkt;
    input logic drop;
    input logic crc_error;
    logic [DEST_IP_LEN-1:0] dip;
    logic [DEST_IP_LEN-1:0] rand_dip;
    logic [PAYLOAD_LEN-1:0] payload;
    logic [CRC_LEN-1:0] crc;
    logic [CRC_LEN-1:0] rand_crc;

    payload = $urandom();
    #1
    if(drop == 1) begin
        while (1) begin
            rand_dip = $urandom();
            if(rand_dip != port_1_ip && rand_dip != port_2_ip && rand_dip != port_3_ip && rand_dip != port_4_ip)
                break;
        end
        dip <= rand_dip;
    end else begin
        rand_dip = $urandom_range(1, 4);
        case (rand_dip)
            1: dip <= port_1_ip;
            2: dip <= port_2_ip;
            3: dip <= port_3_ip;
            4: dip <= port_4_ip;
            default: dip <= 0;
        endcase
    end
    #1
    if(crc_error == 1) begin
        while (1) begin 
            rand_crc = $urandom();
            if(rand_crc != payload + dip)
                break;
        end
        crc <= rand_crc;
    end else begin
        crc <= payload + dip;
    end
    #1
    @(posedge clk);
    port_wan_vld <= 1'b1;
    port_wan <= {dip, payload, crc};
    @(posedge clk);
    port_wan_vld <= 1'b0;
endtask


initial begin
    clk = '0;
    forever #5 clk = ~clk;
end

initial begin
    // Reset inputs
    {port_1_ip, port_2_ip, port_3_ip, port_4_ip} <= 'b0;
    {port_1_en, port_2_en, port_3_en, port_4_en} <= 4'b0;
    port_wan_vld <= 1'b0;
    

    // Reset (Active - Low)
    rstn <= 1'b0;
    repeat (2) @(posedge clk);
    rstn <= 1'b1;

    // PACKET: {Destination_IP[DEST_IP_LEN-1:0] , Payload[PAYLOAD_LEN-1:0] , CRC[CRC_LEN-1:0]}
    
    // Test
    enable_port_1();
    enable_port_2();
    enable_port_3();
    enable_port_4();
    
    for (int i = 0; i < 10; i = i + 1) begin    // valid pkt
        repeat (2) @(posedge clk);
        gen_rand_wan_pkt(0,0);
    end

    for (int i = 0; i < 10; i = i + 1) begin    // drop pkt
        repeat (4) @(posedge clk);
        gen_rand_wan_pkt(1,0);
    end
    
    for (int i = 0; i < 10; i = i + 1) begin    // crc error pkt
        repeat (4) @(posedge clk);
        gen_rand_wan_pkt(0,1);
    end
    
    repeat (15) @(posedge clk);
    for (int i = 0; i < 10; i = i + 1) begin    // link down
        @(posedge clk);
        gen_rand_wan_pkt(0,0);
        repeat($urandom_range (0, 3))@(posedge clk); 
        disable_all_ports();
        enable_all_ports();
        repeat(3)@(posedge clk);
        
    end
    
    repeat (3) @(posedge clk);
    for (int i = 0; i < 40; i = i + 1) begin    // valid pkt with congestion
        repeat (1) @(posedge clk);
        gen_rand_wan_pkt(0,0);
    end
    
    
        
    repeat (40) @(posedge clk);
    $finish();
end

endmodule