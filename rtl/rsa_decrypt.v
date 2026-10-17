module rsa_decrypt (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [15:0] cipher,
    input  wire [15:0] d,
    input  wire [15:0] n,
    output wire [15:0] recovered,
    output wire        done,
    output wire        error
);

modexp u_modexp (
    .clk    (clk),
    .rst    (rst),
    .start  (start),
    .base   (cipher),
    .exp    (d),
    .modu   (n),
    .result (recovered),
    .done   (done),
    .error  (error)
);
endmodule
