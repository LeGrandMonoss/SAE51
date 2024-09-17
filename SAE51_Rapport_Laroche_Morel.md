# SAE51 - Création de machines virtuelles



## Réalisé par :
LAROCHE Léo  
MOREL Robin  


**Date de remise : 19/09/2024**

---
---

## Objectif :

Lors de ce projet, nous avons dû mettre en place un script permettant, via VboxManage, de créer des machines virtuelles, de les démarrer, les supprimer, les lister, les éteindre, ainsi que d'ajouter des fonctionnalités non intégrées précédemment. Nous avons choisi de recommencer le projet à zéro afin de nous replonger dedans et de corriger éventuellement des erreurs.

---
---

## Idées d'ajout :

- Ajout d'un choix d'os qui ajoute directement l'iso correspondant
  - Problème: Lors du projet nous avons paramétré pour que les vm se lancent en pxe donc cette solution n'a pas d'intérêt

- Ajout d'une interface graphique
  - Problème : Le projet avait pour but de se débarrasser de l'interface graphique de Virtual Box pour gagner du temps, mais si on veut absolument utiliser une interface graphique autant utiliser directement Virtual Box

- Ajout de l'allocation de ressource dans les arguments pour pouvoir allouer plus ou moins de ressources si nécessaire, tout en gardant la RAM à 4096 o et le stockage à 64 Go si les arguments restent vides

- Ajout d'un message de confirmation de suppression et un message de confirmation d'arrêt d'une VM

- Ajout d'un argument de création multiple de VM
  
---
---

## Présentation du code

Dans cette partie on va présenter le code que nous avons refait de 0, sans prendre en compte notre précédent rendu.


### Mise en place du script
```
@echo off  
setlocal enabledelayedexpansion         

REM On force l'encodage en UTF-8 pour éviter les problèmes de caractères spéciaux
chcp 65001 >nul
```
Dans les premières lignes, nous avons préparer notre code en le rendant plus lisible et plus agréable à utiliser avec les lignes ci-dessus. echo off va nous permettre de désactiver l'affichage des lignes de commande pour avoir un environement plus clair. On utilise setlocal afin de manipuler plus efficacement les variables dans les boucles ou dans des conditions complexes. Vu que le texte qu'on affiche est en français, on doit activer l'affichage en utf-8 pour bien afficher les caractères spéciaux, pour cela, on a utilisé la commande chcp qui permet de changer la table de caractère par celui-ci.

----------

### Vérification du 1er argument
```
REM Vérifier les arguments
if "%~1"=="" (
    echo Usage: %0 [L|N|S|D|A|M] [nom_VM]
    echo L  - Lister les machines
    echo N  - Créer une nouvelle machine
    echo S  - Supprimer une machine
    echo D  - Démarrer une machine
    echo A  - Arrêter une machine
    echo M  - Créer plusieurs machines (8 max)
    exit /b 
)
REM Vérification si le premier argument n'est pas valide
if /i not "%~1"=="L" if /i not "%~1"=="N" if /i not "%~1"=="S" if /i not "%~1"=="D" if /i not "%~1"=="A" if /i not "%~1"=="M" (
    echo Erreur : Argument non valide "%~1". Veuillez entrer une des options suivantes :
    echo L  - Lister les machines
    echo N  - Créer une nouvelle machine
    echo S  - Supprimer une machine
    echo D  - Démarrer une machine
    echo A  - Arrêter une machine
    echo M  - Créer plusieurs machines (8 max)
    exit /b 1
)
```

On vérifie si la valeur du 1er argument est comprise dans les choix disponibles, si elle n'en fait pas partie, la liste des fonctionnalités sera affichée.

----------

### Initialisation des variables globales
```
REM Définir les variables globales
set "VM_NAME=%~2"
set "VM_TYPE=Debian_64"
set "VM_PATH=D:\RT\RT1\SAE21 Kramm"
set "VBoxManagePath=C:\Program Files\Oracle\VirtualBox"
set "PATH=%PATH%;%VBoxManagePath%"
```

On défini les variables qui seront utille pour les différentes fonctionnalités du script, la variable VM_PATH est à absolument changer le repertoire dans lequel les disques de stockages des VM vont être enregistré.
On prend le temps d'ajouter VBoxManage dans le PATH pour ne pas avoir de problème lors de la première utilisation du script.

----------

