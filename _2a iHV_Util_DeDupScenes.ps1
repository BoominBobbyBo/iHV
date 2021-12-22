<# I Hate VARS - De-Duplicate Scenes

    - Review report to 
        see duplicate file origins
        manually address identified duplicates that have not been automatically moved

    - Scans VAM Custom and Saves folders for instruction files (.JSON, .VAM, .VAP, .VAJ)
    - Compares file names & size to find duplicates
    - Optional: set >>>> $blnMoveDups <<<< to $true to auto move dups into a RecycleBin
    - Reports into a CSV file on all dups found

#>

Write-Host
Write-host ******************** START: iHV DUPLICATE SCENE REPORT ************************
Write-Host


    ###################### SCRIPT TUNING ###################### 

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") }

$ScriptName            = "iHV_Util_DeDupScenes"
$ScriptVersion         = "0.5"
$LogPath               = ".\_2a " + $ScriptName + ".log"
$LogEntry              = Get-Date -Format "yyyy/MM/dd HH:mm" 

$RecycleBin            = ($vamRoot + '_2a iHV_DupRecycleBin')
$DupReportCSVpath      = ($RecycleBin + '\_2a iHV_DupReport.csv')

$blnMoveDups           = $true

# PERSONAL EXCEPTIONS - ignore these anyway (format: keywords, no file extenstions)
$Exceptions = @(
    "aBackup" # optional: have any content you don't want to normalize or change?
    "BobB" # optional: my author name - change to yours
    "2021_clothes_pack_by_Daz" # optional: clothing author who does not use unique file names
    "Custom/Assets/Audio/RT_LipSync" # required for lip sync plugin RT_LipSync
    "Custom/Scripts" # Required: scripts have embedded paths that would be disrupted by iHV
    "favorites" # Required: conventional VAM folder
    "a iHV_" # iHV scripts & log files
    "myFav" # Required: folders/files prefix that identifies content exempt from normalizing by this script, so to establish a personal folder organization scheme
    "VamTextures" # optional: Male gen textures from Jackaroo
)

    ######################               ###################### 

MD ($RecycleBin) -ErrorAction SilentlyContinue
""""+ 'FileName' +""""+","+""""+ 'Path' +""""+","+""""+ 'Duplicate' +"""" +","+""""+ 'Moved' +"""" | Out-File -FilePath $DupReportCSVpath # Clears previous and creates the report file anew for each execution


# Scan VAM folders for instruction files
$arrInstructionFiles = @()
$InstructionFileCount = 0

Write-Host ---Discovering instruction files from VAM\Custom\*.*

Get-ChildItem -Path ($vamRoot + 'Custom' ) -File -Include *.json, *.vap, *.vaj, *.vam -Recurse -Force | Foreach-Object { 
        $tmp = @{FullName=($_.FullName); FileSize=$_.length}
        $arrInstructionFiles += $tmp # $_.FullName
        $InstructionFileCount = $InstructionFileCount + 1
}

Write-Host ---Discovering instruction files from VAM\Saves\*.*

Get-ChildItem -Path ($vamRoot + 'Saves' ) -File -Include *.json, *.vap, *.vaj, *.vam -Recurse -Force | Foreach-Object {
        $tmp = @{FullName=($_.FullName); FileSize=$_.length}
        $arrInstructionFiles += $tmp # $_.FullName
        $InstructionFileCount = $InstructionFileCount + 1
}

Write-Host ...Found: $InstructionFileCount instruction files.

Write-Host
Write-Host ---Comparing instructions for potential duplicates....
Write-Host


# Compare to find duplicates

$FoundDups = 0
$arrMovedFullNames = @()
$arrInstructionFiles | ForEach-Object {

        $FullName1   = $_.FullName

        If($arrMovedFullNames -contains $FullName1){Return}
        
        $arrDupFiles = @()
        $FileSize1   = $_.FileSize
        $Path1       = $FullName1.substring(0, $FullName1.lastindexof("\") + 1)
        $FileName1   = $FullName1.Replace($Path1, "")


        Write-Host ---Check for dups: $FullName1 

        # Validate file isn't protected by an exception
        ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*" + $Exception + "*" )) { Return } }

        # Identify duplicates based on Name and Size
        $arrDupFiles = $arrInstructionFiles | Where-Object{ $_.FullName -ilike ("*" + $FileName1) -and $_.FileSize -match ($FileSize1) }

        If($arrDupFiles.Count -ge 2){

            $arrDupFiles | ForEach-Object {

                $FullName2   = $_.FullName                                              # e.g.  C:\VAM\Saves\scene\ballerdev\ballerdev_ballerfile.json
                $Path2       = $FullName2.substring(0, $FullName2.lastindexof("\") )    # e.g.  C:\VAM\Saves\scene\ballerdev
                $FileName2   = $FullName2.Replace($Path2, "")                           # e.g.  \ballerdev_ballerfile.json
                $FileBase2   = $FileName2.substring(0, $FileName2.lastindexof(".") )    # e.g.  \ballerdev_ballerfile
                $Moved       = $false
 
                If( $FullName1 -eq $FullName2 ){} 
                Else{
                    
                    # Report dup
                    """"+ $FileName1 +""""+","+""""+ $Path1 +""""+","+""""+ $FullName2 +"""" +","+""""+ $Moved +"""" | Out-File -FilePath $DupReportCSVpath -Append
                    $FoundDups = $FoundDups + 1

                    # Optional: move dup
                    If( ($FullName2 -ilike "*aMisc*" -or $blnMoveDups -eq $true)  ){

                        $Moved = $true
                        Get-ChildItem -Path $Path2 -File -Force | Where-Object { $_.Name -ilike ($FileBase2 + "*") } | Foreach-Object{ 
                            
                            # Write-host FOUND DUP:: $Path2 :: FB2:: $FileBase2 ::: FN :: $_.FullName
                            $_ | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue
                            $arrMovedFullNames += $FullName2 
                                               
                        }
                        
                    } # if MoveDups = true

                } # Else

            } # For each Dup found

       }  # If Dups found

} # ForEach VAR in arrVARs


Write-Host
Write-Host Found: $FoundDups duplicate files.
Write-Host Moved: $arrMovedFullNames.Count duplicate files.

    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host

Read-Host -Prompt '(hit ENTER to continue)'