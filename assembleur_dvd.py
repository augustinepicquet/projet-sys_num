def int_to_bin(n_size, entier, signé):
    if not signé:
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
    assert entier < 2**(n_size-1)
    assert entier >= -2**(n_size - 1)
    int_n = entier
    bin_n = ""
    poids_fort = "0"
    if int_n < 0:
        int_n += 2**(n_size-1)
        poids_fort = "1"
    for i in range(n_size-1):
        if int_n % 2 == 1:
            bin_n = "1" + bin_n
        else:
            bin_n = "0" + bin_n
        int_n = int_n // 2
    return poids_fort + bin_n
    

def compil_instr(previous_dico_registre, num_ligne, instr):
    dico_registre = previous_dico_registre
    nb_reg = len(dico_registre)
    max_nb_reg = 32

    def handle_reg_arg(reg):
        if reg not in dico_registre:
            assert reg[0].islower() and reg.isalnum(), "Line " + str(num_ligne) + ":" + "Register name has wrong format"
            assert nb_reg != max_nb_reg, "Line " + str(num_ligne) + ":" + "Not enough registers, some should be used again"
            dico_registre[reg] = int_to_bin(5, nb_reg, False)
        
        return dico_registre[reg]

    n_size = 32
    dico_instr_bin = {"jmp" : "000100", "jnz" : "001000", "wram" : "000001", "rram" : "000010",
                      "copy" : "100000", "and" : "100001", "not" : "100010", "or" : "100011", "xor" : "100100",
                      "addr" : "100101", "add" : "100110", "clear" : "100111", "neg" : "101000", "sub" : "101001", "subr" : "101010", "mod_2" : "101011", 
                      "positif" : "101100"}
    
    bin_instr = dico_instr_bin[instr[0]]
    r_a = "00000"
    r_b = "00000"
    bin_n = "0"*n_size

    if instr[0] == "jmp":
        bin_n = int_to_bin(n_size, instr[1], False)

    elif instr[0] == "jnz":
        bin_n = int_to_bin(n_size, instr[1], False)
        r_a = handle_reg_arg(instr[2])

    elif instr[0] == "add":
        assert (instr[3][1:] == "" or instr[3][1:].isdigit()) and (instr[3][0].isdigit() or instr[3][0] == "-"), "Line " + str(num_ligne) + ":" + "Add third argument should be an integer"
        r_a = handle_reg_arg(instr[1])
        r_b = handle_reg_arg(instr[2])
        bin_n = int_to_bin(n_size, int(instr[3]), True)

    elif instr[0] == "sub":
        assert (instr[2][1:] == "" or instr[2][1:].isdigit()) and (instr[2][0].isdigit() or instr[2][0] == "-"), "Line " + str(num_ligne) + ":" + "Sub third argument should be an integer"
        r_a = handle_reg_arg(instr[1])
        bin_n = int_to_bin(n_size, int(instr[2]), True)

    elif instr[0] == "clear":
        r_a = handle_reg_arg(instr[1])

    else:
        r_a = handle_reg_arg(instr[1])
        r_b = handle_reg_arg(instr[2])

    return bin_instr + r_a + r_b + bin_n, dico_registre

def compil(filename):
    dico_instr_nb_arg = {"jmpa" : 1, "jmpf" : 1, "jmpr" : 1, "jnza" : 2, "jnzf" : 2, "jnzr" : 2, "wram" : 2, "rram" : 2, "clear" : 1, "add" : 3, "sub" : 2,
                        "copy" : 2, "and" : 2, "not" : 2, "or" : 2, "xor" : 2, "addr" : 2, "subr" : 2, "mod_2" : 2, "positif" : 2, "neg" : 2}
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


compil("test.asmb")
