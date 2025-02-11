/*
 * @Author       : Xu Xiaokang
 * @Email        :
 * @Date         : 2025-01-28 00:52:08
 * @LastEditors  : Xu Xiaokang
 * @LastEditTime : 2025-02-11 10:25:48
 * @Filename     :
 * @Description  : 任意CRC代码示例
*/

/*
! 模块功能: 计算CRC-多步
* 思路:
  1.利用并行计算公式推导出CRC-多步公式
  2.模2算法部分的代码, 需要根据具体算法和数据位宽来生成, 博文中提供了生成代码的Python程序
~ 使用:
  1.多步计算CRC, 用于长数据, 避免单步CRC计算长数据时组合逻辑过长的问题
  2.数据位宽DIN_WIDTH必须是8的倍数, 否则在处理输入按字节反转时会出错
  3.数据位宽DIN_WIDTH必须≥CRC宽度WIDTH, 否则在处理初始异或时会出错, 对于初始异或值为0的CRC算法无此要求
  4.补0已在模块内部完成, 外部输入无需考虑最后的补0
  5.必须给出最后一段数据的位宽LAST_DIN_WIDTH, 它必须小于等于DIN_WIDTH,
    它适用于长数据无法整数分割为多个DIN_WIDTH段的场合
    如果能整数分割, 则LAST_DIN_WIDTH可不指定, 它默认等于DIN_WIDTH
  6.当DIN_WIDTH大于等于WIDTH时, 此模块也可以单步算出CRC, 即LAST_DIN_WIDTH=DIN_WIDTH
    din_valid, din_first, din_last同时为1, 且两个valid之间至少间隔一个clk周期
*/

