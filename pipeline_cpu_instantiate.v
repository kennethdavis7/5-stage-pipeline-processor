module pipeline_cpu_instantiate(
    input CLOCK_50, 
    input[9:0] SW, 
    output[6:0] HEX0, 
    output[6:0] HEX1, 
    output[6:0] HEX2, 
    output[6:0] HEX3, 
    output[6:0] HEX4, 
    output[6:0] HEX5,
    output[6:0] HEX6
    );

    wire[3:0] r1, r2, r3, r4, r5, r6, r7; 

    pipeline_cpu CPU(.clk(CLOCK_50), .reset(SW[0]), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7));

    one_hex_display display0(.binary(r1), .hex(HEX0));
    one_hex_display display1(.binary(r2), .hex(HEX1));
    one_hex_display display2(.binary(r3), .hex(HEX2));
    one_hex_display display3(.binary(r4), .hex(HEX3));
    one_hex_display display4(.binary(r5), .hex(HEX4));
    one_hex_display display5(.binary(r6), .hex(HEX5));
    one_hex_display display6(.binary(r7), .hex(HEX6));

endmodule