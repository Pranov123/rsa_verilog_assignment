module rsa_encrypt (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [15:0] message,
    input  wire [15:0] e,
    input  wire [15:0] n,
    output wire [15:0] cipher,
    output wire        done,
    output wire        error
);

modexp u_modexp (
    .clk    (clk),
    .rst    (rst),
    .start  (start),
    .base   (message),
    .exp    (e),
    .modu   (n),
    .result (cipher),
    .done   (done),
    .error  (error)
);
endmodule
