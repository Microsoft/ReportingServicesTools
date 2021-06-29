# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Backup-RsEncryptionKey
{
    <#
        .SYNOPSIS
            This script creates a back up of the SQL Server Reporting Services encryption key.
        
        .DESCRIPTION
            This script creates a back up of the encryption key for SQL Server Reporting Services. This key is needed in order to read all the encrypted content stored in the Reporting Services Catalog database.
        
        .PARAMETER Password
            Specify the password to be used for backing up the encryption key. This password will be required when restoring the encryption key.
        
        .PARAMETER KeyPath
            Specify the path to where the encryption key should be stored.
        
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
            Backup-RSEncryptionKey -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will back up the encryption key against default instance from SQL Server 2016 Reporting Services
        
        .EXAMPLE
            Backup-RSEncryptionKey -ReportServerInstance 'SQL2012' -ReportServerVersion '11' -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will back up the encryption key against named instance (SQL2012) from SQL Server 2012 Reporting Services
        
        .EXAMPLE
            Backup-RSEncryptionKey -ComputerName "sql2012a243" -Credential (Get-Credential) -ReportServerInstance 'SQL2012' -ReportServerVersion 'SQLServer2012' -Password 'Enter Your Password' -KeyPath 'C:\ReportingServices\Default.snk'
            Description
            -----------
            This command will back up the encryption key against named instance (SQL2012) from SQL Server 2012 Reporting Services.
            To do so, it will not use the default connection, but rather connect to the computer "sql2012a243", prompting the user for connection credentials.
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

        [Switch]
        $Force
    )
    
    if ($Force){
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Retrieve encryption key and create backup in $KeyPath"))
    {
        $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
        
        Write-Verbose "Retrieving encryption key..."
        $encryptionKeyResult = $rsWmiObject.BackupEncryptionKey($Password)
        
        if ($encryptionKeyResult.HRESULT -eq 0)
        {
            Write-Verbose "Retrieving encryption key... Success!"
        }
        else
        {
            throw "Failed to create backup of the encryption key. Errors: $($encryptionKeyResult.ExtendedErrors)"
        }
        
        try
        {
            Write-Verbose "Writing key to file..."
            [System.IO.File]::WriteAllBytes($KeyPath, $encryptionKeyResult.KeyFile)
            Write-Verbose "Writing key to file... Success!"
        }
        catch
        {
            throw
        }
    }
}
