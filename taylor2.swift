6 bit pour quelle instruction
5 bit pour savoir sur quel registre on agit (r_a)
5 bit pour savoir sur quel registre on lis (2) (r_b)
16 bits pour un paramètre entier non signé (pour jmp et jnz et add)
TOus les entiers seront signés !!!!!!!!!!!!!!!!!!

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
ADDR additionne r_a et r_b dans r_a et oublie la potentielle retenue 110011
ADD additionne r_b et n dans r_a et oublie la potentielle retenue 110100
CLEAR met le registre r_a au vrai zéro 110101

NEG renvoie -r_b dans r_a
SUB r_a - n et résultat dans r_a
SUBR r_a - r_b et résultat dans r_a
ALEA met r_a au carré et récupère les bits au centre, résultat dans r_a
MOD_VMAXY met r_b mod vmaxy dans r_a
MOD_2 met r_b mod 2 dans r_a
POSITIF met r_a à vrai si la valeur dans r_b est positive

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

