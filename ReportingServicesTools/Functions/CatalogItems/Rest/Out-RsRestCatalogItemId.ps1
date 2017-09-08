# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Out-RsRestCatalogItemId
{
    <#
        .SYNOPSIS
            This is a helper function that helps download and write catalog item to disk (using REST endpoint). It is for SQL Server Reporting Service 2016 and later.
        
        .DESCRIPTION
            This is a helper function that helps download and write catalog item to disk (using REST endpoint). It is for SQL Server Reporting Service 2016 and later.
        
        .PARAMETER RsItemInfo
            OData Catalog Item object returned from REST endpoint
        
        .PARAMETER Destination
            Folder to download catalog item to.
        
        .PARAMETER ApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v1.0". 
            NOTE: v1.0 of REST Endpoint is not supported by Microsoft.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.
        
        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        $RsItemInfo,
        
        [ValidateScript({ Test-Path $_ -PathType Container})]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,

        [ValidateSet("v1.0")]
        [string]
        $ApiVersion = "v1.0",
        
        [string]
        $ReportPortalUri,
        
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
        $catalogItemContentApi = $ReportPortalUri + "api/$ApiVersion/CatalogItems({0})/Content/`$value"
        $DestinationFullPath = Convert-Path $Destination

        # basic validation of RsItemInfo by checking properties that would be defined on a valid RsItemInfo object
        if ($RsItemInfo.Id -eq $null -or
            $RsItemInfo.Name -eq $null -or
            $RsItemInfo.Type -eq $null)
        {
            throw "Invalid object specified for parameter: RsItemInfo!"
        }
    }

    Process
    {
        if ($RsItemInfo.Type -ne 'MobileReport')
        {
            $itemId = $RsItemInfo.Id
            $fileName = $RsItemInfo.Name + (Get-FileExtension -TypeName $RsItemInfo.Type)
        }
        else
        {
            $packageIdProperty = $RsItemInfo.Properties | Where-Object { $_.Name -eq 'PackageId' }
            if ($packageIdProperty -ne $null)
            {
                $itemId = $packageIdProperty.Value
            }
            else
            {
                throw "Unable to determine Id for $($RsItemInfo.Name)!"
            }

            $packageNameProperty = $RsItemInfo.Properties | Where-Object { $_.Name -eq 'PackageName' }
            if ($packageNameProperty -ne $null)
            {
                $fileName = $packageNameProperty.Value
            }
            else
            {
                $fileName = $RsItemInfo.Name + '.rsmobile'
            }
        }

        try
        {
            Write-Verbose "Downloading item content from server..."
            $url = [string]::Format($catalogItemContentApi, $itemId)
            if ($Credential -ne $null)
            {
                $response = Invoke-WebRequest -Uri $url -Method Get -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-WebRequest -Uri $url -Method Get -UseDefaultCredentials -Verbose:$false
            }
        }
        catch
        {
            throw (New-Object System.Exception("Error while downloading $($RsItemInfo.Name)! Exception: $($_.Exception.Message)", $_.Exception))
        }

        Write-Verbose "Writing content to $destinationFilePath..."
        $destinationFilePath = Join-Path -Path $DestinationFullPath -ChildPath $fileName
        [System.IO.File]::WriteAllBytes($destinationFilePath, $response.Content)
        Write-Verbose "$($RsItemInfo.Path) was downloaded to $destinationFilePath successfully!"
    }
}

