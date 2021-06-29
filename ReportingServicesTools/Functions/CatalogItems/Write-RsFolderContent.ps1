# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Write-RsFolderContent
{
    <#
        .SYNOPSIS
            Uploads all items in a folder on disk to a report server.

        .DESCRIPTION
            Uploads all items in a folder on disk to a report server.
            Currently, we are only supporting Report, DataSource, DataSet and jpg/png for uploads

        .PARAMETER Recurse
            A description of the Recurse parameter.

        .PARAMETER Path
            Path to folder which contains items to upload on disk.

        .PARAMETER RsFolder
            Folder on reportserver to upload the item to.

       .PARAMETER Overwrite
            Overwrite the old entry, if an existing catalog item with same name exists at the specified destination.

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
            Write-RsFolderContent -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\monthlyreports -RsFolder /monthlyReports

            Description
            -----------
            Uploads all reports under c:\monthlyreports to folder /monthlyReports.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [switch]
        $Recurse,

        [Parameter(Mandatory = $True)]
        [string]
        $Path,

        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [Alias('Override')]
        [switch]
        $Overwrite,

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

    if ($PSCmdlet.ShouldProcess($Path, "Upload all contents in folder $(if ($Recurse) { "and subfolders " })to $RsFolder"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

        if(-not (Test-Path $Path -PathType Container))
        {
            throw "$Path is not a folder"
        }
        $sourceFolder = Get-Item $Path

        if ($Recurse)
        {
            $items = Get-ChildItem $Path -Recurse
        }
        else
        {
            $items = Get-ChildItem $Path
        }
        foreach ($item in $items)
        {
            if (($item.PSIsContainer) -and $Recurse)
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")
                if ($RsFolder -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $RsFolder + $relativePath
                }
                #replace possible double slash
                $itemToUpload = ("$parentFolder/$($item.Name)") -replace "//", "/"
                try
                {
                    if ($Proxy.GetItemType($itemToUpload) -ne "Folder" )
                    {
                        Write-Verbose "Creating folder $itemToUpload"
                        $Proxy.CreateFolder($item.Name, $parentFolder, $null) | Out-Null
                    }
                    else
                    {
                        Write-Verbose "Folder already exists $parentFolder/$($item.Name)"
                    }
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to create folder '$($item.Name)' in '$parentFolder': $($_.Exception.Message)", $_.Exception))
                }
            }

            if ($item.Extension -eq ".rdl" -or
                $item.Extension -eq ".rsds" -or
                $item.Extension -eq ".rsd" -or
                $item.Extension -eq ".rds" -or
                $item.Extension -eq ".jpg" -or
                $item.Extension -eq ".jpeg" -or
                $item.Extension -eq ".png" )
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")

                if ($RsFolder -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $RsFolder + $relativePath
                }

                try
                {
                    Write-RsCatalogItem -proxy $Proxy -Path $item.FullName -RsFolder $parentFolder -Overwrite:$Overwrite -ErrorAction Stop
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to create catalog item from '$($item.FullName)' in '$parentFolder': $($_.Exception)", $_.Exception))
                }
            }
        }
    }
}
