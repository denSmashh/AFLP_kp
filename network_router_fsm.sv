module network_router_fsm
#(
    // PACKET: {Destination_IP[DEST_IP_LEN-1:0] , Payload[PAYLOAD_LEN-1:0] , CRC[CRC_LEN-1:0]}
    parameter  DEST_IP_LEN = 32,         
    parameter  PAYLOAD_LEN = 32,
    parameter  CRC_LEN     = (DEST_IP_LEN > PAYLOAD_LEN) ? (DEST_IP_LEN) : 
                             (DEST_IP_LEN < PAYLOAD_LEN) ? (PAYLOAD_LEN) : (DEST_IP_LEN + 1),
    parameter  PKT_LEN     = DEST_IP_LEN + PAYLOAD_LEN + CRC_LEN
)
(
    input  logic                    clk,
    input  logic                    rstn,
    
    input  logic                    port_wan_vld,       // receive new packet for routing
    input  logic [PKT_LEN-1:0]      port_wan,           // input WAN port
    
    input  logic                    port_1_en,          // physical connection port 1
    input  logic [DEST_IP_LEN-1:0]  port_1_ip,          // ip adress port 1
    output logic [PKT_LEN-1:0]      port_1,             // output port 1

    input  logic                    port_2_en,          // physical connection port 2
    input  logic [DEST_IP_LEN-1:0]  port_2_ip,          // ip adress port 2
    output logic [PKT_LEN-1:0]      port_2,             // output port 2

    input  logic                    port_3_en,          // physical connection port 3
    input  logic [DEST_IP_LEN-1:0]  port_3_ip,          // ip adress port 3
    output logic [PKT_LEN-1:0]      port_3,             // output port 3

    input  logic                    port_4_en,          // physical connection port 4
    input  logic [DEST_IP_LEN-1:0]  port_4_ip,          // ip adress port 4
    output logic [PKT_LEN-1:0]      port_4,             // output port 4

    output logic                    congestion,         // fifo is full
    output logic                    pkt_drop,           // packet drop
    output logic                    crc_error,          // error CRC
    output logic                    link_down,          // link down error for port 4
    output logic                    pkt_tx_vld          // packet transmit done for port 1
);

localparam NUM_PORTS   = 4;
localparam STATE_WIDTH = 4;

localparam CRC_OFFSET     = 0;
localparam PAYLOAD_OFFSET = CRC_OFFSET + CRC_LEN;
localparam DEST_IP_OFFSET = PAYLOAD_OFFSET + PAYLOAD_LEN;
localparam ADDER_OP_WIDTH = (CRC_LEN > DEST_IP_LEN | CRC_LEN > PAYLOAD_LEN) ? CRC_LEN / 4 : (CRC_LEN-1) / 4;

//-------------------------------------------- WIRES ----------------------------------------------//
logic               fifo_wr_en;
logic               fifo_rd_en;
logic [PKT_LEN-1:0] fifo_data_in;
logic [PKT_LEN-1:0] fifo_data_out;
logic               fifo_empty;
logic               fifo_full;

logic [PKT_LEN-1:0] pkt_wan;
logic [PKT_LEN-1:0] pkt_wan_ff;
logic dip_port_1_equal;
logic dip_port_2_equal;
logic dip_port_3_equal;
logic dip_port_4_equal;
logic [3:0] port_sel;
logic [3:0] port_sel_ff;

logic [(PAYLOAD_LEN/4)-1:0] crc1_sum;
logic [(PAYLOAD_LEN/4)-1:0] crc2_sum;
logic [(PAYLOAD_LEN/4)-1:0] crc3_sum;
logic [(PAYLOAD_LEN/4)-1:0] crc4_sum;
logic crc1_cout;
logic crc2_cout;
logic crc3_cout;
logic crc4_cout;
logic crc1_cout_ff;
logic crc2_cout_ff;
logic crc3_cout_ff;
logic crc4_cout_ff;
logic crc1_equal;
logic crc2_equal;
logic crc3_equal;
logic crc4_equal;
logic cout_equal;
logic crc1_link;
logic crc2_link;
logic crc3_link;
logic crc4_link;

logic pkt_drop_ff;      
logic crc_error_ff;        
logic link_down_ff;
logic pkt_tx_vld_ff;
logic fifo_rd_en_ff;
logic [PKT_LEN-1:0] port_1_ff;
logic [PKT_LEN-1:0] port_2_ff;
logic [PKT_LEN-1:0] port_3_ff;
logic [PKT_LEN-1:0] port_4_ff;

