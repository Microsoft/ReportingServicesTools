# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Set-RsDatabase
{
    <#
        .SYNOPSIS
            This script configures the database settings used by SQL Server Reporting Services.

        .DESCRIPTION
            This script configures SQL Server Reporting Services to either create and use a new RS database or use an existing RS database.
            You must be an admin in RS and SQL Server in order to perform this operation successfully.
            There are three phases to setup:
            1. Create the PBIRS database on the database server
            2. Grant the run-time user access to the PBIRS database - this user must exist before running this
            3. Configure the PowerBI Report Server to use the database and run-time credentials
            Your admin role on SQL Server can be one of:
            * The account under which you run this powershell (default)
            * A specific set of credentials for the SQL Server which has admin rights, specified via -AdminDatabaseCredential

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

        .PARAMETER DatabaseServerName
            Specify the database server name. (e.g. localhost, MyMachine\Sql2016, etc.)

        .PARAMETER IsRemoteDatabaseServer
            Specify this switch if the database server is on a different machine than the machine Reporting Services is running on.

        .PARAMETER Name
            Specify the name of the RS Database.

        .PARAMETER IsExistingDatabase
            Specify this switch if the database to use already exists, and prevent creation of the database.

        .PARAMETER DatabaseCredentialType
            Indicate what type of runtime credentials to use when connecting to the database: Windows, SQL, or Service Account.

        .PARAMETER DatabaseCredential
            Specify the runtime credentials to use when connecting to the SQL Server.
            This credential is used for *run-time* only. It is not used for initial database setup.
            Note: This parameter will be ignored whenever DatabaseCredentialType is set to Service Account!

        .PARAMETER AdminDatabaseCredentialType
            Indicate what type of admin setup credentials to use when connecting to the database: Windows (current user running this powershell) or SQL.
            Defaults to Windows.

        .PARAMETER AdminDatabaseCredential
            Specify the admin setup credentials to use when connecting to the SQL Server.
            This credential is used for *setup* only; it is not used for PowerBI Report Server during runtime.
            Note: This parameter will be ignored whenever AdminDatabaseCredentialType is set to Service Account!

        .PARAMETER QueryTimeout
            Specify how many seconds the query will be running before exit by timeout. Default value is 30.

        .EXAMPLE
            Set-RsDatabase -DatabaseServerName localhost -Name ReportServer -DatabaseCredentialType ServiceAccount
            Description
            -----------
            This command will create a new RS database (ReportServer) and configure Reporting Services to connect to it using Service Account credentials.

        .EXAMPLE
            Set-RsDatabase -DatabaseServerName localhost -Name ExistingReportServer -IsExistingDatabase -DatabaseCredentialType Windows -DatabaseCredential $myCredentials
            Description
            -----------
            This command will configure Reporting Services to connect to an existing RS database (ExistingReportServer) using Windows credentials ($myCredentials).
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $True)]
        [string]
        $DatabaseServerName,

        [switch]
        $IsRemoteDatabaseServer,

        [Parameter(Mandatory = $True)]
        [Alias('DatabaseName')]
        [string]
        $Name,

        [switch]
        $IsExistingDatabase,

        [Parameter(Mandatory = $true)]
        [Alias('Authentication')]
        [Microsoft.ReportingServicesTools.SqlServerAuthenticationType]
        $DatabaseCredentialType,

        [System.Management.Automation.PSCredential]
        $DatabaseCredential,

        [Microsoft.ReportingServicesTools.SqlServerAuthenticationType]
        $AdminDatabaseCredentialType,

        [System.Management.Automation.PSCredential]
        $AdminDatabaseCredential,

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

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Configure to use $DatabaseServerName as database, using $DatabaseCredentialType runtime authentication and $AdminDatabaseCredentialType setup authentication"))
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

        #region Validating admin authentication and normalizing credentials
        $adminUsername = ''
        $adminPassword = $null

        # default is Windows
        $isSQLAdminAccount = ($AdminDatabaseCredentialType -like "SQL")

        # we do not allow service account - only Windows and SQL
        if ($AdminDatabaseCredentialType -like 'serviceaccount')
        {
            throw "Can only use Admin Database Credentials Type of 'Windows' or 'SQL'"
        }

        # must have credentials passed
        if ($isSQLAdminAccount)
        {
            if ($AdminDatabaseCredential -eq $null)
            {
                throw "No Admin Database Credential specified! Admin Database credential must be specified when configuring $AdminDatabaseCredentialType authentication."
            }
            $adminUsername = $AdminDatabaseCredential.UserName
            $adminPassword = $AdminDatabaseCredential.GetNetworkCredential().Password
        }
        #endregion Validating admin authentication and normalizing credentials


        #region Create Database if necessary
        if (-not $IsExistingDatabase)
        {
            # Step 1 - Generate Database Script
            Write-Verbose "Generating database creation script..."
            $EnglishLocaleId = 1033
            $IsSharePointMode = $false
            $result = $rsWmiObject.GenerateDatabaseCreationScript($Name, $EnglishLocaleId, $IsSharePointMode)
            if ($result.HRESULT -ne 0)
            {
                Write-Verbose "Generating database creation script... Failed!"
                throw "Failed to generate the database creation script from the report server using WMI. Errorcode: $($result.HRESULT)"
            }
            else
            {
                $SQLScript = $result.Script
                Write-Verbose "Generating database creation script... Complete!"
            }

            # Step 2 - Run Database creation script
            Write-Verbose "Executing database creation script..."
            try
            {
                if ($isSQLAdminAccount)
                {
                    Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -QueryTimeout $QueryTimeout -ErrorAction Stop -Username $adminUsername -Password $adminPassword
                }
                else
                {
                    Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -QueryTimeout $QueryTimeout -ErrorAction Stop
                }
            }
            catch
            {
                Write-Verbose "Executing database creation script... Failed!"
                throw
            }
            Write-Verbose "Executing database creation script... Complete!"
        }
        #endregion Create Database if necessary

        #region Configuring Database rights
        # Step 3 - Generate database rights script
        Write-Verbose "Generating database rights script..."
        $isWindowsAccount = ($DatabaseCredentialType -like "Windows") -or ($DatabaseCredentialType -like "ServiceAccount")
        $result = $rsWmiObject.GenerateDatabaseRightsScript($username, $Name, $IsRemoteDatabaseServer, $isWindowsAccount)
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

        # Step 4 - Run Database rights script
        Write-Verbose "Executing database rights script..."
        try
        {
            if ($isSQLAdminAccount)
            {
                Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -QueryTimeout $QueryTimeout -ErrorAction Stop -Username $adminUsername -Password $adminPassword
            }
            else
            {
                Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -QueryTimeout $QueryTimeout -ErrorAction Stop
            }
        }
        catch
        {
            Write-Verbose "Executing database rights script... Failed!"
            throw
        }
        Write-Verbose "Executing database rights script... Complete!"
        #endregion Configuring Database rights

        #region Update Reporting Services database configuration
        # Step 5 - Update Reporting Services to connect to new database now
        Write-Verbose "Updating Reporting Services to connect to new database..."
        $result = $rsWmiObject.SetDatabaseConnection($DatabaseServerName, $Name, $DatabaseCredentialType.Value__, $username, $password)
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
