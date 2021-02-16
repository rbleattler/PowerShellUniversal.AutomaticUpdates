#GetUniversalRelease.ps1
param (
    [ValidateSet('Production', 'Nightly')]
    [string]
    $BuildType,
    [string]
    $InstallDirectory = ('{0}\Installation' -f $Env:PSUPATH)
)

switch ($BuildType) {
    'Nightly' {
        $BuildTypeKeyWord = 'universal-nightly'
    }
    Default {
        $BuildTypeKeyWord = 'universal'
        $NewestVersion = Invoke-RestMethod -Method Get -Uri $VersionUri
    }
}
$UniversaleReleaseBlobUri = 'https://imsreleases.blob.core.windows.net/{0}' -f $BuildTypeKeyWord
$UniversalListUri = '{0}?restype=container&comp=list' -f $UniversaleReleaseBlobUri
# This is only used for Production builds
$VersionUri = '{0}/production/version.txt' -f $UniversaleReleaseBlobUri
$UniversalModule = ConvertFrom-Metadata "$InstallDirectory\universal.psd1"

$Message = 'Setting Location to {0}...' -f $Env:UAPath
Write-Output $Message 
Set-Location $Env:UAPath
$Message = 'Setting Install Directory to {0}...' -f $InstallDirectory
Write-Output $Message 
if ($PSEdition -eq 'Core' -and -not $IsWindows) {
    if ($IsMacOs) {
        $InstallationType = 'osx-x64'
    } elseif ($IsLinux) {
        $InstallationType = 'linux-x64'
    }
} else {
    $InstallationType = 'win7-x64'
}

$Message = 'Getting ModuleVersion...'
Write-Output $Message 
$ModuleVersion = Get-PSUCache -Key CurrentVersion
if ([string]::IsNullOrWhiteSpace($ModuleVersion)) {
    Write-Output 'ModuleVersion is not currently set in cache...'
    $ModuleVersion = $UniversalModule.ModuleVersion
    $null = Set-PSUCache -Key CurrentVersion -Value $ModuleVersion
}
$Message = 'Current Module Version: {0}...' -f $ModuleVersion
Write-Output $Message 

$Message = 'Checking For New {0} Builds...' -f $BuildType
Write-Output $Message 
$Message = 'Getting Universal Release List...'
Write-Output $Message
$RawResponse = Invoke-WebRequest -Uri $UniversalListUri 
# There are some weird characters at the beginning of the xml in the response - this is necessary. If someone knows a better way... by all means...
$ReleaseXml = [xml]($RawResponse.Content[$RawResponse.Content.IndexOf('<')..($RawResponse.Content.Length - 1)] -join '')
$Message = 'Parsing XML...'
Write-Output $Message

$Releases = [System.Collections.Generic.List[Object]]::new()
$ReleaseXml.EnumerationResults.Blobs.Blob.ForEach{ 
    $Blob = $PSItem
    $Release = [pscustomobject]@{
        Name = $Blob.Name
        Url  = $Blob.Url
    } 
    $Properties = ([Newtonsoft.Json.JsonConvert]::SerializeXmlNode($Blob.Properties) | ConvertFrom-Json).Properties
    $Properties.psobject.properties.Name.ForEach{
        $Release | Add-Member -MemberType NoteProperty -Name $PSItem -Value $Properties.$PSItem 
    }
    $Release.'Last-Modified' = [datetime]$Release.'Last-Modified'
    $Releases.Add($Release)
}
$Message = 'Found {0} Releases...' -f $Releases.Count
Write-Output $Message
if ([string]::IsNullOrWhiteSpace($NewestVersion)) {
    $Newest = ($Releases.Where{ $PSItem.Name -like "*$InstallationType*zip" } | Sort-Object -Property 'Last-Modified' -Descending -Top 1)
    $NewestVersion = ($Newest.Url | Split-Path -Leaf).TrimStart('.Universal').TrimStart("$InstallationType.") | Split-Path -LeafBase
} else {
    $Newest = ($Releases.Where{ $PSItem.Name -like "*$NewestVersion*$InstallationType*zip" })
}
$Message = 'Newest Version: {0}' -f $NewestVersion
Write-Output $Message

$Message = 'Configuring Cache Entries...'
Write-Output $Message
Set-PSUCache -Key CurrentRelease -Value $NewestVersion
Set-PSUCache -Key CurrentReleaseUrl -Value $Newest.Url
$CurrentRelease = Get-PSUCache -Key CurrentRelease
$CurrentReleaseUrl = Get-PSUCache -Key CurrentReleaseUrl
$CurrentVersion = Get-PSUCache -Key CurrentVersion
$CR = 'Current Release: {0}' -f $CurrentRelease
$CRU = 'Current Release URI: {0}' -f $CurrentReleaseUrl
$CV = 'Current Version: {0}' -f $CurrentVersion
Write-Output $CR 
Write-Output $CRU 
Write-Output $CV 