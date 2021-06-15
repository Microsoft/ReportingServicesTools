# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsRestCacheRefreshPlan
{
    <#
        .SYNOPSIS
            This function creates a new CacheRefreshPlan for the specified Power BI Report.

        .DESCRIPTION
            This function creates a new CacheRefreshPlan for the specified Power BI Report.

        .PARAMETER RsItem
            Specify the location of the Power BI Report.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your Power BI Report Server Instance.

        .PARAMETER Recurrence
            Specify the recurrence frequency

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.
            
        .PARAMETER Description
            Specify the description to be added to the CacheRefreshPlan.

        .EXAMPLE
            New-RsRestCacheRefreshPlan -RsItem /ReportCatalog

            Description
            -----------
            Creates a new CacheRefreshPlan for the ReportCatalog Power BI Report under "/" parent folder.

        .EXAMPLE
            New-RsRestCacheRefreshPlan -RsItem /ReportCatalog -Recurrence @{
            "DailyRecurrence" = @{
                "DaysInterval" = "1";
            }
        }

            Description
            -----------
            Creates a new CacheRefreshPlan for the ReportCatalog Power BI Report under "/" parent folder, with daily recurrence.

        .EXAMPLE
            New-RsRestCacheRefreshPlan -RsItem /ReportCatalog -StartDateTime "2021-01-07T06:00:00-08:00" -Recurrence @{
            "DailyRecurrence" = @{
                "DaysInterval" = "1";
            }
        }

            Description
            -----------
            Creates a new CacheRefreshPlan for the ReportCatalog Power BI Report under "/" parent folder, which will reoccur daily at 6 AM.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsItem,

        [Parameter(Mandatory = $False)]
        [string]
        $ReportPortalUri,

        [Parameter(Mandatory = $False)]
        [string]
        $Description,

        [Parameter(Mandatory = $False)]
        $Recurrence = @{
            "DailyRecurrence" = @{
                "DaysInterval" = "1";
            }
        },

        [Parameter(Mandatory = $False)]
        $StartDateTime = "2021-01-07T02:00:00-08:00",

        [Parameter(Mandatory = $False)]
        $EndDate = "1901-02-01T00:00:00-08:00",

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $refreshplansUri = $ReportPortalUri + "api/$RestApiVersion/CacheRefreshPlans"      
    }
    Process
    {
        try
        {
            if ((Get-RsRestItem -RsItem $RsItem -ReportPortalUri $ReportPortalUri -WebSession $WebSession -Credential $Credential -Verbose:$false).Type -ne 'PowerBIReport' )
            {
                Write-Warning "Unable to create a CacheRefreshPlan for $RsItem because it is not a Power BI report."
            }
            else
            {
                $payload = @{
                    "CatalogItemPath" = $RsItem;
                    "EventType" = "DataModelRefresh";
                    "Schedule" =  @{
                        "Definition" = @{
                            "StartDateTime" = $StartDateTime;
                            "EndDateSpecified" = $false;
                            "EndDate" =  $EndDate;
                            "Recurrence" = $recurrence;
                        }
                    }
                    "Description" = $Description;
                }

                $payloadJson = ConvertTo-Json $payload -Depth 15
                Write-Verbose "Payload: $payloadJson"

                $response = Invoke-RestMethod -Uri $refreshplansUri -Method Post -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -UseDefaultCredentials -Verbose:$false

                Write-Verbose "Schedule payload for $RsItem was created successfully!"
                return $response
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to create CacheRefreshPlan $($_.Exception.Message)", $_.Exception))
        }
    }
}
