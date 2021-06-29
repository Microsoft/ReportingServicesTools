# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsRestItemDataModelParameter
{
    <#
        .SYNOPSIS
            This function updates data sources related to a catalog item from the Report Server.

        .DESCRIPTION
            This function updates data sources related to a catalog item from the Report Server. This is currently only applicable to Power BI Reports and only from ReportServer October/2020 or higher.

        .PARAMETER RsItem
            Specify the location of the catalog item whose data sources will be updated.

        .PARAMETER DataModelParameters
            Specify the data model parameters which were initially fetched via Get-RsRestItemDataModelParameters.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            $parameters = Get-RsRestItemDataModelParameters -RsItem '/MyPowerBIReport'
            $parameters[0].Value = 'NewValue'
            Set-RsRestItemDataModelParameter -RsItem '/MyPowerBIReport' -DataModelParameters $parameters

            Description
            -----------
            Updates data model parameters to the specified $parameters object. This example is only applicable for Power BI Reports.
        
        .LINK
            https://docs.microsoft.com/en-us/power-bi/report-server/connect-data-source-apis
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsItem,

        [Parameter(Mandatory = $True)]
        $DataModelParameters,

        [string]
        $ReportPortalUri,

        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession,

        [switch]
        $Force
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $dataModelParametersUri = $ReportPortalUri + "api/$RestApiVersion/PowerBIReports(Path='{0}')/DataModelParameters"
    }
    Process
    {
        if ($Force) {
            $ConfirmPreference = 'None'
        }

        try
        {          
            $dataModelParametersUri = [String]::Format($dataModelParametersUri, $RsItem)

            # Converting $DataModelParameters into array as PowerBIReport(...)/DataModelParameters expects data model parameters
            # to be in an array in the request body. If $DataModelParameters is already an array, this operation
            # combines $DataModelParameters array with an empty array, so result is still an array.
            $dataModelParametersArray = @($DataModelParameters)

            $payloadJson = ConvertTo-Json -InputObject $dataModelParametersArray -Depth 3

            Write-Verbose "Payload for parameters: $($payloadJson)"

            $method = "POST"

            if ($PSCmdlet.ShouldProcess($RsItem, "Update data model parameters"))
            {
                Write-Verbose "Updating data model parameters for $($RsItem)..."
                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $dataModelParametersUri -Method $method -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -WebSession $WebSession -Credential $Credential -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $dataModelParametersUri -Method $method -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -WebSession $WebSession -UseDefaultCredentials -Verbose:$false | Out-Null
                }
                Write-Verbose "Data model parameters were updated successfully!"
            }
        }
        catch
        {
            Write-Error "Error updating data model parameters for for '$RsItem': $($_.Exception.Message)"            
            throw (New-Object System.Exception("Failed to update data model parameters for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}
New-Alias -Name "Set-RsRestItemDataModelParameters" -Value Set-RsRestItemDataModelParameter -Scope Global