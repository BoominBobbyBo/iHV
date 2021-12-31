<# I Hate VARS - Move Unused Resource Files

    - Scope: Morphs; Optionally: Hair, Clothing, Textures
        Suggestion: scan all new content for morphs and textures >>>> $blnMoveMorphs <<<  >>>> $blnMoveHair <<<  >>>> $blnMoveClothing <<<  >>>> $blnMoveTextures <<<
        Suggestion: only scan mature VAM builds for hair / clothing

    - You can restore any moved files, post execution, if needed/prefered

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
    Read-Host -Prompt 'No. Really. All morphs, hair, and clothes will be moved if you dont run RemoveVARpaths.p1 or Ns.ps1 first (hit ENTER to continue)'
}

    ###################### SCRIPT TUNING ###################### 

# > > > SCRIPT TUNING

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + '\') }

$ScriptName = 'iHV_Util_MoveUnusedFiles'
$ScriptVersion = '1.0.1'
$LogPath = ($PSScriptRoot + '\_2a ' + $ScriptName + '.log')
$LogEntry = Get-Date -Format 'yyyy/MM/dd HH:mm' 

$blnBuildLinkLibrary = $true     # set to false to skip the process of scanning all instruction files and leverage a previous LinksCSV.csv build 
                                 # CAUTION: running as false witout a previous and currents LinksCSV.csv  will cause all morphs, hair and cloths to be moved

$blnMoveMorphs       = $true     # set to false to block action but still produce a log/report
$blnMoveHair         = $false    # set to false to block action but still produce a log/report
$blnMoveClothing     = $false    # set to false to block action but still produce a log/report
$blnMoveTextures     = $false    # set to false to block action but still produce a log/report
$blnMoveAudio        = $false    # set to false to block action but still produce a log/report

$RecycleBin          = ($vamRoot + '_2a iHV_UnusedRecycleBin')
$LinksCSVpath        = ($RecycleBin + '\_2a iHV_InstructionLinks.csv')
$MoveReportCSVpath   = ($RecycleBin + '\_2a iHV_MoveReport.csv')

$blnDebug            = $false     # adds source file to the links file (which doubles it size)


# CONTENT FOLDERS -  directories with content files with pathing that needs to be updated
$InstructionsDirs = @(
    "Custom\Assets\"
    "Custom\Atom\Person\"
    "Custom\Clothing\"
    "Custom\Hair\"
    "Custom\Images\"
    "Custom\SubScene\"
    "Custom\Sounds\"
    "Saves\Person\"
    "Saves\scene\"
)


    ###################### SCRIPT TUNING ###################### 

MD ($RecycleBin) -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Clothing") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Hair") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Morph") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Images") -ErrorAction SilentlyContinue
MD ($RecycleBin + "\Audio") -ErrorAction SilentlyContinue

""""+'Type'+""""+','+""""+ 'FullFilePath' +"""" | Out-File -FilePath $MoveReportCSVpath # Clears previous and creates the report file anew for each execution

# Scan VAM instruction files to build a live database of required resource files (aka 'links')

