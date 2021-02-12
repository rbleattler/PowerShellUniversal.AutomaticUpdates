New-UASchedule -Script "CheckForUniversalUpdates.ps1" -Cron '0 5 0 * * ?' -Environment '5.1.17763.1490'
New-UASchedule -Script "GetLatestUniversalRelease.ps1" -Cron '0 0 0 * * ?'
