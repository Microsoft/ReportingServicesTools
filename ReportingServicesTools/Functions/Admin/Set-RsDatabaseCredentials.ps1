# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsDatabaseCredentials
{
    <#
        .SYNOPSIS
            This script configures the credentials used to connect to the database used by SQL Server Reporting Services.

        .DESCRIPTION
            This script configures the credentials used to connect to the database used by SQL Server Reporting Services. You must be an admin in RS and SQL Server in order to perform this operation successfully.

        .PARAMETER DatabaseCredentialType
            Indicate what type of credentials to use when connecting to the database.

        .PARAMETER DatabaseCredential
            Specify the credentials to use when connecting to the SQL Server.
            Note: This parameter will be ignored whenever DatabaseCredentialType is set to ServiceAccount!

        .PARAMETER IsRemoteDatabaseServer
            Specify this parameter when the database server is on a different machine than the machine Reporting Services is on.

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

        .PARAMETER QueryTimeout
            Specify how many seconds the query will be running before exit by timeout. Default value is 30.

        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType Windows -DatabaseCredential $myCredentials
            Description
            -----------
            This command will configure Reporting Services to connect to the database using Windows credentials ($myCredentials).

        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType SQL -DatabaseCredential $sqlCredentials
            Description
            -----------
            This command will configure Reporting Services to connect to the database using SQL credentials ($sqlCredentials).

        .EXAMPLE
            Set-RsDatabaseCredentials -DatabaseCredentialType ServiceAccount
            Description
            -----------
            This command will configure Reporting Services to connect to the database using Service Account credentials.
    #>
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Authentication')]
        [Microsoft.ReportingServicesTools.SqlServerAuthenticationType]
        $DatabaseCredentialType,

        [System.Management.Automation.PSCredential]
        $DatabaseCredential,

        [switch]
        $IsRemoteDatabaseServer,

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

        [int]
        $QueryTimeout = 30,

        [switch]
        $Force
    )

    if ($Force){
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Configure to use $DatabaseCredentialType authentication"))
    {
        $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters

        #region Validating authentication and normalizing credentials
        $username = ''
        $password = $null
        if ($DatabaseCredentialType -like 'serviceaccount')
        {
            $username = $rsWmiObject.WindowsServiceIdentityActual
            $password = ''
        }

        else
        {
            if ($DatabaseCredential -eq $null)
            {
                throw "No Database Credential specified! Database credential must be specified when configuring $DatabaseCredentialType authentication."
            }
            $username = $DatabaseCredential.UserName
            $password = $DatabaseCredential.GetNetworkCredential().Password
        }
        #endregion Validating authentication and normalizing credentials

        $databaseName = $rsWmiObject.DatabaseName
        $databaseServerName = $rsWmiObject.DatabaseServerName

        #region Configuring Database rights
        # Step 1 - Generate database rights script
        Write-Verbose "Generating database rights script..."
        $isWindowsAccount = ($DatabaseCredentialType -like "Windows") -or ($DatabaseCredentialType -like "ServiceAccount")
        $result = $rsWmiObject.GenerateDatabaseRightsScript($username, $databaseName, $IsRemoteDatabaseServer, $isWindowsAccount)
        if ($result.HRESULT -ne 0)
        {
            Write-Verbose "Generating database rights script... Failed!"
            throw "Failed to generate the database rights script from the report server using WMI. Errorcode: $($result.HRESULT)"
        }
        else
        {
            $SQLscript = $result.Script
            Write-Verbose "Generating database rights script... Complete!"
        }

        # Step 2 - Run Database rights script
        Write-Verbose "Executing database rights script..."
        try
        {
            Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLscript -QueryTimeout $QueryTimeout -ErrorAction Stop
        }
        catch
        {
            Write-Verbose "Executing database rights script... Failed!"
            throw
        }
        Write-Verbose "Executing database rights script... Complete!"
        #endregion Configuring Database rights

        #region Update Reporting Services database configuration
        # Step 3 - Update Reporting Services to connect to new database now
        Write-Verbose "Updating Reporting Services to connect to new database..."
        $result = $rsWmiObject.SetDatabaseConnection($DatabaseServerName, $databaseName, $DatabaseCredentialType.Value__, $username, $password)
        if ($result.HRESULT -ne 0)
        {
            Write-Verbose "Updating Reporting Services to connect to new database... Failed!"
            throw "Failed to update the reporting services to connect to the new database using WMI! Errorcode: $($result.HRESULT)"
        }
        else
        {
            Write-Verbose "Updating Reporting Services to connect to new database... Complete!"
        }
        #endregion Update Reporting Services database configuration
    }
}
