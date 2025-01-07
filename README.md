# projet-sys_num

On peut utiliser le fichier script_shell pour faire toutes les manipulations nécessaires au lancement du processeur.   
Il suffit alors de modifier la dernière ligne de assembleur.py pour avoir 'compil("fichier.asmb")' et d'executer une fois la commande chmod +x script_shell pour rendre le fichier executable.   
On peut alors modifier le script comme on veut et l'éxecuter autant qu'on veut avec ./script_shell

La documentation du langage assembleur se trouve dans langage_assembleur.txt

Il faut mettre tous les fichiers ici présents dans un même dossier et créer le fichier netlist_simulator.byte avec la commande :   
ocamlbuild netlist_simulator.byte   

On peut ensuite exécuter n'importe quel fichier assembleur (fichiers avec l'extension .asmb) en procédant de la façon suivante :  

On modifie la dernière ligne de assembleur.py pour avoir 'compil("fichier.asmb")'  

On exécute assembleur.py avec la commande :   
python assembleur.py   
Un fichier rom.ck contenant le programme en binaire est alors créé.   

On crée le fichier projet.net correspondant à la netlist du processeur avec la commande :   
python carotte.py -o projet.net projet.py   

On peut ensuite exécuter le programme en simulant la netlist du processeur avec la commande :   
./netlist_simulator.byte -n nb_cycles projet.net   
