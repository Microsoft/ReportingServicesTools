# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Revoke-RsSystemAccess
{
    <#
        .SYNOPSIS
            This script revokes access to SQL Server Reporting Services Instance from users/groups.
        
        .DESCRIPTION
            This script revokes all access on the SQL Server Reporting Services Instance located at the specified Report Server URI from the specified user/group.
        
        .PARAMETER Identity
            Specify the user or group name to revoke access from.
        
        .PARAMETER Strict
            Throw a terminating error when trying to revoke all permissions when there are none assigned to the target identity.
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.
            Use the "Connect-RsReportServer" function to set/update a default value.
        
        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.
        
        .EXAMPLE
            Revoke-RsSystemAccess -Identity 'johnd'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and then revoke all access for user 'johnd'.
        
        .EXAMPLE
            Revoke-RsSystemAccess -ReportServerUri 'http://localhost/reportserver_sql2012' -Identity 'johnd'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver_2012 using current user's credentials and then revoke all access for user 'johnd'.
        
        .EXAMPLE
            Revoke-RsSystemAccess -Credential 'CaptainAwesome' -Identity 'johnd'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials and then revoke all access for user 'johnd'.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Alias('UserOrGroupName')]
        [Parameter(Mandatory = $True)]
        [string]
        $Identity,
        
        [switch]
        $Strict,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy,

        [switch]
        $Force
    )

    if ($Force) {
        $ConfirmPreference = 'None'
    }
    
    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetweb -BoundParameters $PSBoundParameters), "Revoke all system access for $Identity"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        #region Retrieve policies and validate
        # retrieving existing policies for the current item
        try
        {
            Write-Verbose "Retrieving system policies..."
            $originalPolicies = $proxy.GetSystemPolicies()
            
            Write-Verbose "Policies retrieved: $($originalPolicies.Length)!"
        }
        catch
        {
            throw (New-Object System.Exception("Error retrieving existing system policies! $($_.Exception.Message)", $_.Exception))
        }
        
        # keeping only those policies where userOrGroupName is not explicitly mentioned
        $policyList = $originalPolicies | Where-Object { $_.GroupUserName -ne $Identity }
        
        if ($Strict -and (-not ($originalPolicies | Where-Object { $_.GroupUserName -eq $Identity })))
        {
            throw (New-Object System.Management.Automation.PSArgumentException("$Identity was not granted any rights on the Report Server!"))
        }
        #endregion Retrieve policies and validate
        
        #region updating policies on the system
        try
        {
            Write-Verbose "Revoking all access for $Identity..."
            $proxy.SetSystemPolicies($policyList)
            Write-Verbose "Revoked all access for $Identity!"
        }
        catch
        {
            throw (New-Object System.Exception("Error occurred while revoking all access from $Identity! $($_.Exception.Message)", $_.Exception))
        }
        #endregion updating policies on the system
    }
}
New-Alias -Name "Revoke-AccessToRs" -Value Revoke-RsSystemAccess -Scope Global
