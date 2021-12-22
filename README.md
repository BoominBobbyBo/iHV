# iHV
I hate VARs. That is, Virt-a-mate (VAM) VAR files. Manage versions, manage duplicate content, and automate global preferences using open, editable Powershell scripts.

Utilities for File Management
Pick one or more. You don’t have to use all. Though, there are some dependencies between them.
The following script works only with VAR files
1.	RationalizeVarVersions.ps1 – remove previous versions of VAR files.
The following scripts don’t work with VAR files. Content must first be extracted from VARs for the scripts to work.
2.	RemoveVarPaths.ps1 –enable VAM to find resources that have been extracted/moved out VARs.
3.	NormalizeVAM4VR.ps1 – Big dog changes. See below.
Once one of the above scripts is run, you can use:
4.	CleanUp.ps1 – remove empty/duplicate items after running NormalizeVAM4VR.ps1 (see below)
5.	DupScenes.ps1 – move duplicates to a recycle bin.
6.	MoveUnusedFiles.ps1 – move “orphaned” resources that are not linked to a VAM instruction file
7.	NormalizeFolder.ps1 –flatten folders by moving content from subfolders into the parent folder
8.	VerifyPaths.ps1 – scans VAM instruction files for dependencies and tells you what’s missing
Requirements
-	Windows PowerShell must be installed and authorized for use on your device
-	PowerShell editor (e.g., Notepad+, I suggest Windows PowerShell ISE)
-	JSON editor (e.g., Notepad+, I suggest Sublime Text as some of the VAM files are large)
-	Zip file manager (e.g., WinRAR, 7Zip)
-	.NET must be installed for the Normalize scripts
-	Some knowledge about JSON structures and about VAR and VAM file architecture
-	Some knowledge about PowerShell – more if you wish to tune the scripts safely
Usage Notes
The table below provides a usage overview of the iHV scripts.
Script	What does it do?	How do I set it up?	Notes
_1a iHV_00_Launch.PS1	Launch scripts in sequence. 	1. Place the iHV scripts in the root of your staging folder.

2. Open the script for editing, update the list of scripts to launch according to your goals.	Optional script.

Recommended if you want to do more than 1 script on a regular basis.
_1a iHV_01_Normalize4VR.PS1	Remove VAR prefixes from all links to resource files. 

Normalizes content by moving it out of ‘idio’ and ‘idiot’ folders into conventional locations.

Updates JSON instruction files with the new, normalized paths.

Updates JSON instruction files with preferences for VR  	1. Place the iHV scripts in the root of your staging folder.

2. Optional: Update the exception array to account for your personal organization scheme, per the instructions found in the script’s comments section (i.e., script header).

3 Optional: Search for “SCRIPT TUNING” to adjust:
•	$blnNormalizeTextures = $false # Normalize texture files into a parent texture folder. Will impact game quality but increase stability.
•	$blnWatchForAllIdiots = $true # Expand the Idiots array to known offenders. Turn off when processing mature installs.
•	$Normalize = $true # Normalize files into a single instance
•	$blnVRprefs= $true # do or don’t deploy config changes for VR lighting, person behavior, etc.
•	$WorldScale= "1.20" # make the game scale smaller by 20% (works only if VRprefs is set to true)
•	$VoicePitch = "1.25" # raise the pitch of female character voices by 25% (works only if VRprefs is set to true)
	REQUIRED if not using the RemoveVarPaths.ps1 script

Create your organizational structure using exceptions for author and myfav folders.

Search the .PS1 file for “SCRIPT TUNING” to adjust values for optimum speed.
_1a iHV_Ut02 _CleanUp.PS1	Removes (deletes) unconventional files and folders.	Place the iHV scripts in the staging folder.

Review the nonstandard content to be sure you’re not deleting preferred content. Esp. if normalizing textures, the game quality may drop if you remove preferred resource files.	Optional script.

This is the only script that removes content from your hard drive disk.

