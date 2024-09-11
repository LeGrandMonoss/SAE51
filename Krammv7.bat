@echo off

REM Définition des variables 
set "RAMSize=4096"
set "DiskSize=64"

set "VBoxManagePath=C:\Program Files\Oracle\VirtualBox"
set "PATH=%PATH%;%VBoxManagePath%"

REM Vérification du nombre d'arguments
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

REM Action basée sur le premier argument
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
) else if /i "%Action%"=="N" (
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
) else if /i "%Action%"=="S" (
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
) else if /i "%Action%"=="D" (
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
) else if /i "%Action%"=="A" (
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
) else (
    echo Action invalide. Veuillez spécifier une action valide.
    exit /b 1
)

exit /b 0
