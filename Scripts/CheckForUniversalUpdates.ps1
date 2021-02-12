#UpdateUniversal.ps1

# Import the Invoke-UpdateUniversalTask function.
. "$PSScriptRoot\Invoke-UpdateUniversalTask.ps1"

$UpdateUniversalScriptPath = "$PSScriptRoot\UpdateUniversal.ps1"

$CurrentRelease = Get-PSUCache -Key CurrentRelease
$CurrentReleaseUrl = Get-PSUCache -Key CurrentReleaseUrl
$CurrentVersion = Get-PSUCache -Key CurrentVersion
$CR = 'Current Release: {0}' -f $CurrentRelease
$CRU = 'Current Release URL: {0}' -f $CurrentReleaseUrl
$CV = 'Current Version: {0}' -f $CurrentVersion
Write-Output $CR 
Write-Output $CRU 
Write-Output $CV 

if ($CurrentRelease -gt $CurrentVersion) {
    Write-Output 'Creating Universal Update Task...'
    Invoke-UniversalUpdateTask -CurrentVersion $CurrentVersion -CurrentRelease $CurrentRelease -UpdateUri $CurrentReleaseUrl -ScriptPath $UpdateUniversalScriptPath -Verbose
} else {
    $Message = 'Newest Version ({0}) is is the same as Installed Version. No action necessary...' -f $CurrentRelease
    Write-Output $Message
}
