Automatic Updating in PowerShell 
=================================

This method of automatic updating for PSU works as of 1.5.12. This could stop working at any time, as it is solely based on the functionality of PSU, and the information currently available to me. It is entirely possible this method is outside of the scope of how [@Adam] at IronManSoftware (IMS) wants this software to be used and will kindly ask for it *not* to be used this way. Currently, this guide serves only to demonstrate how *I* have implemented this in my environment. 

 

>   **IMPORTANT​: USING AUTOMATIC UPDATES IN THIS WAY COULD INTRODUCE INSTABILITY TO YOUR ENVIRONMENT SHOULD AN UPDATE CONTAIN BREAKING CHANGES. FOLLOW THIS GUIDE AT YOUR OWN RISK!**

 

Environment 
------------

The following section describes how the environment was configured for *my* implementation, and what the various pieces do.

 

### Host

+-------------------------+---------------------+
| Operating System        | Windows Server 2019 |
+-------------------------+---------------------+
| RAM                     | 16GB                |
+-------------------------+---------------------+
| Processor(s)            | 6 Cores \@ 3GHz     |
+-------------------------+---------------------+
| PowerShell Environments | 7.1.x, 5.1.x        |
+-------------------------+---------------------+

 

### Environment Variables

These would be the path with the *default* installation. My installation looks a bit different. I set these variables in the environment so they can be accessed both within, and outside of PowerShell Universal. 

+------------------+--------------------------------------+
| UAPath           | C:\\ProgramData\\PowerShellUniversal |
+------------------+--------------------------------------+
| PSUPath          | C:\\ProgramData\\UniversalAutomation |
+------------------+--------------------------------------+
| PSUWebServerPath | C:\\inetpub\\PowerShellUniversal     |
+------------------+--------------------------------------+

 

### PSU Installation

In this example, PowerShell Universal is installed using the zip method. That is to say the OS Appropriate Version of the current release of the software will be fetched from the IMS release server. This particular guide is based on an **IIS HOSTED INSTALLATION. **It is possible to easily modify these files to make this work with other install methods, however I have not done so as of yet. I may (assuming enough interest) further expand my scripts and functions to allow for this. 

 

### Scripts

The following scripts are necessary to the functionality of this auto-update method. They can all be placed in the UA scripts directory - and this is the assumed configuration in this guide.

 

#### UpdateUniversal.ps1

This script will actually handle the updating of PSU. It logs all output to the log specified in the call. *By default, this log file is at \$ENV:UAPath\\PSUUpdateLog.txt.* What it does, in order:

1.  Stop the WebSite in IIS

2.  Stop the AppPool in IIS

3.  Download the (OS Appropriate) Release Archive to the local machine

4.  Backup the current installation

5.  Remove the current installation in the target install directory

6.  Un-zip the new release files into the target install directory

7.  Un-block all the files in the target install directory (recursively)

8.  Replace the appsettings/web.config files with the ones from **\$ENV:PSUWebServerPath **(It has always worked better for me this way. YMMV)

9.  Start the AppPool in IIS

10. Start the WebSite in IIS

 

>   **IMPORTANT: THIS SCRIPT CANNOT BE RUN FROM WITHIN POWERSHELL UNIVERSAL (UNIVERSAL AUTOMATION) AS IT WILL HALT THE PARENT PROCESS AND FAIL. THIS MUST BE CALLED FROM AN EXTERNAL SOURCE.**

 

#### Invoke-UpdateUniversalTask.ps1

This script contains a function that does what the name implies. It will create a **Windows **scheduled task that will call the UpdateUniversal.ps1 script exactly **one** minute after it is created. 

 

#### CheckForUniversalUpdates.ps1

This script should be placed in the scripts directory for Universal Automation. It will run on the schedule you give it (in schedules.ps1) and will fetch the current release information from the IMS Release Blobs. 

 

#### GetLatestUniversalRelease.ps1

This script should be placed in the scripts directory for Universal Automation. It will run on the schedule you give it (in schedules.ps1) and if the current version of PSU is older than the current release, it will create/invoke the update task in task scheduler. (I know this can be done with a trigger rather than two schedules, but for now this is how I’m doing it). 

 

### Config Files

These following are examples of how *I *have implemented my configurations in this example to make this all work. (well, it’s tweaked to follow the standard installation)

 

#### Scripts.ps1

These script entries contain the bases for declaring the scripts in UA.

 

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
New-PSUScript -Name "CheckForUniversalUpdates" -Description "Check for new releases of Universal. Update cached info." -Path "CheckForUniversalUpdates.ps1" -Environment "5.1.17763.1490" -ErrorAction "Continue" -InformationAction "Continue" -MaxHistory 5 
New-PSUScript -Name "GetLatestUniversalRelease" -Description "Update Universal if there is a new version." -Path "GetLatestUniversalRelease.ps1" -Environment "7.1.1" -ErrorAction "Continue" -InformationAction "Continue" -MaxHistory 5 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

#### Schedules.ps1

These schedules will run at 12:00am and 12:05am respectively... Customize as needed

 

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
New-UASchedule -Script "CheckForUniversalUpdates.ps1" -Credential 'UA.Credential.PSSrv' -Cron '0 5 0 * * ?' -Environment '5.1.17763.1490'
New-UASchedule -Script "GetLatestUniversalRelease.ps1" -Credential 'UA.Credential.PSSrv' -Cron '0 0 0 * * ?'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

More Information
----------------

If you found this guide useful or interesting and would like to see expanded functionality / deeper integration, please watch/star the repository on GitHub, and leave your comments on the IronmanSoftware community discussion for this guide. 

 

[GitHub - PowerShellUniversal.AutomaticUpdates](https://github.com/rbleattler/PowerShellUniversal.AutomaticUpdates)

 
