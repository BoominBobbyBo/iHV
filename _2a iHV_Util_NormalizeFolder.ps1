<#
    I Hate VARS - Normalize Folder Content

    Consolidate all files, from subfolders into the root where the script is

    - Place the script in the root folder you wish to flatten, and launch
        - Files will be pulled out of the subfolders and into the root
        - Any file that stays in the subfolder is a duplicate (the script will not force a move - you will need to manage that manually)
        - Manually delete the script and all subfolders after the script closes to finalize

    v.1.0.0

#>

If( ( Test-Path -Path ($PSScriptRoot + "\Custom") ) -or ( Test-Path -Path ($PSScriptRoot + "\Atom") ) -or ( Test-Path -Path ($PSScriptRoot + "\Saves") )-or ( Test-Path -Path ($PSScriptRoot + "\Scene") )){
    Write-Host You launched this script in a core folder. It would cause great harm. 
    Wirte-Host Move the script into a developer folder and try again.
    Write-host
    Read-Host -Prompt "Hit Enter to close the script. Remember to backup!"
    Return   
}
Else{

    Get-ChildItem -Path ($PSScriptRoot) -File -Recurse | ForEach-Object {

        $_ | Move-Item -Destination $PSScriptRoot -ErrorAction SilentlyContinue

    } 

}
