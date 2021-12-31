<#

I Hate VARS - Normalize Content for VR

  Remove idiosynchracies that 
  create duplicates, slow VAM down, make it harder to find things, and reduce VAM's overall stability

  Sets behavior preferences (e.g., Worldscale, default plugins, autoexpressions, etc.) 


WARNING:
 - Directories or files that you do not wish to change must be added to the >>> $Exceptions <<< array 
 - Change >>> $blnNormalizeTextures <<< to true to normalize/consolidate textures. Texture normalization is optional; while beneficial in some ways it will impact game experience
 - Backup you fools, backup!

Functions:
1. Normalize Directories
 - Normalizes: morphs, subscenes, hair, clothing. Optional: textures
 - Doesn't delete any content (the optional "clean up" script does that)
 - Resources are consolidated into a "iHV_Normalized" folder
 - You can use the $Exceptions array to exempt any of your favorite content

2. Update Files
 - Removes VAR paths from content files
 - Updates content files to use the normalized VAM folders
 - Deploys personal preferences for VR: lighting, plugins, person behaviors
 - You can use the $Exceptions array to exempt any of your in place content

Glossary:
 - idio paths: subfolders where duplicate and unused content hide. E.g. \Custom\Assets\Audio\!CustomFilesThatIDuplicatedAndPlacedHereSoKnowOneKnowsIcopiedThierShyte
 - idiot paths: unconventional folders where duplicate and unused content hides E.g. \Custom\TX (which should go under \Custom\Assets\Audio)
 - Instruction files: core instruction files for VAM: .JSON, .VAJ, .VAP
 - Resource files: files consumed by content files: .JPG, .PNG, .CS, .Assetbundle, .VMI, .VAB, etc.
 - Normalize: reduce to 1 instance (i.e. de-duplicate; 'dedup')

#>

write-host
write-host ******************** START: NORMALIZE CONTENT  ************************
write-host

