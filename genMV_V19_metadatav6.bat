@echo off
setlocal enabledelayedexpansion

REM Forcer l'encodage en UTF-8 pour éviter les problèmes de caractères spéciaux
chcp 65001 >nul

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

REM Définir les variables globales
set VM_NAME=%~2
set VM_TYPE=Debian_64
set VM_PATH=D:\Cours_3e_annee\SAE\51\VM_test
set VM_RAM=4096

REM Obtenir l'utilisateur et la date de création
set USER=%USERNAME%
for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do (
    set CREATION_DATE=%%c-%%a-%%b
)

REM Actions basées sur le premier argument
if /i "%~1"=="L" (
    echo Liste des machines créées dans VirtualBox :
    echo ----------------------
    VBoxManage list vms
    echo ----------------------

    REM Afficher les métadonnées pour chaque machine
    for /f "tokens=1 delims={" %%i in ('VBoxManage list vms') do (
        set vm_name=%%i
        REM Nettoyer le nom de la VM en supprimant les guillemets et les espaces
        set vm_name=!vm_name:"=!
        set vm_name=!vm_name: =!

        REM Chemin du fichier de métadonnées
        set vm_metadata_file=%VM_PATH%\!vm_name!\metadata.txt
        
        REM Nettoyer les espaces dans le chemin du fichier de métadonnées
        set vm_metadata_file=!vm_metadata_file: =!

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

if /i "%~1"=="N" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument N.
        exit /b 1
    )
    REM Vérifier si une VM avec le même nom existe déjà
    VBoxManage showvminfo %VM_NAME% >nul 2>&1
    if %errorlevel% == 0 (
        echo La VM %VM_NAME% existe déjà. Suppression en cours...
        VBoxManage unregistervm %VM_NAME% --delete
        echo La VM %VM_NAME% a été supprimée !
    ) else (
        echo Aucune VM nommée %VM_NAME%.
    )

    REM Créer la VM
    VBoxManage createvm --name %VM_NAME% --ostype %VM_TYPE% --basefolder %VM_PATH% --register
    echo La VM %VM_NAME% a été créée dans %VM_PATH% !

    REM Configurer la RAM
    VBoxManage modifyvm %VM_NAME% --memory %VM_RAM%
    echo La RAM de la VM %VM_NAME% a été configurée !

    REM Créer le disque dur virtuel dans un chemin spécifique
    VBoxManage createmedium disk --filename %VM_PATH%\%VM_NAME%\%VM_NAME%.vdi --size 65536 --format VDI
    echo Le disque dur pour la VM %VM_NAME% a été créé !

    REM Ajouter un contrôleur SATA à la VM
    VBoxManage storagectl %VM_NAME% --name "SATA Controller" --add sata --controller IntelAhci

    REM Attacher le disque dur virtuel au port 0 du contrôleur SATA
    VBoxManage storageattach %VM_NAME% --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium %VM_PATH%\%VM_NAME%\%VM_NAME%.vdi
    echo Le disque dur pour la VM %VM_NAME% a été attaché !

    REM Configurer le réseau en NAT
    VBoxManage modifyvm %VM_NAME% --nic1 nat
    echo Le réseau de la VM %VM_NAME% a été configuré !

    REM Configurer pour booter sur le réseau (PXE)
    VBoxManage modifyvm %VM_NAME% --boot1 net
    echo La VM %VM_NAME% est configurée pour démarrer sur le réseau !

    REM Créer le fichier de métadonnées
    mkdir "%VM_PATH%\%VM_NAME%"
    echo Date de création : %CREATION_DATE% > "%VM_PATH%\%VM_NAME%\metadata.txt"
    echo Créée par : %USER% >> "%VM_PATH%\%VM_NAME%\metadata.txt"
    echo Les métadonnées pour la VM %VM_NAME% ont été enregistrées !
)

if /i "%~1"=="S" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument S.
        exit /b 1
    )
    echo Suppression de la machine %VM_NAME%...
    VBoxManage unregistervm %VM_NAME% --delete
    echo La machine %VM_NAME% a été supprimée !
)

if /i "%~1"=="D" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument D.
        exit /b 1
    )
    echo Démarrage de la machine %VM_NAME%...
    VBoxManage startvm %VM_NAME% --type headless
)

if /i "%~1"=="A" (
    if "%VM_NAME%"=="" (
        echo Vous devez spécifier un nom de VM avec l'argument A.
        exit /b 1
    )
    echo Arrêt de la machine %VM_NAME%...
    VBoxManage controlvm %VM_NAME% acpipowerbutton
)

pause
