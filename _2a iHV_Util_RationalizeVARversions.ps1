# I Hate VARS - Rationalize VARs
#    - Rationalize set of VARs by version: i.e. move lessor versions off into a subfolder

Write-Host
Write-host ******************** START: iHV RATIONALIZE VARS ************************
Write-Host

    ###################### SCRIPT TUNING ###################### 

$blnMoveFiles           = $true  # set to false for testing 
$blnCheckArchives       = $true  # Check Zips RARs & 7zs - slows this down by 66%
$blnFixNames            = $true  # Remove anything that's in () from file names; remove .orig extensions; set to true only if extracting content from VARs later, or you may create access issues in game.

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") }

$ScriptName             = "iHV_Util_RationalizeVARs"
$ScriptVersion          = "1.0.2"
$LogPath                = ".\_2a " + $ScriptName + ".log"
$LogEntry               = Get-Date -Format "yyyy/MM/dd HH:mm" 

$RecycleBin             = ($vamRoot + "_2a iHV_VAR RecycleBin")  # SUBFOLDER NAME
$RatVarReportCSVpath    = ($RecycleBin + '\_iHV_RationalizedVarReport.csv')

    ######################               ###################### 



MD ($RecycleBin + "\") -ErrorAction SilentlyContinue
$arrVARs = @()
$arrArchives = @()
$FilesMovedCount = 0

""""+'Type'+""""+','+""""+ 'LagacyFileFullPath' +""""+","+""""+'Moved'+""""+","+""""+'MasterFileName'+"""" | Out-File -FilePath $RatVarReportCSVpath # Clears previous and creates the report file anew for each execution

#
#Optional: Fix file names to reduce errors below


If($blnFixNames -eq $true){

    # Remove (x) from file names - e.g. backup files or copies

    Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { ($_.Name -ilike "*.var" -or $_.Name -ilike "*.zip" -or $_.Name -ilike "*.rar" -or $_.Name -ilike "*.7z") -and $_.Name -inotlike "*Morph*"  -and $_.Name -ilike "*(*" -and $_.Name -ilike "*)*"  -and $_.FullName -inotlike ("*" + $RecycleBin + "*") } | Foreach-Object {
 
        Write-Host ---Fixing file name: $_.Name
 
        $FullName = $_.FullName
        $BeforePar = $_.FullName.Substring(0, $_.FullName.indexOf("(")).Trim()
        $AfterPar = $_.FullName.Replace( $_.FullName, $_.FullName.Substring($_.FullName.indexOf(")") + 1 ) ).Replace(" - Copy","").Trim()

        #write-host FN::: $FullName
        #write-host BP::: $BeforePar
        #write-host AP::: $AfterPar
        #Write-host Combo:: ($BeforePar + $AfterPar)

        $Error.Clear()

        Rename-Item $_ ($BeforePar + $AfterPar) -ErrorAction SilentlyContinue

        If($Error[0] -match "Cannot create a file when that file already exists."){ 

            If($blnMoveFiles -eq $true){ $_ | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue }
            """"+'DUP'+""""+','+""""+ $_.FullName +""""+","+""""+$blnMoveFiles+""""+","+""""+($BeforePar + $AfterPar)+"""" | Out-File -FilePath $RatVarReportCSVpath -Append
        
            Write-host .................................................
            Write-host ...Dup detected: $_.Name
            Write-host .................................................
        
            $FilesMovedCount = $FilesMovedCount + 1        
        }

    } # for each found with ()


    # Remove .orig from file names - e.g. unpacked VARs

    Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { ($_.Name -ilike "*.orig") -and $_.FullName -inotlike ("*" + $RecycleBin + "*") } | Foreach-Object {
 
        Write-Host ---Fixing: $_.Name

        $Error.Clear()

        Rename-Item $_ ($_ -ireplace ".orig", "")  -ErrorAction SilentlyContinue

        If($Error[0] -match "Cannot create a file when that file already exists."){ 

            If($blnMoveFiles -eq $true){ $_ | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue }
            """"+'DUP'+""""+','+""""+ $_.FullName +""""+","+""""+$blnMoveFiles+""""+","+""""+($_ -ireplace ".orig", "")+"""" | Out-File -FilePath $RatVarReportCSVpath -Append
        
            Write-host .................................................
            Write-host ...Dup detected: $_.Name
            Write-host .................................................
        
            $FilesMovedCount = $FilesMovedCount + 1        
        }

    } # for each found with .orig


    # Remove - Copy from file names

    Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { ($_.Name -ilike "* - Copy*") -and $_.FullName -inotlike ("*" + $RecycleBin + "*") } | Foreach-Object {
 
        Write-Host ---Fixing: $_.Name

        $Error.Clear()

        Rename-Item $_ ($_ -ireplace " - Copy", "")  -ErrorAction SilentlyContinue

        If($Error[0] -match "Cannot create a file when that file already exists."){ 

            If($blnMoveFiles -eq $true){ $_ | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue }
            """"+'DUP'+""""+','+""""+ $_.FullName +""""+","+""""+$blnMoveFiles+""""+","+""""+($_ -ireplace " - Copy", "")+"""" | Out-File -FilePath $RatVarReportCSVpath -Append
        
            Write-host .................................................
            Write-host ...Dup detected: $_.Name
            Write-host .................................................
        
            $FilesMovedCount = $FilesMovedCount + 1        
        }

    } # for each found with Copy

    <# Remove []

    Tabled: this change would orphan the .VAR file if the player isn't normalizing.

    Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { ($_.Name -match "\[" -and $_.Name -match "\]") -and $_.FullName -inotlike ("*" + $RecycleBin + "*") } | Foreach-Object {
       
        $NewName = $_.Name.Replace("[", "")
        $NewName = $NewName.Replace("]", "").Trim()

        $Error.Clear()
        
        Rename-Item $_ $NewName -ErrorAction SilentlyContinue

        If($Error[0] -match "Cannot create a file when that file already exists."){ 

            If($blnMoveFiles -eq $true){ $_ | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue }
            """"+'DUP'+""""+','+""""+ $_.FullName +""""+","+""""+$blnMoveFiles+""""+","+""""+$NewName+"""" | Out-File -FilePath $RatVarReportCSVpath -Append
        
            Write-host .................................................
            Write-host ...Dup detected: $_.Name
            Write-host .................................................
        
            $FilesMovedCount = $FilesMovedCount + 1        
        }
    
    } # Remove []
    #>

} # if fix names


# Build master table of VARs 
#  -exclude files with 'Morphs' in the name, which tend to be required regardless of the version, and files already moved into the RecycleBin folder

Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { $_.Name -ilike "*.var" -and $_.Name -inotlike "*Morph*"  -and $_.Name -inotlike "*(*" -and $_.Name -inotlike "*)*"  -and $_.FullName -inotlike ("*" + $RecycleBin + "*")  } | Foreach-Object {

    If( ($_.ToString().ToCharArray() -eq '.').count -ge 2 ){ # not all authors follow the convention; filter out those not formated like a VAR

        $FileName = $_.Name -iReplace(".var","")

        # Get the base name & version

        $BaseName = $FileName.Substring(0, $FileName.lastindexof(".") ).Trim() # remove the suffix, which is the version number
        $Version = $FileName.Replace($BaseName,"").Trim().Trim(".").Replace("_",".") # leave only the suffix, which is the version number

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

    Get-ChildItem -Path $vamRoot -File -Recurse -Force | Where-Object { ($_.Name -ilike "*.zip" -or $_.Name -ilike "*.rar*" -or $_.Name -ilike "*.7z*")  -and $_.Name -inotlike "*(*" -and $_.Name -inotlike "*)*"  -and $_.FullName -inotlike ("*" + $RecycleBin + "*")  } | Foreach-Object {

        $archiveName = $_.Name                                                                                                                        # e.g. BallerDev.BallerLook.2.zip

        If( ($_.ToString().ToCharArray() -eq '.').count -ge 2 ){                                                                                      # not all zips / rars hold VAR content; filter out those not formated like a VAR

            # Get the base name & version

            $BaseName = $archiveName.Substring(0, $archiveName.lastindexof(".") -2 ).Trim()                                                           # e.g. BallerDev.BallerLook
            $Version = $archiveName.Replace($BaseName,"").Trim().Trim(".").Replace(".zip","").Replace(".rar","").Replace(".7z","").Replace("_",".")   # e.g. 2
            $type = ($archiveName.Substring($archiveName.lastindexof(".") +1 ).Trim() )                                                               # e.g. zip

            # write-host archive: ::: $BaseName ::: $Version ::: $Type
            
            $tmp = New-Object -TypeName PSObject
            $tmp | Add-Member -Name 'BaseName' -MemberType Noteproperty -Value $BaseName
            $tmp | Add-Member -Name 'Version' -MemberType Noteproperty -Value $Version
            $tmp | Add-Member -Name 'FullName' -MemberType Noteproperty -Value $_.FullName
            $tmp | Add-Member -Name 'Type' -MemberType Noteproperty -Value $type

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

        If( $arrMovedFiles.Contains($Name) -eq $false ){ # if file has not been moved already

            Write-Host ---Rationalizing: ($Name + ".var")

            $arrVARs | ForEach-Object {

                $BaseName2 = $_.BaseName
                $Version2 = $_.Version
                $Name2 = $BaseName2 + "." + $Version2

                If( $BaseName -eq $BaseName2 ){
            
                    If( $Version -eq $Version2){}                          # -and $arrMovedFiles.Contains($Name2) -eq $false
                    ElseIf( [int]$Version -gt [int]$Version2 ){            # -and $arrMovedFiles.Contains($Name2) -eq $false 

                        If($blnMoveFiles -eq $true){ $_.FullName | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue }
                        """"+'VAR'+""""+','+""""+ $_.FullName +""""+","+""""+$blnMoveFiles+""""+","+""""+($Name + ".var")+"""" | Out-File -FilePath $RatVarReportCSVpath -Append
                    
                        Write-host .................................................
                        Write-host ...Legacy VAR detected: $Name2
                        Write-host .................................................
                    
                        $FilesMovedCount = $FilesMovedCount + 1
                        $arrMovedFiles += $Name2
                    
                    }

                } # If FileName = FileName

            } # Get-ChildItem files

        } # if arrMovedFiles does not contain Name

} # ForEach VAR in arrVARs



# Move archive files with the same name as VARs
# - assuming the archive files have the same content as the VAR

If($blnCheckArchives -eq $true){

    $arrArchives | Foreach-Object { 

        Write-Host ---Rationalizing: ($_.BaseName + "." + $_.Version + "." + $_.Type) 

        If($arrVARs.BaseName -contains $_.BaseName){ 
            
            If($blnMoveFiles -eq $true){ ($_.FullName ) | Move-Item -Destination ($RecycleBin) -Force -ErrorAction SilentlyContinue }
            """"+$_.Type+""""+','+""""+ $_.FullName +""""+","+""""+$blnMoveFiles+""""+","+""""+($_.BaseName + ".X.var")+"""" | Out-File -FilePath $RatVarReportCSVpath -Append
            
            Write-host .................................................
            Write-host ...Legacy Archive Detected: ($_.BaseName + "." +  $_.Version + "." + $_.Type)
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