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
    n = instr[16:48]
    return wram, wreg, rram, jmp, jnz, alu_instr, r_a, r_b, n

def bloc_registre(reg_size: int, raddr1: Variable, raddr2: Variable, wenable: VariableOrDefer, wdata: VariableOrDefer) -> typing.Tuple[Variable, Variable]:
    assert raddr1.bus_size == raddr2.bus_size
    log_nb_registre = 5
    l_wenable = Demux_n(log_nb_registre, wenable, raddr1)
    l_registre = []
    for wenable_reg in l_wenable:
        reg_i = registre_n_bits(reg_size, wdata, wenable_reg)
        l_registre.append(reg_i)
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

    default = Constant("0"*reg_size)
    COPY = data_b
    AND = n_and(data_a, data_b)
    NOT = n_not(data_b)
    OR = n_or(data_a, data_b)
    XOR = n_xor(data_a, data_b)
    ADDR = n_adder(data_a, data_b, Constant("0"))[0]
    ADD = n_adder(n, data_b, Constant("0"))[0]
    CLEAR = default
    NEG = neg(data_b)
    SUB = n_adder(data_a, neg(n), Constant("0"))[0]
    SUBR = n_adder(data_a, neg(data_b), Constant("0"))[0]
    MOD_2 = mod_2(data_b)
    POSITIF = positif(data_b)

    instr_list = [COPY, AND, NOT, OR, XOR, ADDR, ADD, CLEAR, NEG, SUB, SUBR, MOD_2, POSITIF]
    empty_space = 2**alu_instr_size - len(instr_list)
    for i in range(empty_space):
        instr_list.append(default)

    result = Mux_n(alu_instr_size, instr_list, instr)

    return nz, result



def main():
    addr_size_rom = 16
    instr_size = 48
    reg_size = 32
    read_addr = registre_n_bits(addr_size_rom, Defer(addr_size_rom, lambda: new_read_addr), Constant("1"))
    instr = ROM(addr_size_rom, instr_size, read_addr)
    wram, wreg, rram, jmp, jnz, alu_instr, r_a, r_b, n = dec_instr(instr)
    data_a, data_b = bloc_registre(reg_size, r_a, r_b, wreg, Defer(reg_size, lambda: wdata_reg))
    nz, result = alu(reg_size, data_a, data_b, n, alu_instr)
    data_ram = RAM(reg_size, reg_size, data_b, wram, data_b, data_a)
    wdata_reg = Mux(rram, result, data_ram)
    jmp_shift = Mux((nz & jnz) ^ jmp, Constant("0"*(addr_size_rom - 1) + "1"), n[n.bus_size - addr_size_rom:n.bus_size]) # impose n.bus_size > addr_size_rom
    new_read_addr = n_adder(read_addr, jmp_shift, Constant("0"))[0]

    data_a.rename("data_a")
    data_b.rename("data_b")
    r_a.rename("r_a")
    r_b.rename("r_b")
    nz.rename("nz")
    jnz.rename("jnz")
    wram.rename("wram")
    rram.rename("rram")
    #jmp_shift.rename("jmp_shift")
    #read_addr.rename("read_addr")
    #new_read_addr.rename("new_read_addr")
