# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Restore-RSEncryptionKey
{
    <#
        .SYNOPSIS
            This script restores the SQL Server Reporting Services encryption key.

        .DESCRIPTION
            This script restores encryption key for SQL Server Reporting Services. This key is needed in order to read all the encrypted content stored in the Reporting Services Catalog database.

        .PARAMETER Password
            Specify the password that was used when the encryption key was backed up.

        .PARAMETER KeyPath
            Specify the path to where the encryption key is stored.

        .PARAMETER ReportServerInstance
            Specify the name of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER ReportServerVersion
            Specify the version of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER ComputerName
            The Report Server to target.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .EXAMPLE
            Restore-RSEncryptionKey -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will restore the encryption key to the default instance from SQL Server 2016 Reporting Services

        .EXAMPLE
            Restore-RSEncryptionKey -ReportServerInstance 'SQL2012' -ReportServerVersion '11' -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will restore the encryption key to the named instance (SQL2012) from SQL Server 2012 Reporting Services
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $True)]
        [string]
        $Password,

        [Parameter(Mandatory = $True)]
        [string]
        $KeyPath,

        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,

        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,

        [string]
        $ComputerName,

        [System.Management.Automation.PSCredential]
        $Credential,

        [switch]
        $Force
    )

    if ($Force){
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Restore encryptionkey from file $KeyPath"))
    {
        $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters

        $KeyPath = Resolve-Path $KeyPath

        $reportServerService = 'ReportServer'

        if ($rsWmiObject.InstanceName -ne "MSSQLSERVER")
        {
            if ($rsWmiObject.InstanceName -eq "PBIRS")
            {
                $reportServerService = 'PowerBIReportServer'
            }
            elseif ($rsWmiObject.InstanceName -eq "SSRS")
            {
                $reportServerService = 'SQLServerReportingServices'
            }
            else
            {
                $reportServerService = $reportServerService + '$' + $rsWmiObject.InstanceName
            }
        }

        Write-Verbose "Checking if key file path is valid..."
        if (-not (Test-Path $KeyPath))
        {
            throw "No key was found at the specified location: $path"
        }

        try
        {
            $keyBytes = [System.IO.File]::ReadAllBytes($KeyPath)
        }
        catch
        {
            throw
        }

        Write-Verbose "Restoring encryption key..."
        $restoreKeyResult = $rsWmiObject.RestoreEncryptionKey($keyBytes, $keyBytes.Length, $Password)

        if ($restoreKeyResult.HRESULT -eq 0)
        {
            Write-Verbose "Success!"
        }
        else
        {
            throw "Failed to restore the encryption key! Errors: $($restoreKeyResult.ExtendedErrors)"
        }

        try
        {
            # Restarting the Reporting Services Windows service requires a different method if a credential is passed because
            # Get-Service does not have the ability to connect to a remote system with an alternate credential.
            if ($PSBoundParameters.ContainsKey('Credential'))
            {
                $getServiceParams = @{
                    Class        = 'Win32_Service'
                    Filter       = "Name = '$reportServerService'"
                    ComputerName = $rsWmiObject.PSComputerName
                    Credential   = $Credential
                }
                $service = Get-WmiObject @getServiceParams

                Write-Verbose "Stopping Reporting Services Service... $reportServerService"
                $null = $service.StopService()
                do {
                    $service = Get-WmiObject @getServiceParams
                    Start-Sleep -Seconds 1
                } until ($service.State -eq 'Stopped')

                Write-Verbose "Starting Reporting Services Service... $reportServerService"
                $null = $service.StartService()
                do {
                    $service = Get-WmiObject @getServiceParams
                    Start-Sleep -Seconds 1
                } until ($service.State -eq 'Running')
            }
            else
            {
                $service = Get-Service -Name $reportServerService -ComputerName $rsWmiObject.PSComputerName -ErrorAction Stop
                Write-Verbose "Stopping Reporting Services Service... $reportServerService"
                $service.Stop()
                $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped)

                Write-Verbose "Starting Reporting Services Service... $reportServerService"
                $service.Start()
                $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running)
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to restart Report Server database service. Manually restart it for the change to take effect! $($_.Exception.Message)", $_.Exception))
        }
    }
}
