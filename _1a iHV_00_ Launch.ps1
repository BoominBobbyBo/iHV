<# Launch iHV Scripts

Launch iHV scripts in sequence

Use to launch a sequence of iHV scripts, if you wish to run more than one
- adjust to you need

$vamRoot variable must reflect the staging or VAM root folder that you wish to target.
- Do not use ".\" or the Normalize script will fault 

#>

$vamRoot = ($PSScriptRoot + "\")

$scriptList = @(
    $vamRoot + '_1a iHV_01_Normalize4VR.ps1'
    #$vamRoot + '_1a iHV_Util_CleanUp.ps1'
    $vamRoot + '_1a iHV_Util_VerifyPaths.ps1'

)

$scriptList | ForEach-Object { & $_ }