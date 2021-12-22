# iHV
I hate VARs. That is, Virt-A-Mate (VAM) VAR files. Manage versions, manage duplicate content, and automate global preferences using open, editable Powershell scripts.

Utilities for File Management

Pick one or more. You don’t have to use all. Though, there are some dependencies between them.

The following script works only with VAR files
1.	<b>RationalizeVarVersions.ps1</b> – remove previous versions of VAR files.

The following scripts don’t work with VAR files. Content must first be extracted from VARs for the scripts to work.

2.	<b>RemoveVarPaths.ps1</b> –enable VAM to find resources that have been extracted/moved out VARs.

3.	<b>NormalizeVAM4VR.ps1</b> – Big dog changes. See below.

Once one of the above scripts is run, you can use:

4.	<b>CleanUp.ps1</b> – remove empty/duplicate items after running NormalizeVAM4VR.ps1 (see below)

5.	<b>DupScenes.ps1</b> – move duplicates to a recycle bin.

6.	<b>MoveUnusedFiles.ps1</b> – move “orphaned” resources that are not linked to a VAM instruction file

7.	<b>NormalizeFolder.ps1</b> –flatten folders by moving content from subfolders into the parent folder

8.	<b>VerifyPaths.ps1</b> – scans VAM instruction files for dependencies and tells you what’s missing


Requirements
-	Windows PowerShell must be installed and authorized for use on your device
-	PowerShell editor (e.g., Notepad+, I suggest Windows PowerShell ISE)
-	JSON editor (e.g., Notepad+, I suggest Sublime Text as some of the VAM files are large)
-	Zip file manager (e.g., WinRAR, 7Zip)
-	.NET must be installed for the Normalize scripts
-	Some knowledge about JSON structures and about VAR and VAM file architecture
-	Some knowledge about PowerShell – more if you wish to tune the scripts safely
