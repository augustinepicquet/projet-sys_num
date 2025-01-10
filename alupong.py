from lib_carotte import *
from utils import *

def is_0(seg_digit: Variable) -> Variable:
    return seg_digit[3] & (~seg_digit[6])

def is_1(seg_digit: Variable) -> Variable:
    return (~seg_digit[0]) & (~seg_digit[6])

def is_2(seg_digit: Variable) -> Variable:
    return (~seg_digit[2]) & (~seg_digit[5])

def is_3(seg_digit: Variable) -> Variable:
    return ((~seg_digit[4]) & (~seg_digit[5])) & seg_digit[6]

def is_4(seg_digit: Variable) -> Variable:
    return (~seg_digit[0]) & seg_digit[5]

def is_5(seg_digit: Variable) -> Variable:
    return (~seg_digit[1]) & (~seg_digit[4])

def is_6(seg_digit: Variable) -> Variable:
    return (~seg_digit[1]) & seg_digit[4]

def is_7(seg_digit: Variable) -> Variable:
    return (~seg_digit[3]) & seg_digit[0]

def is_8(seg_digit: Variable) -> Variable:
    return (seg_digit[1] & seg_digit[4]) & (seg_digit[5] & seg_digit[6])

def is_9(seg_digit: Variable) -> Variable:
    return (seg_digit[1] & seg_digit[3]) & ((~seg_digit[4]) & seg_digit[5])

def increm(reg_size: int, seg_digit: Variable) -> Variable:
    default = Constant("0"*reg_size)
    choice = seg_digit[1] + seg_digit[4:7]
    variable_list = [default, default, default, digit_segment_of_int(reg_size, 6),
                     default, default, default, digit_segment_of_int(reg_size, 7),
                     digit_segment_of_int(reg_size, 2), digit_segment_of_int(reg_size, 4), digit_segment_of_int(reg_size, 8), digit_segment_of_int(reg_size, 5),
                     default, digit_segment_of_int(reg_size, 3), digit_segment_of_int(reg_size, 1), digit_segment_of_int(reg_size, 9)]
    return Mux_n(4, variable_list, choice)

def mul_4(unité: Variable, dizaine: Variable):
    dizaine_paire = (((is_0(dizaine) | is_2(dizaine)) | is_4(dizaine)) | is_6(dizaine)) | is_8(dizaine)
    unité_mul_4 = (is_0(unité) | is_4(unité)) | is_8(unité)
    unité_2_mod4 = is_2(unité) | is_6(unité)

    return (dizaine_paire & unité_mul_4) | ((~dizaine_paire) & unité_2_mod4)
