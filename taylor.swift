5 bit pour quelle instruction
5 bit pour savoir sur quel registre on agit (r_a)
5 bit pour savoir sur quel registre on lis (2) (r_b)



    
#On stocke toutes les adresses dans des registres pour des soucis de instruction trop longue

WRITE_RAM à l'adresse stocké dans r_b la valeur stocké dans r_a
READ_RAM à l'adresse stocké dans r_b et l'affecter à r_a
JMP à l'adresse stocké dans r_a -> 00000
JNZ offset a si la valeure stocké dans r_b est non nulle -> 00001
ET 
NON 
OR
XOR
IS_0
IS_1
IS_2
IS_3
IS_4
IS_5
IS_6
IS_7
IS_8
IS_9
INCREM
MUL_4 (registre param 2 (unité et dizaine année (potentiellement des centaines)))
MUL_100 (registre param (unité et dizaine année))
MUL_400 (registre param (combinaison de MUL_4 et MUL_100 qui tombe bien sur les trucs))

Decodage (nuage):
    1 bit pour savoir si on écrit dans la RAM
    1 bit pour savoir si on écrit dans le registre
    1 bit pour savoir si on lit dans la RAM
    1 bit pour savoir jmp
    1 bit pour jnz
    1 bit pour jmp ou jnz -> 
    4 bit pour savoir sur quel registre on agit (r_a)
    4 bit pour savoir sur quel registre on lis (r_b)    
    1 bit pour chaque IS_N
    1 bit pour chaque bool_op
    1 bit pour INCREM
    


#alpha
IS_9 b reg(sec)
NOT b b
INCREM reg(sec)
jnz (alpha) b
