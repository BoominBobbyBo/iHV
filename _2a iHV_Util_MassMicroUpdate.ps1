<#

I Hate VARS - Mass Micro Update

        Make a small update to all instruction files

#>

write-host
write-host ******************** START: MASS MICRO UPDATE  ************************
write-host


Function Update-InstructionFile {

    Param (

        [String]
        $File_FullName
    )

        If($blnProcessRootFolders -eq $false -and $File_FullName -imatch "iHV_Normalized"){Return}

        # write-host $ScriptName--UPDATE: $File_FullName

        # Instruction FILES - Get the raw file content to update ----------------------------------------->
        $Instructions = [System.IO.File]::ReadAllLines($File_FullName) # .NET function (requires .NET) (Get-Content -raw $File_FullName)
        $blnWasTheFileChanged = $false

        #-----------------------------------------------------------------------------> 

        # Global Change: SELF
        If($Instructions -match "SELF:/"){
            $blnWasTheFileChanged = $true
            $Instructions = $Instructions -Replace("SELF:/","")
        }

        If($blnWasTheFileChanged = $true){
            
            # write-host $ScriptName---UPDATE: $File_FullName
       
            #fix corruption that occurs when executing more than once on a file
            $Instructions = $Instructions -iReplace("ustom/","Custom/") 
            $Instructions = $Instructions -iReplace("CCustom/","Custom/")
            $Instructions = $Instructions -Replace("//", "/")
            $LogEntry + "---writing Updates.  FILE:" + $File_FullName + " CL:" + $Instructions.Length | Out-File -FilePath $LogPath -Append
            
            If($Instructions -ilike "*/Custom/*"){$LogEntry + " ERROR: VAR prefix. Search for /Custom" + ", FILE:" + $File_FullName | Out-File -FilePath $LogPath -Append}

            # write-host --Writing $File_FullName :: $Instructions.Length
            $Error.Clear()
            [System.IO.File]::WriteAllLines($File_FullName, $Instructions)
            If($Error.Count -ne 0){$LogEntry + " ERROR: " + $Error[0] + ", FILE:" + $File_FullName | Out-File -FilePath $LogPath -Append}
        
        }

} # End Update-InstructionFile Function

    ###################### SCRIPT TUNING ###################### 

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") } # don't use .\ for the root path for this script: it's kills path parsing above

$ScriptName            = "iHV_Normalize4VR"
$ScriptVersion         = "1.0.1"
$LogPath               = ($PSScriptRoot + "\_1a " + $ScriptName + ".log")
$LogEntry              = Get-Date -Format "yyyy/MM/dd HH:mm" 

    ###################### SCRIPT TUNING ###################### 

Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { $_.Name -match "iHV_Normalized" } | Remove-Item # Remove any previous faults. Do so, or more faults will occur.

# CONTENT FOLDERS -  directories with content files with pathing that needs to be updated
$InstructionsDirs = @(
    "Custom/Clothing/Female/"
    "Custom/Clothing/Male/"
    "Custom/Hair/Female/"
    "Custom/Hair/Male/"
    "Custom/SubScene/"
)
$InstructionsDirs += "Saves/scene/"
$InstructionsDirs += "Saves/Person/"

# PRESET FOLDERS - directories with preset files
$PresetDirs = @(
    "Custom/Atom/Person/Appearance/"
    "Custom/Atom/Person/Clothing/"
    "Custom/Atom/Person/Hair/"
    "Custom/Atom/Person/General/"
    "Custom/Atom/Person/GlutePhysics/"
    #"Custom/Atom/Person/Pose/" # skipping: json challenges; not worth the disruption and risk for such a small content size
    "Custom/Atom/Person/Skin/"
)

# RESOURCES FOLDERS - directories with duplicates (files will be moved/consolidated)
$ResourceDirs = @(
    "Custom/Assets/"
    "Custom/Assets/Audio/"
    "Custom/Atom/Person/Morphs/female/"
    "Custom/Atom/Person/Morphs/female_genitalia/"
    "Custom/Atom/Person/Morphs/male/"
    "Custom/Atom/Person/Morphs/male_genitalia/"
    "Custom/Atom/Person/Plugins/"
    "Custom/Sounds/"
    "Custom/Sounds/WEBM/"
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
# NATIVE SAVE FOLDERS - part of the base build
$NativeSaveFsolders = @(
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
    "Custom/Atom"  
    "Custom/Clothing"
    "Custom/Hair"
    "Custom/PluginData"  
    "Custom/PluginPresets"
    "Custom/Scripts" 
    "Custom/Sounds"
    "Custom/SubScene"
)
# PERSONAL EXCEPTIONS - not part of the base build but ignore these anyway (format: keywords, no file extenstions)
$Exceptions = @(
    "assetName" # Required: assetName is a JSON node that we don't want to update by mistake when updating asset paths
    "BobB_" # optional: my author name - change to yours
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
    "myFav" # Required: folders/files prefix that identifies content exempt from normalizing by this script, so to establish a personal folder organization scheme
    "NoStage" # optional: Haire author who does not use unique file names
    "Putz" # optional: clothing author who does not use unique file names
    "RT_LipSync" # Required by this plugin; creates protected space within Custom/audio/rt_lipsync for a curated audio library specific for this script
    "receiverAtom" # Required: json node that we don't want to update by mistake when adjusting paths
    "stringChooserValue" # Required: unity asset path
    "VamTextures" # optional: Male gen textures from Jackaroo
    "VaMChan" # optional: Hair, scene author who does not use unique file names
    "VRDollz" # optional: clothing author who does not use unique file names

    # "./" # Relative path for scenes; if not excepted, this gets turned into a sound path regardless of the actual content
)
If($blnNormalizeTextures = $false){ $Exceptions += "Custom/Atom/Person/Textures"}


<#
 
 UPDATE CONTENT FILES

 Change resource pointers to reflect the new, normalized locations
 .vaj files point to texture files
 .vam files don't seem to hold any paths

#>

$PresetDirs | Foreach-Object { 

    $PrDir = $vamRoot + $_.Replace("/","\")
    Write-Host $ScriptName--UPDATE PRESET DIRS:: $PrDir

    Get-ChildItem -Path $PrDir -File -include *.json, *.vap, *.vaj -Recurse -Force -ErrorAction SilentlyContinue | Foreach-Object { # if this faults, directory in the array doesn't exist in the file system
                    Update-InstructionFile $_.FullName
                    [GC]::Collect()
    }
        
} # $InstructionsDirs | Foreach-Object { 

$InstructionsDirs | Foreach-Object { 

    $InstructionsDir = $vamRoot + $_.Replace("/","\")
    Write-Host $ScriptName--UPDATE CONTENT DIR:: $InstructionsDir

    Get-ChildItem -Path $InstructionsDir -File -include *.json, *.vap, *.vaj -Recurse -Force -ErrorAction SilentlyContinue | Foreach-Object { # if this faults, directory in the array doesn't exist in the file system
                    Update-InstructionFile $_.FullName
                    [GC]::Collect()
    }
        
} # $InstructionsDirs | Foreach-Object { 


    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host


    If($blnLaunched -ne $true){ Read-Host -Prompt "Press Enter to exit" }

<#

bugs:




#>