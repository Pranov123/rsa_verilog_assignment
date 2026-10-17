module modexp (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [15:0] base,
    input  wire [15:0] exp,
    input  wire [15:0] modu,
    output reg  [15:0] result,
    output reg         done,
    output reg         error
);

localparam M_IDLE  = 2'd0,
           M_CHECK = 2'd1,
           M_STEP  = 2'd2;

reg [1:0]  state;
reg [15:0] result_r;
reg [15:0] base_r;
reg [15:0] exp_r;

wire [31:0] result_ext = {16'd0, result_r};
wire [31:0] base_ext   = {16'd0, base_r};
wire [31:0] mod_ext    = {16'd0, modu};
wire [31:0] mul_res    = result_ext * base_ext;
wire [31:0] mul_sq     = base_ext * base_ext;
wire [15:0] red_res    = (modu == 16'd0) ? 16'd0 : (mul_res % mod_ext);
wire [15:0] red_sq     = (modu == 16'd0) ? 16'd0 : (mul_sq  % mod_ext);

always @(posedge clk) begin
    if (rst) begin
        state    <= M_IDLE;
        result   <= 16'd0;
        done     <= 1'b0;
        error    <= 1'b0;
        result_r <= 16'd0;
        base_r   <= 16'd0;
        exp_r    <= 16'd0;
    end else begin
        case (state)
            M_IDLE: begin
                done <= 1'b0;
                if (start) begin
                    error <= 1'b0;
                    if (modu == 16'd0) begin
                        error <= 1'b1;
                        done  <= 1'b1;
                        state <= M_IDLE;
                    end else begin
                        result_r <= 16'd1 % modu;
                        base_r   <= base % modu;
                        exp_r    <= exp;
                        state    <= M_CHECK;
                    end
                end
            end
            M_CHECK: begin
                if (exp_r == 16'd0) begin
                    result <= result_r;
                    done   <= 1'b1;
                    state  <= M_IDLE;
                end else begin
                    state <= M_STEP;
                end
            end
            M_STEP: begin
                if (exp_r[0] == 1'b1) begin
                    result_r <= red_res;
                end
                base_r <= red_sq;
                exp_r  <= exp_r >> 1;
                state  <= M_CHECK;
            end
            default: state <= M_IDLE;
        endcase
    end
end
endmodule
