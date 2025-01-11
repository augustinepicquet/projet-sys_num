from lib_carotte import *




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
        if s[ls-1] == "0":
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

#ajouté par augustine (pas trop testé)

#negation : a = -b (a ne sert à rien )
def neg(a : Variable, b : Variable):
    b = ~b 
    #on se fiche de la retenue sortante, ie de f
    (e,f) = n_adder(b,Variable(1), Variable(0))
    return e 


def subr(a : Variable, b : Variable):
    b = neg(b,b)
    (e,f) = n_adder(a,b, Variable(0))
    return e 

def sub(a : Variable, n : int):
    return subr(a,Variable(n))

def divise_par_deux(a : Variable):
    for i in range(a.bus_size -1):
        a[a.bus_size -i] = a[a.bus_size-i-1]
    a[0] = 0
    return a 

#on utilise la méthode de fibonnaci : on a deux seeds : x_i et x_i_1 et on calcule x_i_2 : x_i + x_i_1 mod M
#pour avoir un nombre relatif, on soustrait (m-1)//2 à la fin.
#renvoie(a,b,c) avec a l'aléatoire qu'on veut (peut etre positif ou négatif), b et c les seeds pour la prochaine génération
#note : il faudra réinjecter les valeurs de retour dans la fonction dans le meme ordre  (sinon risque de conserver toujours une valeur sur les deux)
def alea(x_n : Variable, x_n_1 : Variable, M : int ):
    x_n_2 = n_adder(x_n, x_n_1, Variable(0))
    return (subr(x_n_1, divise_par_deux(Variable(M-1))), x_n_1, x_n_2)


#renvoie un bool avec la convention : 1 = true, 0 = false
def positif(a : Variable):
    return Variable(1- a[0])


def mod_vmaxY(a : Variable, b : Variable, Vmax : int ):
    e = b
    f = b 
    f = sub(f,Vmax )
    while(positif(f)):
        e = f 
        f = sub(f,Vmax)
    return e 

def mod_2(a : Variable):
    #renvoyer bit de poids faible de a
    return Variable(a[a.bus_size -1 ])