```
REM Vérifier et définir la RAM
if "%~3" NEQ "" (
    set "VM_RAM=%~3"
) else (
    set "VM_RAM=4096"
)

REM Vérifier et définir le disque dur
if "%~4" NEQ "" (
    set "VM_DU=%~4"
) else (
    set "VM_DU=65536"
)
```
Dans cette partie on vérifie les arguments 3 et 4, qui correspondent aux variables allouant les ressources en terme de mémoire, si aucun argument n'est écrit, une valeur de base est est attribuée à 4Go pour la RAM et 64Go pour le stockage.  

----------

```
REM Obtenir l'utilisateur et la date de création
set "USER=%USERNAME%"
for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do (
    set "CREATION_DATE=%%c-%%a-%%b"
)


```

Enfin, on initialise les variables des métadonnées qu'on veut attribuer aux VM.

---

### Présentation des fonctionnalités 
#### Lister les machines
```
REM Actions basées sur le premier argument
if /i "%~1"=="L" (
    echo Liste des machines créées dans VirtualBox :
    echo ----------------------
    VBoxManage list vms
    echo ----------------------

    REM Afficher les métadonnées pour chaque machine
    for /f "tokens=1 delims={" %%i in ('VBoxManage list vms') do (
        set "vm_name=%%i"
        REM Nettoyer le nom de la VM en supprimant les guillemets et les espaces
        set "vm_name=!vm_name:"=!"
        set "vm_name=!vm_name: =!"

        REM Chemin du fichier de métadonnées
        set "vm_metadata_file=%VM_PATH%\!vm_name!\metadata.txt"
        
        REM Nettoyer les espaces dans le chemin du fichier de métadonnées
        set "vm_metadata_file=!vm_metadata_file: =!"

        REM Afficher le chemin des métadonnées pour diagnostic
        REM echo Chemin vérifié pour les métadonnées : !vm_metadata_file!

        if exist "!vm_metadata_file!" (
            echo ----------------------
            echo Métadonnées pour !vm_name!
            type "!vm_metadata_file!"
            echo ----------------------
        ) else (
            echo ----------------------
            echo Aucune métadonnée trouvée pour !vm_name!.
            echo ----------------------
        )
    )
)
```
Ici, on défini l'argument L qui permettra de lister les VMs qu'on a créé et de montrer, les métadonnées liées à ces dernières. 

----------

#### Ajouter une machine
```
if /i "%~1"=="N" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument N.
        exit /b 1
    )
    REM Vérifier si une VM avec le même nom existe déjà
    VBoxManage showvminfo "%VM_NAME%" >nul 2>&1
    if %errorlevel% == 0 (
        echo La VM %VM_NAME% existe déjà. Suppression en cours...
        VBoxManage unregistervm "%VM_NAME%" --delete
        echo La VM %VM_NAME% a été supprimée !
    ) else (
        echo Aucune VM nommée %VM_NAME%.
    )

    REM Créer la VM
    VBoxManage createvm --name "%VM_NAME%" --ostype "%VM_TYPE%" --basefolder "%VM_PATH%" --register
    echo La VM %VM_NAME% a été créée dans %VM_PATH% !

    REM Configurer la RAM
    VBoxManage modifyvm "%VM_NAME%" --memory %VM_RAM%
    echo La RAM de la VM %VM_NAME% a été configurée !

    REM Créer le disque dur virtuel dans un chemin spécifique
    VBoxManage createmedium disk --filename "%VM_PATH%\%VM_NAME%\%VM_NAME%.vdi" --size %VM_DU% --format VDI
    echo Le disque dur pour la VM %VM_NAME% a été créé !

    REM Ajouter un contrôleur SATA à la VM
    VBoxManage storagectl "%VM_NAME%" --name "SATA Controller" --add sata --controller IntelAhci

    REM Attacher le disque dur virtuel au port 0 du contrôleur SATA
    VBoxManage storageattach "%VM_NAME%" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "%VM_PATH%\%VM_NAME%\%VM_NAME%.vdi"
    echo Le disque dur pour la VM %VM_NAME% a été attaché !

    REM Configurer le réseau en NAT
    VBoxManage modifyvm "%VM_NAME%" --nic1 nat
    echo Le réseau de la VM %VM_NAME% a été configuré !

    REM Configurer pour booter sur le réseau (PXE)
    VBoxManage modifyvm "%VM_NAME%" --boot1 net
    echo La VM %VM_NAME% est configurée pour démarrer sur le réseau !

    REM Créer le fichier de métadonnées
    mkdir "%VM_PATH%\%VM_NAME%"
    echo Date de création : %CREATION_DATE% > "%VM_PATH%\%VM_NAME%\metadata.txt"
    echo Créée par : %USER% >> "%VM_PATH%\%VM_NAME%\metadata.txt"
    echo Les métadonnées pour la VM %VM_NAME% ont été enregistrées !
)

```
Dans cette étape, on vérifie si un deuxième argument existe pour définir le nom de la VM, on vérifie ensuite si le nom de la machine existe déjà et on supprime la machine existante si c'est le cas, et ensuite on créé la VM, on lui défini la mémoire vive (argument 3), on crée un disque dur (argument 4) qu'on attache au port virtuel sata de la machine et on active le boot prioritaire sur le réseau pour le Pxe.  
On y ajoute le nom de la personne qui a créé la VM et la date et l'heure de création dans les métadonnées.