Function Normalize-ResourceDir {

    Param (

         [Parameter(Mandatory=$true, Position=0)]
         [string] $ResourceDir,
         [Parameter(Mandatory=$false, Position=1)]
         [string] $TargetPath

    )

    Write-Host $ScriptName--NORMALIZING: $ResourceDir Target: $TargetPath

    $LogEntry + "--NORMALIZE DIR:" + $ResourceDir | Out-File -FilePath $LogPath -Append     

    # RESOURCE PATHS
    # Move files out of idio paths into the base VAM file system & remove special characters

        # Get files that are not already normalized
        Get-ChildItem -Path ($vamRoot + $ResourceDir) -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_ -inotlike "*iHV_Normalized*" } | ForEach-Object {

            $ResourceFullName = $_.FullName

            # Skip folders from the exceptions array
            $ExceptionFound = $false
            $Exceptions | ForEach-Object{ If( $ResourceFullName -ilike ("*" + $_.Replace("/","\") + "*") ){ $ExceptionFound = $true } }

            If($ExceptionFound -eq $false){

                $ResourceFile = $_.Name
                #write-Host "----RF: " $ResourceFile

                # Type cases

                If( $ResourceFile -ilike "*.assetbundle" -Or $ResourceFile -ilike "*.scene" ){
                    # write-host ".....Move asset file to Custom\AssetsiHV_Normalized\"
                    $LogEntry + ".....Move asset file: " + $ResourceFile | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + "Custom\Assets\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                }
                ElseIf( $ResourceFile -ilike "*.mp3" -Or $ResourceFile -ilike "*.ogg" -Or $ResourceFile -ilike "*.wav" -Or $ResourceFile -ilike "*.bvh") {
                    #write-host ".....Move media file to Custom\Sounds\iHV_Normalized\"
                    $LogEntry + ".....Move media file: " + $ResourceFile | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + "Custom\Sounds\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                }
                ElseIf( $ResourceFile -ilike "*.webm" ){
                    # write-host ".....Move WEBM file to Custom\Assets\Audio\WEBM\iHV_Normalized\"
                    $LogEntry + ".....Move WEBM file: "  + $ResourceFile | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + "Custom\Sounds\WEBM\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                }

                # Idiot cases

                ElseIf($TargetPath -ilike "*Custom/*"){
                    $LogEntry + ".....Move Idiot: " + $_.FullName + " to " + ($vamRoot + $TargetPath.Replace("/","\")) | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + $TargetPath.Replace("/","\")) -ErrorAction SilentlyContinue
                }
                ElseIf( $ResourceFullName -ilike "*\texture*\*" -and $blnNormalizeTextures -eq $true ){
                    # write-host ".....Move texture file to Custom\Atom\Person\Textures\iHV_Normalized\"
                    $LogEntry + ".....Move texture file: " + $ResourceFile | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + "Custom\Atom\Person\Textures\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                } 

                # Conventional cases

                ElseIf( $ResourceFullName -ilike "*\Saves\*"){ Return }
                Else{
                    # write-host ".....Move efile: " $_.FullName " to " ($vamRoot + $ResourceDir + "iHV_Normalized\") 
                    $LogEntry + ".....Move efile: " + $_.FullName + " to " + ($vamRoot + $ResourceDir + "iHV_Normalized\") | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + $ResourceDir + "iHV_Normalized\") -Force -ErrorAction SilentlyContinue

                } # Else if not an explicit file type

            } # If ExceptionFound = false  
    
        } # Get items in subfolders: Get-ChildItem -Path ($vamRoot + $ResourceDir) -File -Recurse -Force

    [GC]::Collect()

} # End Normalize-ResourceDir Function


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
        If($Instructions -match "SELF:/"){$blnWasTheFileChanged = $true}
        $Instructions = $Instructions -Replace("SELF:/","")
       
        # IDIO PATHS
        # Update $Instructions\resource paths by a) establishing what the path is and b) replacing it with a normalized one

        $Instructions | Where-Object {$_ -match "/"} | ForEach-Object { 

            $Line = ""
            $Line = $_ #.ToLower() # line from the file being read-in

            # ---------------------------> Remove VAR Paths

            $NewLine   = ""
            $NewValue  = ""
            $NodeName  = ""
            $NodeValue = ""
            $RemoveMe  = ""
            $NodeName  = $Line.Substring(0, $Line.indexOf(":") + 3 ).Trim()

            If($NodeName.Length -gt 0){

                $NodeValue = $Line.Replace($NodeName,"")
                $NodeValue = $NodeValue.Trim().Trim(",").Trim("""") 

                # Revmove VAR prefixes from JSON paths to Prefix resources     
                If($NodeName.indexOf("presetName") -ge 0 ){
                    $blnWasTheFileChanged = $true

                    #write-host PresetName found:::::$Line

                    If($NodeValue.indexOf(":") -gt 0){
                        $blnWasTheFileChanged = $true 
                    
                        $RemoveMe = $NodeValue.substring( 0, $NodeValue.indexOf(":") + 1 )
                        $Instructions = $Instructions -ireplace $NodeValue, ( $NodeValue.Replace($RemoveMe, "") )
                    }
                } 
                
                # Remove VAR prefixes from general JSON paths
                if($NodeValue -ilike "*:/*"){
                    $blnWasTheFileChanged = $true

                    $StartIndex = 1                     
                    $EndIndex = $NodeValue.indexOf("/") + 1
                    If($EndIndex -le 1){$LogEntry + " ERROR: VAR prefix. " + $Line + ", FILE:" + $File_FullName | Out-File -FilePath $LogPath -Append}
                    
                    # New method
                    $VARprefix = $NodeValue.SubString(0, $EndIndex).Trim() # e.g. BallerDev.lovescene.69:/
                    $Instructions = $Instructions -ireplace [regex]::Escape($VARprefix), ""
                    $Line = $Line -ireplace [regex]::Escape($VARprefix), ""

                } # if($Line -match "/custom")

            # ---------------------------> End Remove VAR Path Prefixes

            # ---------------------------> Update to normalized Paths

                $ExceptionFound = $false
                $Exceptions | ForEach-Object{ If( $Line -imatch $_ ){ $ExceptionFound = $true } }
                If($Line -ilike "*Custom/Atom/*" -And $Line -inotlike "*Custom/Atom/Person/*"){$ExceptionFound = $true} # For Custom/Atom: Only process Custom/Atom/Person/

                
                $IsIdiotPath = $false
                $IdiotPaths | ForEach-Object { If( $Line -imatch ($_.IdiotPath.Trim("/") ) ) { $IsIdiotPath = $true } }

                If($ExceptionFound -eq $false -and ( $Line.indexof("./") -ge 0 -or $Line.indexof("Custom/") -ge 0 -Or $IsIdiotPath -eq $true ) ){

                    $NodeName = ""
                    $NodeValue = ""
                    $LastSlash = 0
                    $FileName = ""
                    $FullPath = ""

                    $NodeName = $Line.Substring(0, $Line.indexOf(":") + 3 ).Trim()
                    $NodeValue = $Line.Replace($NodeName,"").Trim().Trim(",").Trim("""") 
                    $LastSlash = $NodeValue.lastindexof("/")

                    $FullPath = ($NodeValue.Substring( 0, $LastSlash ).Trim() + "/")
                    $FileName = $NodeValue.Replace($FullPath,"")
                    
                    # Write-Host -------FN:$FileName::::BP:$BasePath
                    If($FileName.Length -ge 5){
                        $blnWasTheFileChanged = $true
  
                        # consider type cases before swapping out idio paths for conventional paths
                        
                        If( $FileName -ilike "*.assetbundle" -Or $FileName -ilike "*.scene" ){ $Instructions = $Instructions -ireplace [regex]::Escape(($FullPath + $FileName)), ("Custom/Assets/iHV_Normalized/" + $FileName) }
                        ElseIf( $FileName -ilike "*.mp3" -Or $FileName -ilike "*.ogg" -Or $FileName -ilike "*.wav" -Or $FileName -ilike "*.bvh" ){$Instructions = $Instructions -ireplace [regex]::Escape(($FullPath + $FileName)), ("Custom/Sounds/iHV_Normalized/" + $FileName)}
                        ElseIf( $FileName -ilike "*.webm" ){$Instructions = $Instructions -ireplace [regex]::Escape(($FullPath + $FileName)), ("Custom/Sounds/WEBM/iHV_Normalized/" + $FileName)}    
                        
                        # consider idiot cases before swapping out idio paths for conventional paths
                        
                        ElseIf( $IsIdiotPath -eq $true){
                            $IdiotPaths | ForEach-Object {
                                $NewLine = $Line -ireplace [regex]::Escape($FullPath), ($_.TargetPath)                               
                                $Instructions = $Instructions -ireplace [regex]::Escape($Line), ($NewLine)
                            } # ElseIf Idiot path
                        }
                        ElseIf( $FullPath -ilike "*/texture*/*" -and $blnNormalizeTextures -eq $true ){ $Instructions = $Instructions -ireplace [regex]::Escape(($FullPath + $FileName)), ("Custom/Atom/Person/Textures/iHV_Normalized/" + $FileName) }
                        
                        # consider special cases before swapping out idio paths for conventional paths
                        
                        ElseIf( $FullPath -ilike "./*" ){ $Instructions = $Instructions -ireplace [regex]::Escape($FullPath), "" }
                        ElseIf( $FullPath -ilike "*/Saves*" ){} # don't do anything further
                        ElseIf( $FullPath -ilike "*iHV_Normalized*" ){} # duplicate idio instance that's already been fixed; don't do anything further: escape
                        
                        # consider idio cases for conventional paths
                        
                        Else{ 
                            $InstructionsDirs | ForEach-Object { if( $FullPath.ToLower().indexOf($_.ToLower() ) -ge 0 ){ 
                                $NewLine = $Line -ireplace [regex]::Escape($FullPath), ($_ + "iHV_Normalized/")                               
                                $Instructions = $Instructions -ireplace [regex]::Escape($Line), ($NewLine)
                                #$Instructions = $Instructions -ireplace "iHV_Normalized/iHV_Normalized/","iHV_Normalized/" # remove mystery doubles
                            
                            } } # truncate path down to the convention

                            $PresetDirs | ForEach-Object { if( $FullPath -ieq $_  ){ 
                                $NewLine = $Line -ireplace [regex]::Escape($FullPath), ($_ + "iHV_Normalized/")                               
                                $Instructions = $Instructions -ireplace [regex]::Escape($Line), ($NewLine)
                                #$Instructions = $Instructions -ireplace "iHV_Normalized/iHV_Normalized/","iHV_Normalized/" # remove mystery doubles
                            
                            } } # repath anything in a root preset folder; leave subfolders alone

                            $ResourceDirs | ForEach-Object { if( $FullPath.ToLower().indexOf($_.ToLower() ) -ge 0 ){ 
                                $NewLine = $Line -ireplace [regex]::Escape($FullPath), ($_ + "iHV_Normalized/")                               
                                $Instructions = $Instructions -ireplace [regex]::Escape($Line), ($NewLine)
                                #$Instructions = $Instructions -ireplace "iHV_Normalized/iHV_Normalized/","iHV_Normalized/" # remove mystery doubles

                            } }
                        } # Else                            

                    } # If($IsIdiotPath -eq $false -and $FileName.Length -ge 5)

                } # If($ExceptionFound -eq $false)

            } #If($NodeName -ne $null)
         
        } # $Instructions | ForEach-Object

            
            # ---------------------------> End Update with normalized paths

            # ---------------------------> Update with VR prefs


        If($blnVRprefs -eq $true -AND ($File_FullName -ilike "*.json" -or $File_FullName -ilike "*.vap")){
            $blnWasTheFileChanged = $true

            #write-host $File_FullName 

            $Json = $Instructions | ConvertFrom-JSON -ErrorAction SilentlyContinue

            IF($? -eq $true){ # if content was converted to JSON

                # CONFIGURE SCALE
                if($File_FullName -ilike "*.json"){
                     If($Json.worldScale -ne $null){$Json.worldScale = $WorldScale}
                     Else{ $Json | add-member -Name "worldScale" -value $WorldScale -MemberType NoteProperty -ErrorAction SilentlyContinue }
                }

                $Json | add-member -Name $ScriptName -value $ScriptVersion -MemberType NoteProperty -Force -ErrorAction SilentlyContinue    

                $Persons = @()
                $Persons = $Json.atoms | Where-Object{$_.type -eq 'Person'}

                ForEach($Person in $Persons){

                    $Storables = @{}
                    $Storables = $Person.storables

                    $Geometry = $Person.storables | Where-Object{$_.id -eq 'geometry'}

                    #Check for sex based on morph
                    $PL = ""
                    $PL = $Geometry.morphs | Where-Object{$_.uid -eq 'Penis Length'}
                    if($PL -eq $null){ $Sex = "Female" } else {$Sex = "Male"}
 
                    # update improvedPoV plugin if male

                    If($Sex -eq "Male" -and $Persons.Count -ge 2){

                        # Add ImprovedPOV and number so we can configure

                        $PluginManager = @{}
                        $PluginManager = $Person.storables | Where-Object{$_.id -eq 'PluginManager'}
                        $PluginManager.plugins | add-member -Name "plugin#100" -value "Custom/Scripts/AcidBubbles/ImprovedPoV.cs" -MemberType NoteProperty -ErrorAction SilentlyContinue  

                        # configure ImprovedPOV

                        $ImprovedPOV = @{}
                        $ImprovedPOV = New-Object -TypeName "PSCustomObject"
                        $ImprovedPOV | add-member -NotePropertyName 'id' -NotePropertyValue "plugin#100_ImprovedPoV" -ErrorAction SilentlyContinue
                        $ImprovedPOV | add-member -NotePropertyName 'Activate only when possessed' -NotePropertyValue "false" -ErrorAction SilentlyContinue
                        $Person.storables += $ImprovedPOV

                        $textures = @{}
                        $textures = $Storables | Where-Object{$_.id -eq 'textures'} -ErrorAction SilentlyContinue

                        if($textures -eq $Null){

                            $textures = New-Object -TypeName "PSCustomObject" -ErrorAction SilentlyContinue
                            $textures | add-member -NotePropertyName 'id' -NotePropertyValue "textures" -ErrorAction SilentlyContinue

                            $Person.storables += $textures
                    
                            $textures = $Person.storables | Where-Object{$_.id -eq 'textures'} -ErrorAction SilentlyContinue
                            add-member -InputObject $textures -NotePropertyMembers @{
                                genitalsSpecularUrl = "Custom/Atom/Person/Textures/VamTextures/JackaroosFreeGens/genitalsS.png"
                                genitalsNormalUrl = "Custom/Atom/Person/Textures/VamTextures/JackaroosFreeGens/JackarooFreeGenNormals2.png"
                                genitalsGlossUrl = "Custom/Atom/Person/Textures/VamTextures/JackaroosFreeGens/GenitalsG.png"
                                genitalsDecalUrl = "Custom/Atom/Person/Textures/VamTextures/JackaroosFreeGens/GenitalsD_Decal.png"
                                }                
                        }
                        else
                        {

                            add-member -InputObject $Textures -NotePropertyMembers @{
                                genitalsSpecularUrl = "Custom/Atom/Person/Textures/VamTextures/JackaroosFreeGens/genitalsS.png"
                                genitalsNormalUrl = "Custom/Atom/Person/Textures/VamTextures/JackaroosFreeGens/JackarooFreeGenNormals2.png"
                                genitalsGlossUrl = "Custom/Atom/Person/Textures/VamTextures/JackaroosFreeGens/GenitalsG.png"
                                genitalsDecalUrl = "Custom/Atom/Person/Textures/VamTextures/JackaroosFreeGens/GenitalsD_Decal.png"
                                } -ErrorAction SilentlyContinue
                        }

                    }

                    # Update Person attributes for VR

                    If($Sex -eq "Female"){

                        $AutoExpressions = $Person.storables | Where-Object{$_.id -eq 'AutoExpressions'}
                        If($AutoExpressions.enabled -eq $null){$AutoExpressions | add-member -Name "enabled" -value 'true' -MemberType NoteProperty -Force} else {$AutoExpressions.enabled = 'true'}

                        $Eyes = $Person.storables | Where-Object{$_.id -eq 'Eyes'}
                        If($Eyes.lookMode -eq $null){$Eyes | add-member -Name "lookMode" -value 'Player' -MemberType NoteProperty -Force} else {$Eyes.lookMode = 'Player'}

                        $EyelidControl = $Person.storables | Where-Object{$_.id -eq 'EyelidControl'}
                        If($EyelidControl.blinkEnabled -eq $null){$EyelidControl | add-member -Name "blinkEnabled" -value 'true' -MemberType NoteProperty -Force} else {$EyelidControl.blinkEnabled = 'true'}

                        $HeadAudioSource = $Person.storables | Where-Object{$_.id -eq 'HeadAudioSource'}
                        If($HeadAudioSource.pitch -eq $null){$HeadAudioSource | add-member -Name "pitch" -value $VoicePitch -MemberType NoteProperty -ErrorAction SilentlyContinue} else {$HeadAudioSource.pitch = '1.20'}

                        $SoftBodyPhysicsEnabler = $Person.storables | Where-Object{$_.id -eq 'SoftBodyPhysicsEnabler'}
                        If($SoftBodyPhysicsEnabler.enabled -eq $null){$SoftBodyPhysicsEnabler | add-member -Name "enabled" -value 'true' -MemberType NoteProperty -Force} else {$SoftBodyPhysicsEnabler.enabled = 'true'}

                    }
                    else # if male then
                    {

                        $AutoExpressions = $Person.storables | Where-Object{$_.id -eq 'AutoExpressions'}
                        If($AutoExpressions.enabled -eq $null){$AutoExpressions | add-member -Name "enabled" -value 'false' -MemberType NoteProperty -Force} else {$AutoExpressions.enabled = 'false'}

                        $Eyes = $Person.storables | Where-Object{$_.id -eq 'Eyes'}
                        If($Eyes.lookMode -eq $null){$Eyes | add-member -Name "lookMode" -value 'None' -MemberType NoteProperty -Force} else {$Eyes.lookMode = 'None'}

                        $EyelidControl = $Person.storables | Where-Object{$_.id -eq 'EyelidControl'}
                        If($EyelidControl.blinkEnabled -eq $null){$EyelidControl | add-member -Name "blinkEnabled" -value 'false' -MemberType NoteProperty -Force} else {$EyelidControl.blinkEnabled = 'false'}
                        If($EyelidControl.eyelidLookMorphsEnabled -eq $null){$EyelidControl | add-member -Name "eyelidLookMorphsEnabled" -value 'false' -MemberType NoteProperty -Force} else {$EyelidControl.eyelidLookMorphsEnabled = 'false'}

                        $eyeTargetControl = $Person.storables | Where-Object{$_.id -eq 'eyeTargetControl'}
                        If($eyeTargetControl.positionState -eq $null){$eyeTargetControl | add-member -Name "positionState" -value 'false' -MemberType NoteProperty -Force} else {$eyeTargetControl.positionState = 'false'}
                        If($eyeTargetControl.rotationState -eq $null){$eyeTargetControl | add-member -Name "rotationState" -value 'false' -MemberType NoteProperty -Force} else {$eyeTargetControl.rotationState = 'false'}

                        $SoftBodyPhysicsEnabler = $Person.storables | Where-Object{$_.id -eq 'SoftBodyPhysicsEnabler'}
                        If($SoftBodyPhysicsEnabler.enabled -eq $null){} else {$SoftBodyPhysicsEnabler.enabled = 'false'}

                    } # Update person attributes by sex
            
                } #ForEach Person     

                # CONFIGURE LIGHTS

                If($File_FullName -inotlike "*Alpaca*" -or $File_FullName -inotlike "*C&G*" -or $File_FullName -inotlike "*Reanimator*" -or $File_FullName -inotlike "*VirtAmteur*"-or $File_FullName -inotlike "*Niko3DX*"){
        
                    $lights = @()
                    $lights = $JSON.atoms | Where-Object{$_.type -eq 'InvisibleLight'}

                    ForEach($light in $lights){
       
                        ForEach($storedObject in $light.storables){
   
                            if ($storedObject.id -eq 'Light'){
                                $key = @()
                                ForEach($key in $storedObject){

                                    If($key.type -eq $null){$key | add-member -Name "type" -value 'Spot' -MemberType NoteProperty}else {$key.type = 'Spot'}
                                    If($key.intensity -eq $null){$key | add-member -Name "intensity" -value '0.9' -MemberType NoteProperty}else {$key.intensity = '0.9'}
                                    If($key.renderType -eq $null){$key | add-member -Name "renderType" -value 'ForcedPixel' -MemberType NoteProperty}else {$key.renderType = 'ForcedPixel'}
                                    If($key.shadowResolution -eq $null){$key | add-member -Name "shadowResolution" -value 'VeryHigh' -MemberType NoteProperty}else {$key.shadowResolution = 'VeryHigh'}
                                }
                            }
                        }
                    } #ForEach($light

                } # if not a skilled electrician

                $Instructions = $JSON | ConvertTo-Json -Depth 24

            } # if convert from JSON = true
            Else{ $LogEntry + "---ERROR: convertTo JSON for VRprefs. FILE:" + $File_FullName | Out-File -FilePath $LogPath -Append }

        } # VR Prefs
           
            # ---------------------------> End Update with VR Prefs

            # ---------------------------> Update file with new content


        If($blnWasTheFileChanged = $true){
            
            # write-host $ScriptName---UPDATE: $File_FullName
       
            #fix corruption that occurs when executing more than once on a file
            $Instructions = $Instructions -iReplace("ustom/","Custom/") -iReplace("CCustom/","Custom/")
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

# > > > SCRIPT TUNING

$blnNormalizeTextures  = $false # Normalize texture files into the parent texture folder. Will impact game quality but increase stability.
$blnProcessRootFolders = $true # Processing root folders on mature installs is redundant, and a considerable waste of processing time
$blnWatchForAllIdiots  = $true # Expand the Idiots array to known offenders. Keep on when dealing with new content. Turn off when processing mature installs.
$Normalize             = $true # Normalize files into a single instance, where possible

$blnVRprefs            = $true
$WorldScale            = "1.20" # make the game content smaller by 20%
$VoicePitch            = "1.25" # raise the pitch of female character voices by 25%

# < < <

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
$InstructionsDirs | Foreach-Object {MD ($vamRoot + $_.Replace("/","\") + "iHV_Normalized\") -ErrorAction SilentlyContinue}
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
$PresetDirs | Foreach-Object {MD ($vamRoot + $_.Replace("/","\") + "iHV_Normalized\") -ErrorAction SilentlyContinue}

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
If($blnNormalizeTextures -eq $true){ $ResourceDirs += "Custom/Atom/Person/Textures/" } # DANGER! test test test and accept results before losing custom textures
$ResourceDirs | Foreach-Object {MD ($vamRoot + $_.Replace("/","\") + "iHV_Normalized\") -ErrorAction SilentlyContinue}

#  IDIOT FOLDERS - case sensitive; this arry will be updated further down to include any unlisted folders found ino the root of VAM
#  add as you see them appear to control the destination 
#  tied to blnWatchForAllIdiots to speed up processing

If($blnWatchForAllIdiots -eq $true){
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
    )
}else
{
    $IdiotPaths = @(
       @{IdiotPath="Custom/Audio/";TargetPath="Custom/Sounds/iHV_Normalized/"} # Should only have entries that don't point to the default idiots path
       @{IdiotPath="Custom/Sound/";TargetPath="Custom/Sounds/iHV_Normalized/"} # nested content not explicitly declared will go to the default idiots path
                                                                # content in the vamRoot will not be picked up here
                                                                # -  use WatchForAllIdiots flag = true to scan the vamRoot
    )
}
MD ($vamRoot + "Custom\Atom\Idiots\") -ErrorAction SilentlyContinue

  
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
    "Custom/SubScene" # Required navtive folder with a small amount of idio content
    "E-Motion" # Required for this popular plugin
    "Electric Dreams" # optional: favorite clothing author
    "Energy85" # optional: clothing author who does not use unique file names
    "favorites" # Required: conventional VAM folder
    "iHV_Normalized" # Required: processed IHV files
    "a iHV_" # iHV scripts & log files
    "Jackaroo" # optional: clothing author who does not use unique file names
    "myFav" # Required: folders/files prefix that identifies content exempt from normalizing by this script, so to establish a personal folder organization scheme
    "NoStage" # optional: hair author
    "PostMagic" # optional: Let it ride and fail. I delete this since it's not VR friendly
    "Putz" # optional: clothing author who does not use unique file names
    "RT_LipSync" # Required by this plugin; creates protected space within Custom/audio/rt_lipsync for a curated audio library specific for this script
    "receiverAtom" # Required: json node that we don't want to update by mistake when adjusting paths
    "stringChooserValue" # Required: unity asset path
    "VamChan" # optional: favorite hair author
    "VamTextures" # optional: Male gen textures from Jackaroo
    "VRDollz" # optional: clothing author who does not use unique file names

    # "./" # Relative path for scenes; if not excepted, this gets turned into a sound path regardless of the actual content
)
If($blnNormalizeTextures = $false){ $Exceptions += "Custom/Atom/Person/Textures"}



#
# CALL - NORMALIZE FILE SYSTEM
# Move files out of idio and idiot locations into base the VAM file locations (to dedupe content)

$InstructionsDirs | Foreach-Object { If($Normalize -eq $true){ Normalize-ResourceDir ( $_ -Replace("/","\") ) } }
$ResourceDirs | Foreach-Object { If($Normalize -eq $true){ Normalize-ResourceDir ( $_ -Replace("/","\") ) } }
$PresetDirs | Foreach-Object { If($Normalize -eq $true){ Normalize-ResourceDir ( $_ -Replace("/","\") ) } }

#
# MOVE IDIOT RESOURCES INTO Custom/Atom/Idiots/


# Get any idiot folders found in the VAM >>> root <<< directory & add to the Idiot array
Get-ChildItem -Path ($vamRoot) -Directory -Force | Foreach-Object { 

    $blnException = $false
    ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*" + $Exception + "*" )) { $blnException = $true } }

    $blnIsRootFolder = $false
    ForEach($RootFolder in $NativeRootFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }

    If($_.FullName -eq $PSScriptRoot){$blnIsRootFolder = $true}

    If($blnException -ne $true -and $blnIsRootFolder -ne $true){
        write-host "++++Idiot folder: " $_.Name.Replace("\","/") " :: " $_.FullName
        $LogEntry + "----Idiot folder: " + $_ + " FileN: " + $_.Name | Out-File -FilePath $LogPath -Append
        $tmp = @{IdiotPath=($_.Name + "/"); TargetPath="Custom/Atom/Idiots/"}
        $IdiotPaths += $tmp  
    }

} # Get idiot folders

# Get any idiot folders found in the VAM >>> Save <<<s directory & add to the Idiot array
Get-ChildItem -Path ($vamRoot + "Saves") -Directory -Force | Foreach-Object { 

    $blnException = $false
    ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*/"+$Exception+"*")) { $blnException = $true } }

    $blnIsRootFolder = $false
    ForEach($RootFolder in $NativeSaveFsolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true }  }

    If($blnException -ne $true -and $blnIsRootFolder -ne $true){
        write-host "++++Idiot folder: Saves/" $_.Name.Replace("\","/") " :: " $_.FullName
        $LogEntry + "----Idiot folder: Saves\" + $_ + " FileN: " + $_.Name | Out-File -FilePath $LogPath -Append
        $tmp = @{IdiotPath=("Saves/" + $_.Name + "/"); TargetPath="Custom/Atom/Idiots/"}
        $IdiotPaths += $tmp  
    }

} # Get idiot folders

# Get any idiot folders found in the VAM >>> Custom <<< directory & add to the Idiot array
Get-ChildItem -Path ($vamRoot + "Custom") -Directory -Force | Foreach-Object { 

    $blnException = $false
    ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*/"+$Exception+"*")) { $blnException = $true } }

    $blnIsRootFolder = $false
    ForEach($RootFolder in $NativeCustomFolders){ If($_.FullName.Replace("\","/") -ilike ("*/"+$RootFolder)) { $blnIsRootFolder = $true } }

    If($blnException -ne $true -and $blnIsRootFolder -ne $true){
        write-host "++++Idiot folder: Custom/" $_.Name.Replace("\","/") " :: " $_.FullName
        $LogEntry + "----Idiot folder: Custom\" + $_ + " FileN: " + $_.Name | Out-File -FilePath $LogPath -Append
        $tmp = @{IdiotPath=("Custom/" + $_.Name + "/"); TargetPath="Custom/Atom/Idiots/"}
        $IdiotPaths += $tmp  
    }

} # Get idiot folders

$IdiotPaths | ForEach-Object{ 

    If($_ -eq $null){Return}

    # Build a source and target paths
    $IdiotDir = ($vamRoot + ($_.IdiotPath -Replace("/","\") ) )
    $TargetDir = ($vamRoot + ($_.TargetPath -Replace("/","\") ) )

    #Write-Host ----IdiotPath: $IdiotDir TargetDir: $TargetDir
    #$LogEntry + "----IdiotDir:" + $IdiotDir + " TargetDir: " + $TargetDir | Out-File -FilePath $LogPath -Append

    #Write-Host $ScriptName--NMLZ IDIOT: $_.IdiotPath
    If($Normalize -eq $true){ Normalize-ResourceDir ($_.IdiotPath) ($_.TargetPath) }
    [GC]::Collect()

} # $IdiotPaths | ForEach-Object{ 

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



# "Poor man's" intrusion detection

$arrBigFiles = @()
Get-ChildItem -Path ($vamRoot) -File -Recurse -Force | Where-Object { ($_.Name -ilike "*.ps1" -And ($_.Name -notlike "*a iHV_*")) -or $_.Name -ilike "*.py" -or $_.Name -ilike "*.pyc" -or $_.Name -ilike "*.pyw" -or $_.Name -ilike "*.pyd" -or $_.Name -ilike "*.exe" -or $_.Name -ilike "*.msi" -or $_.Name -ilike "*.dll" } |  ForEach-Object { $arrBigFiles += $_.FullName } 

$arrBigFiles | Where-Object { $_ -inotlike "*Unity*" -and $_ -inotlike "*VaM*.exe" -and $_ -inotlike "*Mono*" -and $_ -inotlike "*VaM_Data*" } | ForEach-Object { 
       Write-host !!!!!
       Write-host !!!!! FOUND: $_
       $LogEntry + "!!!!! FOUND " + $_ | Out-File -FilePath $LogPath -Append
    } 

    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host


    If($blnLaunched -ne $true){ Read-Host -Prompt "Press Enter to exit" }

<#

bugs:


#>