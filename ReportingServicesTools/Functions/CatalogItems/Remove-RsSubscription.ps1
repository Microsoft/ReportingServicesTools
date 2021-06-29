# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsSubscription
{
    <#
        .SYNOPSIS
            This function removes subscription(s) associated to reports.

        .DESCRIPTION
            This function removes subscription(s) associated to reports.

        .PARAMETER Subscription
            An object returned from Get-RsSubscription that contains one or multiple SubscriptionId to remove. Do NOT specify $SubscriptionId parameter when specifying this parameter.

        .PARAMETER SubscriptionId
            The SubscriptionId to remove. Do NOT specify $Subscription parameter when specifying this parameter.

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
            Remove-RsSubscription -SubscriptionId 'b4694569-99a9-4cb3-bd59-7bf710b04a0c'

            Description
            -----------
            Removes the subscription with ID 'b4694569-99a9-4cb3-bd59-7bf710b04a0c' from Report Server located at http://localhost/reportserver

        .EXAMPLE
            Get-RsSubscription -ReportServerUri http://localhost/ReportServer_SQL2016 -Path '/path/to/my/report' |
            Out-GridView -PassThru |
            Remove-RsSubscription -ReportServerUri http://localhost/ReportServer_SQL2016

            Description
            -----------
            Gets all the subscriptions associated to the report located at '/path/to/my/report' found at the Report Server located at http://localhost/ReportServer_SQL2016 and displays them in a gridview. Then it tries to delete all the susbscriptions after prompting user for confirmation.

        .EXAMPLE
            $rsProxy = New-RsWebServiceyProxy -ReportServerUri http://localhost/ReportServer_SQL2016
            Get-RsSubscription -Proxy $rsProxy -Path '/path/to/my/report' |
            Out-GridView -PassThru |
            Remove-RsSubscription =Proxy $rsProxy

            Description
            -----------
            Gets all the subscriptions associated to the report located at '/path/to/my/report' found at the Report Server located at http://localhost/ReportServer_SQL2016 and displays them in a gridview. Then it tries to delete all the susbscriptions after prompting user for confirmation.
    #>

    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    param (
        [Parameter(ParameterSetName='MutipleSubscriptions', Mandatory=$True, ValueFromPipeline=$True)]
        [object[]]
        $Subscription,

        [Parameter(ParameterSetName='SingleSubscription', Mandatory=$True)]
        [string]
        $SubscriptionId,

        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy,

        [switch]
        $Force
    )
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    Process
    {
        if ($Force) {
            $ConfirmPreference = 'None'
        }

        if ([System.String]::IsNullOrEmpty($SubscriptionId)) 
        {
            foreach ($item in $Subscription)
            {
                if ($PSCmdlet.ShouldProcess($item.SubscriptionId, "Delete the subscription"))
                {
                    try 
                    {
                        Write-Verbose "Deleting subscription $($item.SubscriptionId) ..."
                        $Proxy.DeleteSubscription($item.SubscriptionId)
                        Write-Verbose "Subscription deleted successfully!"
                    }
                    catch 
                    {
                        throw (New-Object System.Exception("Exception occurred while deleting subscription id '$($item.SubscriptionId)'! $($_.Exception.Message)", $_.Exception))
                    }
                }
            }
        }
        else
        {
            if ($PSCmdlet.ShouldProcess($SubscriptionId, "Delete the subscription"))
            {
                try 
                {
                    Write-Verbose "Deleting subscription $SubscriptionId..."
                    $Proxy.DeleteSubscription($SubscriptionId)
                    Write-Verbose "Subscription deleted successfully!"
                }
                catch 
                {
                    throw (New-Object System.Exception("Exception occurred while deleting subscription id '$SubscriptionId'! $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}
