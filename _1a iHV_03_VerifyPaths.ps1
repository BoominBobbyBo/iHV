<# Verify Resource Files

    For each of the core JSON files, read all the paths and verify that a file would be found in the file system

    v1.0.0

#>

Write-Host
Write-host ******************** START: VERIFY RESOURCE PATHS  ************************
Write-Host 



Function Verify-ResourcesInInstructionsFile {

    Param (

        [String]
        $File_FullName
    )

        # write-host ---VERIFYING: $File_FullName

        # Instructions FILES - Get the raw file Instructions to update ----------------------------------------->
        $Instructions = [System.IO.File]::ReadAllLines($File_FullName) # .NET function (requires .NET) (Get-Instructions -raw $File_FullName)

        #-----------------------------------------------------------------------------> 

        $Instructions | Where-Object { $_ -imatch $FileType_RegExFilter } | ForEach-Object { 

            $Line = $_ #.ToLower() # line from the file being read-in

            $NodeName = ""
            $NodeName = $Line.Substring(0, $Line.indexOf(":") + 3 ).Trim()
            
            If($NodeName.length -ge 5){ # if there's enough characters to indicate a file name            
            
                $NodeValue = $Line.Replace($NodeName,"").Trim().Trim(",").Trim("""")

                # Write-Host "----NodeName: " $NodeName " Value: " $NodeValue
                # If($NodeValue -match "Custom"){Write-host ---FFN:: $File_FullName ::DN:: $DirectoryName :: NV:: $NodeValue}

                $TestFileFullName = ""
                If($NodeValue -notmatch "(\./|/)" ){ # if there is either a short-cut VAM path or no relative path (resource file is in the same directory as the instruction file)
                    $DirectoryName = $File_FullName.Substring( 0, ($File_FullName.LastIndexOf("\") + 1) )  
                    $TestFileFullName = ($DirectoryName + $NodeValue).Replace("./","/").Replace("/","\").Trim()
                }            
                Else{ 
                    #write-host  PATH:: $NodeValue
                    $TestFileFullName = ($vamRoot + $NodeValue).Replace("/","\").Trim() 
                } # if there is a VAM path

                # Verify it's a testable path to ensure the qualification above wasn't satisfied by the NodeName

                    #Use Powershell's Test-Path cmdlet to verify file
                    If( Test-Path -LiteralPath $TestFileFullName -PathType Leaf ){ }
                    else{
                       Write-Host "----Not found: " $TestFileFullName " ---Source file: " $File_FullName
                       $_.Trim() + """" + $TestFileFullName + """" +  "," + """" + $File_FullName + """" | Out-File -FilePath $LogPath -Append
                    }
            }
         
        } # $Instructions | ForEach-Object

} # End Update-InstructionsFile Function

    ###################### SCRIPT TUNING ###################### 

# > > > SCRIPT TUNING


$FileType_RegExFilter   = "(\.dll|\.json|\.vab|\.vaj|\.vam|\.vap|\.vmi|\.jpg|\.png|\.mp3|\.wav|\.ogg|\.m4a|\.webm|\.amc|\.assetbundle|\.scene|\.clist|\.cs|\.bvh)"

# Update $vamRoot with the base install path for VAM.exe
If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") } # don't use .\ for the root path for this script: it's kills path parsing above

$ScriptName            = "iHV_VerifyPaths"
$ScriptVersion         = "1.0.0"
$LogPath               = ($PSScriptRoot + "\_1a " + $ScriptName + ".csv")

$ScriptName | Out-File -FilePath $LogPath 
$ScriptVersion  | Out-File -FilePath $LogPath -Append
Get-Date -Format "yyyy/MM/dd HH:mm" | Out-File -FilePath $LogPath -Append


"""" + "Instruction" +""""+ ","+"""" + "TestedMissingFile" +""""+ ","+""""+"SourceFile"+"""" | Out-File -FilePath $LogPath

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