----------

#### Supprimer une machine

```
if /i "%~1"=="S" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument S.
        exit /b 1
    )
    :check_response
    set /p "response=Voulez-vous vraiment supprimer la VM %VM_NAME% ? (Oui/Non) : "

    REM Convertir la réponse en majuscules pour comparaison facile
    if /i "%response%"=="Oui" (
        if "%VM_NAME%"=="" (
            echo Vous devez spécifier un nom de VM avec l'argument S.
            exit /b 1
        )
        echo Suppression de la machine %VM_NAME%...
        VBoxManage unregistervm %VM_NAME% --delete
        echo La machine %VM_NAME% a été supprimée !
        exit /b 0
    ) else if /i "%response%"=="Non" (
        echo Annulation de la suppression de la VM %VM_NAME%.
        exit /b 0
    ) else (
        echo Réponse non valide. Veuillez entrer Oui ou Non.
        goto check_response
    )
)
```
Cette partie gère la suppression de la VM, elle contient un message de confirmation pour empêcher de supprimer une machine par mégarde. 

----------

#### Démarrer une machine existante 
```
if /i "%~1"=="D" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument D.
        exit /b 1
    )
    echo Démarrage de la machine %VM_NAME%...
    VBoxManage startvm "%VM_NAME%" --type headless
)
```
On défini l'argument D, il permet seulement de démarrer une VM.

----------

#### Arrêter une machine
```
if /i "%~1"=="A" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument S.
        exit /b 1
    )
    :check_response2
    set /p "response=Voulez-vous vraiment arrêter la VM %VM_NAME% ? (Oui/Non) : "

    REM Convertir la réponse en majuscules pour comparaison facile
    if /i "%response%"=="Oui" (
        if "%VM_NAME%"=="" (
            echo Vous devez spécifier un nom de VM avec l'argument A.
            exit /b 1
        )
        echo Arrêt de la machine %VM_NAME%...
        VBoxManage controlvm %VM_NAME% poweroff
        echo La machine %VM_NAME% a été arrêtée !
        exit /b 0
    ) else if /i "%response%"=="Non" (
        echo Annulation de l'arrêt de la VM %VM_NAME%.
        exit /b 0
    ) else (
        echo Réponse non valide. Veuillez entrer Oui ou Non.
        goto check_response2
    )
)
```
On reprend la base de l'argument S puis on la modifie pour que cet dernière puisse arrêter une VM et demander la confirmation à l'utilisateur. 

---------- 
### Création multiple

