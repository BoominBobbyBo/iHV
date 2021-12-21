# I Hate VARS - Rationalize VARs
#    - Rationalize set of VARs by version: i.e. move lessor versions off into a subfolder

Write-Host
Write-host ******************** START: iHV RATIONALIZE VARS ************************
Write-Host

    ###################### SCRIPT TUNING ###################### 

$blnMoveFiles = $true # set to false for testing 
$blnCheckArchives = $true # Check Zips and RARs - slows this down by 66%

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") }

$ScriptName = "iHV_Util_RationalizeVARs"
$ScriptVersion = "1.0.0"
$LogPath = ".\_2a " + $ScriptName + ".log"
$LogEntry = Get-Date -Format "yyyy/MM/dd HH:mm" 
$VAR_RecycleBin = ($vamRoot + "_2a iHV_VAR RecycleBin")  # SUBFOLDER NAME

    ######################               ###################### 



MD ($VAR_RecycleBin + "\") -ErrorAction SilentlyContinue
$arrVARs = @()
$arrArchives = @()
$FilesMovedCount = 0



# Build master table of VARs 
#  -exclude files with 'Morphs' in the name, which tend to be required regardless of the version, and files already moved into the RecycleBin folder

Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { $_.Name -ilike "*.var" -and $_.Name -inotlike "*Morph*"  -and $_.Name -inotlike "*(*" -and $_.Name -inotlike "*)*"  -and $_.FullName -inotlike ("*" + $VAR_RecycleBin + "*")  } | Foreach-Object {

    If( ($_.ToString().ToCharArray() -eq '.').count -ge 2 ){ # not all authors follow the convention; filter out those not formated like a VAR

        $VarName = $_.Name -iReplace(".var","")

        # Get the base name & version

        $BaseName = $VarName.Substring(0, $VarName.lastindexof(".") ).Trim() # remove the suffix, which is the version number
        $Version = $VarName.Replace($BaseName,"").Trim().Trim(".") # leave only the suffix, which is the version number

        $tmp = New-Object -TypeName PSObject
        $tmp | Add-Member -Name 'BaseName' -MemberType Noteproperty -Value $BaseName
        $tmp | Add-Member -Name 'Version' -MemberType Noteproperty -Value $Version
        $tmp | Add-Member -Name 'FullName' -MemberType Noteproperty -Value $_.FullName

        $arrVARs += $tmp

    } # if well formed VAR name
                
} # For each .VAR file in vamRoot

Write-host ---Found $arrVARs.Count VAR files


# Build master table of Archives 
# 

If($blnCheckArchives -eq $true){

    Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { ($_.Name -ilike "*.zip" -or $_.Name -ilike "*.rar*")  -and $_.Name -inotlike "*(*" -and $_.Name -inotlike "*)*"  -and $_.FullName -inotlike ("*" + $VAR_RecycleBin + "*")  } | Foreach-Object {

        $archiveName = $_.Name

        If( ($_.ToString().ToCharArray() -eq '.').count -ge 3 ){ # not all zips / rars hold VAR content; filter out those not formated like a VAR

            # Get the base name & version

            $BaseName = $archiveName.Substring(0, $archiveName.lastindexof(".") -1 ).Trim()
            $Version = $archiveName.Replace($BaseName,"").Trim().Trim(".").Replace(".var","").Trim().Trim(".")

            $tmp = New-Object -TypeName PSObject
            $tmp | Add-Member -Name 'BaseName' -MemberType Noteproperty -Value $BaseName
            $tmp | Add-Member -Name 'Version' -MemberType Noteproperty -Value $Version
            $tmp | Add-Member -Name 'FullName' -MemberType Noteproperty -Value $_.FullName

            $arrArchives += $tmp

        }
                
    } # For each .VAR file in vamRoot

    Write-host ---Found $arrArchives.Count Archive files
}


# For each VAR found, compare it's version to other files with the same name
# - move any file with the same name and a lower version into the LegacyVARs folder

$arrMovedFiles =@()
$arrVARs | ForEach-Object {

        $BaseName = $_.BaseName
        $Version = $_.Version
        $Name = $BaseName + "." + $Version

        Write-Host ---Rationalizing: $Name

        If( $arrMovedFiles.Contains($Name) -eq $false ){ # if file has not been moved already

            $arrVARs | ForEach-Object {

                $BaseName2 = $_.BaseName
                $Version2 = $_.Version
                $Name2 = $BaseName2 + "." + $Version2

                If( $BaseName -eq $BaseName2 ){
            
                    If( $Version -eq $Version2 -and $arrMovedFiles.Contains($Name2) -eq $false){}
                    ElseIf( [int]$Version -gt [int]$Version2 -and $arrMovedFiles.Contains($Name2) -eq $false){ 
                        If($blnMoveFiles -eq $true){ $_.FullName | Move-Item -Destination ($VAR_RecycleBin) -Force -ErrorAction SilentlyContinue }
                        Write-host .................................................
                        Write-host ...VAR moved: $Name2
                        Write-host .................................................
                        $FilesMovedCount = $FilesMovedCount + 1
                        $arrMovedFiles += $Name2
                    }

                } # If varName = varName

            } # Get-ChildItem files

        } # if arrMovedFiles does not contain Name

} # ForEach VAR in arrVARs



# Move archive files with the same name as VARs
# - assuming the archive files have the same content as the VAR

If($blnCheckArchives -eq $true){

    $arrArchives | Foreach-Object { 

        $Archive = $_.BaseName

        Write-Host ---Rationalizing: ($Archive + $_.Version) # Version has the file extension too, e.g. "2.zip" but it doesn't matter

        $VarArchive = ""
        $VarArchive = $arrArchives.BaseName |? {$arrVARs.BaseName -contains $_}

        If($VarArchive -ne ""){ 
            If($blnMoveFiles -eq $true){ ($_.FullName ) | Move-Item -Destination ($VAR_RecycleBin) -Force -ErrorAction SilentlyContinue }
            Write-host ...Archive  moved: ($_.BaseName + "." +  $_.Version)
            Write-host .................................................
            $FilesMovedCount = $FilesMovedCount + 1
        }

    }

}

   
    Write-Host
    Write-Host Moved:: ($FilesMovedCount) :: files.

    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host
    Read-Host -Prompt "Press Enter to exit"