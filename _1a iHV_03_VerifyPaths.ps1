<# Verify Resource Files

    For each of the core JSON files, read all the paths and verify that a file would be found in the actual file system

#>

Write-Host
Write-host ******************** START: VERIFY FILES  ************************
Write-Host 


Function Verify-ResourcesInContentFile {

    Param (

        [String]
        $File_FullName
    )

        #write-host ---VERIFYING: $File_FullName

        # CONTENT FILES - Get the raw file content to update ----------------------------------------->
        $Content = [System.IO.File]::ReadAllLines($File_FullName) | Where-Object {$_ -match "/"} # .NET function (requires .NET) (Get-Content -raw $File_FullName)

        #-----------------------------------------------------------------------------> 

        $Content | Where-Object {$_ -match "Custom/" -and $_ -match "."} | ForEach-Object { 

            $Line = $_ #.ToLower() # line from the file being read-in

            $NodeName = $Line.Substring(0, $Line.indexOf(":") + 3 ).Trim()
            $NodeValue = $Line.Replace($NodeName,"").Trim().Trim(",").Trim("""")
            $LastSlash = $NodeValue.lastindexof("/")
            $BasePath = $NodeValue.Substring( 0, $LastSlash ).Trim("/")
            $FileName = $NodeValue.Replace($BasePath,"")

            #Write-Host "----NodeName: " $NodeName " Value: " $NodeValue " BasePath: " $BasePath " File: " $FileName    

            $TestFileFullName = ($vamRoot + "\" + $NodeValue.Replace("/","\"))
            $TestFileFullName = $TestFileFullName -Replace("\\","\") -Replace("SELF:","\")

            #Use Powershell's Test-Path cmdlet to verify file
            If( Test-Path -Path $TestFileFullName -PathType Leaf ){Return} #{ Write-Host "----Found: " $FileName }
            else{
               #Write-Host "----Not found: " $TestFileFullName " Content file: " $File_FullName
               "Missing: " + $TestFileFullName + ". SOURCE: " + $File_FullName | Out-File -FilePath $LogPath -Append
            }
         
        } # $Content | ForEach-Object

} # End Update-ContentFile Function

   ######################

# CONTENT FOLDERS -  directories with content files with pathing to be updated (files will not be moved)
$ContentFilePaths = @(
    "Custom/Clothing/Female/"
    "Custom/Clothing/Male/"
    "Custom/Hair/Female/"
    "Custom/Hair/Male/"
    "Custom/SubScene/"
    "Saves/scene/"
    "Saves/Person/"
    )

# Update $vamRoot with the base install path for VAM.exe
If($vamRoot -eq $null){ $vamRoot = $PSScriptRoot } # don't use .\ for the root path for this script: it's kills path parsing above

$ScriptName            = "iHV_Util_Verify"
$ScriptVersion         = "0.1"
$LogPath               = ($PSScriptRoot + "\_1a " + $ScriptName + ".log")

$ScriptName | Out-File -FilePath $LogPath -Append
$ScriptVersion  | Out-File -FilePath $LogPath -Append
Get-Date -Format "yyyy/MM/dd HH:mm"  | Out-File -FilePath $LogPath -Append
"*********************" | Out-File -FilePath $LogPath -Append




$ContentFilePaths | Foreach-Object { 

    write-host --VERIFY content DIR: $_ # shows the dir being checked as it's being checked

    Get-ChildItem -Path $_ -file -include *.json, *.vap, *.vaj -Recurse -Force -ErrorAction SilentlyContinue | Foreach-Object { # if this faults, directory in the array doesn't exist in the file system
                #write-host Verify:: $_.FullName # shows file by file what's being checked
                Verify-ResourcesInContentFile $_.FullName
                [GC]::Collect()
    }
        
} # $ContentFilePaths | Foreach-Object { 




    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host