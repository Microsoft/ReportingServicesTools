# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsDataSource
{
    <#
        .SYNOPSIS
            This script creates a new data source on Report Server.
        
        .DESCRIPTION
            This script creates a new data source on Report Server.
        
        .PARAMETER RsFolder
            Specify the location where the data source should be created at.
        
        .PARAMETER Name
            Specify the name of the the new data source

        .PARAMETER Description
            Specify the description to be added to the data source.
        
        .PARAMETER Extension
            Specify the extension of the new data source (e.g. SQL, SQLAZURE, OLEDB, OLEDB-MD, etc.) For full list, please look at <Extensions>\<Data> node in C:\Program Files\Microsoft SQL Server\MSRS{VersionNumber}.{InstanceName}\Reporting Services\ReportServer\RSReportServer.config.
        
        .PARAMETER ConnectionString
            Specify the connection string for the new data source.
        
        .PARAMETER CredentialRetrieval
            Specify the type of authentication to use: None, Prompt, Integrated, Store. Please view https://msdn.microsoft.com/en-us/library/reportservice2010.datasourcedefinition.credentialretrieval.aspx for more details on each option.
        
        .PARAMETER DatasourceCredentials
            Specify the Credentials to use when connecting to the data source.
        
        .PARAMETER Prompt
            Specify the prompt to display to user.
        
        .PARAMETER ImpersonateUser
            Specify whether to impersonate using the credentials specify when connecting to the data source. You must specify DatasourceCredentials if you specify this switch.
        
        .PARAMETER WindowsCredentials
            Specify whether the credentials specified are Windows credentials or not. You must specify DatasourceCredentials if you specify this switch.
        
        .PARAMETER Disabled
            Creates this data source in a disabled state.
        
        .PARAMETER Overwrite
            Overwrite the old entry, if an existing data source with same name exists at the specified Path.
        
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
            New-RsDataSource -RsFolder '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'None'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will use not specify any credentials.
        
        .EXAMPLE
            New-RsDataSource -RsFolder '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Integrated'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will assume current user's identity.
        
        .EXAMPLE
            New-RsDataSource -RsFolder '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Prompt' -Prompt 'Please enter your username and password'
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will prompt user for Database credentials.
        
        .EXAMPLE
            New-RsDataSource -RsFolder '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Prompt' -Prompt 'Please enter your username and password' -WindowsCredentials
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, it will prompt user for Windows credentials.
        
        .EXAMPLE
            New-RsDataSource -RsFolder '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Store' -DatasourceCredentials 'sa' -ImpersonateUser
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, the specified credentials will be treated as Database credentials.
        
        .EXAMPLE
            New-RsDataSource -RsFolder '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'Store' -DatasourceCredentials 'sa' -ImpersonateUser -WindowsCredentials
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. When connecting to this data source, the specified credentials will be treated as Windows credentials.
        
        .EXAMPLE
            New-RsDataSource -RsFolder '/' -Name 'My Data Source' -Extension 'SQL' -ConnectionString 'Data Source=.;Initial Catalog=MyDb;' -CredentialRetrieval 'None' -Overwrite
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and create a new SQL Server data source called 'My Data Source' at the root folder. If data source already exists, it will be overwriten.
            
    #>

    [cmdletbinding()]
    param
    (
        [Alias('Destination', 'ItemPath', 'Path')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,
        
        [Parameter(Mandatory = $True)]
        [string]
        $Name,

        [string]
        $Description,
        
        [Parameter(Mandatory = $True)]
        [string]
        $Extension,

        [string]
        $ConnectionString,
        
        [Parameter(Mandatory = $True)]
        [ValidateSet("None", "Prompt", "Integrated", "Store")]
        [string]
        $CredentialRetrieval,

        [System.Management.Automation.PSCredential]
        $DatasourceCredentials,

        [string]
        $Prompt,

        [switch]
        $ImpersonateUser,

        [switch]
        $WindowsCredentials,

        [switch]
        $Disabled,

        [Switch]
        $Overwrite,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

    if (($CredentialRetrieval -eq 'STORE') -and ($DatasourceCredentials.UserName -eq $null))
    {
        throw "Username and password (-DatasourceCredentials) must be specified when CredentialRetrieval is Store!"
    }

    # validating Extension specified by the user
    Write-Verbose "Retrieving data extensions..."
    if ($Proxy.ListExtensions("Data").Name -notcontains $Extension)
    {
        throw "Extension specified is not supported by the report server!"
    }

    $namespace = $proxy.GetType().Namespace
    $datasourceDataType = "$namespace.DataSourceDefinition"
    $propertyDataType = "$namespace.Property"
    $credentialRetrievalEnumType = "$namespace.CredentialRetrievalEnum"

    $datasource = New-Object $datasourceDataType
    $datasource.ConnectString = $ConnectionString
    $datasource.Enabled = $true    
    $datasource.Extension = $Extension
    $datasource.WindowsCredentials = $WindowsCredentials
    $datasource.Prompt = $Prompt
    
    if ($Disabled)
    {
        $datasource.Enabled = $false
    }

    if ($CredentialRetrieval -eq 'STORE')
    {
        $datasource.UserName = $DatasourceCredentials.UserName
        $datasource.Password = $DatasourceCredentials.GetNetworkCredential().Password
        $datasource.ImpersonateUser = $ImpersonateUser
    }

    try
    {
        $datasource.CredentialRetrieval = [Enum]::Parse($credentialRetrievalEnumType, $CredentialRetrieval)
    }
    catch
    {
        throw (New-Object System.Exception("Exception occurred while converting credential retrieval to enum! $($_.Exception.Message)", $_.Exception))
    }

    $additionalProperties = New-Object System.Collections.Generic.List["$propertyDataType"]
    if ($Description)
    {
        $descriptionProperty = New-Object $propertyDataType
        $descriptionProperty.Name = 'Description'
        $descriptionProperty.Value = $Description
        $additionalProperties.Add($descriptionProperty)
    }

    try
    {
        Write-Verbose "Creating data source..."
        $Proxy.CreateDataSource($Name, $RsFolder, $Overwrite, $datasource, $additionalProperties)
        Write-Verbose "Data source created successfully!"
    }
    catch
    {
       throw (New-Object System.Exception("Exception occurred while creating data source! $($_.Exception.Message)", $_.Exception))
    }
}
