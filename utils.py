from lib_carotte import *

def digit_segment_of_int(reg_size, n):
    str_digit_segment = "0000000"
    if n == 0:
        str_digit_segment = "1111110"
    if n == 1:
        str_digit_segment = "0110000"
    if n == 2:
        str_digit_segment = "1101101"
    if n == 3:
        str_digit_segment = "1111001"
    if n == 4:
        str_digit_segment = "0110011"
    if n == 5:
        str_digit_segment = "1011011"
    if n == 6:
        str_digit_segment = "1011111"
    if n == 7:
        str_digit_segment = "1110010"
    if n == 8:
        str_digit_segment = "1111111"
    if n == 9:
        str_digit_segment = "1111011"
    return Constant("0"*(reg_size - 7) + str_digit_segment)

def full_adder(a: Variable, b: Variable, c: Variable) -> typing.Tuple[Variable, Variable]:
    '''1-bit full adder implementation'''
    tmp = a ^ b
    return (tmp ^ c, (tmp & c) | (a & b))

def n_adder(a: Variable, b: Variable, c_in: Variable, i: int | None = None) -> typing.Tuple[Variable, Variable]:
    '''n-bit full-adder implementation'''
    assert a.bus_size == b.bus_size
    if i is None:
        i = a.bus_size-1
    assert 0 <= i < a.bus_size
    if i == 0:
        return full_adder(a[i], b[i], c_in)
    (res_i, c_rest) = full_adder(a[i], b[i], c_in)
    (res_rest, c_out) = n_adder(a, b, c_rest, i-1)
    return (res_rest + res_i, c_out)

def Mux_n(n: int, variable_list: list[Variable], choice: Variable) -> Variable:
    assert 2**n == len(variable_list)
    assert n == choice.bus_size
    if n == 1:
        return Mux(choice, variable_list[0], variable_list[1])
    i = 0
    new_variable_list = []
    while i < 2**n :
        new_variable_list.append(Mux(choice[n-1], variable_list[i], variable_list[i+1]))
        i += 2
    if n == 2:
        new_choice = choice[0]
    else:
        new_choice = choice[0:n-1]
    return Mux_n(n-1, new_variable_list, new_choice)

def Demux_n(n: int, entry: Variable, choice: Variable) -> typing.List[Variable]:
    '''fait passer entry dans le fil désigné par choice et 0 dans les autres fils'''
    assert 1 == entry.bus_size
    assert n == choice.bus_size

    def incr(s):
        ls = len(s)
        if ls == 0:
            return ""
        if s[ls-1] == 0:
            return s[:ls-1] + "1"
        return incr(s[:ls-1]) + "0"
    
    def str_to_variable(s, ls):
        if ls == 0:
            return entry
        if s[ls-1] == "0":
            return str_to_variable(s[:ls-1], ls-1) & (~choice[ls-1])
        return str_to_variable(s[:ls-1], ls-1) & (choice[ls-1])

    str = "0"*n
    l=[]
    for i in range(2**n):
        l.append(str_to_variable(str, n))
        str = incr(str)
    return l