Voici l'ajout le plus visible au sujet, il permet de créer plusieurs VM en renseignant après la commande le nombre de machine à faire.
Pour cela, on a pris la base de la création de la VM, qu'on a mis dans une boucle. Pour y arriver, on a concatené le numéro de la boucle au nom de la VM défini sur la commande de base.
```
if /i "%~1"=="M" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument N.
        exit /b 1
    )
    set "%VM_NAME%=%~2"
    REM Vérifier si une VM avec le même nom existe déjà
    VBoxManage showvminfo "%VM_NAME%" >nul 2>&1
    if %errorlevel% == 0 (
        echo La VM %VM_NAME% existe déjà. Suppression en cours...
        VBoxManage unregistervm "%VM_NAME%" --delete
        echo La VM %VM_NAME% a été supprimée !
    ) else (
        echo Aucune VM nommée %VM_NAME%.
    )
    set z=1
    set /p nb="Combien voulez-vous de VM? "
    :bclmachine
    set "VM_Namenb=%VM_NAME%%z%"
    
     REM Vérifier si une VM avec le même nom existe déjà
    VBoxManage showvminfo "%VM_Namenb%" >nul 2>&1
    if %errorlevel% == 0 (
        echo La VM %VM_Namenb% existe déjà. Suppression en cours...
        VBoxManage unregistervm "%VM_Namenb%" --delete
        echo La VM %VM_Namenb% a été supprimée !
    ) else (
        echo Aucune VM nommée %VM_Namenb%.
    )
    REM Créer la VM
    VBoxManage createvm --name "%VM_Namenb%" --ostype "%VM_TYPE%" --basefolder "%VM_PATH%" --register
    echo La VM %VM_Namenb% a été créée dans %VM_PATH% !

    REM Configurer la RAM
    VBoxManage modifyvm "%VM_Namenb%" --memory %VM_RAM%
    echo La RAM de la VM %VM_Namenb% a été configurée !

    REM Créer le disque dur virtuel dans un chemin spécifique
    VBoxManage createmedium disk --filename "%VM_PATH%\%VM_Namenb%\%VM_Namenb%.vdi" --size %VM_DU% --format VDI
    echo Le disque dur pour la VM %VM_Namenb% a été créé !

    REM Ajouter un contrôleur SATA à la VM
    VBoxManage storagectl "%VM_Namenb%" --name "SATA Controller" --add sata --controller IntelAhci

    REM Attacher le disque dur virtuel au port 0 du contrôleur SATA
    VBoxManage storageattach "%VM_Namenb%" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "%VM_PATH%\%VM_Namenb%\%VM_Namenb%.vdi"
    echo Le disque dur pour la VM %VM_Namenb% a été attaché !

    REM Configurer le réseau en NAT
    VBoxManage modifyvm "%VM_Namenb%" --nic1 nat
    echo Le réseau de la VM %VM_Namenb% a été configuré !

    REM Configurer pour booter sur le réseau (PXE)
    VBoxManage modifyvm "%VM_Namenb%" --boot1 net
    echo La VM %VM_Namenb% est configurée pour démarrer sur le réseau !

    REM Créer le fichier de métadonnées
    mkdir "%VM_PATH%\%VM_Namenb%"
    echo Date de création : %CREATION_DATE% > "%VM_PATH%\%VM_Namenb%\metadata.txt"
    echo Créée par : %USER% >> "%VM_PATH%\%VM_Namenb%\metadata.txt"
    echo Les métadonnées pour la VM %VM_Namenb% ont été enregistrées !
    if "%z%" LEQ "%nb%" (
        set /a z=z+1
        echo %z%
        goto bclmachine
    )
)
```

----------
### Fin du programme 
```
pause
```
On rajoute, une pause afin que l'utilisateur puisse regarder ce qui a été généré. 

---
---

### Problèmes et Améliorations possibles

#### Poweroff
Certaines partie du code pourrait être améliorer par exemple sur la fonction pour arrêter une VM le : 
```
VBoxManage controlvm "%VMName%" poweroff
```
Peut normalement changer par un : 
```
VBoxManage controlvm "%VMName%" acpipowerbutton
```
Pour éteindre de manière plus sécuriser la machine, mais lors des test la commande n'a pas fonctionné.

#### Boucle infinie sur la création multiple

- Lors de la création multiple si on veut ajouter **9** VM la boucle se met à tourner **à l'infini** et donc créé des machines jusqu'à ce qu'on fasse **ctrl+C**.
- Mais ce n'est pas le seul problème avec cette boucle, lorsqu'on met un nombre au-dessus de **9** on se retrouve qu'avec 2 machines à la sortie.
Avec un peu plus de temps pour debugger, on aurait pu corriger ces deux problèmes.

#### Confirmation un peu trop performante

Lors de la confirmation de suppression, on se retrouve avec un problème d'argument vide lors de la première execution de la boucle permettant de décider du sort de la VM. Ce qui en résulte à un **"Non"** qui relance la boucle.
Ce bug n'est pas si dérangeant donc on a pas mis de ressources dessus pour le corriger en priorité.