//--------------------------------------------- FIFO ------------------------------------------------//
fifo_gate #(.DW(PKT_LEN)) i_fifo_gate
(
    .clk(clk),
    .rstn(rstn),
    .wr_en(fifo_wr_en),
    .rd_en(fifo_rd_en),
    .data_in(fifo_data_in),
    .data_out(fifo_data_out),
    .empty(fifo_empty),
    .full(fifo_full)
);

assign fifo_wr_en = port_wan_vld;
assign fifo_data_in = port_wan;
assign congestion = fifo_full;
assign pkt_wan = fifo_data_out;
assign fifo_rd_en = fifo_rd_en_ff;

//----------------------------------------------- FSM -----------------------------------------------//
//typedef enum logic [STATE_WIDTH-1:0] {  IDLE,
//                                        SELECT_PORT,
//                                        CRC_1,
//                                        CRC_2,
//                                        CRC_3,
//                                        CRC_4,
//                                        PKT_DROP,
//                                        PKT_CRC_ERROR,
//                                        LINK_DOWN,
//                                        PKT_TX         } state_t;
                              
//state_t state;
//state_t next_state;

//state_t idle_next_state;
//state_t select_port_next_state;
//state_t crc1_next_state;
//state_t crc2_next_state;
//state_t crc3_next_state;
//state_t crc4_next_state;
//state_t pkt_drop_next_state;
//state_t link_down_next_state;
//state_t pkt_crc_error_next_state;
//state_t pkt_tx_next_state;

localparam logic [STATE_WIDTH-1:0] IDLE          = 'd0,
                                   SELECT_PORT   = 'd1,
                                   CRC_1         = 'd2,
                                   CRC_2         = 'd3,
                                   CRC_3         = 'd4,
                                   CRC_4         = 'd5,
                                   PKT_DROP      = 'd6,
                                   PKT_CRC_ERROR = 'd7,
                                   LINK_DOWN     = 'd8,
                                   PKT_TX        = 'd9;

logic [STATE_WIDTH-1:0] state;
logic [STATE_WIDTH-1:0] next_state;

logic [STATE_WIDTH-1:0] idle_next_state;
logic [STATE_WIDTH-1:0] select_port_next_state;
logic [STATE_WIDTH-1:0] crc1_next_state;
logic [STATE_WIDTH-1:0] crc2_next_state;
logic [STATE_WIDTH-1:0] crc3_next_state;
logic [STATE_WIDTH-1:0] crc4_next_state;
logic [STATE_WIDTH-1:0] pkt_drop_next_state;
logic [STATE_WIDTH-1:0] link_down_next_state;
logic [STATE_WIDTH-1:0] pkt_crc_error_next_state;
logic [STATE_WIDTH-1:0] pkt_tx_next_state;

//---------- transition logic ----------//
always_ff @(posedge clk) begin
    if (~rstn) state <= IDLE;
    else state <= next_state;
end

//---------- next state comb logic --------//

// IDLE 
mux2 #(.DW(STATE_WIDTH)) idle_nxt_state_mux 
      (.a(IDLE), .b(SELECT_PORT), .sel((~fifo_empty) | (port_wan_vld & fifo_empty)), .out(idle_next_state));


// SELECT_PORT
comp #(.DW(DEST_IP_LEN)) dip_port_1_eq (.a(pkt_wan[DEST_IP_OFFSET +: DEST_IP_LEN]), .b(port_1_ip), .eq(dip_port_1_equal));
comp #(.DW(DEST_IP_LEN)) dip_port_2_eq (.a(pkt_wan[DEST_IP_OFFSET +: DEST_IP_LEN]), .b(port_2_ip), .eq(dip_port_2_equal));
comp #(.DW(DEST_IP_LEN)) dip_port_3_eq (.a(pkt_wan[DEST_IP_OFFSET +: DEST_IP_LEN]), .b(port_3_ip), .eq(dip_port_3_equal));
comp #(.DW(DEST_IP_LEN)) dip_port_4_eq (.a(pkt_wan[DEST_IP_OFFSET +: DEST_IP_LEN]), .b(port_4_ip), .eq(dip_port_4_equal));

assign port_sel = { dip_port_4_equal & port_4_en,
                    dip_port_3_equal & port_3_en,
                    dip_port_2_equal & port_2_en,
                    dip_port_1_equal & port_1_en };

mux2 #(.DW(STATE_WIDTH)) sel_port_nxt_state_mux
      (.a(PKT_DROP), .b(CRC_1), .sel(|(port_sel)), .out(select_port_next_state));

always_ff @(posedge clk) begin
    if (~rstn) port_sel_ff <= 'b0;
    else if (state == SELECT_PORT) port_sel_ff <= port_sel;
