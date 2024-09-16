# SAE21 - Création de machines virtuelles



## Réalisé par :
LAROCHE Léo  
MOREL Robin  


**Date de remise : 22/06/2023**

---

### Objectif :

Lors de ce projet nous avons du mettre en place un script permettant via VboxManage de créer des machines virtuelles, les démarer, les supprimer, les lister, les éteindre, ...

---

### Présentation du code

Pour chaque version, on a ajouté une ligne qui précise le chemin vers vboxmanage
```
set PATH=%PATH%;"C:\Program Files\Oracle\VirtualBox"
```
  
Pour commencer, on a fait un code qui permettait de créer une machine avec un nom fixe à l'execution du script : 
```
VBoxManage createvm --name "Michel1" --register
```

Ensuite on a fait évoluer ce script pour créer une vm avec une ram précise et préciser l'os : 

```
set PATH=%PATH%;"C:\Program Files\Oracle\VirtualBox"
VBoxManage createvm --name "Michel1" --register
VBoxManage modifyvm Michel --os-type=Debian_64 --memory=4096
```


Après plusieurs étapes on a fini avec code rendu avec ce fichier.   

On va donc expliquer chaque partie.

```
REM Définition des variables 
set "RAMSize=4096"
set "DiskSize=64"

set "VBoxManagePath=C:\Program Files\Oracle\VirtualBox"
set "PATH=%PATH%;%VBoxManagePath%"
```
Danx cette première partie on initialise des variables qui nous seront utile plus tard.  
```
if "%~1"=="" (
    echo Utilisation: %~nx0 <action> [machine]
    echo   Actions disponibles:
    echo     L - Lister les machines enregistrées
    echo     N - Ajouter une nouvelle machine
    echo     S - Supprimer une machine
    echo     D - Démarrer une machine
    echo     A - Arrêter une machine
    exit /b 1
)

```
Après ça on fait une condition "si" permettant d'affiché les différents arguments existant si la personne n'en rentre aucun.  
#### Présentation des fonctionnalités 
##### Lister les machines
```
set "Action=%~1"
if /i "%Action%"=="L" (
    echo Liste des machines enregistrées:
    VBoxManage list vms > machines.txt
    
    REM Parcourir le fichier des machines et afficher les métadonnées
    for /f "tokens=1" %%a in (machines.txt) do (
        echo Machine : %%a
        VBoxManage getextradata "%%a" "date_de_creation"
        VBoxManage getextradata "%%a" "utilisateur"
        echo.
    )
    
    REM Supprimer le fichier temporaire
    del machines.txt
)
```
Pour la fonction pour lister les machines avec leurs métadonnées, on créé un fichier texte dans lequel on va y transférer les machines virtuelles et grâce à la boucle dans ce fichier texte on y ajoute les métadonnées enregistrées sous la machine correspondante et on affiche le fichier texte avant de le supprimer car il ne nous sera plus d'aucune utilité après.
 ##### Ajouter une machine
```
else if /i "%Action%"=="N" (
    REM Vérification du deuxième argument
    if "%~2"=="" (
        echo Le nom de la machine doit être spécifié en tant que deuxième argument.
        exit /b 1
    )
    set "VMName=%~2"
    
    REM Vérifier si une machine de même nom existe déjà
    VBoxManage showvminfo "%VMName%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo Une machine avec le nom %VMName% existe déjà.
        exit /b 1
    )
    
    REM Créer la machine virtuelle
    VBoxManage createvm --name "%VMName%" --ostype Debian_64 --register
    
    REM Configurer les ressources de la machine virtuelle
    VBoxManage modifyvm "%VMName%" --memory %RAMSize% --vram 128
    VBoxManage createmedium disk --filename "D:\RT\SAE21 Kramm\Disques\%VMName%.vdi" --size %DiskSize% --format VDI
    VBoxManage storagectl "%VMName%" --name "SATA Controller" --add sata --bootable on
    VBoxManage storageattach "%VMName%" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "D:\RT\SAE21 Kramm\Disques\%VMName%.vdi"
    VBoxManage modifyvm "%VMName%" --nic1 intnet --nicbootprio1 1
    
    REM Ajouter les métadonnées
    set "CreationDate=%DATE% %TIME%"
    set "Username=%USERNAME%"
    VBoxManage setextradata "%VMName%" "date_de_creation" "%CreationDate%"
    VBoxManage setextradata "%VMName%" "utilisateur" "%Username%"
)
```
Dans cette étape, on vérifie si un deuxième argument existe pour définir le nom de la VM, on vérifie ensuite si le nom de la machine existe déjà et on arrête de le programme si c'est le cas, et ensuite on créé la VM, on lui défini la mémoire vive, on crée un disque dur qu'on attache au port virtuel sata de la machine et on active le boot prioritaire sur le réseau pour le Pxe.  
On a aussi ajouté en métadonnée le nom de la personne qui a créé la VM et la date et l'heure de création.  
  
