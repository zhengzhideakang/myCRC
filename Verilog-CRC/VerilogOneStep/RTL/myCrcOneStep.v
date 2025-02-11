/*
 * @Author       : Xu Xiaokang
 * @Email        :
 * @Date         : 2025-01-28 00:52:08
 * @LastEditors  : Xu Xiaokang
 * @LastEditTime : 2025-02-10 15:45:41
 * @Filename     :
 * @Description  : 任意CRC代码示例
*/

/*
! 模块功能: 计算CRC-单步
* 思路:
  1.
*/

`default_nettype none

module myCrcOneStep
#(
  parameter DIN_WIDTH = 4, // 输入数据位宽, 取值范围为4的倍数: 如4, 8, 12, ...
  parameter WIDTH = 16,                // CRC宽度, 取值范围4~64
  parameter [0:0] REFLECT_IN = 1,      // 输入是否翻转, 取值范围0或1, 1表示反转, 0表示不反转
  parameter [WIDTH-1 : 0] XOR_IN = 'hFFFF, // 输入异或值, 取值范围全1或全0
  parameter [0:0] REFLECT_OUT = 1,     // 输出是否翻转, 取值范围0或1, 1表示反转, 0表示不反转
  parameter [WIDTH-1 : 0] XOR_OUT = 'hFFFF // 输出异或值, 取值范围全1或全0
)(
  output wire [WIDTH-1 : 0] crc_out, // CRC输出
  output reg                crc_out_valid, // CRC输出是否有效, 高电平有效

  input  wire [DIN_WIDTH-1 : 0] din, // 输入数据
  input  wire                   din_valid, // 输入数据有效, 高电平有效

  input  wire clk,
  input  wire rstn
);


//++ 输入寄存与补齐到整数字节 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// DIN_WIDTH向大取最接近的8的倍数, 如1~8取8, 9~16取16, 17~24取24, ...
localparam DIN_WIDTH_TO_8 = ((DIN_WIDTH + 7) / 8) * 8;

reg [DIN_WIDTH_TO_8-1 : 0] din_r;
always @(posedge clk) begin
  if (~rstn)
    din_r <= 'd0;
  else if (din_valid)
    din_r <= {{(DIN_WIDTH % 8){1'b0}}, din};
end
//-- 输入寄存与补齐到整数字节 ------------------------------------------------------------


//++ 输入按字节反转 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [DIN_WIDTH_TO_8-1:0] din_reflected;

generate
if (REFLECT_IN == 1) begin
  // 对每个字节进行位反转
  genvar i;
  for (i = 0; i < DIN_WIDTH_TO_8 / 8; i = i + 1) begin
    assign din_reflected[i*8+7 : i*8] = { din_r[i*8], din_r[i*8+1], din_r[i*8+2], din_r[i*8+3],
                                          din_r[i*8+4], din_r[i*8+5],din_r[i*8+6], din_r[i*8+7]
                                        };
  end
end else begin
  assign din_reflected = din_r;
end
endgenerate
//-- 输入按字节反转 ------------------------------------------------------------


//++ 输入低位补0后高位与初始值异或 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [DIN_WIDTH_TO_8+WIDTH-1 : 0] din_xor;
assign din_xor = {din_reflected, {(WIDTH){1'b0}}} ^ {XOR_IN, {(DIN_WIDTH_TO_8){1'b0}}};
//-- 输入低位补0后高位与初始值异或 ------------------------------------------------------------


//++ 模2计算 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [WIDTH-1 : 0] crc_calc;
// 此部分代码由Python程序生成 请勿手动修改 begin
/*
单步计算CRC
CRC宽度: 32
CRC多项式: 0x04c11db7
输入数据位宽: 36
*/
assign crc_calc[0] = din_xor[32] ^ din_xor[38] ^ din_xor[41] ^ din_xor[42] ^ din_xor[44]
                    ^ din_xor[48] ^ din_xor[56] ^ din_xor[57] ^ din_xor[58] ^ din_xor[60]
                    ^ din_xor[61] ^ din_xor[62] ^ din_xor[63] ^ din_xor[64] ^ din_xor[66]
                    ^ din_xor[69];
assign crc_calc[1] = din_xor[32] ^ din_xor[33] ^ din_xor[38] ^ din_xor[39] ^ din_xor[41]
                    ^ din_xor[43] ^ din_xor[44] ^ din_xor[45] ^ din_xor[48] ^ din_xor[49]
                    ^ din_xor[56] ^ din_xor[59] ^ din_xor[60] ^ din_xor[65] ^ din_xor[66]
                    ^ din_xor[67] ^ din_xor[69] ^ din_xor[70];
assign crc_calc[2] = din_xor[32] ^ din_xor[33] ^ din_xor[34] ^ din_xor[38] ^ din_xor[39]
                    ^ din_xor[40] ^ din_xor[41] ^ din_xor[45] ^ din_xor[46] ^ din_xor[48]
                    ^ din_xor[49] ^ din_xor[50] ^ din_xor[56] ^ din_xor[58] ^ din_xor[62]
                    ^ din_xor[63] ^ din_xor[64] ^ din_xor[67] ^ din_xor[68] ^ din_xor[69]
                    ^ din_xor[70] ^ din_xor[71];
assign crc_calc[3] = din_xor[33] ^ din_xor[34] ^ din_xor[35] ^ din_xor[39] ^ din_xor[40]
                    ^ din_xor[41] ^ din_xor[42] ^ din_xor[46] ^ din_xor[47] ^ din_xor[49]
                    ^ din_xor[50] ^ din_xor[51] ^ din_xor[57] ^ din_xor[59] ^ din_xor[63]
                    ^ din_xor[64] ^ din_xor[65] ^ din_xor[68] ^ din_xor[69] ^ din_xor[70]
                    ^ din_xor[71];
assign crc_calc[4] = din_xor[32] ^ din_xor[34] ^ din_xor[35] ^ din_xor[36] ^ din_xor[38]
                    ^ din_xor[40] ^ din_xor[43] ^ din_xor[44] ^ din_xor[47] ^ din_xor[50]
                    ^ din_xor[51] ^ din_xor[52] ^ din_xor[56] ^ din_xor[57] ^ din_xor[61]
                    ^ din_xor[62] ^ din_xor[63] ^ din_xor[65] ^ din_xor[70] ^ din_xor[71];
assign crc_calc[5] = din_xor[32] ^ din_xor[33] ^ din_xor[35] ^ din_xor[36] ^ din_xor[37]
                    ^ din_xor[38] ^ din_xor[39] ^ din_xor[42] ^ din_xor[45] ^ din_xor[51]
                    ^ din_xor[52] ^ din_xor[53] ^ din_xor[56] ^ din_xor[60] ^ din_xor[61]
                    ^ din_xor[69] ^ din_xor[71];
assign crc_calc[6] = din_xor[33] ^ din_xor[34] ^ din_xor[36] ^ din_xor[37] ^ din_xor[38]
                    ^ din_xor[39] ^ din_xor[40] ^ din_xor[43] ^ din_xor[46] ^ din_xor[52]
                    ^ din_xor[53] ^ din_xor[54] ^ din_xor[57] ^ din_xor[61] ^ din_xor[62]
                    ^ din_xor[70];
assign crc_calc[7] = din_xor[32] ^ din_xor[34] ^ din_xor[35] ^ din_xor[37] ^ din_xor[39]
                    ^ din_xor[40] ^ din_xor[42] ^ din_xor[47] ^ din_xor[48] ^ din_xor[53]
                    ^ din_xor[54] ^ din_xor[55] ^ din_xor[56] ^ din_xor[57] ^ din_xor[60]
                    ^ din_xor[61] ^ din_xor[64] ^ din_xor[66] ^ din_xor[69] ^ din_xor[71];
assign crc_calc[8] = din_xor[32] ^ din_xor[33] ^ din_xor[35] ^ din_xor[36] ^ din_xor[40]
                    ^ din_xor[42] ^ din_xor[43] ^ din_xor[44] ^ din_xor[49] ^ din_xor[54]
                    ^ din_xor[55] ^ din_xor[60] ^ din_xor[63] ^ din_xor[64] ^ din_xor[65]
                    ^ din_xor[66] ^ din_xor[67] ^ din_xor[69] ^ din_xor[70];
assign crc_calc[9] = din_xor[33] ^ din_xor[34] ^ din_xor[36] ^ din_xor[37] ^ din_xor[41]
                    ^ din_xor[43] ^ din_xor[44] ^ din_xor[45] ^ din_xor[50] ^ din_xor[55]
                    ^ din_xor[56] ^ din_xor[61] ^ din_xor[64] ^ din_xor[65] ^ din_xor[66]
                    ^ din_xor[67] ^ din_xor[68] ^ din_xor[70] ^ din_xor[71];
assign crc_calc[10] = din_xor[32] ^ din_xor[34] ^ din_xor[35] ^ din_xor[37] ^ din_xor[41]
                    ^ din_xor[45] ^ din_xor[46] ^ din_xor[48] ^ din_xor[51] ^ din_xor[58]
                    ^ din_xor[60] ^ din_xor[61] ^ din_xor[63] ^ din_xor[64] ^ din_xor[65]
                    ^ din_xor[67] ^ din_xor[68] ^ din_xor[71];
assign crc_calc[11] = din_xor[32] ^ din_xor[33] ^ din_xor[35] ^ din_xor[36] ^ din_xor[41]
                    ^ din_xor[44] ^ din_xor[46] ^ din_xor[47] ^ din_xor[48] ^ din_xor[49]
                    ^ din_xor[52] ^ din_xor[56] ^ din_xor[57] ^ din_xor[58] ^ din_xor[59]
                    ^ din_xor[60] ^ din_xor[63] ^ din_xor[65] ^ din_xor[68];
assign crc_calc[12] = din_xor[32] ^ din_xor[33] ^ din_xor[34] ^ din_xor[36] ^ din_xor[37]
                    ^ din_xor[38] ^ din_xor[41] ^ din_xor[44] ^ din_xor[45] ^ din_xor[47]
                    ^ din_xor[49] ^ din_xor[50] ^ din_xor[53] ^ din_xor[56] ^ din_xor[59]
                    ^ din_xor[62] ^ din_xor[63];
assign crc_calc[13] = din_xor[33] ^ din_xor[34] ^ din_xor[35] ^ din_xor[37] ^ din_xor[38]
                    ^ din_xor[39] ^ din_xor[42] ^ din_xor[45] ^ din_xor[46] ^ din_xor[48]
                    ^ din_xor[50] ^ din_xor[51] ^ din_xor[54] ^ din_xor[57] ^ din_xor[60]
                    ^ din_xor[63] ^ din_xor[64];
assign crc_calc[14] = din_xor[34] ^ din_xor[35] ^ din_xor[36] ^ din_xor[38] ^ din_xor[39]
                    ^ din_xor[40] ^ din_xor[43] ^ din_xor[46] ^ din_xor[47] ^ din_xor[49]
                    ^ din_xor[51] ^ din_xor[52] ^ din_xor[55] ^ din_xor[58] ^ din_xor[61]
                    ^ din_xor[64] ^ din_xor[65];
assign crc_calc[15] = din_xor[35] ^ din_xor[36] ^ din_xor[37] ^ din_xor[39] ^ din_xor[40]
                    ^ din_xor[41] ^ din_xor[44] ^ din_xor[47] ^ din_xor[48] ^ din_xor[50]
                    ^ din_xor[52] ^ din_xor[53] ^ din_xor[56] ^ din_xor[59] ^ din_xor[62]
                    ^ din_xor[65] ^ din_xor[66];
assign crc_calc[16] = din_xor[32] ^ din_xor[36] ^ din_xor[37] ^ din_xor[40] ^ din_xor[44]
                    ^ din_xor[45] ^ din_xor[49] ^ din_xor[51] ^ din_xor[53] ^ din_xor[54]
                    ^ din_xor[56] ^ din_xor[58] ^ din_xor[61] ^ din_xor[62] ^ din_xor[64]
                    ^ din_xor[67] ^ din_xor[69];
assign crc_calc[17] = din_xor[33] ^ din_xor[37] ^ din_xor[38] ^ din_xor[41] ^ din_xor[45]
                    ^ din_xor[46] ^ din_xor[50] ^ din_xor[52] ^ din_xor[54] ^ din_xor[55]
                    ^ din_xor[57] ^ din_xor[59] ^ din_xor[62] ^ din_xor[63] ^ din_xor[65]
                    ^ din_xor[68] ^ din_xor[70];
assign crc_calc[18] = din_xor[34] ^ din_xor[38] ^ din_xor[39] ^ din_xor[42] ^ din_xor[46]
                    ^ din_xor[47] ^ din_xor[51] ^ din_xor[53] ^ din_xor[55] ^ din_xor[56]
                    ^ din_xor[58] ^ din_xor[60] ^ din_xor[63] ^ din_xor[64] ^ din_xor[66]
                    ^ din_xor[69] ^ din_xor[71];
assign crc_calc[19] = din_xor[35] ^ din_xor[39] ^ din_xor[40] ^ din_xor[43] ^ din_xor[47]
                    ^ din_xor[48] ^ din_xor[52] ^ din_xor[54] ^ din_xor[56] ^ din_xor[57]
                    ^ din_xor[59] ^ din_xor[61] ^ din_xor[64] ^ din_xor[65] ^ din_xor[67]
                    ^ din_xor[70];
assign crc_calc[20] = din_xor[36] ^ din_xor[40] ^ din_xor[41] ^ din_xor[44] ^ din_xor[48]
                    ^ din_xor[49] ^ din_xor[53] ^ din_xor[55] ^ din_xor[57] ^ din_xor[58]
                    ^ din_xor[60] ^ din_xor[62] ^ din_xor[65] ^ din_xor[66] ^ din_xor[68]
                    ^ din_xor[71];
assign crc_calc[21] = din_xor[37] ^ din_xor[41] ^ din_xor[42] ^ din_xor[45] ^ din_xor[49]
                    ^ din_xor[50] ^ din_xor[54] ^ din_xor[56] ^ din_xor[58] ^ din_xor[59]
                    ^ din_xor[61] ^ din_xor[63] ^ din_xor[66] ^ din_xor[67] ^ din_xor[69];
assign crc_calc[22] = din_xor[32] ^ din_xor[41] ^ din_xor[43] ^ din_xor[44] ^ din_xor[46]
                    ^ din_xor[48] ^ din_xor[50] ^ din_xor[51] ^ din_xor[55] ^ din_xor[56]
                    ^ din_xor[58] ^ din_xor[59] ^ din_xor[61] ^ din_xor[63] ^ din_xor[66]
                    ^ din_xor[67] ^ din_xor[68] ^ din_xor[69] ^ din_xor[70];
assign crc_calc[23] = din_xor[32] ^ din_xor[33] ^ din_xor[38] ^ din_xor[41] ^ din_xor[45]
                    ^ din_xor[47] ^ din_xor[48] ^ din_xor[49] ^ din_xor[51] ^ din_xor[52]
                    ^ din_xor[58] ^ din_xor[59] ^ din_xor[61] ^ din_xor[63] ^ din_xor[66]
                    ^ din_xor[67] ^ din_xor[68] ^ din_xor[70] ^ din_xor[71];
assign crc_calc[24] = din_xor[33] ^ din_xor[34] ^ din_xor[39] ^ din_xor[42] ^ din_xor[46]
                    ^ din_xor[48] ^ din_xor[49] ^ din_xor[50] ^ din_xor[52] ^ din_xor[53]
                    ^ din_xor[59] ^ din_xor[60] ^ din_xor[62] ^ din_xor[64] ^ din_xor[67]
                    ^ din_xor[68] ^ din_xor[69] ^ din_xor[71];
assign crc_calc[25] = din_xor[34] ^ din_xor[35] ^ din_xor[40] ^ din_xor[43] ^ din_xor[47]
                    ^ din_xor[49] ^ din_xor[50] ^ din_xor[51] ^ din_xor[53] ^ din_xor[54]
                    ^ din_xor[60] ^ din_xor[61] ^ din_xor[63] ^ din_xor[65] ^ din_xor[68]
                    ^ din_xor[69] ^ din_xor[70];
assign crc_calc[26] = din_xor[32] ^ din_xor[35] ^ din_xor[36] ^ din_xor[38] ^ din_xor[42]
                    ^ din_xor[50] ^ din_xor[51] ^ din_xor[52] ^ din_xor[54] ^ din_xor[55]
                    ^ din_xor[56] ^ din_xor[57] ^ din_xor[58] ^ din_xor[60] ^ din_xor[63]
                    ^ din_xor[70] ^ din_xor[71];
assign crc_calc[27] = din_xor[33] ^ din_xor[36] ^ din_xor[37] ^ din_xor[39] ^ din_xor[43]
                    ^ din_xor[51] ^ din_xor[52] ^ din_xor[53] ^ din_xor[55] ^ din_xor[56]
                    ^ din_xor[57] ^ din_xor[58] ^ din_xor[59] ^ din_xor[61] ^ din_xor[64]
                    ^ din_xor[71];
assign crc_calc[28] = din_xor[34] ^ din_xor[37] ^ din_xor[38] ^ din_xor[40] ^ din_xor[44]
                    ^ din_xor[52] ^ din_xor[53] ^ din_xor[54] ^ din_xor[56] ^ din_xor[57]
                    ^ din_xor[58] ^ din_xor[59] ^ din_xor[60] ^ din_xor[62] ^ din_xor[65];
assign crc_calc[29] = din_xor[35] ^ din_xor[38] ^ din_xor[39] ^ din_xor[41] ^ din_xor[45]
                    ^ din_xor[53] ^ din_xor[54] ^ din_xor[55] ^ din_xor[57] ^ din_xor[58]
                    ^ din_xor[59] ^ din_xor[60] ^ din_xor[61] ^ din_xor[63] ^ din_xor[66];
assign crc_calc[30] = din_xor[36] ^ din_xor[39] ^ din_xor[40] ^ din_xor[42] ^ din_xor[46]
                    ^ din_xor[54] ^ din_xor[55] ^ din_xor[56] ^ din_xor[58] ^ din_xor[59]
                    ^ din_xor[60] ^ din_xor[61] ^ din_xor[62] ^ din_xor[64] ^ din_xor[67];
assign crc_calc[31] = din_xor[37] ^ din_xor[40] ^ din_xor[41] ^ din_xor[43] ^ din_xor[47]
                    ^ din_xor[55] ^ din_xor[56] ^ din_xor[57] ^ din_xor[59] ^ din_xor[60]
                    ^ din_xor[61] ^ din_xor[62] ^ din_xor[63] ^ din_xor[65] ^ din_xor[68];
// 此部分代码由Python程序生成 请勿手动修改 end
//-- 模2计算 ------------------------------------------------------------


//++ 输出反转 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [WIDTH-1 : 0] crc_reflected;
generate
if (REFLECT_OUT == 1) begin // 输出是否翻转
  genvar i;
  for (i = 0; i < WIDTH; i = i + 1) begin : reverse
    assign crc_reflected[i] = crc_calc[WIDTH-1-i];
  end
end else begin
  assign crc_reflected = crc_calc;
end
endgenerate
//-- 输出反转 ------------------------------------------------------------


//++ 输出异或 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
assign crc_out = crc_reflected ^ XOR_OUT; // 输出结果与XOR_OUT异或
always @(posedge clk) begin
  if (~rstn)
    crc_out_valid <= 1'b0;
  else if (din_valid)
    crc_out_valid <= 1'b1;
  else
    crc_out_valid <= 1'b0;
end
//-- 输出异或 ------------------------------------------------------------


endmodule
`resetall