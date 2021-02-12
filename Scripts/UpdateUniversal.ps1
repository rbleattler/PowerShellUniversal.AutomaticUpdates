#UpdateUniversal.ps1
param(
    [Parameter(mandatory)]
    [string]
    $UpdateUri,
    [string]
    $AppPoolName = 'UniversalAutomationAppPool',
    [string]
    $WebSiteName = 'PowerShellUniversal',
    [Parameter(mandatory)]
    [version]
    $CurrentVersion,
    [Parameter(mandatory)]
    [version]
    $CurrentRelease,
    [string]
    $LogFile = "$PWD\PSUUpdateLog.txt"
)
begin {
    Write-Debug "Enter [$($PSCmdlet.MyInvocation.MyCommand.Name)]..."
    $PSBoundParameters.Keys.ForEach{
        if ($PSBoundParameters.PSItem -is [string]) {
            Write-Debug "$_ : $($PSBoundParameters.Item($_))"
        } else {
            Write-Debug "$_ : $($PSBoundParameters.Item($_).GetType())"
        }
    }
    Start-Transcript -Path $LogFile -Append -Force
}
process {
    
    Set-Location $Env:UAPath
    $InstallDirectory = '{0}\Installation' -f $Env:PSUPATH
    $BackupDirectory = '{0}\InstallationBackup' -f $Env:PSUPATH
    $DownloadDirectory = '{0}\Downloads' -f $Env:PSUPATH
    # $UniversalModule = ConvertFrom-Metadata (Join-Path $InstallDirectory -ChildPath 'universal.psd1')
    
    $Message = 'Newest Version ({0}) is newer than Installed Version ({1})...' -f $CurrentRelease, $CurrentVersion
    Write-Verbose -Message $Message
        
    $Message = 'Stopping WebSite ({0})...' -f $WebSiteName
    Write-Verbose -Message $Message
    Stop-Website -Name $WebSiteName -ErrorAction 'Continue'
        
    $Message = 'Stopping AppPool ({0})...' -f $AppPoolName
    Write-Verbose -Message $Message
    Stop-WebAppPool -Name $AppPoolName -ErrorAction 'Continue'
    
    $ArchiveFileName = $UpdateUri.Split('/')[-1]
    $TempFile = Join-Path -Path $DownloadDirectory -ChildPath $ArchiveFileName
    Invoke-WebRequest -Uri $UpdateUri -OutFile $TempFile
    $BackupName = 'PowerShellUniversal-{0}-{1}' -f $CurrentVersion, $(Get-Date -Format yyyyMMdd)
    $BackupPath = Join-Path -Path $BackupDirectory -ChildPath $BackupName
    New-Item -ItemType Directory -Path $BackupPath -Force
        
    $Message = 'Backing Up Installed Version to {0}...' -f $BackupPath
    Write-Verbose -Message $Message
    Copy-Item -Path $InstallDirectory -Destination $BackupPath -Recurse -Container -Force
        
    $Message = 'Removing Universal Version {0}...' -f $CurrentVersion
    Write-Verbose -Message $Message
    Remove-Item -Path $InstallDirectory -Recurse -Force -ErrorAction Continue
        
    $Message = 'Unpacking Universal Version {0}...' -f $CurrentRelease
    Write-Verbose -Message $Message
    Expand-Archive $TempFile -DestinationPath $InstallDirectory -Force
        
    $Message = 'Unblocking Universal Files...'
    Write-Verbose -Message $Message
    Get-ChildItem $InstallDirectory -Recurse | Unblock-File
        
    # Replace appsettings and web.config in installation directory. Otherwise server creates programdata and just falls apart. 
    $Message = 'Updating Configuration Files...'
    Write-Verbose -Message $Message
    $FilesToReplace = (Get-ChildItem -Path $InstallDirectory).Where{
        $PSItem.Name -like "*appsettings*" -or $PSItem.Name -like 'web.config'
    } 
    $ReplacementFiles = (Get-ChildItem -Path $Env:PSUWebServerPath).Where{
        $PSItem.Name -like "*appsettings*" -or $PSItem.Name -like 'web.config'
    } 
    $FilesToReplace.ForEach{
        $Message = 'Deleting {0}...' -f $PSItem
        Write-Verbose -Message $Message
        Remove-Item $PSItem -Force
        $Message = 'Deleted {0}...' -f $PSItem
        Write-Verbose -Message $Message
    }
    $ReplacementFiles.ForEach{
        $Message = 'Copying {0} to {1}...' -f $PSItem, $InstallDirectory
        Write-Verbose -Message $Message
        Copy-Item $PSItem -Destination $InstallDirectory -Force
        $Message = 'Finished Copying {0} to {1}...' -f $PSItem, $InstallDirectory
        Write-Verbose -Message $Message
    }
    $Message = 'Done Updating Configuration Files...'
    Write-Verbose -Message $Message
    #
        
    $Message = 'Starting AppPool ({0})...' -f $AppPoolName
    Write-Verbose -Message $Message
    Start-WebAppPool -Name $AppPoolName
        
    $Message = 'Starting WebSite ({0})...' -f $WebSiteName
    Write-Verbose -Message $Message
    Start-Website -Name $WebSiteName
        
    $Message = 'Finished Installing Universal Version {0}. Please check that everything is working as expected...' -f $CurrentRelease
    Write-Verbose -Message $Message
}
end {
    Stop-Transcript
    Write-Debug "Exit [$($PSCmdlet.MyInvocation.MyCommand.Name)]..."
}


