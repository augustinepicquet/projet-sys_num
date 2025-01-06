6 bit pour quelle instruction
5 bit pour savoir sur quel registre on agit (r_a)
5 bit pour savoir sur quel registre on lis (2) (r_b)
16 bits pour un paramètre entier non signé (pour jmp et jnz et add)

On dispose de 32 registres

WRITE_RAM à l'adresse stocké dans r_b la valeur stocké dans r_a 000001
READ_RAM à l'adresse stocké dans r_b et l'affecter à r_a 000010
JMP offset n 000100
JNZ offset n si la valeure stocké dans r_a est non nulle 001000

COPY copie r_b dans r_a 100000
AND 100001
NOT effectué sur r_b et renvoyé dans r_a 100010
OR 100011
XOR 100100
IS_0 effectué sur r_b renvoyé dans r_a 100101
IS_1 effectué sur r_b renvoyé dans r_a 100110
IS_2 effectué sur r_b renvoyé dans r_a 100111
IS_3 effectué sur r_b renvoyé dans r_a 101000
IS_4 effectué sur r_b renvoyé dans r_a 101001
IS_5 effectué sur r_b renvoyé dans r_a 101010
IS_6 effectué sur r_b renvoyé dans r_a 101011
IS_7 effectué sur r_b renvoyé dans r_a 101100
IS_8 effectué sur r_b renvoyé dans r_a 101101
IS_9 effectué sur r_b renvoyé dans r_a 101110
INCREM effectué sur r_a renvoyé dans r_a 101111 ne pas utiliser INCREM pour passer de 9 à 0 (lorsqu'on passe une dizaine), utiliser RESET à la place
MUL_4 effectué sur r_b et r_a renvoyé dans r_a (registre param 2 (unité (r_a) et dizaine (r_b) année (potentiellement des centaines))) 110000
MUL_100 effectué sur r_b et r_a renvoyé dans r_a (registre param (unité (r_a) et dizaine (r_b) année)) 110001
RESET met le registre r_a à 0 (le zéro de l'affichage 7 segments autrement dit 1111110) 110010
ADDR additionne r_a et r_b dans r_a et oublie la potentielle retenue 110011
ADD additionne r_b et n dans t_a et oublie la potentielle retenue 110100
CLEAR met le registre r_a au vrai zéro 110101

Decodage (nuage):
    1 bit pour savoir si on écrit dans la RAM
    1 bit pour savoir si on écrit dans le registre
    1 bit pour savoir si on lit dans la RAM
    1 bit pour savoir jmp
    1 bit pour jnz
    5 bit pour savoir si on fait appel à ALU et laquelle si oui
    5 bit pour savoir sur quel registre on agit (r_a)
    5 bit pour savoir sur quel registre on agit (r_b)
    16 bits pour un paramètre entier non signé (pour jmp et jnz)
