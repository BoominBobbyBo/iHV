# I Hate VARS - Remove VAR prefixes from Content files
#    - Processes .JSON and .VAP and .VAJ file types
#    - Processes "Custom\Atom\Person","Custom\Clothing","Custom\Hair","Custom\SubScene","Saves\Person","Saves\scene", "Saves\Pose"

Write-Host
Write-host ******************** START: REMOVE VAR PATHS ************************
Write-Host


Function Update-Files {

    Param (

        [String]
        $File_FullName
    )

        #write-host $ScriptName ":" $File_FullName

        # CONTENT FILES - Get the raw file content to update ----------------------------------------->
        $Instructions = [System.IO.File]::ReadAllLines($File_FullName) # .NET function (requires .NET) (Get-Content -raw $File_FullName)
        $blnWasTheFileChanged = $false

        # Global Changes
        If($Instructions -match "SELF:/"){$blnWasTheFileChanged = $true}
        $Instructions = $Instructions -Replace("SELF:/","")

        # RESOURCE PATHS
        # Update $Instructions\resource paths:
        $Instructions | Where-Object {$_ -match "/" -Or $_.indexOf("presetName") -ge 0} | ForEach-Object {
            $Line = $_ 
            #Write-Debug $Line

            # ---------------------------> Remove VAR Paths

                $NodeName = $Line.Substring(0, $Line.indexOf(":") + 3 ).Trim()
                $NodeValue = $Line.Replace($NodeName,"").Trim().Trim(",").Trim("""") 

                # Revmove VAR prefixes from JSON paths to Prefix resources     
                If($NodeName.indexOf("presetName") -ge 0 ){

                    #write-host PresetName found:::::$Line

                    If($NodeValue.indexOf(":") -gt 0){
                        $blnWasTheFileChanged = $true 
                    
                        $RemoveMe = $NodeValue.substring( 0, $NodeValue.indexOf(":") + 1 )
                        $Instructions = $Instructions -ireplace $NodeValue, ( $NodeValue.Replace($RemoveMe, "") )
                    }
                } 
                
                # Remove VAR prefixes from general JSON pathss
                if($NodeValue -match "/Custom"){
                    $blnWasTheFileChanged = $true

                    #write-host VAR Prefix found: $NodeValue.Trim()
                    $StartIndex = 1
                     
                    $EndIndex = $NodeValue.indexOf("/") + 1
                    #Write-host End::: $EndIndex
                    If($EndIndex -le 1){$LogEntry + " VAR prefix error: " + $Line + ", FILE:" + $File_FullName | Out-File -FilePath $LogPath -Appen}
                     
                    $CharIndex = $EndIndex - $StartIndex
                    $NewValue = $NodeValue.Remove(0, $EndIndex)
                    $NewLine = $Line.Replace($NodeValue, $NewValue)
                    #Write-Host NewLine $NewLine
            
                    $Instructions = $Instructions -ireplace [regex]::Escape($Line), $NewLine

                } # if($Line -match "/custom")

            # ---------------------------> End Remove VAR Paths
            
        } # $Instructions | ForEach-Object 

        # Final global fixes
        $Instructions = $Instructions -Replace("ustom/","Custom/") -Replace("cCustom/","Custom/") -Replace("CCustom/","Custom/")

        If( ($blnWasTheFileChanged -eq $true)){
            Write-Host $ScriptName FILE Updated: $File_FullName
            try{ [System.IO.File]::WriteAllLines($File_FullName, $Instructions) }
            catch{$LogEntry + " " + $_ + ", FILE:" + $File_FullName | Out-File -FilePath $LogPath -Append}
        }

} # End Update-Files Function


    ######################

If($vamRoot -eq $null){ $vamRoot = ($PSScriptRoot + "\") }

$ScriptName = "iHV_Util_RemoveVarPaths"
$ScriptVersion = "0.5"
$LogPath = ".\_2a " + $ScriptName + ".log"
$LogEntry = Get-Date -Format "yyyy/MM/dd HH:mm" 

    ######################

$arrTargetDirs = ("Custom\Atom\Person","Custom\Clothing","Custom\Hair","Custom\SubScene","Saves\Person","Saves\scene", "Saves\Pose")
#$arrTargetDirs = ("Saves\Person","Saves\scene", "Saves\Pose")
$arrTargetDirs |  ForEach-Object{

    Write-Host $ScriptName--Scanning: ($vamRoot + $_)

    Get-ChildItem -Path ($vamRoot + $_) -File -include *.json, *.vap, *.vaj -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        #write-host FN: $_.FullName
        Update-Files $_.FullName
        [GC]::Collect()
    }
    
} # forEach Dir



    Write-Host
    Write-host ******************** END: $ScriptName  ************************
    Write-Host