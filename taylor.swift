6 bit pour quelle instruction
5 bit pour savoir sur quel registre on agit (r_a)
5 bit pour savoir sur quel registre on lis (2) (r_b)



    
#On stocke toutes les adresses dans des registres pour des soucis de instruction trop longue

WRITE_RAM à l'adresse stocké dans r_b la valeur stocké dans r_a 000110
READ_RAM à l'adresse stocké dans r_b et l'affecter à r_a 000111
JMP à l'adresse stocké dans r_a 000000
JNZ offset a si la valeure stocké dans r_b est non nulle 000001
ET 100001
NON 100010
OR 100011
XOR 100100
IS_0 100101
IS_1 100110
IS_2 100111
IS_3 101000
IS_4 101001
IS_5 101010
IS_6 101011
IS_7 101100
IS_8 101101
IS_9 101110
INCREM 101111
MUL_4 (registre param 2 (unité et dizaine année (potentiellement des centaines))) 110000
MUL_100 (registre param (unité et dizaine année)) 110001
MUL_400 (registre param (combinaison de MUL_4 et MUL_100 qui tombe bien sur les trucs)) 110010

Decodage (nuage):
    1 bit pour savoir si on écrit dans la RAM -> (1&(!(b<5)))&(1&(!(b<4)))&(1&(!(b<3)))&(1&((b<2)))&(1&((b<1)))&((1&(!b)))
    1 bit pour savoir si on écrit dans le registre -> 1&(b<5)|((1&(!(b<5)))&(1&(!(b<4)))&(1&(!(b<3)))&(1&((b<2)))&(1&((b<1)))&((1&(b))))
    1 bit pour savoir si on lit dans la RAM -> (1&(!(b<5)))&(1&(!(b<4)))&(1&(!(b<3)))&(1&((b<2)))&(1&((b<1)))&((1&(b)))
    1 bit pour savoir jmp -> (1&(!(b<5)))&(1&(!(b<4)))&(1&(!(b<3)))&(1&(!(b<2)))&(1&(!(b<1)))&((1&(!b)))
    1 bit pour jnz -> (1&(!(b<5)))&(1&(!(b<4)))&(1&(!(b<3)))&(1&(!(b<2)))&(1&(!(b<1)))&((1&(b)))
    1 bit pour jmp ou jnz -> (1&(!(b<5)))&(1&(!(b<4)))&(1&(!(b<3)))&(1&(!(b<2)))&(1&(!(b<1)))
    5 bit pour savoir si on fait appel à ALU et laquelle si oui -> (((1&(b<5))>0)|((1&(b<5))>1)|((1&(b<5))>2)|((1&(b<5))>3)|((1&(b<5))>4))&(11111&b)
    5 bit pour savoir sur quel registre on agit (r_a)
    5 bit pour savoir sur quel registre on agit (r_b)



#alpha
IS_9 b reg(sec)
NOT b b
INCREM reg(sec)
jnz (alpha) b

#alpha
IS_9 b reg(sec)
NOT b b
INCREM reg(sec)
jnz (alpha) b