end

always_ff @(posedge clk) begin
    if (~rstn) pkt_wan_ff <= 'b0;
    else if (state == SELECT_PORT) pkt_wan_ff <= pkt_wan;
end

// CRC_1
adder #(.DW(ADDER_OP_WIDTH)) crc_1_adder 
       (.a(pkt_wan_ff[PAYLOAD_OFFSET +: ADDER_OP_WIDTH]), .b(pkt_wan_ff[DEST_IP_OFFSET +: ADDER_OP_WIDTH]), .cin('b0),
        .sum(crc1_sum), .cout(crc1_cout));

always_ff @(posedge clk) begin
    if (~rstn) crc1_cout_ff <= 'b0;
    else if (state == CRC_1) crc1_cout_ff <= crc1_cout;
end

comp #(.DW(ADDER_OP_WIDTH)) crc_1_eq (.a(crc1_sum), .b(pkt_wan_ff[CRC_OFFSET +: ADDER_OP_WIDTH]), .eq(crc1_equal));

assign crc1_link = |(port_sel_ff & {port_4_en, port_3_en, port_2_en, port_1_en});

mux4 #(.DW(STATE_WIDTH)) crc1_nxt_state_mux
      (.a(LINK_DOWN), .b(PKT_CRC_ERROR), .c(LINK_DOWN), .d(CRC_2), .sel({crc1_equal, crc1_link}), .out(crc1_next_state));


// CRC_2
adder #(.DW(ADDER_OP_WIDTH)) crc_2_adder 
       (.a(pkt_wan_ff[(PAYLOAD_OFFSET + ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .b(pkt_wan_ff[(DEST_IP_OFFSET + ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .cin(crc1_cout_ff),
        .sum(crc2_sum), .cout(crc2_cout));

always_ff @(posedge clk) begin
    if (~rstn) crc2_cout_ff <= 'b0;
    else if (state == CRC_2) crc2_cout_ff <= crc2_cout;
end

comp #(.DW(ADDER_OP_WIDTH)) crc_2_eq (.a(crc2_sum), .b(pkt_wan_ff[(CRC_OFFSET + ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .eq(crc2_equal));

assign crc2_link = |(port_sel_ff & {port_4_en, port_3_en, port_2_en, port_1_en});

mux4 #(.DW(STATE_WIDTH)) crc2_nxt_state_mux
      (.a(LINK_DOWN), .b(PKT_CRC_ERROR), .c(LINK_DOWN), .d(CRC_3), .sel({crc2_equal, crc2_link}), .out(crc2_next_state));


// CRC_3
adder #(.DW(ADDER_OP_WIDTH)) crc_3_adder 
       (.a(pkt_wan_ff[(PAYLOAD_OFFSET + 2*ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .b(pkt_wan_ff[(DEST_IP_OFFSET + 2*ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .cin(crc2_cout_ff),
        .sum(crc3_sum), .cout(crc3_cout));

always_ff @(posedge clk) begin
    if (~rstn) crc3_cout_ff <= 'b0;
    else if (state == CRC_3) crc3_cout_ff <= crc3_cout;
end

comp #(.DW(ADDER_OP_WIDTH)) crc_3_eq (.a(crc3_sum), .b(pkt_wan_ff[(CRC_OFFSET + 2*ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .eq(crc3_equal));

assign crc3_link = |(port_sel_ff & {port_4_en, port_3_en, port_2_en, port_1_en});

mux4 #(.DW(STATE_WIDTH)) crc3_nxt_state_mux
      (.a(LINK_DOWN), .b(PKT_CRC_ERROR), .c(LINK_DOWN), .d(CRC_4), .sel({crc3_equal, crc3_link}), .out(crc3_next_state));


// CRC_4
adder #(.DW(ADDER_OP_WIDTH)) crc_4_adder 
       (.a(pkt_wan_ff[(PAYLOAD_OFFSET + 3*ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .b(pkt_wan_ff[(DEST_IP_OFFSET + 3*ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .cin(crc3_cout_ff),
        .sum(crc4_sum), .cout(crc4_cout));

comp #(.DW(ADDER_OP_WIDTH)) crc_4_eq (.a(crc4_sum), .b(pkt_wan_ff[(CRC_OFFSET + 3*ADDER_OP_WIDTH) +: ADDER_OP_WIDTH]), .eq(crc4_equal));

comp #(.DW(1)) cout_eq (.a(crc4_cout), .b(pkt_wan_ff[CRC_OFFSET + CRC_LEN-1]), .eq(cout_equal));

assign crc4_link = |(port_sel_ff & {port_4_en, port_3_en, port_2_en, port_1_en});

mux4 #(.DW(STATE_WIDTH)) crc4_nxt_state_mux
      (.a(LINK_DOWN), .b(PKT_CRC_ERROR), .c(LINK_DOWN), .d(PKT_TX), .sel({(crc4_equal & cout_equal), crc4_link}), .out(crc4_next_state));


// PKT_DROP
mux2 #(.DW(STATE_WIDTH)) pkr_drop_nxt_state_mux 
      (.a(IDLE), .b(SELECT_PORT), .sel((~fifo_empty) | (port_wan_vld & fifo_empty)), .out(pkt_drop_next_state));


// PKT_CRC_ERROR
mux2 #(.DW(STATE_WIDTH)) pkt_crc_error_nxt_state_mux 
      (.a(IDLE), .b(SELECT_PORT), .sel((~fifo_empty) | (port_wan_vld & fifo_empty)), .out(pkt_crc_error_next_state));


// LINK_DOWN
mux2 #(.DW(STATE_WIDTH)) link_down_nxt_state_mux 
      (.a(IDLE), .b(SELECT_PORT), .sel((~fifo_empty) | (port_wan_vld & fifo_empty)), .out(link_down_next_state));


// PKT_TX
mux2 #(.DW(STATE_WIDTH)) pkt_tx_nxt_state_mux 
      (.a(IDLE), .b(SELECT_PORT), .sel((~fifo_empty) | (port_wan_vld & fifo_empty)), .out(pkt_tx_next_state));


always_comb begin
    case (state)
        IDLE:
            next_state = idle_next_state;
        
        SELECT_PORT: 
            next_state = select_port_next_state;
        
        CRC_1:
            next_state = crc1_next_state;
        
        CRC_2:
            next_state = crc2_next_state;
        
        CRC_3:
            next_state = crc3_next_state;

        CRC_4: 
            next_state = crc4_next_state;

        PKT_DROP: 
            next_state = pkt_drop_next_state;
        
        PKT_CRC_ERROR: 
            next_state = pkt_crc_error_next_state;
        
        LINK_DOWN:
            next_state = link_down_next_state;
        
        PKT_TX:
            next_state = pkt_tx_next_state;
        
        default: 
            next_state = IDLE;
    endcase
end

//---------- output logic --------//

always_ff @(posedge clk) begin
    if (~rstn) fifo_rd_en_ff <= 'b0;
    else if(next_state == SELECT_PORT) fifo_rd_en_ff <= 'b1;
    else fifo_rd_en_ff <= 'b0;
end

always_ff @(posedge clk) begin
    if (~rstn) pkt_drop_ff <= 'b0;
    else if(next_state == PKT_DROP) pkt_drop_ff <= 'b1;
    else pkt_drop_ff <= 'b0;
end

always_ff @(posedge clk) begin
    if (~rstn) crc_error_ff <= 'b0;
    else if(next_state == PKT_CRC_ERROR) crc_error_ff <= 'b1;
    else crc_error_ff <= 'b0;
end

always_ff @(posedge clk) begin
    if (~rstn) link_down_ff <= 'b0;
    else if(next_state == LINK_DOWN) link_down_ff <= 'b1;
    else link_down_ff <= 'b0;
end

always_ff @(posedge clk) begin
    if (~rstn) pkt_tx_vld_ff <= 'b0;
    else if(next_state == PKT_TX) pkt_tx_vld_ff <= 'b1;
    else pkt_tx_vld_ff <= 'b0;
end


always_ff @(posedge clk) begin
    if (~rstn) begin
        port_1_ff <= 'b0;      
        port_2_ff <= 'b0;        
        port_3_ff <= 'b0;
        port_4_ff <= 'b0;
    end
    else if(port_sel_ff[0] && next_state == PKT_TX) begin
        port_1_ff <= pkt_wan_ff;
    end
    else if(port_sel_ff[1] && next_state == PKT_TX) begin
        port_2_ff <= pkt_wan_ff;
    end
    else if(port_sel_ff[2] && next_state == PKT_TX) begin
        port_3_ff <= pkt_wan_ff;
    end
    else if(port_sel_ff[3] && next_state == PKT_TX) begin
        port_4_ff <= pkt_wan_ff;
    end
end

assign pkt_drop = pkt_drop_ff;  
assign crc_error = crc_error_ff; 
assign link_down = link_down_ff; 
assign pkt_tx_vld = pkt_tx_vld_ff;

assign port_1 = port_1_ff;
assign port_2 = port_2_ff;
assign port_3 = port_3_ff;
assign port_4 = port_4_ff;

endmodule