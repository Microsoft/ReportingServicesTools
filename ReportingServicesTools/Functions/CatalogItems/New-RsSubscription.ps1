# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsSubscription
{
    <#
        .SYNOPSIS
            This script creates a new reporting subscription.

        .DESCRIPTION
            This script creates a new reporting subscription based on the parameters provided. NOTE: A new subscriptionId will be generated.

        .PARAMETER RsItem
            Specify the path to the destination report.

        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance. Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server. Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Proxy
            Report server proxy to use. Use "New-RsWebServiceProxy" to generate a proxy object for reuse. Useful when repeatedly having to connect to multiple different Report Server.

        .PARAMETER Description
            The description of the schedule.

        .PARAMETER EventType
            The event which triggers the schedule. Specify either 'TimedSubscription' or 'SnapshotUpdated'.
            Default: 'TimedSubscription'.

        .PARAMETER DeliveryMethod
            The delivery method. Specify either 'FileShare' or 'Email'.

        .PARAMETER Schedule
            Either a shared schedule ID or an XML block representing the desired schedule. You can use "New-RsScheduleXML" function to generate the required XML. 
            Required if -EventType 'TimedSubscription' has been used.

        .PARAMETER RenderFormat
            Specify the output format of the report. Must be one of 'PDF','MHTML','IMAGE','CSV','XML','EXCELOPENXML','ATOM','PPTX','WORDOPENXML'

        .PARAMETER To
            Use with -DeliveryMethod 'Email' to specify email addresses.

        .PARAMETER CC
            Use with -DeliveryMethod 'Email' to specify CC email addresses.

        .PARAMETER BCC
            Use with -DeliveryMethod 'Email' to specify BCC email addresses.

        .PARAMETER ReplyTo
            Use with -DeliveryMethod 'Email' to specify ReplyTo email address.

        .PARAMETER Subject
            Use with -DeliveryMethod 'Email' to specify the subject line of the email.

        .PARAMETER ExcludeReport
            Use with -DeliveryMethod 'Email' to exclude the report from the email.

        .PARAMETER ExcludeLink
            Use with -DeliveryMethod 'Email' to exclude a link back to the report from the email.

        .PARAMETER Priority
            Use with -DeliveryMethod 'Email' to set the priority with which the e-mail message is sent. Valid values are LOW, NORMAL, and HIGH. The default value is NORMAL.

        .PARAMETER Comment
            Use with -DeliveryMethod 'Email' to specify a comment in the email.

        .PARAMETER FileSharePath
            Use with -DeliveryMethod 'FileShare' to specify the destination location of the generated report. Must be a UNC path.

        .PARAMETER FileShareCredentials
            Use with -DeliveryMethod 'FileShare' to specify the credentials to use when writing file to fileshare. If no credentials are specified, then Execution Account or Service Account credentials are used.

        .PARAMETER FileName
            Use with -DeliveryMethod 'FileShare' to specify the filename of the generated report.

        .PARAMETER FileWriteMode
            Use with -DeliveryMethod 'FileShare' to specify the write behaviour when a file of the same name already exists. Valid values are NONE, OVERWRITE and AUTOINCREMENT.

        .EXAMPLE
            New-RsSubscription -RsItem '/path/to/my/Report' -Description 'Daily to folder' -RenderFormat 'PDF' -Schedule (New-RsScheduleXML -Daily 1) -DeliveryMethod 'FileShare' -FileSharePath '\\Myserver\folder' -FileName 'MyReport' -FileWriteMode Overwrite

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer using current user's credentials and create a subscription for report '/path/to/my/Report' that outputs and overwrites the report in PDF format to the specified file share path and name on a daily basis at the current time.

        .EXAMPLE
            New-RsSubscription -RsItem '/path/to/my/Report' -Description 'Daily to folder' -RenderFormat 'PDF' -Schedule (New-RsScheduleXML -Daily 1) -DeliveryMethod 'FileShare' -FileSharePath '\\Myserver\folder' -FileName 'MyReport' -FileWriteMode None

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer using current user's credentials and create a subscription for report '/path/to/my/Report' that outputs the report in PDF format to the specified file share path and name (as long as another file with same name does NOT exists) on a daily basis at the current time.

        .EXAMPLE
            New-RsSubscription -RsItem '/path/to/my/Report' -Description 'Daily to folder' -RenderFormat 'PDF' -Schedule (New-RsScheduleXML -Daily 1) -DeliveryMethod 'FileShare' -FileSharePath '\\Myserver\folder' -FileName 'MyReport' -FileWriteMode AutoIncrement

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer using current user's credentials and create a subscription for report '/path/to/my/Report' that outputs the report in PDF format to the specified file share path and name (to a new file) on a daily basis at the current time.

        .EXAMPLE
            New-RsSubscription -RsItem '/path/to/my/Report' -Description 'Daily to folder' -RenderFormat 'PDF' -Schedule (New-RsScheduleXML -Daily 1) -DeliveryMethod 'FileShare' -FileSharePath '\\Myserver\folder' -FileName 'MyReport' -FileWriteMode Overwrite -FileShareCredentials (Get-Credential)

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer using current user's credentials and create a subscription for report '/path/to/my/Report' that outputs and overwrites the report in PDF format to the specified file share path and name using the specified $FileShareCredentials on a daily basis at the current time.

        .EXAMPLE
            New-RsSubscription -RsItem '/path/to/my/Report' -Description 'Fortnightly by email' -RenderFormat 'WordOpenXML' -Schedule (New-RsScheduleXML -Weekly -Interval 2 -DaysOfWeek Saturday) -DeliveryMethod 'Email' -Subject 'Fortnightly report' -To 'test@someaddress.com' 

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer using current user's credentials and create a subscription for report '/path/to/my/Report' that outputs the report in Word format by email to the specified recipient every other Saturday at the current time.
        
        .EXAMPLE
            New-RsSubscription -RsItem '/path/to/my/Report' -Description "One minute from now" -RenderFormat 'MHTML' -Schedule (New-RsScheduleXML -Once -StartDate [datetime]::Now.AddMinutes(1)) -DeliveryMethod 'Email' -Subject 'One minute from now' -To 'Christopher.Wren@example.com' -Priority 'HIGH' -ExcludeLink -Comment 'Check this report out!'

            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/ReportServer using current user's credentials and create a subscription for report '/path/to/my/Report' that outputs the report in MHTML format by email to the specified recipient one minute from now, with HIGH priority, without a link back to the report and a comment saying 'Check this report out'

        .EXAMPLE
            New-RsSubscription -ReportServerUri 'http://myserver/ReportServer' ...

            Description
            -----------
            This command will establish a connection to the Report Server located at http://myserver/ReportServer using current user's credentials and create a subscription based on other parameters specified.

        .EXAMPLE
            $rsProxy = New-RsWebServiceProxy -ReportServerUri 'http://myserver/ReportServer'
            New-RsSubscription -Proxy $rsProxy ...

            Description
            -----------
            This command will establish a connection to the Report Server located at http://myserver/ReportServer using current user's credentials and create a subscription based on other parameters specified.
    #>
    
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName='FileShare')]
    param(
        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy,

        [Alias('ReportPath','ItemPath','Path')]
        [Parameter(Mandatory=$True)]
        [string]
        $RsItem,

        [string]
        $Description,

        [ValidateSet('TimedSubscription','SnapshotUpdated')] 
        [string]
        $EventType = 'TimedSubscription',

        [Parameter(Mandatory=$True)]
        [string]
        $Schedule,

        [Parameter(Mandatory=$False)]
        [AllowNull()]
        [hashtable]
        $Parameters,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Email','FileShare')] 
        [string]
        $DeliveryMethod,

        [Parameter(Mandatory=$True)]
        [ValidateSet('PDF','MHTML','IMAGE','CSV','XML','EXCELOPENXML','ATOM','PPTX','WORDOPENXML')]
        [string]
        $RenderFormat = 'PDF',

        [Parameter(ParameterSetName='Email',Mandatory=$True)]
        [string]
        $To,

        [Parameter(ParameterSetName='Email')]
        [string]
        $CC,

        [Parameter(ParameterSetName='Email')]
        [string]
        $BCC,

        [Parameter(ParameterSetName='Email')]
        [string]
        $ReplyTo,

        [Parameter(ParameterSetName='Email')]
        [switch]
        $ExcludeReport,

        [Parameter(ParameterSetName='Email',Mandatory=$True)]
        [string]
        $Subject,

        [Parameter(ParameterSetName='Email')]
        [string]
        $Comment,

        [Parameter(ParameterSetName='Email')]
        [switch]
        $ExcludeLink,

        [Parameter(ParameterSetName='Email')]
        [ValidateSet('LOW', 'NORMAL', 'HIGH')]
        [string]
        $Priority = 'NORMAL',

        [Alias('DestinationPath')]
        [Parameter(ParameterSetName='FileShare',Mandatory=$True)]
        [string]
        $FileSharePath,

        [Parameter(ParameterSetName='FileShare')]
        [System.Management.Automation.PSCredential]
        $FileShareCredentials,

        [Parameter(ParameterSetName='FileShare',Mandatory=$True)]
        [string]
        $Filename,

        [Parameter(ParameterSetName='FileShare')]
        [ValidateSet('None','Overwrite','AutoIncrement')]
        [string]
        $FileWriteMode = 'Overwrite',

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

        if ([System.String]::IsNullOrEmpty($RsItem))
        {
            throw 'No report path was specified! You need to specify -RsItem variable.'
        }

        try
        {
            Write-Verbose "Validating if target report exists..."
            if (((Get-RsFolderContent -Proxy $Proxy -RsFolder ((Split-Path $RsItem -Parent).Replace('\','/')) | Where-Object Path -eq $RsItem).Count) -eq 0)
            {
                Write-Warning "Can't find the report $RsItem. Skipping."
                Continue
            }

            $Namespace = $Proxy.GetType().NameSpace

            switch ($DeliveryMethod)
            {
                'Email'
                {
                    $ExtensionParams = @{
                        TO = $To
                        CC = $CC
                        BCC = $BCC
                        ReplyTo = $ReplyTo
                        IncludeReport = (-not $ExcludeReport)
                        IncludeLink = (-not $ExcludeLink)
                        Subject = $Subject
                        Comment = $Comment
                        RenderFormat = $RenderFormat
                        Priority = $Priority
                    }
                }
                'FileShare'
                {
                    $ExtensionParams = @{
                        PATH = $FileSharePath
                        FILENAME = $Filename
                        RENDER_FORMAT = $RenderFormat
                        WRITEMODE = $FileWriteMode
                    }

                    if ($FileShareCredentials -ne $null)
                    {
                        $ExtensionParams.USERNAME = $FileShareCredentials.UserName
                        $ExtensionParams.PASSWORD = $FileShareCredentials.GetNetworkCredential().Password
                        $ExtensionParams.DEFAULTCREDENTIALS = $false
                    }
                    else
                    {
                        $ExtensionParams.DEFAULTCREDENTIALS = $true
                    }
                }
            }

            $ExtensionParameterValues = @()

            $ExtensionParams.GetEnumerator() | ForEach-Object {
                $ExtensionParameterValues = $ExtensionParameterValues + (New-Object "$Namespace.ParameterValue" -Property @{ Name = $_.Name; Value = $_.Value })
            }

            $ExtensionSettings = New-Object "$Namespace.ExtensionSettings" -Property @{ Extension = "Report Server $DeliveryMethod"; ParameterValues = $ExtensionParameterValues }

            $MatchData = $Schedule

            # Transform $Parameters to $ParameterValues
            if ($Parameters -ne $null)
            {
                $parametersCopy = @{};
                # First, remove null-valued keys - At some point between SQL Server 2005 and 2016 (probably 2012), null-valued keys are no longer stored in the database.
                # null-valued keys are now represented in the SOAP API by not passing in the null-valued parameter.
                foreach ($key in $Parameters.Keys)
                {
                    if ($Parameters[$key] -ne $null)
                    {
                        $parametersCopy.Add($key, $Parameters[$key]);
                    }
                }

                $Parameters = $parametersCopy;

                # Similarly, if we pass in an empty collection, the SOAP API will also be unhappy!
                # Empty collections must be mapped to $null
                if ($Parameters.Count -ne 0)
                {
                    $ParameterValues = New-Object "$Namespace.ParameterValue[]" $Parameters.Count

                    $i = 0;
                    foreach ($key in $Parameters.Keys)
                    {
                        $tmpValue = $Parameters[$key]

                        # If a key's value is $null or whitespace, skip it. SSRS SOAP API does not like it;
                        # e.g., if a report parameter named 'date' was null,
                        # it would throw an error message "Default value or value provided for the report parameter 'date' is not a valid value."
                        if ([string]::IsNullOrWhiteSpace($tmpValue))
                        {
                            continue;
                        }
                        else
                        {
                            $tmpParameter = New-Object "$Namespace.ParameterValue" -Property @{ Name = $key; Value = $tmpValue }

                            $ParameterValues[$i] = $tmpParameter
                            $i++;
                        }
                    }
                }
                else
                {
                    $ParameterValues = $null;
                }
            }
            else
            {
                $ParameterValues = $null
            }

            if ($PSCmdlet.ShouldProcess($RsItem, "Creating new subscription"))
            {
                Write-Verbose "Creating Subscription..."
                $subscriptionId = $Proxy.CreateSubscription($RsItem, $ExtensionSettings, $Description, $EventType, $MatchData, $ParameterValues)

                [pscustomobject]@{
                    NewSubscriptionId = $subscriptionId
                }

                Write-Verbose "Subscription created successfully! Generated subscriptionId: $subscriptionId"
            }
        }
        catch
        {
            $ex = $_.Exception;
            $ErrorMessage = $ex.Message;
            throw (New-Object System.Exception("Exception occurred while creating subscription! ErrorMessage: [$ErrorMessage]", $Exception))
        }
    }
}