You will want to review the script’s content beforehand, 
_1a iHV_03 _VerifyPaths.PS1	Reports on missing files (dependencies).	1. Place the iHV scripts in the staging folder.

2. Remove the VAR paths using either the RemoveVarPaths.ps1 or NormalizeContent.ps1 scripts.

3. Launch VerifyPaths.ps1

4. See the resultant .LOG file for details on resources that are not found where VAM expects them to be.	Optional script.

If using a staging folder to prepare your content (recommended), you will see many resources reported in the log as missing in the stage folder, even if you have them in your active VAM build.

Ignore, and focus on the files you would expect the VAR itself to provide. If unsure what to expect from the VAR, view the .VAR contents using something like 7Zip.
_1a iHV_Util_RemoveVarPaths.PS1	Removes VAR Path Prefixes from instruction files to enable content to work outside VAR files.

Use is this all you want to do is to enable extracted content to work. It will not normalize or rationalize any content.	Place the iHV scripts in the staging folder.	REQUIRED if not using the Normalize4VR.ps1 script

_2a iHV_Util_RemoveLegacyVars.ps1	Move old versions of VARs into a LegacyVARs folder for easy removal	Place the iHV scripts in the folder you wish to scan for VARs. E.g., C:\VAM\AddonPackages\.

The script will “recursively” iterate through subfolders.	Optional script. 

LagacyVARs folder is created within the folder where the script is launched.

Moph VARs are not removed. They are often required regardless of version.
_2a iHV_Util_NormalizeFolder.ps1	Consolidates content found in subfolders into the root folder.

Useful then you have a developer who nests content in subfolders, which can hide duplicate files and make it more tedious to review/manage.	Place the iHV scripts in the folder you wish to scan for subfolders . E.g., C:\VAM\Saves\Scene\Crazy3D\	Optional script.

Caution: content that has subfolders within subfolder may have “hard coded” dependencies on location. Do not use this script in this case.

E.g., use when content in subfolders is NOT related to other folders:
C:\VAM\Saves\Scenes\Crazy3D:
     \MyBabe-Blnd
     \MyBabe-Brn

Do not use when content is in a subfolder by design. E.g.
C:\VAM\Saves\Scenes\Sapuzex
      \Car Wash
           \Car Wash textures
           \Car Wash assets
_2a iHV_Util_MoveUnusedFiles.ps1	Moves files that are not linked to any look, scene, etc. 

Files are moved to an iHV_Unused folder, for you to disposition (i.e., restore, delete).

See the log for source location.	Place the iHV scripts in the folder you wish to scan for VARs. E.g., C:\VAM\

Set the following flags to suit your purpose:

$blnBuildLinkLibrary = $true
# set to false to skip the process of scanning all instruction files and leverage a previous LinksCSV.csv build 
# CAUTION: running as false without a previous and currents LinksCSV.csv  will cause all morphs, hair and cloths to be moved

$blnMoveMorphs = $true
# set to false to block action but still produce a log/report
$blnMoveHair = $true
# set to false to block action but still produce a log/report
$blnMoveClothing = $true
set to false to block action but still produce a log/report
$blnMoveTextures = $true
set to false to block action but still produce a log/report  
	Optional script.

CAUTION: running without

a)	Removing VAR paths
b)	LinksCSV.csv

Will remove all resources and neuter your VAM build. 

Backup and execute the above before launching this script. Proceed with caution.
_2a iHV_Util_DupScenes.ps1	Identifies duplicate instruction files in VAM\Custom and VAM\Saves.

Provides a CSV formatted report.	Place the iHV scripts in the root folder of the hierarchy you wish to scan for duplicates. E.g., C:\VAM\

Optionally, set $blnMoveDups = $true to move the second+ occurrences found into a RecycleBin.	Optional script.

Duplicates are identified when the file name and file size match. 

Possible duplicates are identified when both the name & size match.
