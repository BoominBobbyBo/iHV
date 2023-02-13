<# CleanUp after NormalizeVAM4VR

  - Remove idio and idiot folder/files that have been processed by NormalizeVAM4VR

  - "idiot" paths are those that are outside the structure of VAM
  - "idio" paths are those that are inside the high-level structure of VAM but often store duplicate content

  - DANGER!!!

  - Must first run NormalizeVAM4VR.ps1 (or ALL links between idio/idiot resources and VAM will be broken)
  - Backup, you fools BACKUP!
  
  - REQUIRES
  - Content must have been extracted from VARs and VAR paths removed using Normalize4VR.ps1
  - Keep the below arrays in synch with the arrays in the Normalize4VR.ps1 script

#>

If($blnLaunched -ne $true){ 
    Read-Host -Prompt 'You must run CleanUp.ps1 on extracted content first (hit ENTER to continue)' 
}


  ###################### SCRIPT TUNING ###################### 

$blnCleanIdiotContent  = $true  # Master switch: purge empty/duplicate content
$blnCleanIdioContent   = $true  # Master switch: purge empty/duplicate content

$NormalizeClothing     = $true  # Set to true if you want to purge empty/duplicate folders inside this major directory: review the exception list below
$NormalizeHair         = $true  # Set to true if you want to purge empty/duplicate folders inside this major directory: review the exception list below
$NormalizeSkin         = $false # Not implemented
$NormalizeTextures     = $false # Not implemented

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") } 

$ScriptName = "iHV_NormalizeVAM4VR_CleanUp"
$ScriptVersion = "1.0.5"
$LogPath = ".\_1a " + $ScriptName + ".log"
$LogEntry = Get-Date -Format "yyyy/MM/dd HH:mm" 


  ###################### SCRIPT TUNING ###################### 


Write-Host
Write-host ******************** START: iHV CLEAN UP ************************
Write-Host

If($blnLaunched -ne $true){ Read-Host -Prompt "You must first run NormalizeVAM4VR.ps1 (hit ENTER to continue)" }

# CONTENT FOLDERS - directories with content files with pathing to be updated (files will not be moved)
$InstructionsDirs = @(
    "Custom/Clothing/Female/"
    "Custom/Clothing/Male/"
    "Custom/Hair/Female/"
    "Custom/Hair/Male/"
    #"Custom/SubScene/"
    #"Saves/scene/"      # NOT IMPLEMENTED
    #"Saves/Person/"
)

# RESOURCES FOLDERS - directories with duplicates (files will be moved/consolidated)
$ResourcePaths = @(
    "Custom/Assets/"
    "Custom/Assets/Audio/"
    "Custom/Atom/Person/Morphs/female/"
    "Custom/Atom/Person/Morphs/female_genitalia/"
    "Custom/Atom/Person/Morphs/male/"
    "Custom/Atom/Person/Morphs/male_genitalia/"
    # "Custom/Atom/Person/Plugins/" NOT IMPLEMENTED
    "Custom/Sounds/"
    # "Custom/Sounds/WEBM/" NOT IMPLEMENTED
  )
If($blnCleanTextures -eq $true){$ResourcePaths += "Custom/Atom/Person/Textures/"} # test test test

# PRESET FOLDERS - directories with unorganized preset files that clutter the preset root folder
$PresetPaths = @(
  "Custom/Atom/Person/Appearance/"
  "Custom/Atom/Person/Clothing/"
  "Custom/Atom/Person/Hair/"
  # "Custom/Atom/Person/Pose/" # NOT IMPLEMENTED
  # "Custom/Atom/Person/Skin/" # NOT IMPLEMENTED
  )

