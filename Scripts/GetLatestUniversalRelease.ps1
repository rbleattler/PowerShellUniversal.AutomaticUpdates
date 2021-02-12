#GetUniversalRelease.ps1

$Message = 'Setting Location to {0}...' -f $Env:UAPath
Write-Output $Message 
Set-Location $Env:UAPath
$Message = 'Setting Install Directory to {0}\Installation...' -f $Env:PSUPath
Write-Output $Message 
$InstallDirectory = '{0}\Installation' -f $Env:PSUPATH
$UniversalModule = ConvertFrom-Metadata "$InstallDirectory\universal.psd1"
$UniversalListUri = 'https://imsreleases.blob.core.windows.net/universal?restype=container&comp=list'
if ($PSEdition -eq 'Core') {
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

$Message = 'Checking For Updates to Universal ({0})...' -f $ModuleVersion
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
$Newest = ($Releases.Where{ $PSItem.Name -like "*$InstallationType*zip" } | Sort-Object -Property 'Last-Modified' -Descending -Top 1)
$NewestVersion = ($Newest.Url | Split-Path -Leaf).TrimStart('.Universal').TrimStart("$InstallationType.") | Split-Path -LeafBase
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
$CRU = 'Current Release: {0}' -f $CurrentReleaseUrl
$CV = 'Current Version: {0}' -f $CurrentVersion
Write-Output $CR 
Write-Output $CRU 
Write-Output $CV 