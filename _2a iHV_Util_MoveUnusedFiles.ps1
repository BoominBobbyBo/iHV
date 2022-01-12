<# I Hate VARS - Move Unused Resource Files

    - Scope: Morphs; Optionally: Hair, Clothing, Textures
        Suggestion: scan all new content for morphs and audio >>>> $blnProcessMorphs <<<  >>>> $blnProcessAudio
        Suggestion: only scan mature VAM builds for hair / clothing / skin

    - You can restore any moved files, post execution, if needed/prefered
        Suggestion: manually delete/archive unwanted files from the Recycle Bin then use the restore script to quickly restore remaining files

    - Scans VAM instruction files to build a live database of linked resource files
    - Scans Windows folders to build a live database of resource files
    - Compare the 2 tables to identify unused resouces 
    - Optionally: Remove unused files

    - DANGER!!!
    - Must first run either RemoveVARpaths.ps1 or NormalizeVAM4VR.ps1 (or ALL resource files will be moved)
    - Backup, you fools BACKUP!
    
    - REQUIRES
    - Content must have been extracted from VARs, and any VAR paths removed using either the RemoveVARpaths.ps1 or Normalize4VR.ps1

#>

Write-Host
Write-host ******************** START: iHV MOVE UNUSED RESOURCE FILES ************************
Write-Host

If($blnLaunched -ne $true){ 
    Read-Host -Prompt 'You must run either RemoveVARpaths.ps1 or NormalizeVAM4VR.ps1 first (hit ENTER to continue)' 
    Read-Host -Prompt 'No. Really. All resourcess will be moved regardless of status, if you dont run RemoveVARpaths.p1 or Normalize4VR.ps1 first (hit ENTER to continue)'
}

    ###################### SCRIPT TUNING ###################### 

# > > > SCRIPT TUNING

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + '\') }

$ScriptName = 'iHV_Util_MoveUnusedFiles'
$ScriptVersion = '1.0.5'
$LogPath = ($PSScriptRoot + '\_2a ' + $ScriptName + '.log')
$LogEntry = Get-Date -Format 'yyyy/MM/dd HH:mm' 

$blnBuildLinkLibrary = $true     # set to false to skip the process of scanning all instruction files and leverage a previous LinksCSV.csv build 
                                 # CAUTION: running as false witout a previous iHV_InstructionLinks.CSV will cause all morphs & audio to be moved regardless of links

$blnProcessMorphs    = $true     # set to false to block action
$blnProcessAudio     = $true     

$blnProcessSkin      = $false     
$blnProcessHair      = $false     
$blnProcessClothing  = $false    
$blnProcessTextures  = $false    

$FileType_RegExFilter = "(\.dll|\.vab|\.vaj|\.vam|\.vap|\.vmi|\.json|\.jpg|\.png|\.mp3|\.wav|\.ogg|\.m4a|\.webm|\.amc|\.assetbundle|\.scene|\.clist|\.cs|\.bvh)"

$RecycleBin          = ($vamRoot + '_2a iHV_UnusedRecycleBin')
$LinksCSVpath        = ($RecycleBin + '\_2a iHV_InstructionLinks.csv')
$MoveReportCSVpath   = ($RecycleBin + '\_2a iHV_MoveReport.csv')

$blnDebug            = $true     # adds source file to the links file (which doubles it size)


# CONTENT FOLDERS -  directories with content files with pathing that needs to be updated
$InstructionsDirs = @(
    "Custom\Assets\"
    "Custom\Atom\Person\"
    "Custom\Clothing\"
    "Custom\Hair\"
    "Custom\SubScene\"
    "Custom\Sounds\"
    "Saves\Person\"
    "Saves\scene\"
)
# PERSONAL EXCEPTIONS - ignore files or folders (format: keywords, paths, no file extenstions)
$Exceptions = @(
    "BobB_" # optional: my author name - change to yours
    "2021_clothes_pack_by_Daz" # optional: clothing author who does not use unique file names
    "Custom/Assets/Audio/RT_LipSync" # required for lip sync plugin RT_LipSync
    "Custom/Sounds/WEBM" # required for lip sync plugin RT_LipSync
    "Custom/Scripts" # Required: scripts have embedded paths that would be disrupted by iHV
    "favorites" # Required: conventional VAM folder
    "a iHV_" # iHV scripts & log files
    "myFav" # Required: folders/files prefix that identifies content exempt from normalizing by this script, so to establish a personal folder organization scheme
    "RT_LipSync" # Required by this plugin; creates protected space within Custom/audio/rt_lipsync for a curated audio library specific for this script
)


    ###################### SCRIPT TUNING ###################### 

MD ($RecycleBin) -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Clothing") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Hair") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Morph") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Images") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Audio") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Skin") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Other") -ErrorAction SilentlyContinue

