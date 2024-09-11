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
