# projet-sys_num

Il faut mettre tous les fichiers ici présents dans un même dossier et rajouter le fichier netlist_simulator.byte.  

On peut ensuite exécuter n'importe quel fichier assembleur (fichiers avec l'extension .asmb) en procédant de la façon suivante :  

On modifie la dernière ligne de assembleur.py pour avoir 'compil("fichier.asmb")'  

On exécute assembleur.py avec la commande : python assembleur.py  
Un fichier rom.ck contenant le programme en binaire est alors créé.

On crée le fichier projet.net correspondant à la netlist du processeur avec la commande : python carotte.py -o projet.net projet.py

On peut ensuite exécuter le programme en simulant la netlist du processeur avec la commande : ./netlist_simulator.byte -n nb_cycles projet.net