""""+'MovedToType'+""""+','+""""+ 'MovedFrom' +"""" | Out-File -FilePath $MoveReportCSVpath # Clears previous and creates the report file anew for each execution

# Scan VAM instruction files to build a live database of required resource files (aka 'links')

If($blnBuildLinkLibrary -eq $true){

    IF($blnDebug -eq $true){ """"+'Link_RelPath' +""""+','+""""+ 'Source' +"""" | Out-File -FilePath $LinksCSVpath } # Clears previous and creates the library file anew for each execution
    Else {""""+'Link_RelPath' +"""" | Out-File -FilePath $LinksCSVpath }

    $arrInstructionLinks = @()
    $InstructionsDirs | ForEach-Object {

        Get-ChildItem -Path ($vamRoot + $_)  -File -include *.json, *.vap, *.vaj -Recurse -Force | Foreach-Object { 
    
            $Source_RelPath = $_.FullName.Replace($vamRoot,"")
            $Directory = $_.Directory.ToString().Replace($vamRoot,"")

            Write-Host ---Reading: $Source_RelPath

            $Instructions = [System.IO.File]::ReadAllLines($_) | Where-Object { $_ -inotmatch (""""+"name"+""""+":") -and ($_ -imatch $FileType_RegExFilter) }

            $Instructions | ForEach-Object { 

                $NodeName = ''
                $Link_FolderPath = ''
                $LastSlash = 0
                $Link_FileName = ''
                $Link_RelPath = ''

                $NodeName = $_.Substring(0, $_.indexOf(':') + 3 ).Trim() # json node value pair - node, e.g. 'ID : '

                If($NodeName.Length -ge 1){
                    $Link_RelPath = $_.Replace($NodeName,'').Trim().Trim(',').Trim("""")  # json node value pair - value, e.g. 'Custom/sounds/some.mp3'

                    # if file name only, add relative path or the check below will show a false positive
                    If($Link_RelPath.IndexOf("/") -eq -1){$Link_RelPath = ($Directory.ToString() + "/" + $Link_RelPath).Replace("\","/")}

                    If($Link_RelPath.Length -ge 16){ # sample: Saves/78/01/3.16

                        If($blnDebug -eq $true){ """"+$Link_RelPath +""""+','+""""+ $Source_RelPath +"""" | Out-File -FilePath $LinksCSVpath -Append }
                        Else{ """"+$Link_RelPath +"""" | Out-File -FilePath $LinksCSVpath -Append }
                    }
                }

            } # $Instructions '/'

        } # Get-ChildItem Custom files
    
    } # For each InstructionDir

} # If($blnBuildLinkLibrary -eq $true){""""+'Link_RelPath' +"""" | Out-File -FilePath $LinksCSVpath}

$LinksCSV = Import-CSV $LinksCSVpath | Get-Unique -AsString

Write-Host ...Loaded: $LinksCSV.Count resource links


# Scan Windows folders to build a live database of actual resource files paths
#      - using explicit paths to avoid scanning \Scripts, etc.

$arrResourceFiles = @()
$InstructionsDirs | ForEach-Object {
    Get-ChildItem -Path ($vamRoot + $_) -File -Include *assetbundle,*.vmi,*.vam,*.jpg,*.png,*.mp3,*.mfa,*.ogg,*wav,*.webm -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_ -inotlike ('*' + $RecycleBin +'*')} | Foreach-Object { $arrResourceFiles += $_.FullName }
}

Write-Host ...Found: $arrResourceFiles.Count Custom and Saves files.



# Compare the two tables to identify 
#        missing and 
#        unused resource files
#        Optionally: Remove unused files


Write-Host
Write-Host ---Comparing instructions against actual files found....
Write-Host

$arrMovedFiles     = @()
$arrResourceFiles | ForEach-Object {

    # Exclude exceptions

    ForEach($Exception in $Exceptions){ If($_.Replace("\","/") -ilike ("*" + $Exception + "*" )) {Return} }

    # For each resource file

    $File_FullPath     = $_ # Sample: C:\VAM\Custom\Sounds\boomboom.mp3
    $File_VAMpath      = $File_FullPath.Replace($vamRoot,'').Replace('\','/')  # sample: Custom/Sounds/boomboom.mp3

    # Write-host - RFP::: $File_VAMpath
    # Write-host - Matched:: ($LinksCSV.Link_RelPath -icontains $File_VAMpath)
    # Write-Host - PreviouslyMoved:: ($arrMovedFiles -icontains $File_FullPath)

    If($arrMovedFiles -icontains $File_FullPath){Return} # file has already been moved
    ElseIf($LinksCSV.Link_RelPath -icontains $File_VAMpath){Return}
    Else{
        # if not in InstructionLinks....

        If($File_VAMpath -imatch '\.vmi' -and $blnProcessMorphs -eq $true){ 

            # Morphs
            write-host ---Orphaned Morph: $File_VAMpath

            # .VMB files are not called directly by instruction files, assume .VMI + .VMB

            $vmb = $File_FullPath -iReplace('.vmi', '.vmb')
            $jpg = $File_FullPath -iReplace('.vmi', '.jpg')
            $png = $File_FullPath -iReplace('.vmi', '.png')
            
            $type = "Morph"
            $Error.Clear()
                
            $File_FullPath | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue 
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $File_VAMpath +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }

            $Error.Clear()

            $vmb | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $vmb.Replace($vamRoot,'') +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }

            $Error.Clear()

            $jpg | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $jpg.Replace($vamRoot,'') +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }

            $Error.Clear()

            $png | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $png.Replace($vamRoot,'') +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }
        
        } # If vmi

        ElseIf( ($File_VAMpath -imatch '\.mp3' -or $File_VAMpath -imatch '\.wav' -or $File_VAMpath -imatch '\.ogg') -and $blnProcessAudio -eq $true){ 

            # Audio
            write-host ---Orphaned Audio: $File_VAMpath           

            $type = "Audio"
            $Error.Clear()
                
            $File_FullPath | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $File_VAMpath +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }

        } # If Audio

        ElseIf($File_VAMpath  -imatch '\.vam' ){

            # Hair | Clothing | Skin
        
            If($File_VAMpath  -imatch '/Hair/'){ $type = 'Hair' }
            ElseIf($File_VAMpath -imatch '/Clothing/'){ $type = 'Clothing' }
            ElseIf($File_VAMpath -imatch '/Skin/'){ $type = 'Skin' }         
            Else{}

            If($type = 'Hair' -and $blnProcessHair -eq $false){Return}
            ElseIf($type = 'Clothing' -and $blnProcessClothing -eq $false){Return}
            ElseIf($type = 'Skin' -and $blnProcessSkin -eq $false){Return}       
            Else{}

            # .vab, vaj and image files are not called directly by instruction files but they're in the filesystem
            # .vap and subfiles have prefixes; get child items with similar names to capture these

            $Path = $File_FullPath.substring( 0, $File_FullPath.LastIndexOf("\") )

            Get-ChildItem -Path $Path -File -Include *.vam, *.vab, *.vaj, *.vap, *.jpg, *.png -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_ -ilike ( $File_FullPath.Replace(".vam", ".") + "*" )} | Foreach-Object {

                write-host ---Orphaned $type : $_
                """"+$type+""""+','+""""+ $_.FullName.Replace($vamRoot,"") +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                       
                    $Error.Clear()

                    $_ | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue
                    If($Error[0] -notmatch "because it does not exist."){ $arrMovedFiles += $_.FullName }


            } # get child items 

        } # if vam

        ElseIf( ($File_VAMpath -imatch '\.jpg' -or $_.Link_RelPath -imatch '\.png') -and $blnProcessTextures -eq $true ){ 

            # Is it a thumbnail?            
            # Search for similar file names with alternate extensions

            $BasePath     = $File_FullPath.ToString()
            $BasePath     = $BasePath.Substring( 0, $BasePath.LastIndexOf("\") + 1 )
            $FileName     = $File_FullPath.ToString().Replace($BasePath,"")
            $BaseFileName = $FileName.substring( 0, $FileName.LastIndexOf(".") + 1 )
            # write-host  BP:: $BasePath BFN:: $BaseFileName FN:: $FileName

            $Error.Clear()
            $SimilarFiles = Get-ChildItem -Path ($BasePath) -File -Force | Where-Object {$_.Name -ilike ($BaseFileName + "*") -and $_.Name -ne $FileName} 
            # write-host SF:: $SimilarFiles.Count

            If($Error.Count -eq 0 -and $SimilarFiles.Count -eq 0){ 
                            
                Write-Host ---Orphaned image: $File_FullPath
                """"+'Image'+""""+','+""""+$File_VAMpath+"""" | Out-File -FilePath $MoveReportCSVpath -Append
                
                ($File_FullPath) | Move-Item -Destination ($RecycleBin + "\Images")  -Force -ErrorAction SilentlyContinue 
                If($Error[0] -notmatch "because it does not exist."){ $arrMovedFiles += $_.FullName }
                               
            }
       
        } # if jpg or png

        ElseIf( $File_VAMpath -imatch '\.dll' -or $File_VAMpath -imatch '\.exe' -or $File_VAMpath -imatch '\.ps1'){ 

            write-host ---Orphaned OTHER: $File_VAMpath           

            $type = "Other"
            $Error.Clear()
                
            $File_FullPath | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $File_VAMpath +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }

        } # If Audio

        Else{

            <# Other types not managed:          
                .AssetBundles -
                .Scenes
                .clist
                .CS
                .fav
            #>

        }
 
    } 

} # for each ResourceFile

Write-Host Found: $arrMovedFiles.Count unused files.

    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host

    If($blnLaunched -ne $true){ Read-Host -Prompt "Press Enter to exit" }