# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Copy-RsSubscription
{
    <#
        .SYNOPSIS
            This script creates a new reporting subscription using an existing subscription.
        
        .DESCRIPTION
            This script creates a new reporting subscription based on the info of an existing subscription (retrieved using Get-RsSubscription).
            You can choose a specific report or pass a folder. When using a folder, the report must have the same name.
            NOTE: A new subscriptionId will be generated.

        .PARAMETER RsItem
            Specify the path to the destination report. Can't be used with -RsFolder parameter.

        .PARAMETER RsFolder
            Specify the folder where the destination reports exists. Can't be used with -RsItem parameter.

        .PARAMETER Subscription
            A object with all subscritpion configurations. The default output of Get-RsSubscription. You must piping it to this command.

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

        .PARAMETER SkipOwner
            Used to skip attempting to change the owner of a subscription to the owner being piped in. 

        .EXAMPLE
            Get-RsSubscription -ReportServerUri 'http://localhost/ReportServer_sql14' -RsItem '/path/to/my/oldReport' | Copy-RsSubscription -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsItem '/path/to/newReport'

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer_sql14 using current user's credentials get all subscriptions from report '/path/to/my/oldReport'
            and pipe the results to Copy-RsSubscription which will create a new subscription on report '/path/to/newReport' located at Report Server 'http://remote-machine:8080/reportserver_sql16'

        .EXAMPLE
            Get-RsSubscription -ReportServerUri 'http://localhost/ReportServer_sql14' -RsItem '/path/to/my/oldReport' | Copy-RsSubscription -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsFolder '/New Folder'

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer_sql14 using current user's credentials get all subscriptions from report '/path/to/my/oldReport'
            and pipe the results to Copy-RsSubscription which will create a new subscription on each report that exists with the same name on the destination folder '/New Folder' located at Report Server 'http://remote-machine:8080/reportserver_sql16'

        .EXAMPLE
            $paths = Get-RsCatalogItems -ReportServerUri 'http://localhost/ReportServer_sql14' -RsFolder /Origin | Where-Object TypeName -eq "Report" | Select-Object -ExpandProperty Path
            Get-RsSubscription -ReportServerUri 'http://localhost/ReportServer_sql14' RsItem $paths | Copy-RsSubscription -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsFolder '/New Folder'

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer_sql14 using current user's credentials get all the paths from all reports at '/Origin' folder.
            Then it uses the $paths variable to get all existing subscriptions and pipe the results to Copy-RsSubscription which will create a new subscription on each report that exists with the same name on the destination folder '/New Folder' located at Report Server 'http://remote-machine:8080/reportserver_sql16'

        .EXAMPLE
            Import-RsSubscriptionXml .\MySubscriptions.xml | Copy-RsSubscription -RsItem /Example/Report -SkipOwner $True

            Description
            -----------
            This command will import all the subscriptions contained in .\MySubscriptions.xml, recreate any SRSS specific properties
            and pipe the results to Copy-RsSubscription which will add them to the /Example/Report report.  The newly copied 
            subscriptions will have their owner set to the person running the command since the -SkipOwner parameter was supplied 
            with a value of $True.
            NOTE: You will need to supply the correct path for the -ReportServerUri parameter to both the Import-RsSubscriptionXml 
            & Copy-RsSubscription functions.  It has been omitted from this example for brevity.
    #>

    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy,

        [Alias('ReportPath','ItemPath','Path')]
        [Parameter(ParameterSetName='Report', Mandatory=$True)]
        [string]
        $RsItem,

        [Alias('Folder')]
        [Parameter(ParameterSetName='Folder', Mandatory=$True)]
        [string]
        $RsFolder,

        [Parameter(Mandatory = $True, ValueFromPipeline=$true)]
        [object[]]
        $Subscription,

        [parameter(Mandatory = $False)]
        [System.Boolean]
        $SkipOwner = $False,

        [switch]
        $Force
    )
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

        #region Input Validation
        $itemNullOrEmpty = [System.String]::IsNullOrEmpty($RsItem)
        $folderNullOrEmpty = [System.String]::IsNullOrEmpty($RsFolder)
        if ($itemNullOrEmpty -and $folderNullOrEmpty)
        {
            throw 'No folder or report path was specified! You need to specify -RsFolder or -RsItem.'
        }
        elseif (!$itemNullOrEmpty -and !$folderNullOrEmpty)
        {
            throw 'Both folder and report path were specified! Please specify either -RsFolder or -RsItem.'
        }
        #endregion Input Validation
    }
    Process
    {
        try
        {
            if ($Force) {
                $ConfirmPreference = 'None'
            }

            foreach ($sub in $Subscription)
            {
                if ($RsFolder)
                {
                    $RsItem = "$RsFolder/$($sub.Report)"
                }
                else 
                {
                    $RsFolder = (Split-Path $RsItem -Parent).Replace("\", "/")
                }

                Write-Verbose "Validating if target report exists..."
                if (((Get-RsFolderContent -Proxy $Proxy -RsFolder $RsFolder | Where-Object Path -eq $RsItem).Count) -eq 0)
                {
                    Write-Warning "Can't find the report $RsItem. Skipping."
                    Continue
                }

                if ($PSCmdlet.ShouldProcess($RsItem, "Creating new subscription"))
                {
                    Write-Verbose "Creating Subscription..."
                    if ($sub.IsDataDriven)
                    {
                        $subscriptionId = $Proxy.CreateDataDrivenSubscription($RsItem, $sub.DeliverySettings, $sub.DataRetrievalPlan, $sub.Description, $sub.EventType, $sub.MatchData, $sub.Values)
                    }
                    else
                    {
                        $subscriptionId = $Proxy.CreateSubscription($RsItem, $sub.DeliverySettings, $sub.Description, $sub.EventType, $sub.MatchData, $sub.Values)
                    }

                    [pscustomobject]@{
                        NewSubscriptionId = $subscriptionId
                        DestinationReport = $RsItem
                        OriginalReport    = $sub.Path
                    }
                    Write-Verbose "Subscription created successfully! Generated subscriptionId: $subscriptionId"
                    if ($SkipOwner -eq $False)
                    {
                        try {
                            $proxy.ChangeSubscriptionOwner($subscriptionId,$sub.owner)
                        }
                        catch {
                            Write-Warning "Unable to change owner of $($subscriptionId) after creating subscription because: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        catch
        {
            Write-Error "Error occurred while creating subscription $($sub.SubscriptionId) because: $($_.Exception.Message)"
        }
    }
}
