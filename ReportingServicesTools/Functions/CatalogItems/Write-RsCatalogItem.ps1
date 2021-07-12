# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Write-RsCatalogItem
{
    <#
        .SYNOPSIS
            Uploads an item from disk to a report server.

        .DESCRIPTION
            Uploads an item from disk to a report server.
            Currently, we are only supporting Report, DataSource, DataSet, jpg/png/gif/bmp, xls/xlsx and pdf for upload

        .PARAMETER Path
            Path to item to upload on disk.

        .PARAMETER RsFolder
            Folder on reportserver to upload the item to.

        .PARAMETER Name
            Specify the Name to be used for the report.

        .PARAMETER Description
            Specify the description to be added to the report.

        .PARAMETER Overwrite
            Overwrite the old entry, if an existing catalog item with same name exists at the specified destination.

        .PARAMETER Hidden
            Mark the item as hidden on the destination server.

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
            Write-RsCatalogItem -ReportServerUri 'http://localhost/reportserver_sql2012' -Path c:\reports\monthlyreport.rdl -RsFolder /monthlyreports

            Description
            -----------
            Uploads the report monthlyreport.rdl to folder /monthlyreports
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,

        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [string]
        $Name,

        [string]
        $Description,

        [Alias('Override')]
        [switch]
        $Overwrite,

        [switch]
        $Hidden,

        [string]
        $ReportServerUri,

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy
    )

    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        $namespace = $proxy.GetType().Namespace
        $propertyDataType = "$namespace.Property"
    }

    Process
    {
        foreach ($item in $Path)
        {
            #region Manage Paths
            if (!(Test-Path $item))
            {
                throw "No item found at the specified path: $item!"
            }

            $EntirePath = Convert-Path $item
            $item = Get-Item $EntirePath
            $itemType = Get-ItemType $item.Extension
            if ([string]::IsNullOrEmpty($Name))
            {
                $itemName = $item.BaseName
            }
            else
            {
                $itemName = $Name
            }

            if (
                (
                    $itemType -ne "Report" -and
                    $itemType -ne "DataSource" -and
                    $itemType -ne "DataSet" -and
                    $itemType -ne "Resource" -and
                    $itemType -ne "ExcelWorkbook"
                ) -or
                (
                    $itemType -eq "Resource" -and
                    $item.Extension -notin ('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.pdf')
                ) -or
                (
                    $itemType -eq "ExcelWorkbook" -and
                    $item.Extension -notin ('.xls', '.xlsx')
                )
            )
            {
                throw "Invalid item specified! You can only upload Report, DataSource, DataSet, jpg/png/gif/bmp, xls/xlsx and pdf files using this command!"
            }

            if ($RsFolder -eq "/")
            {
                Write-Verbose "Uploading $EntirePath to /$($itemName)"
            }
            else
            {
                Write-Verbose "Uploading $EntirePath to $RsFolder/$($itemName)"
            }
            #endregion Manage Paths

            if ($PSCmdlet.ShouldProcess("$itemName", "Upload from $EntirePath to Report Server at $RsFolder"))
            {
                #region Upload DataSource
                if ($itemType -eq 'DataSource')
                {
                    try
                    {
                        [xml]$content = Get-Content -Path $EntirePath -ErrorAction Stop
                    }
                    catch
                    {
                        throw (New-Object System.Exception("Failed to access XML content of '$EntirePath': $($_.Exception.Message)", $_.Exception))
                    }

                    if ($item.Extension -eq '.rsds')
                    {
                        if ($content.DataSourceDefinition -eq $null)
                        {
                            throw "Data Source Definition not found in the specified file: $EntirePath!"
                        }

                        $NewRsDataSourceParam = @{
                            Proxy = $Proxy
                            RsFolder = $RsFolder
                            Name = $itemName
                            Extension = $content.DataSourceDefinition.Extension
                            ConnectionString = $content.DataSourceDefinition.ConnectString
                            Disabled = ("false" -like $content.DataSourceDefinition.Enabled)
                            CredentialRetrieval = 'None'
                            Overwrite = $Overwrite
                        }
                    }
                    elseif ($item.Extension -eq '.rds')
                    {
                        if ($content -eq $null -or
                            $content.RptDataSource -eq $null -or
                            $content.RptDataSource.Name -eq $null -or
                            $content.RptDataSource.ConnectionProperties -eq $null -or
                            $content.RptDataSource.ConnectionProperties.ConnectString -eq $null -or
                            $content.RptDataSource.ConnectionProperties.Extension -eq $null)
                        {
                            throw 'Invalid data source file!'
                        }

                        $connectionProperties = $content.RptDataSource.ConnectionProperties
                        $credentialRetrieval = "None"
                        if ($connectionProperties.Prompt -ne $null)
                        {
                            $credentialRetrieval = "Prompt"
                            $prompt = $connectionProperties.Prompt
                        }
                        elseif ($connectionProperties.IntegratedSecurity -eq $true)
                        {
                            $credentialRetrieval = "Integrated"
                        }
                        $NewRsDataSourceParam = @{
                            Proxy = $Proxy
                            RsFolder = $RsFolder
                            Name = $content.RptDataSource.Name
                            Extension = $connectionProperties.Extension
                            ConnectionString = $connectionProperties.ConnectString
                            Disabled = $false
                            CredentialRetrieval = $credentialRetrieval
                            Overwrite = $Overwrite
                        }

                        if ($credentialRetrieval -eq "prompt")
                        {
                            $NewRsDataSourceParam.Add("Prompt", $prompt)
                            $NewRsDataSourceParam.Add("WindowsCredentials", $true)
                        }
                    }
                    else
                    {
                        throw 'Invalid data source file specified!'
                    }

                    New-RsDataSource @NewRsDataSourceParam
                }
                #endregion Upload DataSource

                #region Upload other stuff
                else
                {
                    $additionalProperties = New-Object System.Collections.Generic.List[$propertyDataType]
                    $property = New-Object $propertyDataType

                    if ($itemType -in ('Resource', 'ExcelWorkbook'))
                    {
                        #If it is a resource we need to save the extension so the file can be recognized
                        $itemName = $item.Name
                        $property.Name = 'MimeType'
                        switch ($item.Extension)
                        {
                            ".png"
                            {
                                $property.Value = 'image/png'
                                break
                            }
                            ".jpeg"
                            {
                                $property.Value = 'image/jpeg'
                                break
                            }
                            ".jpg"
                            {
                                $property.Value = 'image/jpg'
                                break
                            }
                            ".gif"
                            {
                                $property.Value = 'image/gif'
                                break
                            }
                            ".bmp"
                            {
                                $property.Value = 'image/bmp'
                                break
                            }
                            ".xls"
                            {
                                #To upload the item type needs to be 'Resource'
                                $itemType = "Resource"
                                $property.Value = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                                break
                            }
                            ".xlsx"
                            {
                                #To upload the item type needs to be 'Resource'
                                $itemType = "Resource"
                                $property.Value = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                                break
                            }
                            ".pdf"
                            {
                                $property.Value = 'application/pdf'
                                break
                            }
                        }
                    }
                    else
                    {
                        $property.Name = 'Description'
                        $property.Value = $Description
                        $errorMessageItemType = 'catalog'
                    }

                    $additionalProperties.Add($property)

                    if ($Hidden)
                    {
                        $hiddenProperty = New-Object $propertyDataType
                        $hiddenProperty.Name = 'Hidden'
                        $hiddenProperty.Value = $Hidden
                        $additionalProperties.Add($hiddenProperty)
                    }

                    $bytes = [System.IO.File]::ReadAllBytes($EntirePath)
                    $warnings = $null
                    try
                    {
                        $Proxy.CreateCatalogItem($itemType, $itemName, $RsFolder, $Overwrite, $bytes, $additionalProperties, [ref]$warnings) | Out-Null
                        if ($warnings)
                        {
                            foreach ($warn in $warnings)
                            {
                                Write-Warning $warn.Message
                            }
                        }
                    }
                    catch
                    {
                        throw (New-Object System.Exception("Failed to create $errorMessageItemType item $($item.FullName) : $($_.Exception.Message)", $_.Exception))
                    }
                }
                #endregion Upload other stuff

                Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
            }
        }
    }
}
