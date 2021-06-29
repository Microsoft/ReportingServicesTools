# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)


function Set-RsDataSetReference
{
    <#
        .SYNOPSIS
            Overrides the reference of a report to a shared dataset.
        
        .DESCRIPTION
            Overrides the reference of a report to a shared dataset.
        
        .PARAMETER Path
            Path of the report.
        
        .PARAMETER DataSetName
            Name of the dataset reference to override.
        
        .PARAMETER DataSetPath
            Path to the shared dataset the reference will point to.
        
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
            Set-RsDataSetReference -ReportServerUri 'http://localhost/reportserver_sql2012' -Path /ReportWithDSReference -DataSetName Dataset1 -DataSetPath /Datasets/SampleSet
            
            Description
            -----------
            Sets the dataset reference 'DataSet1' of report /ReportWithDSReference to point to dataset '/DataSets/SampleSet'
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $true)]
        [string[]] 
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSetName,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSetPath,
        
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

        foreach ($item in $Path)
        {
            #region Process each path passed
            if ($PSCmdlet.ShouldProcess($item, "Set datasource's DataSet $DataSetName to $DataSetPath"))
            {
                Write-Verbose "Processing: $item"
                
                try
                {
                    $dataSets = $Proxy.GetItemReferences($item, "DataSet")
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to retrieve item references from Report Server for '$item': $($_.Exception.Message)", $_.Exception))
                }
                $dataSetReference = $dataSets | Where-Object { $_.Name -eq $DataSetName } | Select-Object -First 1
                
                if (-not $dataSetReference)
                {
                    throw "$item does not contain a dataSet reference with name $DataSetName"
                }
                
                $proxyNamespace = $dataSetReference.GetType().Namespace
                $dataSetReference = New-Object "$($proxyNamespace).ItemReference"
                $dataSetReference.Name = $DataSetName
                $dataSetReference.Reference = $DataSetPath
                
                Write-Verbose "Set dataSet reference '$DataSetName' of item $item to $DataSetPath"
                $Proxy.SetItemReferences($item, @($dataSetReference))
            }
            #endregion Process each path passed
        }
    }
}

New-Alias -Name Set-RsDataSet -Value Set-RsDataSetReference -Scope Global