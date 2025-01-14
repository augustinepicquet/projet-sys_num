import argparse

def int_to_bin(n_size, entier):
    int_n = entier
    bin_n = ""
    while int_n < 0:
        int_n += 2**n_size
    for i in range(n_size):
        if int_n % 2 == 1:
            bin_n = "1" + bin_n
        else:
            bin_n = "0" + bin_n
        int_n = int_n // 2
    return bin_n

def compil_instr(previous_dico_registre, num_ligne, instr):
    dico_registre = previous_dico_registre
    nb_reg = len(dico_registre)
    max_nb_reg = 32

    def handle_reg_arg(reg):
        if reg not in dico_registre:
            assert reg[0].islower() and reg.isalnum(), "Line " + str(num_ligne) + ":" + "Register name has wrong format"
            assert nb_reg != max_nb_reg, "Line " + str(num_ligne) + ":" + "Not enough registers, some should be used again"
            dico_registre[reg] = int_to_bin(5, nb_reg)
        
        return dico_registre[reg]

    n_size = 16
    dico_instr_bin = {"jmp" : "000100", "jnz" : "001000", "wram" : "000001", "rram" : "000010", "increm" : "101111", "reset" : "110010", "clear" : "110101", "add" : "110100", 
                      "copy" : "100000", "and" : "100001", "not" : "100010", "or" : "100011", "xor" : "100100", "mul_4" : "110000", "mul_100" : "110001", "addr" : "110011",
                      "is_0" : "100101", "is_1" : "100110", "is_2" : "100111", "is_3" : "101000", "is_4" : "101001", "is_5" : "101010", "is_6" : "101011", 
                      "is_7" : "101100", "is_8" : "101101", "is_9" : "101110"}
    
    bin_instr = dico_instr_bin[instr[0]]
    r_a = "00000"
    r_b = "00000"
    bin_n = "0"*n_size

    if instr[0] == "jmp":
        bin_n = int_to_bin(n_size, instr[1])

    elif instr[0] == "jnz":
        bin_n = int_to_bin(n_size, instr[1])
        r_a = handle_reg_arg(instr[2])

    elif instr[0] == "add":
        assert instr[3].isdigit(), "Line " + str(num_ligne) + ":" + "Add third argument should be a positive integer"
        r_a = handle_reg_arg(instr[1])
        r_b = handle_reg_arg(instr[2])
        bin_n = int_to_bin(n_size, int(instr[3]))

    elif instr[0] in ["increm", "reset", "clear"]:
        r_a = handle_reg_arg(instr[1])

    else:
        r_a = handle_reg_arg(instr[1])
        r_b = handle_reg_arg(instr[2])

    return bin_instr + r_a + r_b + bin_n, dico_registre