If($blnBuildLinkLibrary -eq $true){

    IF($blnDebug -eq $true){ """"+'Link_RelPath' +""""+','+""""+ 'Source' +"""" | Out-File -FilePath $LinksCSVpath } # Clears previous and creates the library file anew for each execution
    Else {""""+'Link_RelPath' +"""" | Out-File -FilePath $LinksCSVpath }

    $arrInstructionLinks = @()
    $InstructionsDirs | ForEach-Object {

        Get-ChildItem -Path ($vamRoot + $_)  -File -include *.json, *.vap, *.vaj -Recurse -Force | Foreach-Object { 
    
            $SourceFullFilePath = $_.FullName
            $Directory = $_.Directory

            Write-Host ---Reading: $SourceFullFilePath

            $Instructions = [System.IO.File]::ReadAllLines($_) | Where-Object { $_ -inotmatch (""""+"name"+""""+":") -and ($_ -ilike "*Custom/*" -or $_ -ilike "*Saves/*") -and ($_ -imatch ".vam" -or $_ -imatch ".vmi" -or $_ -imatch ".jpg" -or $_ -imatch ".png" -or $_ -imatch ".mp3" -or $_ -imatch ".wav" -or $_ -imatch ".ogg") }

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
                    If($Link_RelPath.IndexOf("/") -eq -1){$Link_RelPath = ($Directory.ToString().Replace("\","/") + "/" + $Link_RelPath)}

                    If($Link_RelPath.Length -ge 18){ # sample: Custom/890/234.578

                        If($blnDebug -eq $true){ """"+$Link_RelPath +""""+','+""""+ $SourceFullFilePath +"""" | Out-File -FilePath $LinksCSVpath -Append }
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
    Get-ChildItem -Path ($vamRoot + $_) -File -Include *.vmi, *.vam, *.jpg, *.png, *.mp3, *.wav, *.ogg -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_ -inotlike ('*' + $RecycleBin +'*')} | Foreach-Object { $arrResourceFiles += $_.FullName }
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

    # For each resource file

    $File_FullPath     = $_ # Sample: C:\VAM\Custom\Sounds\boomboom.mp3
    $File_VAMpath      = [regex]::Escape( $File_FullPath.Replace($vamRoot,'').Replace('\','/') ) # sample: Custom/Sounds/boomboom.mp3

    If($arrMovedFiles -icontains $File_FullPath){Return} # file has already been moved

    # Find resource file in the instructions path

    if ($LinksCSV -imatch [regex]::Escape($File_VAMpath)){}
    Else{
        # if not in InstructionLinks....


        If($File_VAMpath  -ilike '*.vam' ){

            # Hair | Clothing
        
            If($File_VAMpath  -imatch '/hair/'){ $type = 'Hair' }
            ElseIf($File_VAMpath -imatch '/Clothing/'){ $type = 'Clothing' }       
            Else{}

            # .vab, vaj and image files are not called directly by instruction files but they're in the filesystem
            # .vap and subfiles have prefixes; get child items with similar names to capture these

            $Path = $File_FullPath.substring( 0, $File_FullPath.LastIndexOf("\") )

            Get-ChildItem -Path $Path -File -Include *.vam, *.vab, *.vaj, *.vap, *.jpg, *.png -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_ -ilike ( $File_FullPath.Replace(".vam", ".") + "*" )} | Foreach-Object {

                write-host ---Orphaned $type : $_
                """"+$type+""""+','+""""+ $_ +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                       
                If( ($blnMoveHair -eq $true -and $File_VAMpath -ilike '*/hair/*') -or ($blnMoveClothing -eq $true -and $File_VAMpath -ilike '*/Clothing/*') ){

                    $Error.Clear()

                    If($blnMoveMorphs -eq $true){ $_ | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue}
                    If($Error[0] -notmatch "because it does not exist."){ $arrMovedFiles += $_.FullName }

                } # If( ($blnMoveHair -eq $true -and $File_FullPath -ilike '*\hair\*')

            } # get child items 

        } # if vam
        ElseIf($File_VAMpath -ilike '*.vmi'){ 

            # Morphs
            write-host ---Orphaned Morph: $File_VAMpath

            # .VMB files are not called directly by instruction files, assume .VMI + .VMB

            $vmb = $File_FullPath -iReplace('.vmi', '.vmb')
            $jpg = $File_FullPath -iReplace('.vmi', '.jpg')
            $png = $File_FullPath -iReplace('.vmi', '.png')
            
            $type = "Morph"
            $Error.Clear()
                
            If($blnMoveMorphs -eq $true){ $File_FullPath | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue }
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $File_FullPath +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }

            $Error.Clear()

            If($blnMoveMorphs -eq $true){ $vmb | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue }
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $vmb +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }

            $Error.Clear()

            If($blnMoveMorphs -eq $true){ $jpg | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue }
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $jpg +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }

                $Error.Clear()

            If($blnMoveMorphs -eq $true){ $png | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue }
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $png +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
            }
        
        } # If vmi

        ElseIf($File_VAMpath -imatch '.jpg' -or $_.Link_RelPath -imatch '.png'){ 

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
                """"+'Image'+""""+','+""""+$File_FullPath+"""" | Out-File -FilePath $MoveReportCSVpath -Append
                
                If($blnMoveTextures -eq $true){ ($File_FullPath) | Move-Item -Destination ($RecycleBin + "\Images")  -Force -ErrorAction SilentlyContinue }
                If($Error[0] -notmatch "because it does not exist."){ 
                    """"+"Image"+""""+','+""""+ $png +"""" | Out-File -FilePath $MoveReportCSVpath -Append
                    $arrMovedFiles += $_.FullName
                }
                               
            }
       
        } # if jpg or png

        ElseIf($File_VAMpath -ilike '*.mp3' -or $File_VAMpath -ilike '*.wav' -or $File_VAMpath -ilike '*.ogg'){ 

            # Audio
            write-host ---Orphaned Audio: $File_VAMpath           

            $type = "Audio"
            $Error.Clear()
                
            If($blnMoveAudio -eq $true){ $File_FullPath | Move-Item -Destination ($RecycleBin + "\" + $type) -Force -ErrorAction SilentlyContinue }
            If($Error[0] -notmatch "because it does not exist."){ 
                    """"+$type+""""+','+""""+ $File_FullPath +"""" | Out-File -FilePath $MoveReportCSVpath -Append
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

            ($LogEntry + "---Unlinked resource found. Potential 'idiot' content. " +  $File_VAMpath) | Out-File -FilePath $LogPath -Append

        }
 
    } 

} # for each ResourceFile

Write-Host Found: $arrMovedFiles.Count unused files.

    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host

    If($blnLaunched -ne $true){ Read-Host -Prompt "Press Enter to exit" }