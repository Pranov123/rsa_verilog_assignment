`timescale 1ns/1ps

module tb_rsa;

reg         clk;
reg         rst;
reg         start;
reg  [7:0]  p;
reg  [7:0]  q;
reg  [15:0] message;

wire [15:0] n;
wire [15:0] phi;
wire [15:0] e;
wire [15:0] d;
wire [15:0] cipher;
wire [15:0] recovered;
wire        match;
wire        done;
wire        busy;
wire        error;

wire [2:0] fsm_state;
wire [2:0] kg_state;
wire [2:0] enc_state;
wire [2:0] dec_state;

assign fsm_state = dut.state;
assign kg_state  = dut.u_keygen.state;
assign enc_state = dut.u_encrypt.u_modexp.state;
assign dec_state = dut.u_decrypt.u_modexp.state;

integer errors;
integer i;
reg [15:0] msgs [0:4];
reg [15:0] exps [0:4];

rsa_top dut (
    .clk       (clk),
    .rst       (rst),
    .start     (start),
    .p         (p),
    .q         (q),
    .message   (message),
    .n         (n),
    .phi       (phi),
    .e         (e),
    .d         (d),
    .cipher    (cipher),
    .recovered (recovered),
    .match     (match),
    .done      (done),
    .busy      (busy),
    .error     (error)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("/content/rsa_submission/rsa.vcd");
    $dumpvars(0, tb_rsa);
end

initial begin
    errors = 0;
    rst     = 1'b1;
    start   = 1'b0;
    p       = 8'd3;
    q       = 8'd11;
    message = 16'd0;

    msgs[0] = 16'd4;  exps[0] = 16'd31;
    msgs[1] = 16'd10; exps[1] = 16'd10;
    msgs[2] = 16'd32; exps[2] = 16'd32;
    msgs[3] = 16'd5;  exps[3] = 16'd26;
    msgs[4] = 16'd25; exps[4] = 16'd16;

    repeat (3) @(posedge clk);
    rst = 1'b0;
    repeat (2) @(posedge clk);

    $display("==========================================================");
    $display(" RSA Verilog Testbench");
    $display(" p=3  q=11  expected n=33 phi=20 e=3 d=7");
    $display("==========================================================");

    for (i = 0; i < 5; i = i + 1) begin
        @(negedge clk);
        message = msgs[i];
        start   = 1'b1;
        @(negedge clk);
        start   = 1'b0;

        wait (done == 1'b1);
        @(posedge clk);

        $display("  M=%0d  n=%0d  phi=%0d  e=%0d  d=%0d  C=%0d  M'=%0d  match=%0d  err=%0d",
                 message, n, phi, e, d, cipher, recovered, match, error);

        if ((n !== 16'd33) || (phi !== 16'd20) || (e !== 16'd3) || (d !== 16'd7)) begin
            $display("    FAIL: key mismatch");
            errors = errors + 1;
        end else if (cipher !== exps[i]) begin
            $display("    FAIL: expected C=%0d", exps[i]);
            errors = errors + 1;
        end else if ((recovered !== msgs[i]) || (match !== 1'b1)) begin
            $display("    FAIL: round-trip mismatch");
            errors = errors + 1;
        end else if (error !== 1'b0) begin
            $display("    FAIL: unexpected error");
            errors = errors + 1;
        end else begin
            $display("    PASS");
        end
    end

    $display("----------------------------------------------------------");
    if (errors == 0) begin
        $display(" RESULT: 5/5 PASS");
        $display(" OVERALL: PASS");
    end else begin
        $display(" RESULT: %0d FAILURES", errors);
        $display(" OVERALL: FAIL");
    end
    $display("==========================================================");
    $finish;
end

initial begin
    #2000000;
    $display("GLOBAL TIMEOUT");
    $finish;
end
endmodule