# IDIOT FOLDERS - case sensitive; this arry will be updated further down to include any unlisted folders found ino the root of VAM
# add as you seem them appear but remove after no longer needed to speed up processing
$IdiotPaths = @(
        @{IdiotPath="Addonpackages/_texture/";TargetPath="Custom/Atom/Idiots/"} # BoyaVAM
        @{IdiotPath="Addonpackages/Decals & Textures/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Addonpackages/WadVRX Mega Scene Pack Dec'19/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Addonpackages/UJVAM/";TargetPath="Custom/Atom/Idiots/"}
        @{IdiotPath="Audio for Scenes/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/Audio/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/comm/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/clinic/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/drone/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/ride/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/Sound/";TargetPath="Custom/Sounds/iHV_Normalized/"}
        @{IdiotPath="Custom/Clothing/alpha/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="Custom/Clothing/Neutral/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="custom/Clothing/Other Textures/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="custom/Clothing/repleace/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="custom/Clothing/Road/";TargetPath="Custom/Atom/Idiots/"} # 
        @{IdiotPath="Custom/Clothing/Texture-Pack/";TargetPath="Custom/Atom/Idiots/"} # ivansx
        @{IdiotPath="Saves/CUSTOM IMPORT - GF/";TargetPath="Custom/Atom/Idiots/"} # texture files
        @{IdiotPath="Saves/Images/";TargetPath="Custom/Atom/Idiots/"} # texture files
        @{IdiotPath="Saves/Room textures/";TargetPath="Custom/Atom/Idiots/"} # texture files
        @{IdiotPath="Saves/Textures/";TargetPath="Custom/Atom/Idiots/"} # texture files
        @{IdiotPath="Saves/Textures-Mix/";TargetPath="Custom/Atom/Idiots/"} # texture files
        @{IdiotPath="Saves/V0.1_YUKA/";TargetPath="Custom/Atom/Idiots/"} # texture files
        @{IdiotPath="Saves/资源打包(Thorn)/";TargetPath="Custom/Atom/Idiots/"} # texture files
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
# NATIVE SAVE FOLDERS - part of the base build - folders found within the parent that are not in this array will be treated as Idiot folders
$NativeSaveFolders = @(
    "Saves/AnimationPattern" # DillDoe
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
# NATIVE CUSTOM FOLDERS - part of the base build - folders found within the parent that are not in this array will be treated as Idiot folders
$NativeCustomFolders = @(
    "Custom/Assets"
    "Custom/Atom"  
    "Custom/Clothing"
    "E-Motion" # not native but popular
    "Custom/Hair"
    "Custom/PluginData"  
    "Custom/PluginPresets"
    "Custom/Scripts" 
    "Custom/Sounds"
    "Custom/SubScene"
  )
# PERSONAL EXCEPTIONS - not part of the base build but ignore these anyway (must be lower case; format: keywords, no file extenstions)
$Exceptions = @(
    "assetName"                       # Required: assetName is a JSON node that we don't want to update by mistake when updating asset paths
    "Builtin"                         # Required: native folder
    "Custom/Scripts"                  # Required: native; some scripts have embedded paths that would be disrupted by iHV
    "Custom/SubScene"
    "displayName"                     # Required: these often have pseudo paths should must be ignored
    "favorites"                       # Required: native VAM folder
    "a iHV_"                          # Required: iHV scripts & log files
    "receiverAtom"                    # Required: json node that we don't want to update by mistake when adjusting paths
    "stringChooserValue"              # Required: unity asset path    
    "BobB_"                           # Required: my author name - change to yours
    "MyFav"                           # Required: folders/files prefix that identifies content exempt from normalizing by this script, so to establish a personal folder organization scheme
  # "Custom/Assets/Audio/RT_LipSync"  # Optional: for lip sync plugin RT_LipSync
    "RT_LipSync"                      # Optional: by this plugin; creates protected space within Custom/audio/rt_lipsync for a curated audio library specific for this script
    "TexturePack"                     # optional: ChoiwaruOyaji (author) files that do not use unique file names
    "VamTextures"                     # optional: Male gen textures from Jackaroo
)
$Exceptions += "iHV_Normalized"       # don't touch anything in normalized folders

If($NormalizeClothing -eq $false){ 
    $Exceptions += "Custom/Clothing/Female"
}
else{
    $Exceptions += "A1X"                             # optional: clothing author who does not use unique file names 
    $Exceptions += "2021_clothes_pack_by_Daz"        # optional: major clothing package without unique file names
    $Exceptions += "AnythingFashionVR"               # optional: major clothing author who does not use unique file names
    $Exceptions += "cotyounoyume"                    # optional: plugin from cotyounoyume *
    $Exceptions += "CosmicFTW"                       # optional: major clothing author who does not use unique file names
    $Exceptions += "CuteSvetlana"                    # optional: major clothing author who does not use unique file names
    $Exceptions += "Dixi"                            # optional: clothing author who does not use unique file names *
    $Exceptions += "DillDoe"                         # optional: clothing author who does not use unique file names
    $Exceptions += "Eros"                            # optional: clothing author who does not use unique file name
    $Exceptions += "ExpressionBlushingAndTears"      # optional: plugin from cotyounoyume
    $Exceptions += "GeeMan55"                        # optional: clothing author who does not use unique file names
    $Exceptions += "huaQ"                            # optional: clothing author who does not use unique file names
    $Exceptions += "HUNTING-SUCCUBUS"                # optional: clothing author who does not use unique file names
    $Exceptions += "Jackaroo"                        # optional: clothing author who does not use unique file names
    $Exceptions += "JaxZoa"                          # optional: major clothing author who does not use unique file names
    $Exceptions += "JoyBoy"                          # optional: clothing author who does not use unique file names
    $Exceptions += "Molmark"                         # optional: major clothing author who does not use unique file names
    $Exceptions += "MonsterShinka"                   # optional: clothing author who does not use unique file names    
    $Exceptions += "Mr_CadillacV8"                   # optional: major clothing author who does not use unique file names
    $Exceptions += "Oeshii"                          # optional: clothing author who does not use unique file names
    $Exceptions += "OptiMist"                        # optional: clothing author who does not use unique file names *
    $Exceptions += "paledriver"                      # optional: clothing author who does not use unique file names 
    $Exceptions += "PL_Artists"                      # optional: clothing author who does not use unique file names *
    $Exceptions += "Putz"                            # optional: clothing author who does not use unique file names
    $Exceptions += "Qing"                            # optional: clothing author who does not use unique file names
    $Exceptions += "Ramsess"                         # optional: clothing author who does not use unique file names
    $Exceptions += "sharr"                           # optional: clothing author who does not use unique file names *
    $Exceptions += "siwen666"                        # optional: clothing author who does not use unique file names
    $Exceptions += "Skipppy"                         # optional: clothing author who does not use unique file names
    $Exceptions += "Summer Sleepwear"
    $Exceptions += "SupaRioAmateur"                  # optional: major clothing author who does not use unique file names
    $Exceptions += "tolborg"                         # optional: clothing author who does not use unique file names
    $Exceptions += "VAM_GS"                          # optional: clothing author who uses idio structures
    $Exceptions += "Vmax"                            # optional: clothing author who uses idio structures
    $Exceptions += "VL_13"                           # optional: major clothing author who uses idio structures
    $Exceptions += "VirtaArtieMitchel"               # optional: clothing author who uses idio structures *    
    $Exceptions += "VRDollz"                         # optional: major clothing author who uses idio structures
    $Exceptions += "XRWizard"                        # optional: clothing author who uses idio structures  
    $Exceptions += "VaMChan"                         # optional: major Hair, scene author who does not use unique file names
    $Exceptions += "vvvevevvv"                       # optional: major clothing author who uses idio structures    
}
If($NormalizeHair -eq $false){ 
    $Exceptions += "Custom/Hair/Female"
}
else{
    $Exceptions += "A1X"                             # optional: Hair author who does not use unique file names *
    $Exceptions += "CMA"                             # optional: Hair author who does not use unique file names *
    $Exceptions += "BooGoo"                          # optional: Hair author who does not use unique file names *
    $Exceptions += "Dnaddr"                          # optional: Hair author who does not use unique file names *
    $Exceptions += "Jackaroo"                        # optional: clothing author who does not use unique file names
    $Exceptions += "Oronan"                          # optional: clothing author who does not use unique file names
    $Exceptions += "niko"                            # optional: Hair author who does not use unique file names *
    $Exceptions += "Niko3DX"                         # optional: Hair author who does not use unique file names *
    $Exceptions += "NoStage"                         # optional: major Hair author who does not use unique file names
    $Exceptions += "PodFlower"                       # optional: clothing author who does not use unique file names
    $Exceptions += "Qing"                            # optional: clothing author who does not use unique file names
    $Exceptions += "Ramsess"                         # optional: major Hair author who does not use unique file names
    $Exceptions += "Roac"                            # optional: major Hair author who does not use unique file names
    $Exceptions += "Skipppy"                         # optional: clothing author who does not use unique file names
    $Exceptions += "sharr"                           # optional: clothing author who does not use unique file names *
    $Exceptions += "Sirap"                           # optional: clothing author who does not use unique file names
    $Exceptions += "SupaRioAmateur"                  # optional: major clothing author who does not use unique file names
    $Exceptions += "Theuf"                           # optional: clothing author who does not use unique file names
    $Exceptions += "tolborg"                         # optional: clothing author who does not use unique file names
    $Exceptions += "VAM_GS"                          # optional: clothing author who uses idio structures
    $Exceptions += "vecterror"                       # optional: clothing author who does not use unique file names
    $Exceptions += "Vmax"                            # optional: clothing author who uses idio structures
    $Exceptions += "VL_13"                           # optional: major clothing author who uses idio structures
    $Exceptions += "VirtaArtieMitchel"               # optional: clothing author who uses idio structures *    
    $Exceptions += "VRDollz"                         # optional: major clothing author who uses idio structures
    $Exceptions += "XRWizard"                        # optional: clothing author who uses idio structures  
    $Exceptions += "VaMChan"                         # optional: major Hair, scene author who does not use unique file names
}

If($NormalizeSkin -eq $false){ $Exceptions += "Custom/Atom/Person/Skin" }

If($NormalizeTextures -eq $false){ $Exceptions += "Custom/Atom/Person/Textures" }


#
# REMOVE IDIOT FOLDERS

If($blnCleanIdiotContent -eq $true) {

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
      ForEach($RootFolder in $NativeSaveFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }

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

} # If($blnCleanIdiotContent -eq $true) {

#########################################################


#
# REMOVE IDIO FOLDERS

If($blnCleanIdioContent -eq $true){

    $allResourcePaths =@()
    $allResourcePaths += $InstructionsDirs
    $allResourcePaths += $ResourcePaths
    $allResourcePaths += $PresetPaths

    $allResourcePaths | Foreach-Object { 
    
      $ResourceDir = $_
      Write-Host $ScriptName "---Processing: " $ResourceDir

      Get-ChildItem -Path ($vamRoot + $ResourceDir) -Directory -Force -ErrorAction SilentlyContinue | Foreach-Object { # if this faults, directory in the array doesn't exist in the file system
        # Write-Host $ScriptName "   Subfolder: " $_.

        $blnException = $false
        ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*/"+$Exception+"*")) { $blnException = $true } }
        # Write-Host $ScriptName is exception? ... $_.FullName $blnException

        $blnIsRootFolder = $false
        ForEach($RootFolder in $NativeRootFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }
        ForEach($RootFolder in $NativeSavesFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }
        ForEach($RootFolder in $NativeCustomFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }
        # Write-Host $ScriptName "IsRootFldr: .... " $_.FullName $blnIsRootFolder

        If($blnException -eq $true -or $_ -match "Saves/" -or $blnIsRootFolder -eq $true){ $LogEntry + "----IDIO EXCEPTION: " + $_.FullName | Out-File -FilePath $LogPath -Append} 
        ElseIf($blnCleanTextures -eq $false -and $_.FullName-ilike ("*\texture*\*") ) {} # Write-Host $ScriptName Texture fldr .... $_.FullName - exempt }
        Else{

          $_ | Remove-Item -Force -Recurse
          Write-Host "----DELETE IDIO: " $_.FullName
          $LogEntry + "----DELETE IDIO: " + $_.FullName | Out-File -FilePath $LogPath -Append

        }

      } # Get-Childitem 
    
    } # $allResourcePaths | Foreach-Object { 

} # If($blnCleanIdioContent -eq $true){



#
# Purge extra files by type

# Enable if you are not developing / testing; leave as conditionals (like vs match) to ensure hyper accurate matches
Get-ChildItem -Path ($vamRoot + "Addonpackages") -File -Recurse -Force | Where-Object { $_.Name -ilike "meta.json" -or $_.Name -ilike "*.txt" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.obj" -or $_.Name -ilike "*.mtl" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.duf" -or $_.Name -ilike "*.dsf" -or $_.Name -ilike "*.psd" -or $_.Name -ilike "*.obj" -or $_.Name -ilike "*.info" -or $_.Name -ilike "*.meta"} | Remove-Item -Force
Get-ChildItem -Path ($vamRoot + "Custom") -File -Recurse -Force | Where-Object { $_.Name -ilike "*PostMagic*" -OR $_.Name -ilike "*.var" -or $_.Name -ilike "*.zip" -or $_.Name -ilike "*.rar" -or $_.Name -ilike "meta.json" -or $_.Name -ilike "*.txt" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.obj" -or $_.Name -ilike "*.mtl" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.duf" -or $_.Name -ilike "*.dsf" -or $_.Name -ilike "*.psd" -or $_.Name -ilike "*.obj" -or $_.Name -ilike "*.info" -or $_.Name -ilike "*.meta"} | Remove-Item -Force
Get-ChildItem -Path ($vamRoot + "Saves") -File -Recurse -Force | Where-Object { $_.Name -ilike "*.var" -or $_.Name -ilike "*.zip" -or $_.Name -ilike "*.rar" -or $_.Name -ilike "meta.json" -or $_.Name -ilike "*.txt" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.obj" -or $_.Name -ilike "*.mtl" -or $_.Name -ilike "*.dds" -or $_.Name -ilike "*.duf" -or $_.Name -ilike "*.dsf" -or $_.Name -ilike "*.psd" -or $_.Name -ilike "*.obj" -or $_.Name -ilike "*.info" -or $_.Name -ilike "*.meta"} | Remove-Item -Force


# "Poor man's" intrusion detection

$arrBigFiles = @()
Get-ChildItem -Path ($vamRoot) -File -Recurse -Force | Where-Object { ($_.Name -ilike "*.ps1" -And ($_.Name -notlike "*a iHV_*")) -or $_.Name -ilike "*.py" -or $_.Name -ilike "*.pyc" -or $_.Name -ilike "*.pyw" -or $_.Name -ilike "*.pyd" -or $_.Name -ilike "*.exe" -or $_.Name -ilike "*.msi" -or $_.Name -ilike "*.dll" } | ForEach-Object { $arrBigFiles += $_.FullName } 

$arrBigFiles | Where-Object { $_ -inotlike "*Unity*" -and $_ -inotlike "*VaM*.exe" -and $_ -inotlike "*Mono*" -and $_ -inotlike "*VaM_Data*" } | ForEach-Object { 
    Write-host !!!!!
    Write-host !!!!! FOUND: $_ . Warning only. Review and remove as needed.
    $LogEntry + "!!!!! FOUND " + $_ | Out-File -FilePath $LogPath -Append
  } 

  Write-Host
  Write-host ******************** END: $ScriptName ************************
  Write-Host
  If($blnLaunched -ne $true){ Read-Host -Prompt "Press Enter to exit" }