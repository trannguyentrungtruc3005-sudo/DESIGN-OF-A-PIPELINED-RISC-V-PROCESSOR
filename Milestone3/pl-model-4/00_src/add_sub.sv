module add_sub(
	input logic [31:0] x,y,
	input logic c_in,
	output logic [31:0] s,
	output logic c_out
	);
	
	logic[30:0] tmp;
	
  full_adder bit_0(.x(x[0]), .y(y[0]^c_in), .z(c_in), .s(s[0]), .c(tmp[0]));
  full_adder bit_1(.x(x[1]), .y(y[1]^c_in), .z(tmp[0]), .s(s[1]), .c(tmp[1]));
  full_adder bit_2(.x(x[2]), .y(y[2]^c_in), .z(tmp[1]), .s(s[2]), .c(tmp[2]));
  full_adder bit_3(.x(x[3]), .y(y[3]^c_in), .z(tmp[2]), .s(s[3]), .c(tmp[3]));
  full_adder bit_4(.x(x[4]), .y(y[4]^c_in), .z(tmp[3]), .s(s[4]), .c(tmp[4]));
  full_adder bit_5(.x(x[5]), .y(y[5]^c_in), .z(tmp[4]), .s(s[5]), .c(tmp[5]));
  full_adder bit_6(.x(x[6]), .y(y[6]^c_in), .z(tmp[5]), .s(s[6]), .c(tmp[6]));
  full_adder bit_7(.x(x[7]), .y(y[7]^c_in), .z(tmp[6]), .s(s[7]), .c(tmp[7]));
  full_adder bit_8(.x(x[8]), .y(y[8]^c_in), .z(tmp[7]), .s(s[8]), .c(tmp[8]));
  full_adder bit_9(.x(x[9]), .y(y[9]^c_in), .z(tmp[8]), .s(s[9]), .c(tmp[9]));
  full_adder bit_10(.x(x[10]), .y(y[10]^c_in), .z(tmp[9]), .s(s[10]), .c(tmp[10]));
  full_adder bit_11(.x(x[11]), .y(y[11]^c_in), .z(tmp[10]), .s(s[11]), .c(tmp[11]));
  full_adder bit_12(.x(x[12]), .y(y[12]^c_in), .z(tmp[11]), .s(s[12]), .c(tmp[12]));
  full_adder bit_13(.x(x[13]), .y(y[13]^c_in), .z(tmp[12]), .s(s[13]), .c(tmp[13]));
  full_adder bit_14(.x(x[14]), .y(y[14]^c_in), .z(tmp[13]), .s(s[14]), .c(tmp[14]));
  full_adder bit_15(.x(x[15]), .y(y[15]^c_in), .z(tmp[14]), .s(s[15]), .c(tmp[15]));
  full_adder bit_16(.x(x[16]), .y(y[16]^c_in), .z(tmp[15]), .s(s[16]), .c(tmp[16]));
  full_adder bit_17(.x(x[17]), .y(y[17]^c_in), .z(tmp[16]), .s(s[17]), .c(tmp[17]));
  full_adder bit_18(.x(x[18]), .y(y[18]^c_in), .z(tmp[17]), .s(s[18]), .c(tmp[18]));
  full_adder bit_19(.x(x[19]), .y(y[19]^c_in), .z(tmp[18]), .s(s[19]), .c(tmp[19]));
  full_adder bit_20(.x(x[20]), .y(y[20]^c_in), .z(tmp[19]), .s(s[20]), .c(tmp[20]));
  full_adder bit_21(.x(x[21]), .y(y[21]^c_in), .z(tmp[20]), .s(s[21]), .c(tmp[21]));
  full_adder bit_22(.x(x[22]), .y(y[22]^c_in), .z(tmp[21]), .s(s[22]), .c(tmp[22]));
  full_adder bit_23(.x(x[23]), .y(y[23]^c_in), .z(tmp[22]), .s(s[23]), .c(tmp[23]));
  full_adder bit_24(.x(x[24]), .y(y[24]^c_in), .z(tmp[23]), .s(s[24]), .c(tmp[24]));
  full_adder bit_25(.x(x[25]), .y(y[25]^c_in), .z(tmp[24]), .s(s[25]), .c(tmp[25]));
  full_adder bit_26(.x(x[26]), .y(y[26]^c_in), .z(tmp[25]), .s(s[26]), .c(tmp[26]));
  full_adder bit_27(.x(x[27]), .y(y[27]^c_in), .z(tmp[26]), .s(s[27]), .c(tmp[27]));
  full_adder bit_28(.x(x[28]), .y(y[28]^c_in), .z(tmp[27]), .s(s[28]), .c(tmp[28]));
  full_adder bit_29(.x(x[29]), .y(y[29]^c_in), .z(tmp[28]), .s(s[29]), .c(tmp[29]));
  full_adder bit_30(.x(x[30]), .y(y[30]^c_in), .z(tmp[29]), .s(s[30]), .c(tmp[30]));
  full_adder bit_31(.x(x[31]), .y(y[31]^c_in), .z(tmp[30]), .s(s[31]), .c(c_out));
  
	endmodule
	