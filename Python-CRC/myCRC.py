'''
Author       : Xu Xiaokang
Email        :
Date         : 2025-01-22 10:41:15
LastEditors  : Xu Xiaokang
LastEditTime : 2025-01-22 15:18:12
Filename     :
Description  :
'''

import re
import numpy as np
from dataclasses import dataclass


@dataclass
class CRCConfig:
    width: int = 16         # CRC宽度，默认值为 16
    poly: int = 0x8005      # CRC生成多项式，默认值为 CRC-16/MODBUS
    reflect_in: bool = True  # 输入反转标志，默认反转
    xor_in: int = 0xFFFF    # 输入异或值，默认值为 0xFFFF
    reflect_out: bool = True  # 输出反转标志，默认反转
    xor_out: int = 0x0000   # 输出异或值，默认值为 0x0000

    def __post_init__(self):
        # 验证 width 是否在允许范围内
        if not (4 <= self.width <= 64):
            raise ValueError(f"width ({self.width}) 必须在 4 到 64 之间")
        # 验证多项式的二进制位宽是否小于等于 width
        if self.poly >= (1 << self.width):
            raise ValueError(
                f"多项式 poly 的二进制位宽 ({self.poly.bit_length()}) 超过了指定的位宽 width ({self.width})")
        # 验证 xor_in 的二进制位宽是否小于等于 width
        if self.xor_in >= (1 << self.width):
            raise ValueError(
                f"xor_in 的二进制位宽 ({self.xor_in.bit_length()}) 超过了指定的位宽 width ({self.width})")
        # 验证 xor_out 的二进制位宽是否小于等于 width
        if self.xor_out >= (1 << self.width):
            raise ValueError(
                f"xor_out 的二进制位宽 ({self.xor_out.bit_length()}) 超过了指定的位宽 width ({self.width})")


class CRCCalculator:
    def __init__(self, crc_config: CRCConfig):
        self.crc_config = crc_config

    def string_to_hex(self, input_value) -> str:
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

    def validate_hex_input(self, input_str: str) -> str:
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

    def reverse_single_byte(self, hex_str: str) -> str:
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

    def pad0_and_xorin(self, hex_str: str) -> str:
        hex_to_bin_table = {
            '0': '0000', '1': '0001', '2': '0010', '3': '0011',
            '4': '0100', '5': '0101', '6': '0110', '7': '0111',
            '8': '1000', '9': '1001', 'A': '1010', 'B': '1011',
            'C': '1100', 'D': '1101', 'E': '1110', 'F': '1111',
            'a': '1010', 'b': '1011', 'c': '1100', 'd': '1101',
            'e': '1110', 'f': '1111'
        }
        n = self.crc_config.width
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

    def build_transfer_matrix(self, g_hex: str, n: int) -> np.ndarray:
        g_bin = bin(g_hex)[2:].zfill(n)
        T = np.zeros((n, n), dtype=int)
        for i in range(n):
            if i < len(g_bin):
                T[0, n - 1 - i] = int(g_bin[-1 - i])
        for i in range(1, n):
            T[i, i - 1] = 1
        return T

    def get_next_c(self, bin_input: str, T: np.ndarray) -> str:
        n = T.shape[0]
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

    def output_reverse_and_xor(self, bin_input: str) -> str:
        processed_bin = bin_input[::-1] if self.crc_config.reflect_out else bin_input
        # 将 xor_out 转换为二进制字符串并确保其长度与 processed_bin 一致
        xor_out_bin = format(self.crc_config.xor_out, f'0{len(processed_bin)}b')
        # 对 processed_bin 和 xor_out 进行按位异或操作
        result_bin = ''.join('1' if a != b else '0' for a, b in zip(processed_bin, xor_out_bin))
        return result_bin

    def calculate_crc(self, input_value) -> str:
        # 将输入转换为十六进制字符串
        hex_str = self.string_to_hex(input_value)
        # 根据配置验证并清理十六进制字符串
        validated_hex = self.validate_hex_input(hex_str)
        # 可选地反转单个字节内的半字节
        if self.crc_config.reflect_in:
            validated_hex = self.reverse_single_byte(validated_hex)
        # 填充与异或操作（这里假设只对高n位进行异或）
        bin_str = self.pad0_and_xorin(validated_hex)
        # 构建转移矩阵
        T = self.build_transfer_matrix(
            self.crc_config.poly, self.crc_config.width)
        # 计算状态转移
        C = self.get_next_c(bin_str, T)
        # 对输出结果进行反转和/或取反
        final_result = self.output_reverse_and_xor(C)
        return final_result