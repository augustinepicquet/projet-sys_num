# Projet système numérique
# Nouvelle version
Les scripts script_clock_fast, script_clock_real et script_dvd font tout directement pas besoin de se prendre la tête. 
```bash
chmod +x script_dvd
./script_dvd
```
Le fichier projet.py utilise carotte.py pour créer une netlist projet.net (pareil pour projet_dvd.py avec projet_dvd.net).  
Ensuite cette netlist est compilé à l'aide du netlist_simulator.ml dans un fichier C.  
Cependant, pour permettre la visualisation des programmes et la gestion des entrées, les programmes C sont ensuites modifiés à la main pour ces cas la. Le code de la netlist traduit en C est quant à lui repris tel quel.  
Les fichiers clock.c et dvd.c sont ces fichiers retravaillés. Le premier permet donc l'affichage 7 segment. Seul l'affichage et le principe de ticking est ajouté, c'est le programme simulé qui s'occcupe de dire quel segment allumé.  
De même dvd.c affiche le carré mais sa position est toujours calculé par le processeur qui est simulé dans le fichier c.  
Le fichier assembleur.py (ou assembleur_dvd.py) sert à charger un fichier asmb dans un ficher rom.ck. 
Et une fois que cela est fait on peut lancer le programme compilé clock ou dvd pour faire ce que l'on souhaite. Il est possible de faire totalement autre chose avec dvd notamment.  
L'affichage est prévu pour le programme du dvd mais n'importe quel programme est possible en changeant la ROM, seul l'affichage serait à refaire en C.  
**ATTENTION **  
Si vous voulez tester il faudra que vous ayez installé la bibliothèque SDL2 au préalable (c'est la bibliothèque qui gère la partie graphique des programmes C)  
Si vous êtes sur Linux il suffit de faire  
```bash
sudo apt install libsdl2-dev
```
Aussi il faut bien penser à lier le module pendant la compilation (les scripts le font automatiquement).  


# Ancienne version
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
