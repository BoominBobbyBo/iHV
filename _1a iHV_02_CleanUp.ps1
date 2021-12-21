<# CleanUp after iHV
    - Remove idio and idiot folder/filess

    - "idiot" paths are those that are outside the structure of VAM
    - "idio" paths are those that are inside the high-level structure of VAM but often store duplicate content

    - DANGER!!!
    - Must first run NormalizeVAM4VR.ps1 (or ALL links between resources and VAM will be broken)
    - Backup, you fools BACKUP!
    
    - REQUIRES
    - Content must have been extracted from VARs and VAR paths removed, using Normalize4VR.ps1

#>
Write-Host
Write-host ******************** START: iHV CLEAN UP  ************************
Write-Host

Read-Host -Prompt "You must first run NormalizeVAM4VR.ps1 (hit ENTER to continue)"

# CONTENT FOLDERS -  directories with content files with pathing to be updated (files will not be moved)
$ContentFilePaths = @(
    "Custom/Clothing/Female/"
    "Custom/Clothing/Male/"
    "Custom/Hair/Female/"
    "Custom/Hair/Male/"
    "Custom/SubScene/"
    #"Saves/scene/" # DO NOT CULL CONTENT IN THE SAVES NOR PERSON FOLDERS
    #"Saves/Person/"
    )

# RESOURCES FOLDERS - directories with duplicates (files will be moved/consolidated)
$ResourcePaths = @(
    "Custom/Assets/"
    "Custom/Assets/Audio/"
    "Custom/Atom/Person/Textures/" # test test test
    "Custom/Atom/Person/Morphs/female/"
    "Custom/Atom/Person/Morphs/female_genitalia/"
    "Custom/Atom/Person/Morphs/male/"
    "Custom/Atom/Person/Morphs/male_genitalia/"
    )

# PRESET FOLDERS - directories with unorganized preset files that clutter the preset root folder
$PresetPaths = @(
    "Custom/Atom/Person/Appearance/"
    "Custom/Atom/Person/Clothing/"
    "Custom/Atom/Person/Hair/"
    # "Custom/Atom/Person/Pose/" # skipping: not worth the risk of disruption for such a small content size
    "Custom/Atom/Person/Skin/"
    )

