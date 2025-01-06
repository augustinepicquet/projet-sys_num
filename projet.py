from lib_carotte import *
from aluinstr import *
from utils import *

def registre_1_bit(wdata: VariableOrDefer, wenable: VariableOrDefer) -> Variable:
    output = Reg(Defer(1, lambda: input))
    input = Mux(wenable, output, wdata)
    return output

def registre_n_bits(n: int, wdata: VariableOrDefer, wenable: VariableOrDefer) -> Variable:
    assert n == wdata.bus_size
    output = registre_1_bit(Select(0, wdata), wenable)
    for i in range(n-1):
        output = output + registre_1_bit(Select(i+1, wdata), wenable)
    return output

def dec_instr(instr: Variable) -> typing.Tuple[Variable, Variable, Variable, Variable, Variable, Variable, Variable, Variable, Variable]:
    wram = (~instr[0]) & instr[5]
    rram = (~instr[0]) & instr[4]
    wreg = instr[0] | rram
    jmp = (~instr[0]) & instr[3]
    jnz = (~instr[0]) & instr[2]
    alu_instr = instr[1:6]
    r_a = instr[6:11]
    r_b = instr[11:16]
    n = instr[16:32]
    return wram, wreg, rram, jmp, jnz, alu_instr, r_a, r_b, n

def bloc_registre(reg_size: int, raddr1: Variable, raddr2: Variable, wenable: VariableOrDefer, wdata: VariableOrDefer) -> typing.Tuple[Variable, Variable]:
    assert raddr1.bus_size == raddr2.bus_size
    log_nb_registre = 5
    l_wenable = Demux_n(log_nb_registre, wenable, raddr1)
    l_registre = []
    i=0
    for wenable_reg in l_wenable:
        reg_i = registre_n_bits(reg_size, wdata, wenable_reg)
        l_registre.append(reg_i)
        if i < 2:
            wenable_reg.rename("wenalbe_" + str(i))
            reg_i.rename("reg_" + str(i))
        i += 1
    data1 = Mux_n(log_nb_registre, l_registre, raddr1)
    data2 = Mux_n(log_nb_registre, l_registre, raddr2)
    return data1, data2

def alu(reg_size: int, data_a: Variable, data_b: Variable, n: Variable, instr: Variable) -> typing.Tuple[Variable, Variable]:
    alu_instr_size = instr.bus_size
    assert reg_size == data_a.bus_size
    assert reg_size == data_b.bus_size
    nz = Constant("0")
    for i in range(reg_size):
        nz = nz | data_a[i]

    def bool_to_reg(b):
        return Constant("0"*(reg_size-1)) + b

    default = Constant("0"*reg_size)
    COPY = data_b
    AND = bool_to_reg(data_a[reg_size - 1] & data_b[reg_size - 1])
    NOT = bool_to_reg(~data_b[reg_size - 1])
    OR = bool_to_reg(data_a[reg_size - 1] | data_b[reg_size - 1])
    XOR = bool_to_reg(data_a[reg_size - 1] ^ data_b[reg_size - 1]) 
    IS_0 = bool_to_reg(is_0(data_b[reg_size-7:reg_size]))
    IS_1 = bool_to_reg(is_1(data_b[reg_size-7:reg_size]))
    IS_2 = bool_to_reg(is_2(data_b[reg_size-7:reg_size]))
    IS_3 = bool_to_reg(is_3(data_b[reg_size-7:reg_size]))
    IS_4 = bool_to_reg(is_4(data_b[reg_size-7:reg_size]))
    IS_5 = bool_to_reg(is_5(data_b[reg_size-7:reg_size]))
    IS_6 = bool_to_reg(is_6(data_b[reg_size-7:reg_size]))
    IS_7 = bool_to_reg(is_7(data_b[reg_size-7:reg_size]))
    IS_8 = bool_to_reg(is_8(data_b[reg_size-7:reg_size]))
    IS_9 = bool_to_reg(is_9(data_b[reg_size-7:reg_size]))
    INCREM = increm(reg_size, data_a[reg_size-7:reg_size])
    MUL_4 = bool_to_reg(mul_4(data_a[reg_size-7:reg_size], data_b[reg_size-7:reg_size]))
    MUL_100 = bool_to_reg(is_0(data_a[reg_size-7:reg_size]) & is_0(data_b[reg_size-7:reg_size]))
    RESET = digit_segment_of_int(reg_size, 0)
    ADDR = n_adder(data_a, data_b, Constant("0"))[0]
    ADD = n_adder(n, data_b, Constant("0"))[0]
    CLEAR = default

    instr_list = [COPY, AND, NOT, OR, XOR, IS_0, IS_1, IS_2, IS_3, IS_4, IS_5, IS_6, IS_7, IS_8, IS_9, INCREM, MUL_4, MUL_100, RESET, ADDR, ADD, CLEAR]
    empty_space = 2**alu_instr_size - len(instr_list)
    for i in range(empty_space):
        instr_list.append(default)

    result = Mux_n(alu_instr_size, instr_list, instr)

    return nz, result



def main():
    # taille max de programme : 2^11 = 2048 lignes
    addr_size_rom = 16
    instr_size = 32
    log_instr_size = 5
    reg_size = 16
    read_addr = registre_n_bits(addr_size_rom, Defer(addr_size_rom, lambda: new_read_addr), Constant("1"))
    instr = ROM(addr_size_rom, instr_size, read_addr)
    wram, wreg, rram, jmp, jnz, alu_instr, r_a, r_b, n = dec_instr(instr)
    data_a, data_b = bloc_registre(reg_size, r_a, r_b, wreg, Defer(reg_size, lambda: wdata_reg))
    nz, result = alu(reg_size, data_a, data_b, n, alu_instr)
    data_ram = RAM(reg_size, reg_size, data_b, wram, data_b, data_a)
    wdata_reg = Mux(rram, result, data_ram)
    jmp_shift = Mux((nz & jnz) ^ jmp, Constant("0"*(addr_size_rom - log_instr_size - 1) + "1" + "0"*log_instr_size), n[log_instr_size:addr_size_rom] + Constant("0"*log_instr_size)) # impose n.bus_size > addr_size_rom
    new_read_addr = n_adder(read_addr, jmp_shift, Constant("0"))[0]

    data_a.rename("data_a")
    data_b.rename("data_b")
    r_a.rename("r_a")
    r_b.rename("r_b")
    #nz.rename("nz")
    #jnz.rename("jnz")
    #jmp_shift.rename("jmp_shift")
    #read_addr.rename("read_addr")
    #new_read_addr.rename("new_read_addr")