`default_nettype none

module myCrcMultiStep
#(
  parameter DIN_WIDTH = 32, // 输入数据位宽, 取值范围为8的倍数: 如8, 16, 32, ...
  // 最后一段的有效数据位宽, 高位为有效数据, 它必须是8的倍数, 最小值为8, 最大值为DIN_WIDTH
  parameter LAST_DIN_WIDTH = DIN_WIDTH,
  parameter WIDTH = 16,                // CRC宽度, 取值范围4~64
  parameter [0:0] REFLECT_IN = 1,      // 输入是否翻转, 取值范围0或1, 1表示反转, 0表示不反转
  parameter [WIDTH-1 : 0] XOR_IN = 'hFFFF, // 输入异或值, 取值范围全1或全0
  parameter [0:0] REFLECT_OUT = 1,     // 输出是否翻转, 取值范围0或1, 1表示反转, 0表示不反转
  parameter [WIDTH-1 : 0] XOR_OUT = 'hFFFF // 输出异或值, 取值范围全1或全0
)(
  output reg [WIDTH-1 : 0] crc_out, // CRC输出
  output reg               crc_out_valid, // CRC输出是否有效指示, 高电平有效

  input  wire [DIN_WIDTH-1 : 0] din, // 输入数据
  input  wire                   din_valid, // 输入数据有效指示, 高电平有效
  input  wire                   din_first, // 第一个输入数据指示, 高电平有效
  input  wire                   din_last,  // 最后一个输入数据指示, 高电平有效

  input  wire clk,
  input  wire rstn
);


//++ 输入寄存 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg [DIN_WIDTH-1 : 0] din_r;
always @(posedge clk) begin
  if (~rstn)
    din_r <= 'd0;
  else if (din_valid)
    din_r <= din;
end

reg din_valid_r1;
reg din_valid_r2;
reg din_valid_r3;
always @(posedge clk) begin
  din_valid_r1 <= din_valid;
  din_valid_r2 <= din_valid_r1;
  din_valid_r3 <= din_valid_r2;
end

reg din_first_r1;
always @(posedge clk) begin
  din_first_r1 <= din_first;
end

reg din_last_r1;
reg din_last_r2;
reg din_last_r3;
always @(posedge clk) begin
  din_last_r1 <= din_last;
  din_last_r2 <= din_last_r1;
  din_last_r3 <= din_last_r2;
end
//-- 输入寄存 ------------------------------------------------------------


//++ 输入按字节反转 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [DIN_WIDTH-1:0] din_reflected;

generate
if (REFLECT_IN == 1) begin
  // 对每个字节进行位反转
  genvar i;
  for (i = 0; i < DIN_WIDTH / 8; i = i + 1) begin
    assign din_reflected[i*8+7 : i*8] = { din_r[i*8], din_r[i*8+1], din_r[i*8+2], din_r[i*8+3],
                                          din_r[i*8+4], din_r[i*8+5],din_r[i*8+6], din_r[i*8+7]
                                        };
  end
end else begin
  assign din_reflected = din_r;
end
endgenerate
//-- 输入按字节反转 ------------------------------------------------------------


//++ 第一个输入与初始值异或 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg [DIN_WIDTH-1 : 0] din_xor;

generate
if (XOR_IN == 0) begin
  always @(posedge clk) begin
    if (din_valid_r1)
      din_xor <= din_reflected;
  end
end else begin
  always @(posedge clk) begin
    if (~rstn)
      din_xor <= 'd0;
    else if (din_valid_r1)
      if (din_first_r1)
        din_xor <= din_reflected ^ {XOR_IN, {(DIN_WIDTH-WIDTH){1'b0}}};
      else
        din_xor <= din_reflected;
    else
      din_xor <= din_xor;
  end
end
endgenerate
//-- 第一个输入与初始值异或 ------------------------------------------------------------


//++ 模2计算 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [WIDTH-1 : 0] crc_calc;
wire [WIDTH-1 : 0] crc_calc_last;
reg  [WIDTH-1 : 0] crc;
always @(posedge clk) begin
  if (~rstn)
    crc <= 'd0;
  else if (din_last_r2)
    crc <= 'd0;
  else if (din_valid_r2)
    crc <= crc_calc;
end

// 此部分代码由Python程序生成 请勿手动修改 begin
/*
多步计算CRC
CRC宽度: 32
CRC多项式: 0x04c11db7
输入数据位宽: 32
最后一段数据位宽: 16
*/
assign crc_calc[0] = crc[0] ^ crc[6] ^ crc[9] ^ crc[10] ^ crc[12] ^ crc[16] ^ crc[24] ^ crc[25]
                    ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31] ^ din_xor[0];
assign crc_calc[1] = crc[0] ^ crc[1] ^ crc[6] ^ crc[7] ^ crc[9] ^ crc[11] ^ crc[12] ^ crc[13]
                    ^ crc[16] ^ crc[17] ^ crc[24] ^ crc[27] ^ crc[28] ^ din_xor[1];
assign crc_calc[2] = crc[0] ^ crc[1] ^ crc[2] ^ crc[6] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[13]
                    ^ crc[14] ^ crc[16] ^ crc[17] ^ crc[18] ^ crc[24] ^ crc[26] ^ crc[30]
                    ^ crc[31] ^ din_xor[2];
assign crc_calc[3] = crc[1] ^ crc[2] ^ crc[3] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[10] ^ crc[14]
                    ^ crc[15] ^ crc[17] ^ crc[18] ^ crc[19] ^ crc[25] ^ crc[27] ^ crc[31]
                    ^ din_xor[3];
assign crc_calc[4] = crc[0] ^ crc[2] ^ crc[3] ^ crc[4] ^ crc[6] ^ crc[8] ^ crc[11] ^ crc[12]
                    ^ crc[15] ^ crc[18] ^ crc[19] ^ crc[20] ^ crc[24] ^ crc[25] ^ crc[29]
                    ^ crc[30] ^ crc[31] ^ din_xor[4];
assign crc_calc[5] = crc[0] ^ crc[1] ^ crc[3] ^ crc[4] ^ crc[5] ^ crc[6] ^ crc[7] ^ crc[10]
                    ^ crc[13] ^ crc[19] ^ crc[20] ^ crc[21] ^ crc[24] ^ crc[28] ^ crc[29]
                    ^ din_xor[5];
assign crc_calc[6] = crc[1] ^ crc[2] ^ crc[4] ^ crc[5] ^ crc[6] ^ crc[7] ^ crc[8] ^ crc[11]
                    ^ crc[14] ^ crc[20] ^ crc[21] ^ crc[22] ^ crc[25] ^ crc[29] ^ crc[30]
                    ^ din_xor[6];
assign crc_calc[7] = crc[0] ^ crc[2] ^ crc[3] ^ crc[5] ^ crc[7] ^ crc[8] ^ crc[10] ^ crc[15]
                    ^ crc[16] ^ crc[21] ^ crc[22] ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[28]
                    ^ crc[29] ^ din_xor[7];
assign crc_calc[8] = crc[0] ^ crc[1] ^ crc[3] ^ crc[4] ^ crc[8] ^ crc[10] ^ crc[11] ^ crc[12]
                    ^ crc[17] ^ crc[22] ^ crc[23] ^ crc[28] ^ crc[31] ^ din_xor[8];
assign crc_calc[9] = crc[1] ^ crc[2] ^ crc[4] ^ crc[5] ^ crc[9] ^ crc[11] ^ crc[12] ^ crc[13]
                    ^ crc[18] ^ crc[23] ^ crc[24] ^ crc[29] ^ din_xor[9];
assign crc_calc[10] = crc[0] ^ crc[2] ^ crc[3] ^ crc[5] ^ crc[9] ^ crc[13] ^ crc[14] ^ crc[16]
                    ^ crc[19] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[31] ^ din_xor[10];
assign crc_calc[11] = crc[0] ^ crc[1] ^ crc[3] ^ crc[4] ^ crc[9] ^ crc[12] ^ crc[14] ^ crc[15]
                    ^ crc[16] ^ crc[17] ^ crc[20] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[27]
                    ^ crc[28] ^ crc[31] ^ din_xor[11];
assign crc_calc[12] = crc[0] ^ crc[1] ^ crc[2] ^ crc[4] ^ crc[5] ^ crc[6] ^ crc[9] ^ crc[12]
                    ^ crc[13] ^ crc[15] ^ crc[17] ^ crc[18] ^ crc[21] ^ crc[24] ^ crc[27]
                    ^ crc[30] ^ crc[31] ^ din_xor[12];
assign crc_calc[13] = crc[1] ^ crc[2] ^ crc[3] ^ crc[5] ^ crc[6] ^ crc[7] ^ crc[10] ^ crc[13]
                    ^ crc[14] ^ crc[16] ^ crc[18] ^ crc[19] ^ crc[22] ^ crc[25] ^ crc[28]
                    ^ crc[31] ^ din_xor[13];
assign crc_calc[14] = crc[2] ^ crc[3] ^ crc[4] ^ crc[6] ^ crc[7] ^ crc[8] ^ crc[11] ^ crc[14]
                    ^ crc[15] ^ crc[17] ^ crc[19] ^ crc[20] ^ crc[23] ^ crc[26] ^ crc[29]
                    ^ din_xor[14];
assign crc_calc[15] = crc[3] ^ crc[4] ^ crc[5] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[12] ^ crc[15]
                    ^ crc[16] ^ crc[18] ^ crc[20] ^ crc[21] ^ crc[24] ^ crc[27] ^ crc[30]
                    ^ din_xor[15];
assign crc_calc[16] = crc[0] ^ crc[4] ^ crc[5] ^ crc[8] ^ crc[12] ^ crc[13] ^ crc[17] ^ crc[19]
                    ^ crc[21] ^ crc[22] ^ crc[24] ^ crc[26] ^ crc[29] ^ crc[30] ^ din_xor[16];
assign crc_calc[17] = crc[1] ^ crc[5] ^ crc[6] ^ crc[9] ^ crc[13] ^ crc[14] ^ crc[18] ^ crc[20]
                    ^ crc[22] ^ crc[23] ^ crc[25] ^ crc[27] ^ crc[30] ^ crc[31] ^ din_xor[17];
assign crc_calc[18] = crc[2] ^ crc[6] ^ crc[7] ^ crc[10] ^ crc[14] ^ crc[15] ^ crc[19] ^ crc[21]
                    ^ crc[23] ^ crc[24] ^ crc[26] ^ crc[28] ^ crc[31] ^ din_xor[18];
assign crc_calc[19] = crc[3] ^ crc[7] ^ crc[8] ^ crc[11] ^ crc[15] ^ crc[16] ^ crc[20] ^ crc[22]
                    ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[29] ^ din_xor[19];
assign crc_calc[20] = crc[4] ^ crc[8] ^ crc[9] ^ crc[12] ^ crc[16] ^ crc[17] ^ crc[21] ^ crc[23]
                    ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[30] ^ din_xor[20];
assign crc_calc[21] = crc[5] ^ crc[9] ^ crc[10] ^ crc[13] ^ crc[17] ^ crc[18] ^ crc[22] ^ crc[24]
                    ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31] ^ din_xor[21];
assign crc_calc[22] = crc[0] ^ crc[9] ^ crc[11] ^ crc[12] ^ crc[14] ^ crc[16] ^ crc[18] ^ crc[19]
                    ^ crc[23] ^ crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31] ^ din_xor[22];
assign crc_calc[23] = crc[0] ^ crc[1] ^ crc[6] ^ crc[9] ^ crc[13] ^ crc[15] ^ crc[16] ^ crc[17]
                    ^ crc[19] ^ crc[20] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31] ^ din_xor[23];
assign crc_calc[24] = crc[1] ^ crc[2] ^ crc[7] ^ crc[10] ^ crc[14] ^ crc[16] ^ crc[17] ^ crc[18]
                    ^ crc[20] ^ crc[21] ^ crc[27] ^ crc[28] ^ crc[30] ^ din_xor[24];
assign crc_calc[25] = crc[2] ^ crc[3] ^ crc[8] ^ crc[11] ^ crc[15] ^ crc[17] ^ crc[18] ^ crc[19]
                    ^ crc[21] ^ crc[22] ^ crc[28] ^ crc[29] ^ crc[31] ^ din_xor[25];
assign crc_calc[26] = crc[0] ^ crc[3] ^ crc[4] ^ crc[6] ^ crc[10] ^ crc[18] ^ crc[19] ^ crc[20]
                    ^ crc[22] ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[31]
                    ^ din_xor[26];
assign crc_calc[27] = crc[1] ^ crc[4] ^ crc[5] ^ crc[7] ^ crc[11] ^ crc[19] ^ crc[20] ^ crc[21]
                    ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[29] ^ din_xor[27];
assign crc_calc[28] = crc[2] ^ crc[5] ^ crc[6] ^ crc[8] ^ crc[12] ^ crc[20] ^ crc[21] ^ crc[22]
                    ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[30] ^ din_xor[28];
assign crc_calc[29] = crc[3] ^ crc[6] ^ crc[7] ^ crc[9] ^ crc[13] ^ crc[21] ^ crc[22] ^ crc[23]
                    ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[31] ^ din_xor[29];
assign crc_calc[30] = crc[4] ^ crc[7] ^ crc[8] ^ crc[10] ^ crc[14] ^ crc[22] ^ crc[23] ^ crc[24]
                    ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[30] ^ din_xor[30];
assign crc_calc[31] = crc[5] ^ crc[8] ^ crc[9] ^ crc[11] ^ crc[15] ^ crc[23] ^ crc[24] ^ crc[25]
                    ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31] ^ din_xor[31];
// 最后一段数据的计算代码, 已考虑了补CRC宽度个0
assign crc_calc_last[0] = crc[0] ^ crc[8] ^ crc[9] ^ crc[10] ^ crc[12] ^ crc[13] ^ crc[14]
                    ^ crc[15] ^ crc[16] ^ crc[18] ^ crc[21] ^ crc[28] ^ crc[29] ^ crc[31]
                    ^ din_xor[16] ^ din_xor[22] ^ din_xor[25] ^ din_xor[26] ^ din_xor[28];
assign crc_calc_last[1] = crc[0] ^ crc[1] ^ crc[8] ^ crc[11] ^ crc[12] ^ crc[17] ^ crc[18]
                    ^ crc[19] ^ crc[21] ^ crc[22] ^ crc[28] ^ crc[30] ^ crc[31] ^ din_xor[16]
                    ^ din_xor[17] ^ din_xor[22] ^ din_xor[23] ^ din_xor[25] ^ din_xor[27]
                    ^ din_xor[28] ^ din_xor[29];
assign crc_calc_last[2] = crc[0] ^ crc[1] ^ crc[2] ^ crc[8] ^ crc[10] ^ crc[14] ^ crc[15]
                    ^ crc[16] ^ crc[19] ^ crc[20] ^ crc[21] ^ crc[22] ^ crc[23] ^ crc[28]
                    ^ din_xor[16] ^ din_xor[17] ^ din_xor[18] ^ din_xor[22] ^ din_xor[23]
                    ^ din_xor[24] ^ din_xor[25] ^ din_xor[29] ^ din_xor[30];
assign crc_calc_last[3] = crc[1] ^ crc[2] ^ crc[3] ^ crc[9] ^ crc[11] ^ crc[15] ^ crc[16]
                    ^ crc[17] ^ crc[20] ^ crc[21] ^ crc[22] ^ crc[23] ^ crc[24] ^ crc[29]
                    ^ din_xor[17] ^ din_xor[18] ^ din_xor[19] ^ din_xor[23] ^ din_xor[24]
                    ^ din_xor[25] ^ din_xor[26] ^ din_xor[30] ^ din_xor[31];
assign crc_calc_last[4] = crc[2] ^ crc[3] ^ crc[4] ^ crc[8] ^ crc[9] ^ crc[13] ^ crc[14] ^ crc[15]
                    ^ crc[17] ^ crc[22] ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[28] ^ crc[29]
                    ^ crc[30] ^ crc[31] ^ din_xor[16] ^ din_xor[18] ^ din_xor[19] ^ din_xor[20]
                    ^ din_xor[22] ^ din_xor[24] ^ din_xor[27] ^ din_xor[28] ^ din_xor[31];
assign crc_calc_last[5] = crc[3] ^ crc[4] ^ crc[5] ^ crc[8] ^ crc[12] ^ crc[13] ^ crc[21]
                    ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[30] ^ din_xor[16]
                    ^ din_xor[17] ^ din_xor[19] ^ din_xor[20] ^ din_xor[21] ^ din_xor[22]
                    ^ din_xor[23] ^ din_xor[26] ^ din_xor[29];
assign crc_calc_last[6] = crc[4] ^ crc[5] ^ crc[6] ^ crc[9] ^ crc[13] ^ crc[14] ^ crc[22]
                    ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31] ^ din_xor[17]
                    ^ din_xor[18] ^ din_xor[20] ^ din_xor[21] ^ din_xor[22] ^ din_xor[23]
                    ^ din_xor[24] ^ din_xor[27] ^ din_xor[30];
assign crc_calc_last[7] = crc[0] ^ crc[5] ^ crc[6] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[12] ^ crc[13]
                    ^ crc[16] ^ crc[18] ^ crc[21] ^ crc[23] ^ crc[25] ^ crc[26] ^ crc[27]
                    ^ crc[29] ^ crc[30] ^ crc[31] ^ din_xor[16] ^ din_xor[18] ^ din_xor[19]
                    ^ din_xor[21] ^ din_xor[23] ^ din_xor[24] ^ din_xor[26] ^ din_xor[31];
assign crc_calc_last[8] = crc[1] ^ crc[6] ^ crc[7] ^ crc[12] ^ crc[15] ^ crc[16] ^ crc[17]
                    ^ crc[18] ^ crc[19] ^ crc[21] ^ crc[22] ^ crc[24] ^ crc[26] ^ crc[27]
                    ^ crc[29] ^ crc[30] ^ din_xor[16] ^ din_xor[17] ^ din_xor[19] ^ din_xor[20]
                    ^ din_xor[24] ^ din_xor[26] ^ din_xor[27] ^ din_xor[28];
assign crc_calc_last[9] = crc[2] ^ crc[7] ^ crc[8] ^ crc[13] ^ crc[16] ^ crc[17] ^ crc[18]
                    ^ crc[19] ^ crc[20] ^ crc[22] ^ crc[23] ^ crc[25] ^ crc[27] ^ crc[28]
                    ^ crc[30] ^ crc[31] ^ din_xor[17] ^ din_xor[18] ^ din_xor[20] ^ din_xor[21]
                    ^ din_xor[25] ^ din_xor[27] ^ din_xor[28] ^ din_xor[29];
assign crc_calc_last[10] = crc[0] ^ crc[3] ^ crc[10] ^ crc[12] ^ crc[13] ^ crc[15] ^ crc[16]
                    ^ crc[17] ^ crc[19] ^ crc[20] ^ crc[23] ^ crc[24] ^ crc[26] ^ din_xor[16]
                    ^ din_xor[18] ^ din_xor[19] ^ din_xor[21] ^ din_xor[25] ^ din_xor[29]
                    ^ din_xor[30];
assign crc_calc_last[11] = crc[0] ^ crc[1] ^ crc[4] ^ crc[8] ^ crc[9] ^ crc[10] ^ crc[11]
                    ^ crc[12] ^ crc[15] ^ crc[17] ^ crc[20] ^ crc[24] ^ crc[25] ^ crc[27]
                    ^ crc[28] ^ crc[29] ^ crc[31] ^ din_xor[16] ^ din_xor[17] ^ din_xor[19]
                    ^ din_xor[20] ^ din_xor[25] ^ din_xor[28] ^ din_xor[30] ^ din_xor[31];
assign crc_calc_last[12] = crc[1] ^ crc[2] ^ crc[5] ^ crc[8] ^ crc[11] ^ crc[14] ^ crc[15]
                    ^ crc[25] ^ crc[26] ^ crc[30] ^ crc[31] ^ din_xor[16] ^ din_xor[17]
                    ^ din_xor[18] ^ din_xor[20] ^ din_xor[21] ^ din_xor[22] ^ din_xor[25]
                    ^ din_xor[28] ^ din_xor[29] ^ din_xor[31];
assign crc_calc_last[13] = crc[0] ^ crc[2] ^ crc[3] ^ crc[6] ^ crc[9] ^ crc[12] ^ crc[15]
                    ^ crc[16] ^ crc[26] ^ crc[27] ^ crc[31] ^ din_xor[17] ^ din_xor[18]
                    ^ din_xor[19] ^ din_xor[21] ^ din_xor[22] ^ din_xor[23] ^ din_xor[26]
                    ^ din_xor[29] ^ din_xor[30];
assign crc_calc_last[14] = crc[1] ^ crc[3] ^ crc[4] ^ crc[7] ^ crc[10] ^ crc[13] ^ crc[16]
                    ^ crc[17] ^ crc[27] ^ crc[28] ^ din_xor[18] ^ din_xor[19] ^ din_xor[20]
                    ^ din_xor[22] ^ din_xor[23] ^ din_xor[24] ^ din_xor[27] ^ din_xor[30]
                    ^ din_xor[31];
assign crc_calc_last[15] = crc[0] ^ crc[2] ^ crc[4] ^ crc[5] ^ crc[8] ^ crc[11] ^ crc[14]
                    ^ crc[17] ^ crc[18] ^ crc[28] ^ crc[29] ^ din_xor[19] ^ din_xor[20]
                    ^ din_xor[21] ^ din_xor[23] ^ din_xor[24] ^ din_xor[25] ^ din_xor[28]
                    ^ din_xor[31];
assign crc_calc_last[16] = crc[1] ^ crc[3] ^ crc[5] ^ crc[6] ^ crc[8] ^ crc[10] ^ crc[13]
                    ^ crc[14] ^ crc[16] ^ crc[19] ^ crc[21] ^ crc[28] ^ crc[30] ^ crc[31]
                    ^ din_xor[16] ^ din_xor[20] ^ din_xor[21] ^ din_xor[24] ^ din_xor[28]
                    ^ din_xor[29];
assign crc_calc_last[17] = crc[2] ^ crc[4] ^ crc[6] ^ crc[7] ^ crc[9] ^ crc[11] ^ crc[14]
                    ^ crc[15] ^ crc[17] ^ crc[20] ^ crc[22] ^ crc[29] ^ crc[31] ^ din_xor[17]
                    ^ din_xor[21] ^ din_xor[22] ^ din_xor[25] ^ din_xor[29] ^ din_xor[30];
assign crc_calc_last[18] = crc[3] ^ crc[5] ^ crc[7] ^ crc[8] ^ crc[10] ^ crc[12] ^ crc[15]
                    ^ crc[16] ^ crc[18] ^ crc[21] ^ crc[23] ^ crc[30] ^ din_xor[18] ^ din_xor[22]
                    ^ din_xor[23] ^ din_xor[26] ^ din_xor[30] ^ din_xor[31];
assign crc_calc_last[19] = crc[0] ^ crc[4] ^ crc[6] ^ crc[8] ^ crc[9] ^ crc[11] ^ crc[13]
                    ^ crc[16] ^ crc[17] ^ crc[19] ^ crc[22] ^ crc[24] ^ crc[31] ^ din_xor[19]
                    ^ din_xor[23] ^ din_xor[24] ^ din_xor[27] ^ din_xor[31];
assign crc_calc_last[20] = crc[0] ^ crc[1] ^ crc[5] ^ crc[7] ^ crc[9] ^ crc[10] ^ crc[12]
                    ^ crc[14] ^ crc[17] ^ crc[18] ^ crc[20] ^ crc[23] ^ crc[25] ^ din_xor[20]
                    ^ din_xor[24] ^ din_xor[25] ^ din_xor[28];
assign crc_calc_last[21] = crc[1] ^ crc[2] ^ crc[6] ^ crc[8] ^ crc[10] ^ crc[11] ^ crc[13]
                    ^ crc[15] ^ crc[18] ^ crc[19] ^ crc[21] ^ crc[24] ^ crc[26] ^ din_xor[21]
                    ^ din_xor[25] ^ din_xor[26] ^ din_xor[29];
assign crc_calc_last[22] = crc[0] ^ crc[2] ^ crc[3] ^ crc[7] ^ crc[8] ^ crc[10] ^ crc[11]
                    ^ crc[13] ^ crc[15] ^ crc[18] ^ crc[19] ^ crc[20] ^ crc[21] ^ crc[22]
                    ^ crc[25] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[31] ^ din_xor[16] ^ din_xor[25]
                    ^ din_xor[27] ^ din_xor[28] ^ din_xor[30];
assign crc_calc_last[23] = crc[0] ^ crc[1] ^ crc[3] ^ crc[4] ^ crc[10] ^ crc[11] ^ crc[13]
                    ^ crc[15] ^ crc[18] ^ crc[19] ^ crc[20] ^ crc[22] ^ crc[23] ^ crc[26]
                    ^ crc[30] ^ crc[31] ^ din_xor[16] ^ din_xor[17] ^ din_xor[22] ^ din_xor[25]
                    ^ din_xor[29] ^ din_xor[31];
assign crc_calc_last[24] = crc[0] ^ crc[1] ^ crc[2] ^ crc[4] ^ crc[5] ^ crc[11] ^ crc[12]
                    ^ crc[14] ^ crc[16] ^ crc[19] ^ crc[20] ^ crc[21] ^ crc[23] ^ crc[24]
                    ^ crc[27] ^ crc[31] ^ din_xor[17] ^ din_xor[18] ^ din_xor[23] ^ din_xor[26]
                    ^ din_xor[30];
assign crc_calc_last[25] = crc[1] ^ crc[2] ^ crc[3] ^ crc[5] ^ crc[6] ^ crc[12] ^ crc[13]
                    ^ crc[15] ^ crc[17] ^ crc[20] ^ crc[21] ^ crc[22] ^ crc[24] ^ crc[25]
                    ^ crc[28] ^ din_xor[18] ^ din_xor[19] ^ din_xor[24] ^ din_xor[27] ^ din_xor[31];
assign crc_calc_last[26] = crc[2] ^ crc[3] ^ crc[4] ^ crc[6] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[10]
                    ^ crc[12] ^ crc[15] ^ crc[22] ^ crc[23] ^ crc[25] ^ crc[26] ^ crc[28]
                    ^ crc[31] ^ din_xor[16] ^ din_xor[19] ^ din_xor[20] ^ din_xor[22] ^ din_xor[26];
assign crc_calc_last[27] = crc[3] ^ crc[4] ^ crc[5] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[10] ^ crc[11]
                    ^ crc[13] ^ crc[16] ^ crc[23] ^ crc[24] ^ crc[26] ^ crc[27] ^ crc[29]
                    ^ din_xor[17] ^ din_xor[20] ^ din_xor[21] ^ din_xor[23] ^ din_xor[27];
assign crc_calc_last[28] = crc[4] ^ crc[5] ^ crc[6] ^ crc[8] ^ crc[9] ^ crc[10] ^ crc[11]
                    ^ crc[12] ^ crc[14] ^ crc[17] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[28]
                    ^ crc[30] ^ din_xor[18] ^ din_xor[21] ^ din_xor[22] ^ din_xor[24] ^ din_xor[28];
assign crc_calc_last[29] = crc[5] ^ crc[6] ^ crc[7] ^ crc[9] ^ crc[10] ^ crc[11] ^ crc[12]
                    ^ crc[13] ^ crc[15] ^ crc[18] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[29]
                    ^ crc[31] ^ din_xor[19] ^ din_xor[22] ^ din_xor[23] ^ din_xor[25] ^ din_xor[29];
assign crc_calc_last[30] = crc[6] ^ crc[7] ^ crc[8] ^ crc[10] ^ crc[11] ^ crc[12] ^ crc[13]
                    ^ crc[14] ^ crc[16] ^ crc[19] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[30]
                    ^ din_xor[20] ^ din_xor[23] ^ din_xor[24] ^ din_xor[26] ^ din_xor[30];
assign crc_calc_last[31] = crc[7] ^ crc[8] ^ crc[9] ^ crc[11] ^ crc[12] ^ crc[13] ^ crc[14]
                    ^ crc[15] ^ crc[17] ^ crc[20] ^ crc[27] ^ crc[28] ^ crc[30] ^ crc[31]
                    ^ din_xor[21] ^ din_xor[24] ^ din_xor[25] ^ din_xor[27] ^ din_xor[31];
// 此部分代码由Python程序生成 请勿手动修改 end
//-- 模2计算 ------------------------------------------------------------


//++ 输出反转 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg  [WIDTH-1 : 0] crc_reflected;
generate
if (REFLECT_OUT == 1) begin // 输出是否翻转
  genvar i;
  for (i = 0; i < WIDTH; i = i + 1) begin : reverse
    always @(posedge clk) begin
      if (din_last_r2)
        crc_reflected[i] = crc_calc_last[WIDTH-1-i]; // 最后一步输出反转
    end
  end
end else begin
  always @(posedge clk) begin
    if (din_last_r2)
      crc_reflected <= crc_calc_last;
  end
end
endgenerate
//-- 输出反转 ------------------------------------------------------------


//++ 输出异或 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
always @(posedge clk) begin
  if (din_last_r3)
    crc_out <= crc_reflected ^ XOR_OUT; // 最后一步输出结果与XOR_OUT异或
end

always @(posedge clk) begin
  if (~rstn)
    crc_out_valid <= 1'b0;
  else if (din_last_r3)
    crc_out_valid <= 1'b1;
  else
    crc_out_valid <= 1'b0;
end
//-- 输出异或 ------------------------------------------------------------


endmodule
`resetall