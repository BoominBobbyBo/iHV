<# I Hate VARS - Restore Unused Resource Files

    1. Read in the MoveReport
    2. Fore every entry:
        - build a source path: get where it came from from the path entry
        - copy file back to the source dir 
            (leave it in the Recycle Bin in case there are multiple destinations)

 Note:  Update the "Where-object" fileter below to chose which types of objects to restore
    example: Morph | Audio | Hair | Clothing | Skin | Images | Other

#>

Write-Host
Write-host ******************** START: iHV MOVE UNUSED RESOURCE FILES ************************
Write-Host



    ###################### SCRIPT TUNING ###################### 

# > > > SCRIPT TUNING

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + '\') }

$ScriptName = 'iHV_Util_MoveUnusedFiles-Woops'
$ScriptVersion = '1.0.1'
$LogPath = ($PSScriptRoot + '\_2a ' + $ScriptName + '.log')
$LogEntry = Get-Date -Format 'yyyy/MM/dd HH:mm' 

$RecycleBin          = ($vamRoot + '_2a iHV_RecycleBin')
$LinksCSVpath        = ($RecycleBin + '\_2a iHV_InstructionLinks.csv')
$MoveReportCSVpath   = ($RecycleBin + '\_2a iHV_MoveReport.csv')


    ###################### SCRIPT TUNING ###################### 

$FilePathCount = 0

$MoveReportCSV = Import-CSV $MoveReportCSVpath | Get-Unique -AsString | Where-Object {$_.Type -eq "Morph" -and ($_.FullFilePath -imatch "\(" -or $_.FullFilePath -imatch "\)")} | ForEach-Object{

    
    $SourceDir = $_.FullFilePath
    $SourceDir = $SourceDir.Substring(0, $SourceDir.LastIndexOf("\") + 1)
    $FileName = $_.FullFilePath.Replace($SourceDir, "").Trim("\")

    Write-Host ---Move::: $FileName ::: to ::: $SourceDir 

    ($RecycleBin + "\" + $_.MovedToType + "\" + $FileName) | Copy-Item -Destination $SourceDir

    $FilePathCount = $FilePathCount + 1

}

Write-Host ...Restored: $FilePathCount resource files

    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host

Read-Host -Prompt 'Files were copied to thier origin. The recycle bin was not cleared. Manually deleted any files as needed. (hit ENTER to continue)'