module rsa_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  p,
    input  wire [7:0]  q,
    input  wire [15:0] message,
    output wire [15:0] n,
    output wire [15:0] phi,
    output wire [15:0] e,
    output wire [15:0] d,
    output wire [15:0] cipher,
    output wire [15:0] recovered,
    output reg         match,
    output reg         done,
    output wire        busy,
    output reg         error
);

localparam T_IDLE = 3'd0,
           T_KG   = 3'd1,
           T_ENC  = 3'd2,
           T_DEC  = 3'd3,
           T_DONE = 3'd4;

reg [2:0]  state;
reg [15:0] msg_r;
reg        kg_start;
reg        enc_start;
reg        dec_start;

wire [15:0] n_int;
wire [15:0] phi_int;
wire [15:0] e_int;
wire [15:0] d_int;
wire [15:0] cipher_int;
wire [15:0] recovered_int;

wire kg_done;
wire kg_error;
wire enc_done;
wire enc_error;
wire dec_done;
wire dec_error;

keygen u_keygen (
    .clk   (clk),
    .rst   (rst),
    .start (kg_start),
    .p     (p),
    .q     (q),
    .n     (n_int),
    .phi   (phi_int),
    .e     (e_int),
    .d     (d_int),
    .done  (kg_done),
    .error (kg_error)
);

rsa_encrypt u_encrypt (
    .clk     (clk),
    .rst     (rst),
    .start   (enc_start),
    .message (msg_r),
    .e       (e_int),
    .n       (n_int),
    .cipher  (cipher_int),
    .done    (enc_done),
    .error   (enc_error)
);

rsa_decrypt u_decrypt (
    .clk       (clk),
    .rst       (rst),
    .start     (dec_start),
    .cipher    (cipher_int),
    .d         (d_int),
    .n         (n_int),
    .recovered (recovered_int),
    .done      (dec_done),
    .error     (dec_error)
);

assign n         = n_int;
assign phi       = phi_int;
assign e         = e_int;
assign d         = d_int;
assign cipher    = cipher_int;
assign recovered = recovered_int;
assign busy      = (state != T_IDLE) && (state != T_DONE);

always @(posedge clk) begin
    if (rst) begin
        state     <= T_IDLE;
        msg_r     <= 16'd0;
        kg_start  <= 1'b0;
        enc_start <= 1'b0;
        dec_start <= 1'b0;
        match     <= 1'b0;
        done      <= 1'b0;
        error     <= 1'b0;
    end else begin
        case (state)
            T_IDLE: begin
                kg_start  <= 1'b0;
                enc_start <= 1'b0;
                dec_start <= 1'b0;
                done      <= 1'b0;
                if (start) begin
                    msg_r    <= message;
                    match    <= 1'b0;
                    error    <= 1'b0;
                    kg_start <= 1'b1;
                    state    <= T_KG;
                end
            end
            T_KG: begin
                kg_start <= 1'b0;
                if (kg_error) begin
                    error <= 1'b1;
                    done  <= 1'b1;
                    state <= T_DONE;
                end else if (kg_done) begin
                    if (msg_r >= n_int) begin
                        error <= 1'b1;
                        done  <= 1'b1;
                        state <= T_DONE;
                    end else begin
                        enc_start <= 1'b1;
                        state     <= T_ENC;
                    end
                end
            end
            T_ENC: begin
                enc_start <= 1'b0;
                if (enc_error) begin
                    error <= 1'b1;
                    done  <= 1'b1;
                    state <= T_DONE;
                end else if (enc_done) begin
                    dec_start <= 1'b1;
                    state     <= T_DEC;
                end
            end
            T_DEC: begin
                dec_start <= 1'b0;
                if (dec_error) begin
                    error <= 1'b1;
                    done  <= 1'b1;
                    state <= T_DONE;
                end else if (dec_done) begin
                    match <= (recovered_int == msg_r);
                    done  <= 1'b1;
                    state <= T_DONE;
                end
            end
            T_DONE: begin
                done <= 1'b1;
                if (start) begin
                    done      <= 1'b0;
                    match     <= 1'b0;
                    error     <= 1'b0;
                    msg_r     <= message;
                    kg_start  <= 1'b1;
                    state     <= T_KG;
                end
            end
            default: state <= T_IDLE;
        endcase
    end
end
endmodule