#  IDIOT FOLDERS - case sensitive; this arry will be updated further down to include any unlisted folders found ino the root of VAM
#  add as you seem them appear but remove after no longer needed to speed up processing
$IdiotPaths = @(
        @{IdiotPath="Addonpackages/_texture/";TargetPath="Custom/Atom/Idiots/"} # BoyaVAM
        @{IdiotPath="Addonpackages/Decals & Textures/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Addonpackages/WadVRX Mega Scene Pack Dec'19/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Custom/Audio/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/ClubV/";TargetPath="Custom/Atom/Idiots/"} # ClubV
        @{IdiotPath="Custom/Clothing/alpha/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="Custom/Clothing/Neutral/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="custom/Clothing/Other Textures/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="custom/Clothing/repleace/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="custom/Clothing/Road/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="Custom/Clothing/Texture-Pack/";TargetPath="Custom/Atom/Idiots/"} # ivansx
        @{IdiotPath="Custom/comm/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/Decals/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="Custom/Fabrics/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Custom/Image/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Custom/Images/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Custom/Materials/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Custom/Sound/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/texture/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Custom/textures/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Custom/TX/";TargetPath="Custom/Atom/Idiots/"} #UVM
        @{IdiotPath="Saves/TextureG/";TargetPath="Custom/Atom/Idiots/"} #UJVAM
        @{IdiotPath="Saves/Textures-Mix/";TargetPath="Custom/Atom/Idiots/"} #
        @{IdiotPath="Custom/Audio/";TargetPath="Custom/Sounds/iHV_Normalized/"} # Should only have entries that don't point to the default idiots path
        @{IdiotPath="Custom/Sound/";TargetPath="Custom/Sounds/iHV_Normalized/"} # nested content not explicitly declared will go to the default idiots path
 )
   
# NATIVE VAM ROOT FOLDERS - part of the base build
$NativeRootFolders = @(
    "AddonPackages"
    "AddonPackagesUserPrefs"  # appears as needed
    "Assets"
    "BrowserProfile"
    "Cache"  # appears as needed
    "Custom"
    "GPUCache" # appears as needed
    "Keys"
    "IPA" # not native but leave it be for DirectorNero
    "logs"
    "Mono"
    "Plugins" # not native but leave it be for DirectorNero
    "Saves"
    "VaM_Data"
    )
# NATIVE SAVE FOLDERS - part of the base build: ignore these
$NativeSavesFolders = @(
    "Saves/Animations" # native
    "Saves/AudioMate" # Dub plugin
    "Saves/coliders" # native
    "Saves/directorNeo" # DN plugin
    "Saves/ExpToolPresets" # Coolsilver presets
    "Saves/Person" # native
    "Saves/PluginData" # native
    "Saves/Video" # VideoController 2 by @VamSander. 
    "Saves/scene" # native
    )
# NATIVE CUSTOM FOLDERS - part of the base build
$NativeCustomFolders = @(
    "Custom/Assets"
    "Custom/Assets/Audio"  
    "Custom/Atom"  
    "Custom/Clothing"
    "Custom/Hair"
    "Custom/PluginData"  
    "Custom/PluginPresets"
    "Custom/Scripts" 
    "Custom/Sounds"
    "Custom/SubScene"
    )
# PERSONAL EXCEPTIONS - not part of the base build but ignore these anyway (must be lower case; format: keywords, no file extenstions)
$Exceptions = @(
    "aBackup" # optional: have any content you don't want to normalize or change?
    "assetName" # Required: assetName is a JSON node that we don't want to update by mistake when updating asset paths
    "BobB" # optional: my author name - change to yours
    "2021_clothes_pack_by_Daz" # optional: clothing author who does not use unique file names
    "Custom/Assets/Audio/RT_LipSync" # required for lip sync plugin RT_LipSync
    "Custom/Scripts" # Required: scripts have embedded paths that would be disrupted by iHV
    "E-Motion" # Required for this popular plugin
    "Electric Dreams" # optional: favorite clothing author
    "Energy85" # optional: clothing author who does not use unique file names
    "favorites" # Required: conventional VAM folder
    "iHV_Normalized" # Required: processed IHV files
    "a iHV_" # iHV scripts & log files
    "Jackaroo" # optional: clothing author who does not use unique file names
    "myFav" # Required: folders/files prefix that identifies content exempt from normalizing by this script, so to establish an folder organization scheme
    "NoStage" # optional: hair author
    "PostMagic" # optional: Let it ride and fail. I delete this since it's not VR friendly
    "Putz" # optional: clothing author who does not use unique file names
    "RT_LipSync" # Required by this plugin; creates protected space within Custom/audio/rt_lipsync for a curated audio library specific for this script
    "receiverAtom" # Required: json node that we don't want to update by mistake when adjusting paths
    "stringChooserValue" # Required: unity asset path
    "VamChan" # optional: favorite hair author
    "VamTextures" # optional: Male gen textures from Jackaroo

    # "./" # Relative path for scenes; if not excepted, this gets turned into a sound path regardless of the actual content
    )

    ###################### SCRIPT TUNING ###################### 

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") } 

$ScriptName = "iHV_CleanUp"
$ScriptVersion = "0.5"
$LogPath = ".\_1a " + $ScriptName + ".log"
$LogEntry = Get-Date -Format "yyyy/MM/dd HH:mm" 

    ###################### SCRIPT TUNING ###################### 

#
# REMOVE IDIOT FOLDERS


# Get any idiot folders found in the VAM >>> root <<< directory & add to the Idiot array
Get-ChildItem -Path ($vamRoot) -Directory -Force | Foreach-Object { 

    $blnException = $false
    ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*" + $Exception +"*")) { $blnException = $true } }

    $blnIsRootFolder = $false
    ForEach($RootFolder in $NativeRootFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }

    If($blnException -ne $true -and $blnIsRootFolder -ne $true){
        write-host "++++Idiot folder: " $_.Name.Replace("\","/") " :: " $_.FullName
        $LogEntry + "----Idiot folder: " + $_ + " FileN: " + $_.Name | Out-File -FilePath $LogPath -Append
        $tmp = @{IdiotPath=($_.Name); TargetPath="Custom/Atom/Idiots/"}
        $IdiotPaths += $tmp  
    }

} # Get folders

# Get any idiot folders found in the VAM >>> Save <<<s directory & add to the Idiot array
Get-ChildItem -Path ($vamRoot + "Saves") -Directory -Force | Foreach-Object { 

    $blnException = $false
    ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*/"+$Exception+"*")) { $blnException = $true } }

    $blnIsRootFolder = $false
    ForEach($RootFolder in $NativeSavesFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }

    If($blnException -ne $true -and $blnIsRootFolder -ne $true){
        write-host "++++Idiot folder: Saves/" $_.Name.Replace("\","/") " :: " $_.FullName
        $LogEntry + "----Idiot folder: Saves\" + $_ + " FileN: " + $_.Name | Out-File -FilePath $LogPath -Append
        $tmp = @{IdiotPath=("Saves/" + $_.Name); TargetPath="Custom/Atom/Idiots/"}
        $IdiotPaths += $tmp  
    }

} # Get folders

# Get any idiot folders found in the VAM >>> Custom <<< directory & add to the Idiot array
Get-ChildItem -Path ($vamRoot + "Custom") -Directory -Force | Foreach-Object { 

    $blnException = $false
    ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*/"+$Exception+"*")) { $blnException = $true } }

    $blnIsRootFolder = $false
    ForEach($RootFolder in $NativeCustomFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }

    If($blnException -ne $true -and $blnIsRootFolder -ne $true){
        write-host "++++Idiot folder: Custom/" $_.Name.Replace("\","/") " :: " $_.FullName
        $LogEntry + "----Idiot folder: Custom\" + $_ + " FileN: " + $_.Name | Out-File -FilePath $LogPath -Append
        $tmp = @{IdiotPath=("Custom/" + $_.Name); TargetPath="Custom/Atom/Idiots/"}
        $IdiotPaths += $tmp  
    }

} # Get folders

#Write-host "IDIOT PATHS------------------------------------------------"
#$IdiotPaths | ForEach-Object { Write-Host IP: $_.IdiotPath TP: $_.TargetPath }

$IdiotPaths | ForEach-Object { Remove-Item -path ($vamRoot + $_.IdiotPath.Replace("/","\")) -Force -Recurse -ErrorAction SilentlyContinue }

#########################################################


#
# REMOVE IDIO FOLDERS


$allResourcePaths =@()
$allResourcePaths += $ContentFilePaths
$allResourcePaths += $ResourcePaths
$allResourcePaths += $PresetPaths

$allResourcePaths | Foreach-Object { 
        
    $ResourceDir = $_
    #Write-Host $ScriptName "---Is Idio? " $ResourceDir

    Get-ChildItem -Path ($vamRoot + $ResourceDir) -Directory -Force -ErrorAction SilentlyContinue | Foreach-Object { # if this faults, directory in the array doesn't exist in the file system

        $blnException = $false
        ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*/"+$Exception+"*")) { $blnException = $true } }
        #Write-Host is exception? ... $_.FullName.Replace("\","/") $blnException

        $blnIsRootFolder = $false
        ForEach($RootFolder in $NativeRootFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }
        ForEach($RootFolder in $NativeSavesFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }
        ForEach($RootFolder in $NativeCustomFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }

        If($blnException -eq $false -and $blnIsRootFolder -eq $false) {

            $_ | Remove-Item -Force -Recurse
            Write-Host "----DELETE IDIO: " $_.FullName
            $LogEntry + "----DELETE IDIO: " + $_.FullName | Out-File -FilePath $LogPath -Append

        }
        Else {
        write-host Exception for Idio: ...........  ($_.FullName)
        $LogEntry + "----IDIO EXCEPTION: " + $_.FullName | Out-File -FilePath $LogPath -Append}

    }
        
} # $allResourcePaths | Foreach-Object { 



#
# Purge extra files

# Enable if you are not developing / testing
Get-ChildItem -Path ($vamRoot + "Custom")  -File -Recurse -Force | Where-Object { $_.Name -ilike "*.var" -or $_.Name -ilike "*.zip" -or $_.Name -ilike "*.rar" -or $_.Name -ilike "meta.json" -or $_.Name -ilike "*.txt" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.obj" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.duf"  -or $_.Name -ilike "*.dsf"  -or $_.Name -ilike "*.psd"   -or $_.Name -ilike "*.obj"} | Remove-Item -Force
Get-ChildItem -Path ($vamRoot + "Saves")  -File -Recurse -Force | Where-Object { $_.Name -ilike "*.var" -or $_.Name -ilike "*.zip" -or $_.Name -ilike "*.rar" -or $_.Name -ilike "meta.json" -or $_.Name -ilike "*.txt" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.obj" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.duf"  -or $_.Name -ilike "*.dsf"  -or $_.Name -ilike "*.psd"  -or $_.Name -ilike "*.obj"} | Remove-Item -Force


# "Poor man's" intrusion detection

$arrBigFiles = @()
Get-ChildItem -Path ($vamRoot) -File -Recurse -Force | Where-Object { ($_.Name -ilike "*.ps1" -And ($_.Name -notlike "*a iHV_*")) -or $_.Name -ilike "*.py" -or $_.Name -ilike "*.pyc" -or $_.Name -ilike "*.pyw" -or $_.Name -ilike "*.pyd" -or $_.Name -ilike "*.exe" -or $_.Name -ilike "*.msi" -or $_.Name -ilike "*.dll" } |  ForEach-Object { $arrBigFiles += $_.FullName } 

$arrBigFiles | Where-Object { $_ -inotlike "*Unity*" -and $_ -inotlike "*VaM*.exe" -and $_ -inotlike "*Mono*" -and $_ -inotlike "*VaM_Data*" } | ForEach-Object { 
       Write-host !!!!!
       Write-host !!!!! FOUND: $_ . Warning only. Review and remove as needed.
       $LogEntry + "!!!!! FOUND " + $_ | Out-File -FilePath $LogPath -Append
    } 

    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host
    Read-Host -Prompt "Press Enter to exit"