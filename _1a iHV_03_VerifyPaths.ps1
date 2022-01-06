<# Verify Resource Files

    For each of the core JSON files, read all the paths and verify that a file would be found in the file system

#>

Write-Host
Write-host ******************** START: VERIFY RESOURCE PATHS  ************************
Write-Host 



Function Verify-ResourcesInInstructionsFile {

    Param (

        [String]
        $File_FullName
    )

        #write-host ---VERIFYING: $File_FullName

        # Instructions FILES - Get the raw file Instructions to update ----------------------------------------->
        $Instructions = [System.IO.File]::ReadAllLines($File_FullName) | Where-Object {($_ -match "Custom/" -or $_ -match "Saves/" -or $_ -match "./") -and $_ -match "."} # .NET function (requires .NET) (Get-Instructions -raw $File_FullName)

        #-----------------------------------------------------------------------------> 

        $Instructions | ForEach-Object { 

            $Line = $_ #.ToLower() # line from the file being read-in

            $NodeName = $Line.Substring(0, $Line.indexOf(":") + 3 ).Trim()
            $NodeValue = $Line.Replace($NodeName,"").Trim().Trim(",").Trim("""")
            # $LastSlash = $NodeValue.lastindexof("/")
            # $BasePath = $NodeValue.Substring( 0, $LastSlash ).Trim("/")
            # $FileName = $NodeValue.Replace($BasePath,"").Trim("/")

            # Write-Host "----NodeName: " $NodeName " Value: " $NodeValue

            $TestFileFullName = ($vamRoot + $NodeValue.Replace("/","\").Replace(".\","")).Trim()

            # Verify it's a testable path to ensure the qualification above wasn't satisfied by the NodeName
            If( ($TestFileFullName -ilike "*Custom\*" -or $TestFileFullName -ilike "*Saves\*") -and $TestFileFullName -like "*.*" ){

                #Use Powershell's Test-Path cmdlet to verify file
                If( Test-Path -LiteralPath $TestFileFullName -PathType Leaf ){ }
                else{
                   Write-Host "----Not found: " $TestFileFullName " ---Sourc file: " $File_FullName
                   """" + $TestFileFullName +""""+ ","+""""+$File_FullName+"""" | Out-File -FilePath $LogPath -Append
                }
            }
         
        } # $Instructions | ForEach-Object

} # End Update-InstructionsFile Function

    ###################### SCRIPT TUNING ###################### 

# > > > SCRIPT TUNING


# Update $vamRoot with the base install path for VAM.exe
If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") } # don't use .\ for the root path for this script: it's kills path parsing above

$ScriptName            = "iHV_VerifyPaths"
$ScriptVersion         = "1.0.0"
$LogPath               = ($PSScriptRoot + "\_1a " + $ScriptName + ".csv")

$ScriptName | Out-File -FilePath $LogPath 
$ScriptVersion  | Out-File -FilePath $LogPath -Append
Get-Date -Format "yyyy/MM/dd HH:mm" | Out-File -FilePath $LogPath -Append


"""" + "Missing" +""""+ ","+""""+"Source"+"""" | Out-File -FilePath $LogPath

# Instructions FOLDERS -  directories with Instructions files with pathing to be updated (files will not be moved)
$InstructionsFilePaths = @(
    "Custom/Clothing/Female/"
    "Custom/Clothing/Male/"
    "Custom/Hair/Female/"
    "Custom/Hair/Male/"
    "Custom/SubScene/"
    "Saves/scene/"
    "Saves/Person/"
    )

    ######################             ###################### 

$InstructionsFilePaths | Foreach-Object { 

    write-host --VERIFY Instructions DIR: $_ # shows the dir being checked as it's being checked

    Get-ChildItem -Path $_ -file -include *.json, *.vap, *.vaj -Recurse -Force -ErrorAction SilentlyContinue | Foreach-Object { # if this faults, directory in the array doesn't exist in the file system
                #write-host Verify:: $_.FullName # shows file by file what's being checked
                Verify-ResourcesInInstructionsFile $_.FullName
                [GC]::Collect()
    }
        
} # $InstructionsFilePaths | Foreach-Object { 




    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host
    If($blnLaunched -ne $true){ Read-Host -Prompt "Press Enter to exit" }