function Invoke-UniversalUpdateTask {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        $ScriptPath = $(Resolve-Path "$PSScriptRoot\UpdateUniversal.ps1"),
        [string]
        $AppPoolName = 'UniversalAutomationAppPool',
        [string]
        $WebSiteName = 'PowerShellUniversal',
        $CurrentVersion,
        $CurrentRelease,
        $UpdateUri
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
        $FilteredParameters = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable'
        $UserParameterKeys = $PSBoundParameters.Keys.Where{ $PSItem -notin $FilteredParameters }
    }
    process {
        $StringBuilder = [System.Text.StringBuilder]::new()
        $UserParameterKeys.ForEach{
            $null = $StringBuilder.AppendFormat('-{0} {1} ', $PSItem, $PSBoundParameters.Item($PSItem))
        }
        $ScriptParamstring = $StringBuilder.ToString() 
        $Params = @{
            Execute          = "C:\Program Files\PowerShell\7\pwsh.exe"
            Argument         = ". `"$ScriptPath`" $ScriptParamstring"
            WorkingDirectory = ${UA.Repository.Global.Logs}
        }
        $Action = New-ScheduledTaskAction @Params

        Write-Output 'Created New Task Action:'
        Write-Output $Action
        
        $RunAt = (Get-Date).AddMinutes(1)

        # We use randomdelay to try to curb failed task initiation
        $Params = @{
            Once        = $True
            At          = $RunAt
            RandomDelay = $([timespan]::FromSeconds(30))
        }  
        $Trigger = New-ScheduledTaskTrigger @Params
        # Set the expiration time of the task to TEN MINUTES after starting...
        $Trigger.EndBoundary = $RunAt.AddMinutes(10).ToString('o')
        # Write-Output 'Created New Task Trigger:'
        # Write-Output $Trigger
        

        $Params = @{
            #UserID    = "NT AUTHORITY\\SYSTEM"
            UserID    = "LOCALSERVICE"
            LogonType = 'ServiceAccount'
            RunLevel  = 'Highest'
        }   
        $Principal = New-ScheduledTaskPrincipal @Params
        # Write-Output 'Created New Task Principal:'
        # Write-Output $Principal 
        
        $Params = @{
            ExecutionTimeLimit     = (New-TimeSpan -Minutes 5)
            #RestartCount           = 1
            #RestartInterval        = (New-TimeSpan -Minutes 3)
            DeleteExpiredTaskAfter = (New-TimeSpan -Minutes 5)
            Compatibility          = 'V1'
            
        }
        $Settings = New-ScheduledTaskSettingsSet @Params
        # Write-Output 'Created New Task Settings Set:'
        # Write-Output $Settings
        
        $TaskParams = @{
            Action    = $Action
            Principal = $Principal
            Trigger   = $Trigger
            Setting   = $Settings
            #TaskName  = 'UpdateUniversal'
        }    
        $Task = New-ScheduledTask @TaskParams
        # Write-Output 'Created New Task Params:'
        # Write-Output $Task
        
        #Testing User/Pass
        $RegParams = @{
            InputObject = $Task
            TaskName    = 'Update.PSUniversal'
        }
        
        if ($PSCmdlet.ShouldProcess("Target", "RegisterTask")) {
            Write-Output 'Registering Task...'
            Register-ScheduledTask @RegParams
            Write-Output 'Registered Task!'
        } else {
            $Task
        }
    }
    end {
        Write-Debug "Exit [$($PSCmdlet.MyInvocation.MyCommand.Name)]..."
    }
}
