# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsCatalogItem
{
    <#
        .SYNOPSIS
            This function removes an item from the Report Server Catalog.
        
        .DESCRIPTION
            This function removes an item from the Report Server Catalog.
        
        .PARAMETER RsItem
            Specify the path of the catalog item to remove.
    
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
            Remove-RsCatalogItem -ReportServerUri http://localhost/ReportServer -RsItem /monthlyreports
   
            Description
            -----------
            Removes the monthlyreports folder, located directly at the root of the SSRS instance, and all objects below it.

        .EXAMPLE
            Get-RsCatalogItems -ReportServerUri http://localhost/ReportServer_SQL2016 -RsFolder '/SQL Server Performance Dashboard' |
            Out-GridView -PassThru |
            Remove-RsCatalogItem -ReportServerUri http://localhost/ReportServer_SQL2016
   
            Description
            -----------
            Gets a list of items from the SQL Server Performance Dashboard folder in a GridView from an SSRS instance names SQL2016 and allows the user to select items to be removed, after clicking "OK", only the items selected will be removed.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Alias('ItemPath', 'Path', 'RsFolder')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [ System.Object[] ]
        $RsItem,

        [string]
        $ReportServerUri,

        [Alias('ReportServerCredentials')]
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

        foreach ($item in $RsItem)
        {
            if ($PSCmdlet.ShouldProcess($item, "Delete the catalog item"))
            {
                try
                {
                    Write-Verbose "Deleting catalog item $item..."
                    if( $item -is [string] )
                    {
                        $Proxy.DeleteItem($item)
                    } 
                    else
                    {
                        $Proxy.DeleteItem($item.path)
                    }
                    Write-Verbose "Catalog item deleted successfully!"
                    
                }
                catch
                {
                    throw (New-Object System.Exception("Exception occurred while deleting catalog item '$item'! $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}