def compil(filename):
    dico_instr_nb_arg = {"jmpa" : 1, "jmpf" : 1, "jmpr" : 1, "jnza" : 2, "jnzf" : 2, "jnzr" : 2, "wram" : 2, "rram" : 2, "increm" : 1, "reset" : 1, "clear" : 1, "add" : 3, 
                        "copy" : 2, "and" : 2, "not" : 2, "or" : 2, "xor" : 2, "mul_4" : 2, "mul_100" : 2, "addr" : 2,
                        "is_0" : 2, "is_1" : 2, "is_2" : 2, "is_3" : 2, "is_4" : 2, "is_5" : 2, "is_6" : 2, "is_7" : 2, "is_8" : 2, "is_9" : 2}
    dico_fonction = {}
    dico_registre = {}
    tableau_lignes_instruction = [0]
    liste_instr = []
    assert filename[-5:] == ".asmb"
    with open("rom.ck", 'w') as outfile, open(filename, 'r', encoding='utf-8') as infile:
        lines = infile.readlines()
        compteur_lignes = 0
        compteur_instructions = 0
        for line in lines:
            compteur_lignes += 1
            tableau_lignes_instruction.append(compteur_instructions)
            strip_line = line.strip().split(" ")
            if strip_line != [""]:
                first_char = strip_line[0][0]
                assert first_char.isalpha() or first_char == "#", "Line " + str(compteur_lignes) + ":" + "A line should begin by a letter or a '#'"
                if first_char.isupper():
                   f_name = strip_line[0][:-1]
                   assert f_name.isalnum(), "Line " + str(compteur_lignes) + ":" + "A function name should only have alphanumeric characters"
                   assert strip_line[0][-1] == ":", "Line " + str(compteur_lignes) + ":" + "A function definition should be followed by a ':'"
                   assert f_name not in dico_fonction, "Line " + str(compteur_lignes) + ":" + "Function '" + f_name + "' already exists"
                   dico_fonction[f_name] = compteur_instructions
                if first_char.islower():
                    assert strip_line[0] in dico_instr_nb_arg, "Line " + str(compteur_lignes) + ":" + "Instruction '" + strip_line[0] + "' does not exists"
                    compteur_instructions += 1
                    instr = []
                    for s in strip_line:
                        if s != "":
                            instr.append(s)
                    assert len(instr) == dico_instr_nb_arg[strip_line[0]] + 1, "Line " + str(compteur_lignes) + ":" + "Wrong instruction format" 
                    liste_instr.append((compteur_lignes, instr))

        output = ""
        for num_ligne, instr in liste_instr:
            if instr[0] == "jmpa":
                assert instr[1].isdigit(), "Line " + str(num_ligne) + ":" + "Jmpa argument should be a positive integer"
                destination = int(instr[1])
                n = tableau_lignes_instruction[destination] - tableau_lignes_instruction[num_ligne]
                bin_instr, dico_registre = compil_instr(dico_registre, num_ligne, ["jmp", n])
                output += bin_instr
            
            elif instr[0] == "jmpf":
                assert instr[1] in dico_fonction, "Line " + str(num_ligne) + ":" + "Jmpf argument should be an existing function"
                destination = dico_fonction[instr[1]]
                n = destination - tableau_lignes_instruction[num_ligne]
                bin_instr, dico_registre = compil_instr(dico_registre, num_ligne, ["jmp", n])
                output += bin_instr

            elif instr[0] == "jmpr":
                assert (instr[1][1:] == "" or instr[1][1:].isdigit()) and (instr[1][0].isdigit() or instr[1][0] == "-"), "Line " + str(num_ligne) + ":" + "Jmpr argument should be an integer"
                destination = int(instr[1]) + num_ligne
                n = tableau_lignes_instruction[destination] - tableau_lignes_instruction[num_ligne]
                bin_instr, dico_registre = compil_instr(dico_registre, num_ligne, ["jmp", n])
                output += bin_instr
            
            elif instr[0] == "jnza":
                assert instr[1].isdigit(), "Line " + str(num_ligne) + ":" + "Jnza first argument should be a positive integer"
                destination = int(instr[1])
                n = tableau_lignes_instruction[destination] - tableau_lignes_instruction[num_ligne]
                bin_instr, dico_registre = compil_instr(dico_registre, num_ligne, ["jnz", n, instr[2]])
                output += bin_instr
            
            elif instr[0] == "jnzf":
                assert instr[1] in dico_fonction, "Line " + str(num_ligne) + ":" + "Jnzf first argument should be an existing function"
                destination = dico_fonction[instr[1]]
                n = destination - tableau_lignes_instruction[num_ligne]
                bin_instr, dico_registre = compil_instr(dico_registre, num_ligne, ["jnz", n, instr[2]])
                output += bin_instr

            elif instr[0] == "jnzr":
                assert (instr[1][1:] == "" or instr[1][1:].isdigit()) and (instr[1][0].isdigit() or instr[1][0] == "-"), "Line " + str(num_ligne) + ":" + "Jnzr first argument should be an integer"
                destination = int(instr[1]) + num_ligne
                n = tableau_lignes_instruction[destination] - tableau_lignes_instruction[num_ligne]
                bin_instr, dico_registre = compil_instr(dico_registre, num_ligne, ["jnz", n, instr[2]])
                output += bin_instr

            else:
                bin_instr, dico_registre = compil_instr(dico_registre, num_ligne, instr)
                output += bin_instr
        outfile.write(output)


parser = argparse.ArgumentParser(description="")
parser.add_argument('-s', '--source', type=str, help="Nom du fichier source à utiliser", required=True)
args = parser.parse_args()

compil(args.source)
