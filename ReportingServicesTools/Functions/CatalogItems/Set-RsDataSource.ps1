# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Set-RsDataSource
{
    <#
        .SYNOPSIS
            This script updates information about a data source on Report Server.
        
        .DESCRIPTION
            This script updates information about a data source on Report Server that was retrieved using Get-RsDataSource.
        
        .PARAMETER RsItem
            Specify the path to the data source.

        .PARAMETER Description
            Specify the updated description to display for the data source.
        
        .PARAMETER DataSourceDefinition
            Specify the data source definition of the Data Source to update
        
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
            Set-RsDataSource -RsItem '/path/to/my/datasource' -DataSourceDefinition $dataSourceDefinition
            Description
            -----------
            This command will establish a connection to the Report Server located at http://localhost/reportserver using current user's credentials and update the details of data source found at '/path/to/my/datasource'.
        
        .EXAMPLE
            Set-RsDataSource -ReportServerUri 'http://remote-machine:8080/reportserver_sql16' -RsItem '/path/to/my/datasource' -DataSourceDefinition $dataSourceDefinition
            Description
            -----------
            This command will establish a connection to the Report Server located at http://remote-machine:8080/reportserver_sql16 using current user's credentials and update the details of data source found at '/path/to/my/datasource'.

        .EXAMPLE
            $rsProxy = New-RsWebServiceProxy (...)
            Set-RsDataSource -Proxy $rsProxy -RsItem '/path/to/my/datasource' -DataSourceDefinition $dataSourceDefinition
            Description
            -----------
            This command will establish a connection to the Report Server located at $rsProxy using current user's credentials and update the details of data source found at '/path/to/my/datasource'.
    #>
    
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Alias('DataSourcePath','ItemPath', 'Path')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsItem,
        
        [Parameter(Mandatory = $True)]
        $DataSourceDefinition,

        [string]
        $Description,
        
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
    
    if ($PSCmdlet.ShouldProcess($RsItem, "Applying new definition"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        #region Input Validation
        if ($DataSourceDefinition.GetType().Name -ne 'DataSourceDefinition')
        {
            throw 'Invalid object specified for DataSourceDefinition!'
        }
        
        if ($DataSourceDefinition.CredentialRetrieval -like 'STORE')
        {
            if (-not ($DataSourceDefinition.UserName))
            {
                throw "Username and password must be specified when CredentialRetrieval is set to Store!"
            }
        }
        else
        {
            if ($DataSourceDefinition.UserName -or $DataSourceDefinition.Password)
            {
                throw "Username and/or password can be specified only when CredentialRetrieval is Store!"
            }
            
            if ($DataSourceDefinition.ImpersonateUser)
            {
                throw "ImpersonateUser can be set to true only when CredentialRetrieval is Store!"
            }
        }
        #endregion Input Validation
        
        # validating extension specified by the user is supported
        Write-Verbose "Retrieving data extensions..."
        try
        {
            Write-Verbose "Validating data extension..."
            if ($Proxy.ListExtensions("Data").Name -notcontains $DataSourceDefinition.Extension)
            {
                throw "Extension specified is not supported by the report server!"
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to retrieve list of supported extensions from Report Server: $($_.Exception.Message)", $_.Exception))
        }
        
        
        try
        {
            if ($Description)
            {
                Write-Verbose "Retrieving existing data source description..."
                $properties = $Proxy.GetProperties($RsItem, $null)
                $descriptionProperty = $properties | Where { $_.Name -eq 'Description' }
                if (!$descriptionProperty)
                {
                    $namespace = $proxy.GetType().Namespace
                    $propertyDataType = "$namespace.Property"
                    $descriptionProperty = New-Object $propertyDataType
                    $descriptionProperty.Name = 'Description'
                    $descriptionProperty.Value = $Description
                    $properties.Add($descriptionProperty)
                }
                else
                {
                    $descriptionProperty.Value = $Description
                }

                Write-Verbose "Updating data source description..."
                $Proxy.SetProperties($RsItem, $descriptionProperty)
            }
            
            Write-Verbose "Updating data source contents..."
            $Proxy.SetDataSourceContents($RsItem, $DataSourceDefinition)
            Write-Verbose "Data source updated successfully!"
        }
        catch
        {
            throw (New-Object System.Exception("Exception occurred while updating data source! $($_.Exception.Message)", $_.Exception))
        }
    }
}
