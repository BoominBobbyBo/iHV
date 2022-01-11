<# Launch iHV Scripts

Launch iHV scripts in sequence

WARNING: The below is intended to be used on specially curated content that has been extracted from VARs. Do not use on VARs.

Use to launch a sequence of iHV scripts, if you wish to run more than one
- adjust list below to your need

$vamRoot variable must reflect the staging or VAM root folder that you wish to target.
- Do not use ".\" or the Normalize script will fault 

v1.0.0

#>


Read-Host -Prompt '1. Backup you fools. 2. Execute iHV on staging content only (suggested).' 
Read-Host -Prompt 'Exit now if you have not completed step 1 and 2. (hit ENTER to continue)'

$vamRoot = ($PSScriptRoot + "\") # use the current folder as the root; example: C:\iHV_VAM\ (if staging) or C:\VAM\
$blnLaunched = $true # sends a queue to the scripts below not to prompt warnings before executing

$scriptList = @(
    $vamRoot + '_1a iHV_01_Normalize4VR'
    $vamRoot + '_1a iHV_02_Normalize4VR-CleanUp'
    $vamRoot + '_2a iHV_Util_MoveUnusedFiles'
    $vamRoot + '_1a iHV_03_VerifyPaths'
)

$scriptList | ForEach-Object { & $_ }