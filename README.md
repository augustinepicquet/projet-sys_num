# Projet système numérique
## Utilisation et description des principaux fichiers
Les scripts script_clock_fast, script_clock_real et script_dvd permettent d'éxécuter directement les 3 programmes implémentés. 
```bash
chmod +x script_dvd
./script_dvd
```
### Présentation des différents programmes  
script_clock_fast et script_clock_real utilise tous deux le même processeur. C'est un processeur spécialement optimisé pour gérer une clock.  
Il a été implémenté à l'aide de carotte.py (voir explication plus loin) puis a été compilé dans un fichier C. Ce fichier C a été modifié pour ajouter la gestion de l'affichage en 7 segment.  
Le fichier C a aussi été modifié pour permettre d'initialiser la clock à l'heure et date de notre choix. L'utilisation est la suivante :
```bash
./clock 00091014012025
```
permettra d'initialiser la clock au 14 janvier 2025 à 10 heures 9 minutes et 0 secondes. L'ordre est l'ordre lexicographique.  
Les deux programmes clock.asmb et clock_ticking.asmb profite de l'initialisation quelconque de la clock. Si aucun argument n'est fourni, la date par défaut est le premier janvier de l'an 0 à minuit pile.  
Les fichiers asmb sont transformés en binaire à l'aide de assembleur.py et directement chargé dans rom.ck.  
Un second processeur est implémenté, lui dans le fichier dvd.c. Ce processeur est plus complet et peut implémenter n'importe quel programme.  
Un programme est déja fait, DVD.asmb (c'est celui qui est lancé par script_dvd). Il simule l'écran d'attente d'un lecteur DVD qui rebondit.  
Le fichier dvd.c a été modifié manuellement pour ajouter un rendu graphique.  
La vitesse et la direction peuvent d'ailleurs facilement être modifé en changeant une ligne dans le fichier asmb.  

### Explication sommaire des différents fichiers et de leur rôle
Le fichier projet.py utilise carotte.py pour créer une netlist projet.net (pareil pour projet_dvd.py avec projet_dvd.net).  
Ensuite cette netlist est compilé à l'aide du netlist_simulator.ml dans un fichier C.  
Cependant, pour permettre la visualisation des programmes et la gestion des entrées, les programmes C sont ensuites modifiés à la main pour ces cas là. Le code de la netlist traduit en C est quant à lui repris tel quel.  
Les fichiers clock.c et dvd.c sont ces fichiers retravaillés. Le premier permet donc l'affichage 7 segment. Seul l'affichage et le principe de ticking est ajouté, c'est le programme simulé qui s'occcupe de dire quel segment allumé.  
De même dvd.c affiche le carré mais sa position est toujours calculé par le processeur qui est simulé dans le fichier c.  
Le fichier assembleur.py (ou assembleur_dvd.py) sert à charger un fichier asmb dans un ficher rom.ck. 
Et une fois que cela est fait on peut lancer le programme compilé clock ou dvd pour faire ce que l'on souhaite. Il est possible de faire totalement autre chose avec dvd notamment.  
L'affichage est prévu pour le programme du dvd mais n'importe quel programme est possible en changeant la ROM, seul l'affichage serait à refaire en C.  
  
**ATTENTION**  
  
Si vous voulez tester il faudra que vous ayez installé la bibliothèque SDL2 au préalable (c'est la bibliothèque qui gère la partie graphique des programmes C)  
Si vous êtes sur Linux il suffit de faire :  
```bash
sudo apt install libsdl2-dev
```
Aussi il faut bien penser à lier le module pendant la compilation (les scripts le font automatiquement).  

### Performance  
La clock_fast tourne à 30 secondes pour un an soit 12 heures par seconde sur un ordinateur classique (des tests plus poussé serait nécessaire).  

## Remarque sur le simulateur de netlist  
Le simulateur de netlist est celui que l'un des membres du groupe avait déjà codé. Il compile directement en C les netlist pour des questions de performance. Il pourrait d'ailleurs être optimisé. Il a été modifié pour internaliser la RAM.  

## Documentation
Les fichiers langage_assembleur.txt et langage_assembleur_dvd.txt explique le langage asmb associé aux 2 processeurs.  
Le jeu d'instruction a été créé par nos soins et n'est basé que sur l'utilisation que l'on en fait et le jeu minimal que l'on a considéré comme nécessaire pour écrire des programmes complexes (pour celui sur le dvd).
