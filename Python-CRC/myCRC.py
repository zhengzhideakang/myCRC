'''
Author       : Xu Xiaokang
Email        :
Date         : 2025-01-22 15:42:50
LastEditors  : Xu Xiaokang
LastEditTime : 2025-02-10 15:20:06
Filename     :
Description  :
'''

import re
import numpy as np
from dataclasses import dataclass
from sympy import symbols
import pyperclip

@dataclass(frozen=True)
class CRCConfig:
    width: int = 16         # CRC宽度，默认值为 16
    poly: int = 0x8005      # CRC生成多项式，默认值为 CRC-16/MODBUS
    reflect_in: bool = True  # 输入反转标志，默认反转
    xor_in: int = 0x0000    # 输入异或值，默认值为 0xFFFF
    reflect_out: bool = True  # 输出反转标志，默认反转
    xor_out: int = 0x0000   # 输出异或值，默认值为 0x0000

    def __post_init__(self):
        # 验证配置参数的合法性，确保它们在允许范围内
        if not (4 <= self.width <= 64):
            raise ValueError(f"width ({self.width}) 必须在 4 到 64 之间")
        if self.poly > (1 << self.width):
            raise ValueError(
                f"多项式 poly 的二进制位宽 ({self.poly.bit_length()}) 超过了指定的位宽 width ({self.width})")
        if self.xor_in > (1 << self.width):
            raise ValueError(
                f"xor_in 的二进制位宽 ({self.xor_in.bit_length()}) 超过了指定的位宽 width ({self.width})")
        if self.xor_out > (1 << self.width):
            raise ValueError(
                f"xor_out 的二进制位宽 ({self.xor_out.bit_length()}) 超过了指定的位宽 width ({self.width})")

    def calc_crc(self, input_value: str) -> str:
        # 实例化类, 直接计算给定输入的CRC值
        crc_calculator = _CRCCalculator(self)
        return crc_calculator._calculate_crc(input_value)

CRC_4_ITU = CRCConfig(
    width       = 4,
    poly        = 0x03,
    reflect_in  = True,
    xor_in      = 0x00,
    reflect_out = True,
    xor_out     = 0x00
)

CRC_5_EPC = CRCConfig(
    width       = 5,
    poly        = 0x09,
    reflect_in  = False,
    xor_in      = 0x09,
    reflect_out = False,
    xor_out     = 0x00
)

CRC_5_ITU = CRCConfig(
    width       = 5,
    poly        = 0x15,
    reflect_in  = True,
    xor_in      = 0x00,
    reflect_out = True,
    xor_out     = 0x00
)

CRC_5_USB = CRCConfig(
    width       = 5,
    poly        = 0x05,
    reflect_in  = True,
    xor_in      = 0x1F,
    reflect_out = True,
    xor_out     = 0x1F
)

CRC_6_ITU = CRCConfig(
    width       = 6,
    poly        = 0x03,
    reflect_in  = True,
    xor_in      = 0x00,
    reflect_out = True,
    xor_out     = 0x00
)

CRC_7_MMC = CRCConfig(
    width       = 7,
    poly        = 0x09,
    reflect_in  = False,
    xor_in      = 0x00,
    reflect_out = False,
    xor_out     = 0x00
)

CRC_8 = CRCConfig(
    width       = 8,
    poly        = 0x07,
    reflect_in  = False,
    xor_in      = 0x00,
    reflect_out = False,
    xor_out     = 0x00
)

CRC_8_ITU = CRCConfig(
    width       = 8,
    poly        = 0x07,
    reflect_in  = False,
    xor_in      = 0x00,
    reflect_out = False,
    xor_out     = 0x55
)

CRC_8_ROHC = CRCConfig(
    width       = 8,
    poly        = 0x07,
    reflect_in  = True,
    xor_in      = 0xFF,
    reflect_out = True,
    xor_out     = 0x00
)

CRC_8_MAXIM = CRCConfig(
    width       = 8,
    poly        = 0x31,
    reflect_in  = True,
    xor_in      = 0x00,
    reflect_out = True,
    xor_out     = 0x00
)

