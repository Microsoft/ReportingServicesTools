# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsRestCatalogItem
{
    <#
        .SYNOPSIS
            This script deletes a catalog item from the Report Server

        .DESCRIPTION
            This script deletes a catalog item from the Report Server

        .PARAMETER RsItem
            Specify the location of the item to be deleted.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Remove-RsRestCatalogItem -RsItem /MyReport

            Description
            -----------
            Deletes "/MyReport" catalog item from Report Server.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsItem,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
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
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems(Path='{0}')"
    }
    Process
    {
        if ($Force) {
            $ConfirmPreference = 'None'
        }

        if ($RsItem -eq '/')
        {
            throw "Root folder cannot be deleted!"
        }

        if ($PSCmdlet.ShouldProcess($RsItem, "Delete the item"))
        {
            try
            {
                Write-Verbose "Deleting item $RsItem..."
                $catalogItemsUri = [String]::Format($catalogItemsUri, $RsItem)
    
                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Delete -WebSession $WebSession -Credential $Credential -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Delete -WebSession $WebSession -UseDefaultCredentials -Verbose:$false | Out-Null
                }
    
                Write-Verbose "Catalog item $RsItem was deleted successfully!"
            }
            catch
            {
                throw (New-Object System.Exception("Failed to delete catalog item '$RsItem': $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}