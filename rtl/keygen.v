module keygen (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  p,
    input  wire [7:0]  q,
    output reg  [15:0] n,
    output reg  [15:0] phi,
    output reg  [15:0] e,
    output reg  [15:0] d,
    output reg         done,
    output reg         error
);

localparam K_IDLE   = 3'd0,
           K_FIND_E = 3'd1,
           K_FIND_D = 3'd2;

reg [2:0]  state;
reg [15:0] e_c;
reg [15:0] d_c;

wire [15:0] p_ext    = {8'd0, p};
wire [15:0] q_ext    = {8'd0, q};
wire [15:0] n_calc   = p_ext * q_ext;
wire [15:0] phi_calc = (p_ext - 16'd1) * (q_ext - 16'd1);

wire [31:0] ed_prod = {16'd0, e} * {16'd0, d_c};
wire [31:0] ed_mod  = (phi == 16'd0) ? 32'hFFFFFFFF
                                      : (ed_prod % {16'd0, phi});

function [15:0] gcd16;
    input [15:0] a;
    input [15:0] b;
    integer i;
    reg [15:0] x, y, t;
    begin
        x = a;
        y = b;
        for (i = 0; i < 32; i = i + 1) begin
            if (y != 16'd0) begin
                t = x % y;
                x = y;
                y = t;
            end
        end
        gcd16 = x;
    end
endfunction

always @(posedge clk) begin
    if (rst) begin
        state  <= K_IDLE;
        n      <= 16'd0;
        phi    <= 16'd0;
        e      <= 16'd0;
        d      <= 16'd0;
        done   <= 1'b0;
        error  <= 1'b0;
        e_c    <= 16'd2;
        d_c    <= 16'd1;
    end else begin
        case (state)
            K_IDLE: begin
                done <= 1'b0;
                if (start) begin
                    error <= 1'b0;
                    if ((p < 8'd2) || (q < 8'd2) || (phi_calc <= 16'd2)) begin
                        error <= 1'b1;
                        done  <= 1'b1;
                        state <= K_IDLE;
                    end else begin
                        n     <= n_calc;
                        phi   <= phi_calc;
                        e_c   <= 16'd2;
                        d_c   <= 16'd1;
                        state <= K_FIND_E;
                    end
                end
            end
            K_FIND_E: begin
                if (gcd16(e_c, phi) == 16'd1) begin
                    e     <= e_c;
                    d_c   <= 16'd1;
                    state <= K_FIND_D;
                end else if (e_c <= (phi - 16'd2)) begin
                    e_c <= e_c + 16'd1;
                end else begin
                    error <= 1'b1;
                    done  <= 1'b1;
                    state <= K_IDLE;
                end
            end
            K_FIND_D: begin
                if (ed_mod == 32'd1) begin
                    d     <= d_c;
                    done  <= 1'b1;
                    state <= K_IDLE;
                end else if (d_c <= (phi - 16'd2)) begin
                    d_c <= d_c + 16'd1;
                end else begin
                    error <= 1'b1;
                    done  <= 1'b1;
                    state <= K_IDLE;
                end
            end
            default: state <= K_IDLE;
        endcase
    end
end
endmodule
