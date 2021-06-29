# Copyright (c) 2017 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Set-RsRestItemDataSource
{
    <#
        .SYNOPSIS
            This script updates data sources related to a catalog item from the Report Server.

        .DESCRIPTION
            This script updates data sources related to a catalog item from the Report Server.

        .PARAMETER RsItem
            Specify the location of the catalog item whose data sources will be updated.

        .PARAMETER RsItemType
            Specify the type of the $RsItem. Valid values are: Dataset, PowerBIReport or Report.

        .PARAMETER DataSources
            Specify the datasources which were initially fetched via Get-RsItemDataSource.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            $dataSources = Get-RsRestItemDataSource -RsItem '/MyPowerBIReport'
            $dataSources[0].DataModelDataSource.AuthType = 'Windows'
            $dataSources[0].DataModelDataSource.Username = 'domain\\user'
            $dataSources[0].DataModelDataSource.Secret = 'UserPassword'
            Set-RsRestItemDataSource -RsItem '/MyPowerBIReport' -RsItemType PowerBIReport -DataSources $datasources

            Description
            -----------
            Updates data sources to the specified $dataSources object. This example is only applicable for Power BI Reports.

        .EXAMPLE
            $dataSources = Get-RsRestItemDataSource -RsItem '/MyPowerBIReport'
            $dataSources[0].DataModelDataSource.AuthType = 'UsernamePassword' # UsernamePassword should be used when specifying SQL or Basic Credentials
            $dataSources[0].DataModelDataSource.Username = 'sqlSa'
            $dataSources[0].DataModelDataSource.Secret = 'sqlSaPassword'
            Set-RsRestItemDataSource -RsItem '/MyPowerBIReport' -RsItemType PowerBIReport -DataSources $datasources

            Description
            -----------
            Updates data sources to the specified $dataSources object. This example is only applicable for Power BI Reports.

        .EXAMPLE
            $dataSources = Get-RsRestItemDataSource -RsItem '/MyPowerBIReport'
            $dataSources[0].DataModelDataSource.AuthType = 'Key'
            $dataSources[0].DataModelDataSource.Secret = 'aASDBsdas12?asd2+asdajkda='
            Set-RsRestItemDataSource -RsItem '/MyPowerBIReport' -RsItemType PowerBIReport -DataSources $datasources

            Description
            -----------
            Updates data sources to the specified $dataSources object. This example is only applicable for Power BI Reports.

        .EXAMPLE
            $dataSources = Get-RsRestItemDataSource -RsItem '/MyPaginatedReport'
            $dataSources[0].CredentialRetrieval = 'Integrated'
            Set-RsRestItemDataSource -RsItem '/MyPaginatedReport' -RsItemType Report -DataSources $datasources

            Description
            -----------
            Updates data sources to the specified $dataSources object. This example is only applicable to Paginated Reports.

        .EXAMPLE
            $dataSources = Get-RsRestItemDataSource -RsItem '/MyPaginatedReport'
            $dataSources[0].CredentialRetrieval = 'Store'
            $dataSources[0].CredentialsInServer = New-RsRestCredentialsInServerObject -Username "domain\\username" -Password "userPassword" -WindowsCredentials
            Set-RsRestItemDataSource -RsItem '/MyPaginatedReport' -RsItemType Report -DataSources $datasources

            Description
            -----------
            Updates data sources to the specified $dataSources object. This example is only applicable to Paginated Reports.

        .EXAMPLE
            $dataSources = Get-RsRestItemDataSource -RsItem '/MyPaginatedReport'
            $dataSources[0].CredentialRetrieval = 'Prompt'
            $dataSources[0].CredentialsByUser = New-RsRestCredentialsByUserObject -PromptMessage "Please enter your credentials" -WindowsCredentials
            Set-RsRestItemDataSource -RsItem '/MyPaginatedReport' -RsItemType Report -DataSources $datasources

            Description
            -----------
            Updates data sources to the specified $dataSources object. This example is only applicable to Paginated Reports.

        .EXAMPLE
            $dataSources = Get-RsRestItemDataSource -RsItem '/MyPaginatedReport'
            $dataSources[0].CredentialRetrieval = 'None'
            Set-RsRestItemDataSource -RsItem '/MyPaginatedReport' -RsItemType Report -DataSources $datasources

            Description
            -----------
            Updates data sources to the specified $dataSources object. This example is only applicable to Paginated Reports.
        
        .LINK
            https://docs.microsoft.com/en-us/power-bi/report-server/connect-data-source-apis-pre-oct-2020
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True)]
        [Alias('ItemPath','Path')]
        [string]
        $RsItem,

        [Parameter(Mandatory = $True)]
        [ValidateSet("PowerBIReport", "Report")]
        [string]
        $RsItemType,

        [Parameter(Mandatory = $True)]
        $DataSources,

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
        $dataSourcesUri = $ReportPortalUri + "api/$RestApiVersion/{0}(Path='{1}')/DataSources"
    }
    Process
    {
        if ($Force) {
            $ConfirmPreference = 'None'
        }

        try
        {
            # Basic DataSource Validation - Start
            foreach ($ds in $DataSources)
            {
                if ($ds.DataSourceSubType -eq 'DataModel')
                {
                    # DataModelDataSource.AuthType must be specified!
                    if ($ds.DataModelDataSource.AuthType -eq $null)
                    {
                        throw "DataModelDataSource.AuthType must be specified: $ds!"
                    }
                    elseif (($ds.DataModelDataSource.AuthType -LIKE 'Windows' -or
                            $ds.DataModelDataSource.AuthType -LIKE 'UsernamePassword' -or
                            $ds.DataModelDataSource.AuthType -LIKE 'Impersonate') -and
                            ($ds.DataModelDataSource.Username -eq $null -or
                            $ds.DataModelDataSource.Secret -eq $null))
                    {
                        # Username and Secret are required for Windows, UsernamePassword and Impersonate Auth Types
                        throw "Username and Secret must be specified for this AuthType: $ds!"
                    }
                    elseif ($ds.DataModelDataSource.AuthType -LIKE 'Key' -and
                            $ds.DataModelDataSource.Secret -eq $null)
                    {
                        # Secret is required for Key Auth Type
                        throw "Secret must be specified for this AuthType: $ds!"
                    }
                }
                elseif ($ds.DataSourceSubType -eq $null)
                {
                    # DataSourceType, ConnectionString and CredentialRetrieval must always be specified!
                    if ($ds.DataSourceType -eq $null -or
                        $ds.ConnectionString -eq $null -or
                        $ds.CredentialRetrieval -eq $null -or
                        !($ds.CredentialRetrieval -LIKE 'Integrated' -or
                        $ds.CredentialRetrieval -LIKE 'Store' -or
                        $ds.CredentialRetrieval -LIKE 'Prompt' -or
                        $ds.CredentialRetrieval -LIKE 'None'))
                    {
                        throw "Invalid data source specified: $ds!"
                    }
                    elseif ($ds.DataModelDataSource -ne $null)
                    {
                        # since this is an embedded data source for Paginated Report/Shared data set,
                        # you should not set any value to DataModelDataSource
                        throw "You cannot specify DataModelDataSource for this datasource: $ds!"
                    }

                    if ($ds.CredentialRetrieval -LIKE 'Store' -and $ds.CredentialsInServer -eq $null)
                    {
                        # CredentialsInServer must be specified for Store
                        throw "CredentialsInServer must be specified when CredentialRetrieval is set to Store: $ds!"
                    }
                    elseif ($ds.CredentialRetrieval -LIKE 'Prompt' -and $ds.CredentialsByUser -eq $null)
                    {
                        # CredentialsByUser must be specified for Prompt
                        throw "CredentialsByUser must be specified when CredentialRetrieval is set to Prompt: $ds!"
                    }
                }
                else
                {
                    throw "Unexpected data source subtype!"
                }
            }
            # Basic DataSource Validation - End

            $dataSourcesUri = [String]::Format($dataSourcesUri, $RsItemType + "s", $RsItem)

            # Converting $DataSources into array as PowerBIReport(...)/DataSources expects data sources
            # to be in an array in the request body. If $DataSources is already an array, this operation
            # combines $DataSources array with an empty array, so result is still an array.
            $dataSourcesArray = @($DataSources)

            # Depth needs to be specified otherwise whenever DataModelDataSource is present
            # Supported Auth Types will not be serialized correctly
            $payloadJson = ConvertTo-Json -InputObject $dataSourcesArray -Depth 3

            if ($RsItemType -eq "DataSet" -or $RsItemType -eq "Report")
            {
                $method = "PUT"
            }
            elseif ($RsItemType -eq "PowerBIReport")
            {
                $method = "PATCH"
            }
            else
            {
                throw "Invalid item type!"
            }

            if ($PSCmdlet.ShouldProcess($RsItem, "Update data sources"))
            {
                Write-Verbose "Updating data sources for $($RsItem)..."
                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $dataSourcesUri -Method $method -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -WebSession $WebSession -Credential $Credential -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $dataSourcesUri -Method $method -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -WebSession $WebSession -UseDefaultCredentials -Verbose:$false | Out-Null
                }
                Write-Verbose "Data sources were updated successfully!"
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to update data sources for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}