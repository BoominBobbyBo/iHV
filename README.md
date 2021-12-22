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
