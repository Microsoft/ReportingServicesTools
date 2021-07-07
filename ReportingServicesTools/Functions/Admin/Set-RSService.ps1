# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Set-RSService
{
    <#
        .SYNOPSIS
            This command configures service account for PBI and Reporting Server.

        .DESCRIPTION
            This command configures service account for PBI and Reporting Server.

        .PARAMETER ServiceAccount
            Specify the domain account reporting services will run under.
            Use the "ServiceAccount Domain\JonhDow" string to set/update a default value.

        .PARAMETER Password
            Specify the password to use when running Reporting Services Instance.
            This is an optional string as its not needed when using managed service accounts or gMSA.

        .PARAMETER ReportServerInstance
            Specify the name of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER ReportServerVersion
            Specify the version of the SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .EXAMPLE
            PS C:\> Set-RSService -ServiceAccount Domain\JohnDow -Password -ReportServerInstance SSRS -ReportServerVersion SQLServer2014

            PS C:\> Set-RSService -ServiceAccount Domain\JohnDow -Password "MySuperPassw0rd!" -ReportServerInstance SSRS -ReportServerVersion SQLServer2016

            This will set the User Account and password Reporting Services runs under.
    #>
    
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceAccount,

        [string]
        $Password,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion
        
    )
    
    try
    {
        #Get Server Instance
        Write-Verbose -Message "Get Server Instance"
        $RSObject = Get-WmiObject -namespace "root\Microsoft\SqlServer\ReportServer\RS_$ReportServerInstance\v$($ReportServerVersion.Value__)\Admin" `
        -class "MSReportServer_ConfigurationSetting"

        #set service account
        Write-Verbose -Message "Setting Service Account"
        $useBuiltInServiceAccount = $false
        $RSObject.SetWindowsServiceIdentity($useBuiltInServiceAccount, $builtInServiceAccount, $Password) | out-null

    }
    catch
    {
        throw (New-Object System.Exception("Failed to connect to instance $($_.Exception.Message)", $_.Exception))
    }
    
    if ($RSObject.HRESULT -ne 0)
    {
        throw "Failed to connect to instance, Errocode: $($RSObject.HRESULT)"
    }
}