CRC_16_IBM = CRCConfig(
    width       = 16,
    poly        = 0x8005,
    reflect_in  = True,
    xor_in      = 0x0000,
    reflect_out = True,
    xor_out     = 0x0000
)

CRC_16_MAXIM = CRCConfig(
    width       = 16,
    poly        = 0x8005,
    reflect_in  = True,
    xor_in      = 0x0000,
    reflect_out = True,
    xor_out     = 0xFFFF
)

CRC_16_USB = CRCConfig(
    width       = 16,
    poly        = 0x8005,
    reflect_in  = True,
    xor_in      = 0xFFFF,
    reflect_out = True,
    xor_out     = 0xFFFF
)

CRC_16_MODBUS = CRCConfig(
    width       = 16,
    poly        = 0x8005,
    reflect_in  = True,
    xor_in      = 0xFFFF,
    reflect_out = True,
    xor_out     = 0x0000
)

CRC_16_CCITT = CRCConfig(
    width       = 16,
    poly        = 0x1021,
    reflect_in  = True,
    xor_in      = 0x0000,
    reflect_out = True,
    xor_out     = 0x0000
)

CRC_16_CCITT_FALSE = CRCConfig(
    width       = 16,
    poly        = 0x1021,
    reflect_in  = False,
    xor_in      = 0xFFFF,
    reflect_out = False,
    xor_out     = 0x0000
)

CRC_16_X25 = CRCConfig(
    width       = 16,
    poly        = 0x1021,
    reflect_in  = True,
    xor_in      = 0xFFFF,
    reflect_out = True,
    xor_out     = 0xFFFF
)

CRC_16_XMODEM = CRCConfig(
    width       = 16,
    poly        = 0x1021,
    reflect_in  = False,
    xor_in      = 0x0000,
    reflect_out = False,
    xor_out     = 0x0000
)

CRC_16_DNP = CRCConfig(
    width       = 16,
    poly        = 0x3D65,
    reflect_in  = True,
    xor_in      = 0x0000,
    reflect_out = True,
    xor_out     = 0xFFFF
)

CRC_32 = CRCConfig(
    width       = 32,
    poly        = 0x04C11DB7,
    reflect_in  = True,
    xor_in      = 0xFFFFFFFF,
    reflect_out = True,
    xor_out     = 0xFFFFFFFF
)

CRC_32_MPEG_2 = CRCConfig(
    width       = 32,
    poly        = 0x04C11DB7,
    reflect_in  = False,
    xor_in      = 0xFFFFFFFF,
    reflect_out = False,
    xor_out     = 0x00000000
)


