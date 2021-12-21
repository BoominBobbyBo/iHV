<# I Hate VARS - Duplicate Scene Report

    - Scan VAM folders for instruction files
    - Compare to find duplicates
    - Move known dups into a RecycleBin
    - Report on all dups found

#>

Write-Host
Write-host ******************** START: iHV DUPLICATE SCENE REPORT ************************
Write-Host


    ###################### SCRIPT TUNING ###################### 

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") }

$ScriptName = "iHV_Util_DupSceneReport"
$ScriptVersion = "0.5"
$LogPath = ".\_2a " + $ScriptName + ".log"
$LogEntry = Get-Date -Format "yyyy/MM/dd HH:mm" 

$RecycleBin          = ($vamRoot + '_2a iHV_RecycleBin')
$DupReportCSVpath    = ($RecycleBin + '\_2a iHV_DupReport.csv')

    ######################               ###################### 

MD ($RecycleBin) -ErrorAction SilentlyContinue
""""+ 'FileName' +""""+","+""""+ 'Path' +""""+","+""""+ 'Duplicate' +"""" +","+""""+ 'Moved' +"""" | Out-File -FilePath $DupReportCSVpath # Clears previous and creates the report file anew for each execution


# Scan VAM folders for instruction files
$arrInstructionFiles = @()
$FileCount = 0

Get-ChildItem -Path ($vamRoot + 'Custom' ) -File -Include *.json, *.vap, *.vaj -Recurse -Force | Where-Object {$_ -inotlike ('*' + $RecycleBin +'*')} | Foreach-Object { 
        $tmp = @{FullName=($_.FullName); FileSize=$_.length}
        $arrInstructionFiles += $tmp # $_.FullName
        $FileCount = $FileCount + 1
}
Get-ChildItem -Path ($vamRoot + 'Saves' ) -File -Include *.json, *.vap, *.vaj -Recurse -Force | Where-Object {$_ -inotlike ('*' + $RecycleBin +'*')} | Foreach-Object {
        $tmp = @{FullName=($_.FullName); FileSize=$_.length}
        $arrInstructionFiles += $tmp # $_.FullName
        $FileCount = $FileCount + 1
}

Write-Host ...Found: $arrResourceFiles.Count $FileCount Custom and Saves files.

Write-Host
Write-Host ---Comparing instructions against actual files found....
Write-Host


    # Compare to find duplicates


$arrInstructionFiles | ForEach-Object {

        $arrDupFiles = @()
        $FullName1   = $_.FullName
        $FileSize1   = $_.FileSize
        $Path1       = $FullName1.substring(0, $FullName1.lastindexof("\") + 1)
        $FileName1   = $FullName1.Replace($Path1, "")

        Write-Host ---Check for dups: $FullName1 

        $arrDupFiles = $arrInstructionFiles | Where-Object{ $_.FullName -ilike ("*"+$FileName1) -and $_.FileSize -match ($FileSize1) }

       # if( $arrDupFiles.Contains($FullName1) -eq $false ){ # if file has not been moved already

       If($arrDupFiles.Count -ge 2){

            $arrDupFiles | ForEach-Object {

                $FullName2   = $_.FullName
                $Path2       = $FullName2.substring(0, $FullName2.lastindexof("\") + 1)
                $FileName2   = $FullName2.Replace($Path2, "")

                If( $FullName1 -eq $FullName2 ){} 
                Else{

                    $Moved = $false
                    If($FullName2 -ilike ("*Misc*")){

                        $Moved = $true
                        Get-ChildItem -Path $Path2 -File -Include *.json, *.vab, *.vaj, *.vap, *.jpg, *.png -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_ -ilike ( ($FullName2 -Replace ".json", "" -replace ".vap", "" -replace ".vaj", "") + "*" )} | Foreach-Object {
                        
                            $_ | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue                    
                        }
                    }

                    """"+ $FileName1 +""""+","+""""+ $Path1 +""""+","+""""+ $FullName2 +"""" +","+""""+ $Moved +"""" | Out-File -FilePath $DupReportCSVpath -Append

                   
                }

            } # Get-ChildItem files

       }  # if arrMovedFiles does not contain Name

} # ForEach VAR in arrVARs