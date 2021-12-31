<# I Hate VARS - Move Unused Resource Files

    1. Read in the MoveReport
    2. Every entry with an ( or an )
        - build a source var: get where it came from from the path
        - move $ to the source dir

#>

Write-Host
Write-host ******************** START: iHV MOVE UNUSED RESOURCE FILES ************************
Write-Host



    ###################### SCRIPT TUNING ###################### 

# > > > SCRIPT TUNING

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + '\') }

$ScriptName = 'iHV_Util_MoveUnusedFiles-Woops'
$ScriptVersion = '1.0.0'
$LogPath = ($PSScriptRoot + '\_2a ' + $ScriptName + '.log')
$LogEntry = Get-Date -Format 'yyyy/MM/dd HH:mm' 

$blnBuildLinkLibrary = $true   # set to false to skip the process of scanning all instruction files and leverage a previous LinksCSV.csv build 
                               # CAUTION: running as false witout a previous and currents LinksCSV.csv  will cause all morphs, hair and cloths to be moved

$blnMoveMorphs = $true         # set to false to block action but still produce a log/report
$blnMoveHair = $false          # set to false to block action but still produce a log/report
$blnMoveClothing = $false      # set to false to block action but still produce a log/report
$blnMoveTextures = $false       # set to false to block action but still produce a log/report

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

    ($RecycleBin + "\Morph\" + $FileName) | Move-Item -Destination $SourceDir

    $FilePathCount = $FilePathCount + 1

}

Write-Host ...Restored: $FilePathCount resource files






    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host

Read-Host -Prompt '(hit ENTER to continue)'