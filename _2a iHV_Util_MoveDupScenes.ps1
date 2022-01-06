<# I Hate VARS - Move Duplicate Scenes

    - Review report to 
        see duplicate file origins
        manually address identified duplicates that have not been automatically moved

    - Scans VAM Custom and Saves folders for instruction files (.JSON)
    - Compares file names & size to find duplicates
    - Optional: set >>>> $blnMoveDups <<<< to $true to auto move dups into a RecycleBin
    - Reports into a CSV file on all dups found

#>

Write-Host
Write-host ******************** START: iHV DUPLICATE SCENE REPORT ************************
Write-Host


    ###################### SCRIPT TUNING ###################### 

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") }

$ScriptName            = "iHV_Util_MoveDupScenes"
$ScriptVersion         = "1.0.1"
$LogPath               = ".\_2a " + $ScriptName + ".log"
$LogEntry              = Get-Date -Format "yyyy/MM/dd HH:mm" 

$RecycleBin            = ($vamRoot + '_2a iHV_DupRecycleBin')
$DupReportCSVpath      = ($RecycleBin + '\_2a iHV_DupReport.csv')

$blnMoveDups           = $true

# PERSONAL EXCEPTIONS - ignore these anyway (format: keywords, no file extenstions)
$Exceptions = @(
    "BobB_" # optional: my author name - change to yours
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
""""+ 'DupName' +""""+","+""""+ 'DupPath' +""""+","+""""+ 'PrimaryFile' +"""" +","+""""+ 'Moved' +"""" | Out-File -FilePath $DupReportCSVpath # Clears previous and creates the report file anew for each execution


# Scan VAM folders for instruction files
$arrInstructionFiles = @()
$InstructionFileCount = 0

Write-Host ---Discovering instruction files from VAM\Saves\*.*

Get-ChildItem -Path ($vamRoot + 'Saves' ) -File -Include *.json -Recurse -Force | Foreach-Object {
        $tmp = @{FullName=$_.FullName; FileSize=$_.length}
        $arrInstructionFiles += $tmp # $_.FullName
        $InstructionFileCount = $InstructionFileCount + 1
}

Write-Host
Write-Host ...Found: $InstructionFileCount instruction files.

Write-Host
Write-Host ---Comparing instructions for potential duplicates....
Write-Host


# Compare instruction files names/size to identify duplicates & report/move them

$FoundDups         = 0
$arrMovedFiles     = @() 

$arrInstructionFiles | ForEach-Object {

        $FullName1   = $_.FullName

        If($arrMovedFiles -contains $FullName1){Return} # file has already been moved
        
        $arrDupFiles = @()
        $FileSize1   = $_.FileSize
        $Path1       = $FullName1.substring(0, $FullName1.lastindexof("\") + 1)
        $FileName1   = $FullName1.Replace($Path1, "")

        Write-Host ---Check for dups: $FullName1 

        # Validate file isn't protected by an exception
        ForEach($Exception in $Exceptions){ If($_.FullName.Replace("\","/") -ilike ("*" + $Exception + "*" )) { Return } }

        # Identify duplicates based on Name and Size
        $arrDupFiles = $arrInstructionFiles | Where-Object{ $_.FullName.Replace("[","").Replace("]","").Replace("(","").Replace(")","") -imatch $FileName1.Replace("[","").Replace("]","").Replace("(","").Replace(")","") -and $_.FileSize -imatch $FileSize1 }
          
        $arrDupFiles | ForEach-Object {

            If($FullName1 -ne $_.FullName){ # files have to be unalike somehow

                $FullName2   = $_.FullName                                              # e.g.  C:\VAM\Saves\scene\ballerdev\ballerdev_ballerfile.json
                $Path2       = $FullName2.substring(0, $FullName2.lastindexof("\") + 1) # e.g.  C:\VAM\Saves\scene\ballerdev
                $FileName2   = $FullName2.Replace($Path2, "")                           # e.g.  \ballerdev_ballerfile.json
                $FileBase2   = $FileName2.substring(0, $FileName2.lastindexof(".") )    # e.g.  \ballerdev_ballerfile
                $Moved       = $false
                
                #Write-Host ---Potential DUP::: FN1: $FullName1 FN2: $FullName2
                #Write-Host ---Potential DUP::: FN1: $FileName1 FN2: $FileName2

                If( $FileName1 -eq $FileName2) { # filter out partial name matches like 1.vam and 21.vam
                    
                    Write-Host
                    Write-Host --- DUP FOUND: $FullName2 ::: Moving: $blnMoveDups  
                    Write-Host

                    If( $FullName1 -ilike "*\aMisc\*" -or $FullName1 -ilike "*\iHV_Normalized\*" ){$TargetPath = $Path1; $PrimaryFile = $FullName2}                  
                    Else{$TargetPath = $Path2; $PrimaryFile = $FullName1}

                    Get-ChildItem -Path $TargetPath -File -Force | Where-Object { $_.Name -ilike $FileBase2 + ".*" } | Foreach-Object{    
                                
                        #Write-Host ---Dup: $_.FullName                          

                        If( $blnMoveDups -eq $true ){
                     
                            $Error.Clear()  

                            $_ | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue
                            If($Error[0] -notmatch "because it does not exist."){ 
                                $MovedFilesCount = $MovedFilesCount + 1
                                $Moved = $true
                            }
                            $arrMovedFiles += $_.FullName
                        }

                        # Report dup
                        """"+ $_.Name +""""+","+""""+ $TargetPath +""""+","+""""+ $PrimaryFile +"""" +","+""""+ $Moved +"""" | Out-File -FilePath $DupReportCSVpath -Append
                        $FoundDups = $FoundDups + 1                

                    } # Get-Children Path2
                        
                } # ElseIf FN = FN

            } # For each Dup found

        } # if dup names are not equal

} # ForEach VAR in arrVARs


Write-Host
Write-Host Found: $FoundDups duplicate files.
Write-Host Moved: $arrMovedFiles.Count  duplicate files. Note: Only 1 instance will be found in the Recycle Bin but all instances will be logged.

    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host

    If($blnLaunched -ne $true){ Read-Host -Prompt "Press Enter to exit" }