class _CRCCalculator:
    def __init__(self, crc_config: CRCConfig):
        # 初始化CRC计算器，传入CRC配置
        self.crc_config = crc_config
        self.N = self.crc_config.width
        self.T = self._build_transfer_matrix(self.crc_config.poly, self.N)

    def _string_to_hex(self, input_value) -> str:
        # 将输入值转换为十六进制字符串表示形式
        if isinstance(input_value, int):
            return hex(input_value)[2:]  # 如果输入是数字，直接转换为十六进制
        # 如果是字符串，则根据配置进行编码和转换
        encoding = 'utf-8'
        try:
            encoded_bytes = input_value.encode(encoding)
            hex_str = ''.join(f'{byte:02x}' for byte in encoded_bytes)
            return hex_str
        except UnicodeEncodeError as e:
            raise ValueError(f"字符集 '{encoding}' 不支持字符串中的某些字符: {e}")

    def _validate_hex_input(self, input_str: str) -> str:
        # 清理并验证输入的十六进制字符串是否有效
        stripped_input = re.sub(r'\s+', '', input_str)
        if stripped_input == "":
            raise ValueError("输入不能为空")
        if stripped_input.startswith("0x") or stripped_input.startswith("0X"):
            stripped_input = stripped_input[2:]
        if not re.fullmatch(r"[0-9a-fA-F]+", stripped_input):
            raise ValueError("输入不是有效的16进制数")
        if len(stripped_input) % 2 != 0:
            stripped_input = '0' + stripped_input
        return stripped_input

    def _reverse_single_byte(self, hex_str: str) -> str:
        # 反转每个字节内的半字节顺序（适用于需要反转输入/输出的情况）
        reverse_table = {
            '0': '0', '1': '8', '2': '4', '3': 'C',
            '4': '2', '5': 'A', '6': '6', '7': 'E',
            '8': '1', '9': '9', 'A': '5', 'B': 'D',
            'C': '3', 'D': 'B', 'E': '7', 'F': 'F',
            'a': 'f', 'b': 'd', 'c': '3', 'd': 'b',
            'e': '7', 'f': 'f'
        }
        reversed_hex = ''
        for i in range(0, len(hex_str), 2):
            byte = hex_str[i:i+2]
            high_nibble = byte[0].upper()
            low_nibble = byte[1].upper()
            reversed_high = reverse_table.get(high_nibble, high_nibble)
            reversed_low = reverse_table.get(low_nibble, low_nibble)
            reversed_hex += reversed_low + reversed_high
        return reversed_hex

    def _pad0_and_xorin(self, hex_str: str) -> str:
        # 对输入的十六进制字符串进行填充零和与初始值xor_in进行按位异或操作
        hex_to_bin_table = {
            '0': '0000', '1': '0001', '2': '0010', '3': '0011',
            '4': '0100', '5': '0101', '6': '0110', '7': '0111',
            '8': '1000', '9': '1001', 'A': '1010', 'B': '1011',
            'C': '1100', 'D': '1101', 'E': '1110', 'F': '1111',
            'a': '1010', 'b': '1011', 'c': '1100', 'd': '1101',
            'e': '1110', 'f': '1111'
        }
        n = self.N
        # 使用 format 函数将 xor_in 转换为固定长度的二进制字符串
        xor_bin_str = format(self.crc_config.xor_in, f'0{n}b')
        # 将输入的十六进制字符串转换为二进制字符串
        bin_str = ''.join(hex_to_bin_table[char] for char in hex_str.upper())
        bin_str += '0' * n  # 在二进制字符串后面直接添加 n 个零
        # 对最开始的 n 位进行异或操作
        high_n_bits = bin_str[:n]
        xor_result_high_bits = ''.join(
            '1' if a != b else '0' for a, b in zip(high_n_bits, xor_bin_str))
        low_bits = bin_str[n:]  # 取剩余的低位
        final_bin = xor_result_high_bits + low_bits
        return final_bin

    def _build_transfer_matrix(self, g_hex: str, n: int) -> np.ndarray:
        # 构建基于生成多项式的状态转移矩阵
        g_bin = bin(g_hex)[2:].zfill(n)
        T = np.zeros((n, n), dtype=int)
        for i in range(n):
            if i < len(g_bin):
                T[0, n - 1 - i] = int(g_bin[-1 - i])
        for i in range(1, n):
            T[i, i - 1] = 1
        return T

    def _get_next_c(self, bin_input: str, T: np.ndarray) -> str:
        # 根据状态转移矩阵计算下一个CRC校验值
        n = self.N
        this_c = np.zeros(n, dtype=int)
        C = np.dot(this_c, np.linalg.matrix_power(T, len(bin_input)))
        blocks = [bin_input[i:i+n] for i in range(0, len(bin_input), n)]
        i = len(blocks[-1]) if blocks else 0
        for j, block in enumerate(blocks):
            D = np.array([int(bit) for bit in block], dtype=int)
            if len(D) < n:
                D = np.pad(D, (n - len(D), 0), 'constant')
                C += D
                break
            power = n * (len(blocks)-j-2) + i
            T_power = np.linalg.matrix_power(T, power)
            C += np.dot(D, T_power)
        C = C % 2
        C = ''.join(map(str, C))
        return C

    def _output_reverse_and_xor(self, bin_input: str) -> str:
        # 对最终的CRC结果进行可能的反转和与xor_out的按位异或操作
        processed_bin = bin_input[::-1] if self.crc_config.reflect_out else bin_input
        # 将 xor_out 转换为二进制字符串并确保其长度与 processed_bin 一致
        xor_out_bin = format(self.crc_config.xor_out, f'0{len(processed_bin)}b')
        # 对 processed_bin 和 xor_out 进行按位异或操作
        result_bin = ''.join('1' if a != b else '0' for a, b in zip(processed_bin, xor_out_bin))
        return result_bin

    def _calculate_crc(self, input_value: str) -> str:
        # 执行完整的CRC计算流程
        # 将输入转换为十六进制字符串
        hex_str = self._string_to_hex(input_value)
        # 根据配置验证并清理十六进制字符串
        validated_hex = self._validate_hex_input(hex_str)
        # 可选地反转单个字节内的半字节
        if self.crc_config.reflect_in:
            validated_hex = self._reverse_single_byte(validated_hex)
        # 填充与异或操作（这里假设只对高n位进行异或）
        bin_str = self._pad0_and_xorin(validated_hex)
        # 计算状态转移
        C = self._get_next_c(bin_str, self.T)
        # 对输出结果进行反转和/或取反
        final_result = self._output_reverse_and_xor(C)
        return final_result