Note : Ayant mit un chemin absolu, il faudra le changer pour faire fonctionner le script sur un autre pc

##### Supprimer la machine
```
else if /i "%Action%"=="S" (
    REM Vérification du deuxième argument
    if "%~2"=="" (
        echo Le nom de la machine doit être spécifié en tant que deuxième argument.
        exit /b 1
    )
    set "VMName=%~2"
    
    REM Vérifier si la machine existe
    VBoxManage showvminfo "%VMName%" >nul 2>&1
    if %errorlevel% neq 0 (
        echo La machine avec le nom %VMName% n'existe pas.
        exit /b 1
    )
    
    REM Supprimer la machine virtuelle
    VBoxManage unregistervm "%VMName%" --delete
}
```
Pour supprimer la machine, on vérifie que la machine existe (nom = 2ème arg) et si c'est le cas on la supprime.  
##### Démarrer une machine existante 
```
else if /i "%Action%"=="D" (
    REM Vérification du deuxième argument
    if "%~2"=="" (
        echo Le nom de la machine doit être spécifié en tant que deuxième argument.
        exit /b 1
    )
    set "VMName=%~2"
    
    REM Vérifier si la machine existe
    VBoxManage showvminfo "%VMName%" >nul 2>&1
    if %errorlevel% neq 0 (
        echo La machine avec le nom %VMName% n'existe pas.
        exit /b 1
    )
    
    REM Démarrer la machine virtuelle
    VBoxManage startvm "%VMName%"
)
```
Pour démarrer la vm on vérifie que la machine existe et on la lance.
##### Arrêter une machine
```
else if /i "%Action%"=="A" (
    REM Vérification du deuxième argument
    if "%~2"=="" (
        echo Le nom de la machine doit être spécifié en tant que deuxième argument.
        exit /b 1
    )
    set "VMName=%~2"
    
    REM Vérifier si la machine existe
    VBoxManage showvminfo "%VMName%" >nul 2>&1
    if %errorlevel% neq 0 (
        echo La machine avec le nom %VMName% n'existe pas.
        exit /b 1
    )
    
    REM Arrêter la machine virtuelle
    VBoxManage controlvm "%VMName%" poweroff
)
```
Pour finir, on vérifie que la VM existe et on l'éteint.

--- 

### Problèmes et Améliorations possibles

