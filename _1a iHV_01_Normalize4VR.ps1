<#
I Hate VARS - Normalize Content for VR
  Remove idiosynchracies that create duplicates, slow VAM down, make it harder to find things, and reduce VAM's overall stability
  And set in-game preferences (e.g., Worldscale, default plugins, autoexpressions, etc.) 

WARNING:
 - Directories or files that you do not wish to change must be added to the >>> $Exceptions <<< array 
 - Changes to the Normalize function must be matched with a change to the Update function, and vice versa
 - Backup you fools, backup!

Functions:
1. Normalize Resource Files
 - Move resource files into a single folder (by type): morphs, subscenes, hair, clothing
 - Doesn't delete duplicate content (the optional "clean up" script does that)
 - You can use the $Exceptions array to exempt any of your favorite content

2. Update Instruction Files
 - Remove VAR prefixes from paths so the files can be found in the Windows file system
 - Update paths to the normalized VAM folders (i.e., VAM\Custom and VAM\Saves))
 - Deploy personal preferences for VR: lighting, plugins, person behaviors
 - You can use the $Exceptions array to exempt any of your in-place content

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
        Get-ChildItem -Path ($vamRoot + $ResourceDir) -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_ -inotmatch "iHV_Normalized" } | ForEach-Object {

            # Write-host Nmlz Child: $_.FullName

            $ResourceFullName = $_.FullName

            # Skip folders from the exceptions array
            $ExceptionFound = $false
            $Exceptions | ForEach-Object{ If( $ResourceFullName -ilike ("*" + $_.Replace("/","\") + "*") ){ $ExceptionFound = $true } }

            # Don't skip folders from the Idiot array
            $IsIdiotPath = $false
            If($blnWatchForAllIdiots -eq $true){ $IdiotPaths | ForEach-Object { If( $ResourceFullName -imatch ($_.IdiotPath.Replace("/","\\")) ) { $IsIdiotPath = $true } } }

            If($ExceptionFound -eq $false -Or $IsIdiotPath -eq $true ){

                $ResourceFile = $_.Name
                #write-Host "----RF: " $ResourceFile

                # File type cases

                If( $ResourceFile -match "\.assetbundle$" -Or $ResourceFile -ilike "*.scene$" ){
                    # write-host ".....Move asset file to Custom\AssetsiHV_Normalized\"
                    $LogEntry + ".....Move asset file: " + $ResourceFile | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + "Custom\Assets\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                }
                ElseIf( $ResourceFile -match "(\.mp3$|\.ogg$|\.wav$|\.bvh$)") {
                    #write-host ".....Move media file to Custom\Sounds\iHV_Normalized\"
                    $LogEntry + ".....Move media file: " + $ResourceFile | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + "Custom\Sounds\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                }
                ElseIf( $ResourceFile -match "\.webm$" ){
                    # write-host ".....Move WEBM file to Custom\Assets\Audio\WEBM\iHV_Normalized\"
                    $LogEntry + ".....Move WEBM file: "  + $ResourceFile | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + "Custom\Sounds\WEBM\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                }
                ElseIf( $ResourceFile -match "(\.cs$|\.clist$)" ){ # Clists have hard-coded paths that would need to be re-written; task item
                    # Custom\Scripts is an exception, so that folder will not be normalized
                    # write-host ".....Move Script file to Custom\Scripts\"
                    #$LogEntry + ".....Move Script file: "  + $ResourceFile | Out-File -FilePath $LogPath -Append
                    #$_ | Move-Item -Destination ($vamRoot + "Custom\Scripts\") -Force -ErrorAction SilentlyContinue
                }

                # Idiot cases

                # for idiot cases (folders), there is a provided $TargetPath value is passed to the Update function
                ElseIf($TargetPath -match "Custom\\"){
                    $LogEntry + ".....Move Idiot: " + $_.FullName + " to " + ($vamRoot + $TargetPath.Replace("/","\")) | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + $TargetPath.Replace("/","\")) -ErrorAction SilentlyContinue
                }
                ElseIf( $NormalizeTextures -eq $true -and $ResourceFullName -ilike "*\texture*\*" ){
                    # write-host ".....Move texture file to Custom\Atom\Person\Textures\iHV_Normalized\"
                    $LogEntry + ".....Move texture file: " + $ResourceFile | Out-File -FilePath $LogPath -Append
                    $_ | Move-Item -Destination ($vamRoot + "Custom\Atom\Person\Textures\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                } 

                # Idio cases

                ElseIf( $ResourceFullName -imatch "Saves\\" ){

                    # trap all Saves\ content here to avoid them falling tinto the default condition below
                    # only image scene\files are processed here; .cs files along with other resources are processed above

                    If( $ResourceFullName -match "(\.jpg$|\.png$)"){

                        #pull the file extension off the path
                        $rootPathName = $ResourceFullName.Substring(0, $ResourceFullName.lastIndexOf(".") ) 

                        #write-host ----- (test-path ($rootPathName + ".json"))
                        if ( (test-path ($rootPathName + ".json")) -or (test-path ($rootPathName + ".vap")) -or (test-path ($rootPathName + ".vaj")) ){}
                        Else{
                            $LogEntry + ".....Move Save texture: " + $_.FullName + " to " + ("Custom\Atom\Person\Textures\iHV_Normalized\") | Out-File -FilePath $LogPath -Append
                            $_ | Move-Item -Destination ($vamRoot + "Custom\Atom\Person\Textures\iHV_Normalized\") -Force -ErrorAction SilentlyContinue
                        }
                    }
                }

                # Conventional cases
                
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

        # write-host --UPDATE KICKOFF: $File_FullName

        # Instruction FILES - Get the raw file content to update ----------------------------------------->
        $Instructions = [System.IO.File]::ReadAllLines($File_FullName) # .NET function (requires .NET) (Get-Content -raw $File_FullName)
        $blnWasTheFileChanged = $false

        #-----------------------------------------------------------------------------> 

        # Global Change: SELF
        If($Instructions -match "SELF:/"){
            $blnWasTheFileChanged = $true
            $Instructions = $Instructions -Replace("SELF:/","")
        }
        
       
        # IDIO PATHS
        # Update $Instructions\resource paths with a normalized one

        $Instructions | Where-Object { $_ -imatch $FileType_RegExFilter } | ForEach-Object { # only process lines with file extensions

            $Line = ""
            $Line = $_ #.ToLower() # line from the file being read-in

            # ---------------------------> Remove VAR Paths

            If($Line -imatch "(:/|presetName)"){

                $NewLine   = ""
                $NewValue  = ""
                $NodeName  = ""
                $NodeValue = ""
                $RemoveMe  = ""

                # break the line down to Name and Value pairs

                # NodeName
                $NodeName  = $Line.Substring(0, $Line.indexOf(":") + 3 ).Trim()

                If($NodeName.Length -gt 0){ 

                    #NodeValue
                    $NodeValue = $Line.Replace($NodeName,"")
                    $NodeValue = $NodeValue.Trim().Trim(",").Trim("""") 

                    # Case 1: Revmove VAR prefixes from JSON paths to Prefix resources
                        
                    If($NodeName -match "presetName"){

                        #write-host PresetName found:::::$Line

                        If($NodeValue -match ":"){
                            $blnWasTheFileChanged = $true 
                    
                            $RemoveMe = $NodeValue.substring( 0, $NodeValue.indexOf(":") + 1 )
                            $Instructions = $Instructions -ireplace $NodeValue, ( $NodeValue.Replace($RemoveMe, "") )
                        }

                    } # if preset
                
                    # Case 2: Remove VAR prefixes from general JSON paths
                    
                    Elseif($NodeValue -imatch ":/"){
                        $blnWasTheFileChanged = $true

                        $StartIndex = 1                     
                        $EndIndex = $NodeValue.indexOf("/") + 1
                        If($EndIndex -le 1){$LogEntry + " ERROR: VAR prefix. " + $Line + ", FILE:" + $File_FullName | Out-File -FilePath $LogPath -Append}
                    
                        $VARprefix = $NodeValue.SubString(0, $EndIndex).Trim() # e.g. BallerDev.lovescene.69:/
                        $Instructions = $Instructions -ireplace [regex]::Escape($VARprefix), ""
                        $Line = $Line -ireplace [regex]::Escape($VARprefix), ""

                    } # Elseif($Line -match ":/")

                } # if NodeName gt 0

            } #if line match :/ + presetname

            # ---------------------------> End Remove VAR Path Prefixes

            # ---------------------------> Update to normalized Paths

            $ExceptionFound = $false
            $Exceptions | ForEach-Object{ If( $Line -imatch $_ ){ $ExceptionFound = $true } }
            #If($Line -ilike "*Custom/Atom*" -And ($Line -inotlike "*Custom/Atom/Person*"  -or $Line -inotlike "*Custom/Atom/Idiots*")){$ExceptionFound = $true} # For Custom/Atom: Only process Custom/Atom/Person/

            $IsIdiotPath = $false
            If($blnWatchForAllIdiots -eq $true){ $IdiotPaths | ForEach-Object { If( $Line -imatch ($_.IdiotPath) ) { $IsIdiotPath = $true } } }

            # Write-host --- $Line  ExceptionFound $ExceptionFound IsIdiotPath $IsIdiotPath

            If($ExceptionFound -eq $false -Or $IsIdiotPath -eq $true ){

                $NodeName  = ""
                $NodeValue = ""
                $LastSlash = 0
                $FileName  = ""
                $vamPath  = ""

            #
            # Parse the JSON value pair into name + value
            #

                $NodeName  = $Line.Substring(0, $Line.indexOf(":") + 3 ).Trim()
                
                If($NodeName.length -eq 0){Return} # not a viable JSON path
                
                $NodeValue = $Line.Replace($NodeName,"").Trim().Trim(",").Trim("""") 
                $LastSlash = $NodeValue.lastindexof("/")
            
            #
            # Parse out the file and the path
            #

                # 2 kinds of paths: nominal & relative. If Relative, then convert to nominal to support appearance files

                # Nominal path
                If($LastSlash -ge 3 -And $NodeValue -inotmatch "^\./"){ # this is a nominal path
                    
                        $vamPath   = ($NodeValue.Substring( 0, $LastSlash ).Trim() + "/")                # e.g. Custom/Clothing/Female/DevName/
                        $FileName  = $NodeValue.Replace($vamPath,"")                                     # e.g. file.png

                    }

            #     Write-Host vamPath:: $vamPath FileName:: $FileName
            
            #
            # Normalize the path
            #

                If($FileName.Length -ge 5){
                        $blnWasTheFileChanged = $true

                    # consider type cases before swapping out idio paths for conventional paths

                        If( $FileName -imatch "(sample\.wav$|PostMagic)"){ $Instructions = $Instructions -ireplace [regex]::Escape(($vamPath + $FileName)), ("iHV_ValueRemoved") }
                         
                        ElseIf( $FileName -imatch "(\.assetbundle$|\.scene$)" -and $vamPath -inotmatch "Custom/Assets/iHV_Normalized/" ){ $Instructions = $Instructions -ireplace [regex]::Escape(($vamPath + $FileName)), ("Custom/Assets/iHV_Normalized/" + $FileName) }
                        ElseIf( $FileName -imatch "(\.mp3$|\.ogg$|\.wav$|\.bvh$)" -and $vamPath -inotmatch "Custom/Sounds/iHV_Normalized/" ){$Instructions = $Instructions -ireplace [regex]::Escape(($vamPath + $FileName)), ("Custom/Sounds/iHV_Normalized/" + $FileName)}
                        ElseIf( $FileName -imatch "\.webm$" -and $vamPath -inotmatch "Custom/Sounds/WEBM/iHV_Normalized/" ){$Instructions = $Instructions -ireplace [regex]::Escape(($vamPath + $FileName)), ("Custom/Sounds/WEBM/iHV_Normalized/" + $FileName)} 

                    # consider idiot cases before swapping out idio paths for conventional paths
                        
                        ElseIf( $IsIdiotPath -eq $true){ $IdiotPaths | ForEach-Object {

                                    $NewLine = $Line -ireplace $vamPath, ($_.TargetPath)                               
                                    $Instructions = $Instructions -ireplace [regex]::Escape($Line), $NewLine

                            } # ForEach

                        } # ElseIf

                        ElseIf( $vamPath -imatch "/texture" -and $NormalizeTextures -eq $true ){ $Instructions = $Instructions -ireplace [regex]::Escape(($vamPath + $FileName)), ("Custom/Atom/Person/Textures/iHV_Normalized/" + $FileName) }
                        
                    # consider special cases before swapping out idio paths for conventional paths
                                                
                        If( $vamPath -imatch "Saves/" -and $FileName -match "(\.jpg$|\.png$)" ){
                            
                            # Write-host Saves path found

                            # check to see if the image file is a thumbnail 
                            #    pull the file extension off the path
                            $rootPathName = $vamRoot + $vamPath + $FileName.Substring(0, $FileName.lastIndexOf(".") ) 

                            if ( (test-path ($rootPathName + ".json")) -or (test-path ($rootPathName + ".vap")) -or (test-path ($rootPathName + ".vaj")) ){ Return } # it's a thumbnail, don't move                      
                            Else{$Instructions = $Instructions -ireplace ($vamPath + $FileName), ("Custom/Atom/Person/Textures/iHV_Normalized/" + $FileName) }                            
                                      
                        }

                        <# ElseIf( $vamPath -imatch "Saves/scene/" -and $FileName -match "(\.cs|\.clist)" ){ 
                            $Instructions = $Instructions -ireplace ($vamPath + $FileName), ("Custom/Scripts/iHV_Normalized/" + $FileName)
                            #moving .cs and .clist means that the .clist must be rewritten: task list item               
                        #>
                                               
                    # consider idio cases for conventional paths: moves/consolidates content out of subfolders into a normalized folder
                        
                        Else{ 
                            # Write-Host Nominal case: vamPath:: $vamPath FileName:: $FileName
                             
                            $InstructionsDirs | ForEach-Object { if($vamPath -imatch $_){ 
                                $NewLine = $Line -ireplace [regex]::Escape($vamPath), ($_ + "iHV_Normalized/")                               
                                $Instructions = $Instructions -ireplace [regex]::Escape($Line), ($NewLine)
                            
                            } } # truncate path down to the convention

                            $PresetDirs | ForEach-Object { if($vamPath -imatch $_){ 
                                $NewLine = $Line -ireplace [regex]::Escape($vamPath), ($_ + "iHV_Normalized/")                               
                                $Instructions = $Instructions -ireplace [regex]::Escape($Line), ($NewLine)
                            
                            } } # repath anything in a root preset folder; leave subfolders alone

                            $ResourceDirs | ForEach-Object { if($vamPath -imatch $_){ 
                                $NewLine = $Line -ireplace [regex]::Escape($vamPath), ($_ + "iHV_Normalized/")                               
                                $Instructions = $Instructions -ireplace [regex]::Escape($Line), ($NewLine)

                            } }

                        } # Else                            

                    } # If($FileName.Length -ge 5)

            } # If($ExceptionFound -eq $false -Or $IsIdiotPath -eq $true ){
                     
            # ---------------------------> End Update with normalized paths

        } # $Instructions | Where-Object

        
        # ---------------------------> Update with VR prefs


        If($blnVRprefs -eq $true -AND ($File_FullName -imatch "\.json$" -or $File_FullName -imatch "\.vap$")){
            $blnWasTheFileChanged = $true

            #write-host $File_FullName 
            $Json = ""
            $Json = $Instructions | ConvertFrom-JSON -ErrorAction SilentlyContinue

            IF($? -eq $true){ # if content was converted to JSON

            # CONFIGURE SCALE
                if($File_FullName -imatch "\.json$"){
                     If($Json.worldScale -ne $null){$Json.worldScale = $WorldScale}
                     Else{ $Json | add-member -Name "worldScale" -value $WorldScale -MemberType NoteProperty -ErrorAction SilentlyContinue }
                }

                $Json | add-member -Name $ScriptName -value $ScriptVersion -MemberType NoteProperty -Force -ErrorAction SilentlyContinue    

                $Persons = @()
                $Persons = $Json.atoms | Where-Object {$_.type -eq 'Person'}

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

                    } # if sex eq male

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

                    } # if sex eq female
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

                    } # If Male 
            
                } #ForEach Person     

             # CONFIGURE LIGHTS

            If($File_FullName -inotmatch $AuthorLighting_RegExFilter){ # fix defaults: lighting best practice generally is as below. Some noted exceptions are in the $AuthorLighting_RegExFilter                        

                    $lights = @()
                    $lights = $JSON.atoms | Where-Object{$_.type -eq 'InvisibleLight'}

                    ForEach($light in $lights){
       
                        ForEach($storedObject in $light.storables){
   
                            if ($storedObject.id -eq 'Light'){
                                $key = @()
                                ForEach($key in $storedObject){

                                    #If($key.type -eq $null){$key | add-member -Name "type" -value 'Spot' -MemberType NoteProperty}else {$key.type = 'Spot'}
                                    If($key.intensity -eq $null){$key | add-member -Name "intensity" -value '0.9' -MemberType NoteProperty}else {$key.intensity = '0.9'}
                                    If($key.renderType -eq $null){$key | add-member -Name "renderType" -value 'ForcedPixel' -MemberType NoteProperty}else {$key.renderType = 'ForcedPixel'}
                                    If($key.shadowResolution -eq $null){$key | add-member -Name "shadowResolution" -value 'VeryHigh' -MemberType NoteProperty}else {$key.shadowResolution = 'VeryHigh'}
                                }
                            }
                        
                        } #ForEach(storedObject

                    } #ForEach($light

             } # if not a skilled electrician

                $Instructions = $JSON | ConvertTo-Json -Depth 16
                $Json = ""

        } # if convert from JSON = true
        Else{ $LogEntry + "---ERROR: convertTo JSON for VRprefs. FILE:" + $File_FullName | Out-File -FilePath $LogPath -Append }

    } # VR Prefs
           
    # ---------------------------> End Update with VR Prefs
        
        
        
    # ---------------------------> Update file with new content

    If($blnWasTheFileChanged -eq $true){
            
        # write-host $ScriptName---UPDATE: $File_FullName
       
        #fix corruption that occurs when executing more than once on a file
        #$Instructions = $Instructions -Replace("//", "/")
        #$Instructions = $Instructions -Replace("Custom/Sounds/iHV_Normalized/Custom/Sounds/iHV_Normalized/", "Custom/Sounds/iHV_Normalized/")
        #$Instructions = $Instructions -Replace("AdamAnt5.Realtime_LipSync.1:/","")
            
        $LogEntry + "---writing Updates.  FILE:" + $File_FullName + " CL:" + $Instructions.Length | Out-File -FilePath $LogPath -Append
            
        If($Instructions -imatch "/Custom/|/Saves/" ){
            Write-Host ---ERROR: VAR prefix. Search for /Custom or /Saves in: $File_FullName
            $LogEntry + " ERROR: VAR prefix. Search for /Custom or /Saves in: " + $File_FullName | Out-File -FilePath $LogPath -Append
        }

        # write-host --Writing $File_FullName :: $Instructions.Length
        $Error.Clear()
        [System.IO.File]::WriteAllLines($File_FullName, $Instructions)
        If($Error.Count -ne 0){
            Write-Host ---ERROR: $Error[0] FILE: $File_FullName
            $LogEntry + " ERROR: " + $Error[0] + ", FILE:" + $File_FullName | Out-File -FilePath $LogPath -Append
        }
        
    } #  If($blnWasTheFileChanged -eq $true){


} # End Update-InstructionFile Function

    ###################### SCRIPT TUNING ###################### 

# > > > SCRIPT TUNING

$blnProcessRootFolders = $true  # Set to false if you are only processing Saves\scene content and nothing in the Custom folder
$blnWatchForAllIdiots  = $true  # Expand the Idiots array to known offenders. Keep on when dealing with new content. Turn off when processing mature installs.

$Normalize             = $true  # Normalize files into a single instance, where possible. Set to false if you've already run iHV and are updating only
$NormalizeClothing     = $false 
$NormalizeHair         = $true
$NormalizeSkin         = $true  
$NormalizeTextures     = $false # Normalize texture files into the parent texture folder. Will impact game quality but increase stability.

$blnVRprefs            = $true
$WorldScale            = "1.20" # makes the in-game objects (e.g., people) smaller by 20%
$VoicePitch            = "1.25" # raise the pitch of female character voices by 25%

$FileType_RegExFilter       = "(\.dll|\.vab|\.vapb|\.vaj|\.vam|\.vap|\.vmi|\.json|\.jpg|\.png|\.mp3|\.wav|\.ogg|\.m4a|\.webm|\.amc|\.assetbundle|\.scene|\.clist|\.cs|\.bvh)"
$AuthorLighting_RegExFilter = "(Alpaca|Androinz|C\&G|ClubJulze|KittyMocap|Nial|Niko3DX|Reanimator|ReignMocap|Vipher|VirtAmteur|WadeVR)"


# < < <

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") } # don't use .\ for the root path for this script: it's kills path parsing above

$ScriptName            = "iHV_Normalize4VR"
$ScriptVersion         = "1.0.9"
$LogPath               = ($PSScriptRoot + "\_1a " + $ScriptName + ".log")
$LogEntry              = Get-Date -Format "yyyy/MM/dd HH:mm" 


    ###################### SCRIPT TUNING ###################### 


# CONTENT FOLDERS -  directories with content files with pathing that needs to be updated
$InstructionsDirs = @(
    "Custom/Clothing/Female/"
    "Custom/Clothing/Male/"
    "Custom/Hair/Female/"
    "Custom/Hair/Male/"
    "Custom/SubScene/"
)
$InstructionsDirs | Foreach-Object {MD ($vamRoot + $_.Replace("/","\") + "iHV_Normalized\") -ErrorAction SilentlyContinue}
$InstructionsDirs += "Saves/Person/"
$InstructionsDirs += "Saves/scene/"


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
If($NormalizeTextures -eq $true){ $ResourceDirs += "Custom/Atom/Person/Textures/" } # DANGER! test test test and accept results before losing custom textures
$ResourceDirs | Foreach-Object {MD ($vamRoot + $_.Replace("/","\") + "iHV_Normalized\") -ErrorAction SilentlyContinue}
MD ($vamRoot + "Custom\Atom\Person\Textures\iHV_Normalized\") -ErrorAction SilentlyContinue


<#  IDIOT FOLDERS - entries are for:
  - when you need to Provide an explicit destination in the $TargetPath variable, e.g. Sound files
    Otherwise, all Idiot folder content will be moved to the Custom/Atom/Idiots folder 

  - when you find nested content within a native VAM folder and within a subfolder, e.g. /Custom/Clothing/Texture-Pack/ 
  
  this array can be turrned off via the $blnWatchForAllIdiots switch to speed up processing

#>

If($blnWatchForAllIdiots -eq $true){
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
    )
}
MD ($vamRoot + "Custom\Atom\Idiots\") -ErrorAction SilentlyContinue

  
# NATIVE VAM ROOT FOLDERS - part of the base build - folders found within the parent that are not in this array will be treated as Idiot folders
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
# PERSONAL EXCEPTIONS - not part of the base build but ignore these anyway (format: keywords, no file extenstions)
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

If($blnProcessRootFolders -eq $false){ $Exceptions += "iHV_Normalized" }

If($NormalizeClothing -eq $false){ 
    $Exceptions += "Custom/Clothing/Female"
}
else{
    $Exceptions += "2021_clothes_pack_by_Daz"        # optional: major clothing package without unique file names
    $Exceptions += "AnythingFashionVR"               # optional: major clothing author who does not use unique file names
    $Exceptions += "CosmicFTW"                       # optional: major clothing author who does not use unique file names
    $Exceptions += "CuteSvetlana"                    # optional: major clothing author who does not use unique file names
    $Exceptions += "DillDoe     "                    # optional: clothing author who does not use unique file names
    $Exceptions += "ExpressionBlushingAndTears"      # optional: plugin from cotyounoyume
    $Exceptions += "Jackaroo"                        # optional: clothing author who does not use unique file names
    $Exceptions += "JaxZoa"                          # optional: major clothing author who does not use unique file names
    $Exceptions += "Molmark"                         # optional: clothing author who does not use unique file names
    $Exceptions += "Oeshii"                          # optional: clothing author who does not use unique file names
    $Exceptions += "Putz"                            # optional: clothing author who does not use unique file names
    $Exceptions += "Qing"                            # optional: clothing author who does not use unique file names
    $Exceptions += "SupaRioAmateur"                  # optional: major clothing author who does not use unique file names
    $Exceptions += "VL_13"                           # optional: clothing author who uses idio structures
    $Exceptions += "VRDollz"                         # optional: clothing author who uses idio structures
}
If($NormalizeHair -eq $false){ 
    $Exceptions += "Custom/Hair/Female"
}
else{
    $Exceptions += "NoStage"                         # optional: major Hair author who does not use unique file names
    $Exceptions += "Roac"                            # optional: major Hair author who does not use unique file names
    $Exceptions += "VaMChan"                         # optional: major Hair, scene author who does not use unique file names
}

If($NormalizeSkin -eq $false){ $Exceptions += "Custom/Atom/Person/Skin" }

If($NormalizeTextures -eq $false){ $Exceptions += "Custom/Atom/Person/Textures" }

write-host ........................
write-host EXCEPTIONS:
write-host
write-host $Exceptions
write-host
write-host .......................

# DISCOVER IDIOT RESOURCES


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


# ------------------------------------------->

<#
# CALL - NORMALIZE FILE SYSTEM
# Move files out of idio and idiot locations into base the VAM file locations (to dedupe content)
#>

$IdiotPaths | ForEach-Object{ 

    # Write-Host $ScriptName--NMLZ IDIOT: $_.IdiotPath
    
    If($Normalize -eq $true){ Normalize-ResourceDir ($_.IdiotPath.Replace("/","\")) ($_.TargetPath.Replace("/","\")) }
    [GC]::Collect()

} # $IdiotPaths | ForEach-Object{ 


$InstructionsDirs | Foreach-Object { If($Normalize -eq $true){ Normalize-ResourceDir ( $_ -Replace("/","\") ) } }
$ResourceDirs | Foreach-Object { If($Normalize -eq $true){ Normalize-ResourceDir ( $_ -Replace("/","\") ) } }
$PresetDirs | Foreach-Object { If($Normalize -eq $true){ Normalize-ResourceDir ( $_ -Replace("/","\") ) } }


# ------------------------------------------->

<#
 
 CALL - UPDATE CONTENT FILES
 Change resource pointers to reflect the new, normalized locations
 .vaj files point to texture files
 .vam files don't seem to hold any paths

 Note: idiot folders are not called. They are resources, not instructions.

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



# ------------------------------------------->


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

# Clists have hard-coded paths that would need to be re-written; task item

.8

- added flags for normalizing base clothing, hair, skin (presets are still normalized)
- fix relative pathing to better support appearances
- fix subscenes
- stop processing subscene  



WIP

                # Relative path
                ElseIf($NodeValue -match "^\./"){
                        $blnWasTheFileChanged = $true
                        Write-Host relative path... $LastSlash
                        Write-host NodeValue....... $NodeValue

                        # nominalize the relative path so it can be processed below by the normalize functions

                        $vamPath  = $File_FullName.Substring(0,$File_FullName.LastIndexOf("\") + 1)      # e.g. C:\VAM\Custom\Clothing\Female\DevName\
                        $vamPath  = $vamPath.Replace($vamRoot, "").Replace("\","/")                      # e.g. Custom/Clothing/Female/DevName/

                        $IdioPath = $NodeValue.Substring(0,$NodeValue.LastIndexOf("/") + 1)              # e.g. ./Idio/
                        $FileName = $NodeValue.Trim()                                                    # e.g. ./Idio/file.png
                        $FileName = $FileName.Replace($IdioPath,"")                                      # e.g. "file.png"

                        If($Normalize -eq $true ){ # clear $IdioPath if normalizing

                                If($NormalizeClothing -eq $true -and $vamPath -match "/Clothing"){ $IdioPath = ""}
                                ElseIf($NormalizeHair -eq $true -and $vamPath -match "/Hair"){ $IdioPath = ""}
                                ElseIf($NormalizeSkin -eq $true -and $vamPath -match "/Skin"){ $IdioPath = ""}

                        } # if normalizing

                        $vamPath = $vamPath + $IdioPath.Replace("./","")                                 # e.g. Custom/Clothing/Female/DevName/          -> if normalizing
                                                                                                         # e.g. Custom/Clothing/Female/DevName/Idio/     -> if not normalizing
                        # port the normalized path into the instructions feed

                        $NewLine = $Line.Replace($NodeValue, $vamPath + $FileName)
                        #$Instructions = $Instructions.Replace( $Line, $NewLine )

                    } # Else rel path



#>