class CRCVerilog(_CRCCalculator):
    def _crc_one_step_formula(self, din_width: int) -> np.ndarray:
        # Verilog CRC计算单步并行公式
        N = self.N
        # 判断din_width是否大于0
        if din_width == 0:
            raise ValueError("din_width must be greater than 0")
        # 生成数据行向量, 输入位宽变为8的倍数, 然后加上N
        total_width = ((din_width + 7) // 8) * 8 + N
        d_symbols = symbols(' '.join([f'd{i:02d}' for i in range(total_width)]))
        D = np.array([list(d_symbols[::-1])])
        # 取前total_width-d_min个元素
        d_min = min(din_width, N)
        D = D[:, :(total_width - d_min)]
        # 后补d_min个0
        D = np.concatenate((D, np.zeros((1, d_min), int)), axis=1)
        # 生成状态转移矩阵
        T = self.T
        # 进行并行CRC计算
        verilog_one_step = 0
        j, i = divmod(total_width, N)
        for k in range(j):
            start_idx = k * N
            end_idx = (k + 1) * N
            sub_D = D[:, start_idx:end_idx]
            exp = N * (j - 1 - k) + i
            T_exp = np.linalg.matrix_power(T,  exp) % 2
            term = np.dot(sub_D,  T_exp)
            verilog_one_step += term
        # 处理余数项
        if i > 0:
            sub_D_last = D[:, j * N: j * N + i]
            eye_matrix = np.eye(i,  dtype=int)
            term_last = np.dot(sub_D_last, eye_matrix)
            verilog_one_step[0, :i] += term_last[0, :]
        return verilog_one_step

    def _split_long_line(self, line: str, len_limit: int = 100) -> list:
        """
        分割长度超过指定限制的行，使得每个分割出来的部分都以'^'开头。
        :param line: 要分割的字符串
        :param len_limit: 单行的最大长度限制，默认为100
        :return: 分割后的字符串列表
        """
        if len(line) <= len_limit:
            return [line]
        parts = []
        while len(line) > len_limit:
            split_index = line.rfind('^', 0, len_limit)
            parts.append(line[:split_index])
            line = ' ' * 20 + line[split_index:]
        parts.append(line)
        return parts

    def generate_verilog_crc_one_step_code(self, din_width) -> str:
        """
        将输入行向量转换为Verilog crc_calc赋值语句
        :param din_width: 输入数据宽度
        :return: 生成的Verilog代码字符串
        """
        verilog_crc_one_step_list = []
        verilog_crc_one_step_list.append('// 此部分代码由Python程序生成 请勿手动修改 begin')
        verilog_crc_one_step_list.append('/*')
        verilog_crc_one_step_list.append('单步计算CRC')
        verilog_crc_one_step_list.append('CRC宽度: ' + str(self.N))
        verilog_crc_one_step_list.append('CRC多项式: '
                                            + f'0x{self.crc_config.poly:0{(self.N+3)//4}x}')
        verilog_crc_one_step_list.append('输入数据位宽: ' + str(din_width))
        verilog_crc_one_step_list.append('*/')
        # 单步CRC计算公式
        row_vector = self._crc_one_step_formula(din_width)
        crc_list = [str(item) for item in row_vector[0]][::-1]
        for i in range(len(crc_list)):
            item = crc_list[i].replace('+', '^')
            item = re.sub(r'\bd(\d{2})\b', lambda m: f"din_xor[{int(m.group(1))}]", item)
            new_item = f'assign crc_calc[{i}] = ' + item + ';'
            # 对过长的行进行分割
            split_items = self._split_long_line(new_item)
            verilog_crc_one_step_list.extend(split_items)
        verilog_crc_one_step_list.append('// 此部分代码由Python程序生成 请勿手动修改 end')
        verilog_crc_one_step_code = '\n'.join(verilog_crc_one_step_list)
        # 代码复制到剪贴板, 便于直接粘贴
        pyperclip.copy(verilog_crc_one_step_code)
        return verilog_crc_one_step_code

    def _crc_multi_step_formula(self, din_width: int) -> np.ndarray:
        # Verilog CRC计算多步并行公式
        N = self.N
        # 判断din_width是否大于0, 并且小于等于N
        if din_width == 0:
            raise ValueError("din_width must be greater than 0")
        if din_width < N:
            raise ValueError("din_width can't be less than CRC width")
        # 生成状态行向量
        c_symbols = symbols(' '.join([f'c{i:02d}' for i in range(N)]))
        C = np.array([list(c_symbols[::-1])])
        # 生成数据行向量
        d_symbols = symbols(' '.join([f'd{i:02d}' for i in range(din_width)]))
        D = np.array([list(d_symbols[::-1])])
        # 生成状态转移矩阵
        T = self.T
        # 进行并行CRC计算
        verilog_multi_step = 0
        # 第一项
        verilog_multi_step += np.dot(C,  np.linalg.matrix_power(T,  din_width) % 2)
        # 中间项
        j, i = divmod(din_width, N)
        for k in range(j):
            start_idx = k * N
            end_idx = (k + 1) * N
            sub_D = D[:, start_idx:end_idx]
            exp = N * (j - 1 - k) + i
            T_exp = np.linalg.matrix_power(T,  exp) % 2
            term = np.dot(sub_D,  T_exp)
            verilog_multi_step += term
        # 处理余数项
        if i > 0:
            sub_D_last = D[:, j * N: j * N + i]
            eye_matrix = np.eye(i,  dtype=int)
            term_last = np.dot(sub_D_last, eye_matrix)
            verilog_multi_step[0, :i] += term_last[0, :]
        return verilog_multi_step

    def _crc_multi_step_formula_last(self, din_width: int, last_din_width: int) -> np.ndarray:
        # Verilog CRC计算多步并行公式
        N = self.N
        # 判断last_din_width是否大于0, 并且小于等于N
        if last_din_width == 0:
            raise ValueError("last_din_width must be greater than 0")
        if last_din_width > din_width:
            raise ValueError("last_din_width can't be greater than din_width")
        # 生成状态行向量
        c_symbols = symbols(' '.join([f'c{i:02d}' for i in range(N)]))
        C = np.array([list(c_symbols[::-1])])
        # 生成数据行向量
        d_symbols = symbols(' '.join([f'd{i:02d}' for i in range(din_width)]))
        D = np.array([list(d_symbols[::-1])])
        # 取前last_din_width个数据
        D = D[:, :last_din_width]
        # 将D后补N个0
        D = np.concatenate((D, np.zeros((1, N), int)), axis=1)
        # 生成状态转移矩阵
        T = self.T
        # 进行并行CRC计算
        verilog_multi_step_last = 0
        # 第一项
        verilog_multi_step_last += np.dot(C,  np.linalg.matrix_power(T,  last_din_width+N) % 2)
        # 中间项
        j, i = divmod(last_din_width+N, N)
        for k in range(j):
            start_idx = k * N
            end_idx = (k + 1) * N
            sub_D = D[:, start_idx:end_idx]
            exp = N * (j - 1 - k) + i
            T_exp = np.linalg.matrix_power(T,  exp) % 2
            term = np.dot(sub_D,  T_exp)
            verilog_multi_step_last += term
        # 处理余数项
        if i > 0:
            sub_D_last = D[:, j * N: j * N + i]
            eye_matrix = np.eye(i,  dtype=int)
            term_last = np.dot(sub_D_last, eye_matrix)
            verilog_multi_step_last[0, :i] += term_last[0, :]
        return verilog_multi_step_last


    def generate_verilog_crc_multi_step_code(self, din_width: int, last_din_width: int) -> str:
        """
        将输入行向量转换为Verilog crc_calc赋值语句
        :param din_width: 输入数据宽度
        :return: 生成的Verilog代码字符串
        """
        verilog_crc_multi_step_list = []
        # 添加注释
        verilog_crc_multi_step_list.append('// 此部分代码由Python程序生成 请勿手动修改 begin')
        verilog_crc_multi_step_list.append('/*')
        verilog_crc_multi_step_list.append('多步计算CRC')
        verilog_crc_multi_step_list.append('CRC宽度: ' + str(self.N))
        verilog_crc_multi_step_list.append('CRC多项式: '
                                            + f'0x{self.crc_config.poly:0{(self.N+3)//4}x}')
        verilog_crc_multi_step_list.append('输入数据位宽: ' + str(din_width))
        verilog_crc_multi_step_list.append('最后一段数据位宽: ' + str(last_din_width))
        verilog_crc_multi_step_list.append('*/')
        # 多步CRC计算第一部分
        row_vector = self._crc_multi_step_formula(din_width)
        crc_list = [str(item) for item in row_vector[0]][::-1]
        for i in range(len(crc_list)):
            item = crc_list[i].replace('+', '^')
            item = re.sub(r'\bd(\d{2})\b', lambda m: f"din_xor[{int(m.group(1))}]", item)
            item = re.sub(r'\bc(\d{2})\b', lambda m: f"crc[{int(m.group(1))}]", item)
            new_item = f'assign crc_calc[{i}] = ' + item + ';'
            # 对过长的行进行分割
            split_items = self._split_long_line(new_item)
            verilog_crc_multi_step_list.extend(split_items)
        # 添加注释
        verilog_crc_multi_step_list.append('// 最后一段数据的计算代码, 已考虑了补CRC宽度个0')
        # 多步CRC计算第二部分
        row_vector = self._crc_multi_step_formula_last(din_width, last_din_width)
        crc_list = [str(item) for item in row_vector[0]][::-1]
        for i in range(len(crc_list)):
            item = crc_list[i].replace('+', '^')
            item = re.sub(r'\bd(\d{2})\b', lambda m: f"din_xor[{int(m.group(1))}]", item)
            item = re.sub(r'\bc(\d{2})\b', lambda m: f"crc[{int(m.group(1))}]", item)
            new_item = f'assign crc_calc_last[{i}] = ' + item + ';'
            # 对过长的行进行分割
            split_items = self._split_long_line(new_item)
            verilog_crc_multi_step_list.extend(split_items)
        # 添加注释
        verilog_crc_multi_step_list.append('// 此部分代码由Python程序生成 请勿手动修改 end')
        # 转为字符串
        verilog_crc_multi_step_code = '\n'.join(verilog_crc_multi_step_list)
        # 代码复制到剪贴板, 便于直接粘贴
        pyperclip.copy(verilog_crc_multi_step_code)
        return verilog_crc_multi_step_code