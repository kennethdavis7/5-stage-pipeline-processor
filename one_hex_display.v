module one_hex_display(binary, hex);
    input wire[3:0] binary;
    output reg[6:0] hex;
	always @(binary) begin
		case (binary)
            4'b0000: begin hex = 7'b1000000; end
            4'b0001: begin hex = 7'b1111001; end
            4'b0010: begin hex = 7'b0100100; end
            4'b0011: begin hex = 7'b0110000; end
            4'b0100: begin hex = 7'b0011001; end
            4'b0101: begin hex = 7'b0010010; end
            4'b0110: begin hex = 7'b0000010; end
            4'b0111: begin hex = 7'b1111000; end
            4'b1000: begin hex = 7'b0000000; end
            default: begin hex = 7'b0010000; end
		endcase
	end
endmodule