#### Problème argument
Lors des tests une désynchronisation des arguments (Apparition d'arguments précèdents lors de l'execution d'une nouvelle commande) est apparue, je n'ai néanmoins pas trouvé d'où vennait ce problème.  

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

# SAE51 - Ajout de fonctionnalités

## Réalisé par :
LAROCHE Léo  
MOREL Robin  


**Date de remise : XX/XX/20XX**

---

### Objectif :

Lors de ce projet, nous avons dû mettre en place un script permettant, via VboxManage, de créer des machines virtuelles, de les démarrer, les supprimer, les lister, les éteindre, ainsi que d'ajouter des fonctionnalités non intégrées précédemment. Nous avons choisi de recommencer le projet à zéro afin de nous replonger dedans et de corriger éventuellement des erreurs.

### Idées d'ajout :

- Ajout d'un choix d'os qui ajoute directement l'iso correspondant
  - Problème: Lors du projet nous avons paramétré pour que les vm se lancent en pxe donc cette solution n'a pas d'intérêt

- Ajout d'une interface graphique
  - Problème : Le projet avait pour but de se débarrasser de l'interface graphique de Virtual Box pour gagner du temps, mais si on veut absolument utiliser une interface graphique autant utiliser directement Virtual Box

- Ajout de l'allocation de ressource dans les arguments pour pouvoir allouer plus ou moins de ressources si nécessaire, tout en gardant la RAM à 4096 o et le stockage à 64 Go si les arguments restent vides

- Rajouter une vérification pour supprimation une VM (voir aussi plus tard pour demander lors de l'arrêt d'une VM)


### Ce qui à était fait :

##### Mise en place du code
```
@echo off  
setlocal enabledelayedexpansion         

REM On force l'encodage en UTF-8 pour éviter les problèmes de caractères spéciaux
chcp 65001 >nul
```
Dans les premières lignes, nous avons préparer notre code en le rendant plus lisible et plus agréable à utiliser avec les lignes ci-dessus. echo off va nous permettre de désactiver l'affichhge des lignes de commande pour avoir un environement plus clair. On utilise setlocal afin de manipuler plus efficacement les variables dans les boucles ou dans des conditions complexes. Vu que plustard nous utilisions du français dans des messages des retours et qui à des caractères spéciaux, on va utiliser la commande chcp qui permet de changer la page de code utilisée dans l'invite de commande, afin d'utiliser utf-8.

#### Vérification des arguments 

```
REM Vérifier les arguments
if "%~1"=="" (
    echo Usage: %0 [L|N|S|D|A] [nom_VM]
    echo L  - Lister les machines
    echo N  - Créer une nouvelle machine
    echo S  - Supprimer une machine
    echo D  - Démarrer une machine
    echo A  - Arrêter une machine
    exit /b 
)
```
Dans cette partie de code, on va vérifier si l'un des arugments est utiliser 

#### Arguments valide 

```
REM Vérification si le premier argument n'est pas valide
if /i not "%~1"=="L" if /i not "%~1"=="N" if /i not "%~1"=="S" if /i not "%~1"=="D" if /i not "%~1"=="A" (
    echo Erreur : Argument non valide "%~1". Veuillez entrer une des options suivantes :
    echo L  - Lister les machines
    echo N  - Créer une nouvelle machine
    echo S  - Supprimer une machine
    echo D  - Démarrer une machine
    echo A  - Arrêter une machine
    exit /b 1
)
```
Ce morceau de code permet de vérifier si l'argument qu'on a rentrer est bien dans la liste sinon on echo un message d'erreur. 
 
#### Argument RAM

```
REM Vérifier et définir la RAM
if "%~3" NEQ "" (
    set "VM_RAM=%~3"
) else (
    set "VM_RAM=4096"
)
```
Comme dit dans nos idées, on à rajouter la possibilté de choisir la RAM en tant qu'argument 

#### Argument disque dur 

```
REM Vérifier et définir le disque dur
if "%~4" NEQ "" (
    set "VM_DU=%~4"
) else (
    set "VM_DU=65536"
)
```
Pareil pour la RAM, on rajoute la possibilité de choisir la taille du disque mais en tant qu'argument

#### User & date

```
REM Obtenir l'utilisateur et la date de création
set "USER=%USERNAME%"
for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do (
    set "CREATION_DATE=%%c-%%a-%%b"
)
```
Ce morceau, nous sert à récuperer le nom du user créateur d'une VM et sa date de création pour les métadonnées

#### Argument L : Liste des VM 

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
Ici, on défini l'argument L qui permettra de lister les VMs qu'on à créer et de montrer, les métadonnées liers à ces dernières. 

#### Argument S : suppresion de VM 

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
Pour la définition de l'argument S, on lui permet de supprimer une VM mais avant de la supprimer, on demade confirmation pour éviter les erreurs. 

#### Argument D : Démarrer une VM 

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
On défini l'argument D, elle permet seulement de démarrer une VM.

#### Argument A : L'arrét d'une VM 

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

#### Fin du programme 
```
pause
```
On rajoute, une pause afin que l'utilisateur puisse regarder ce qui à était générer. 
