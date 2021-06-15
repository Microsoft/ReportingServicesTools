function New-RsWebServiceProxyHelper
{
    <#
        .SYNOPSIS
            Internal helper function. Facilitates generating WebProxy objects.
        
        .DESCRIPTION
            Internal helper function. Facilitates generating WebProxy objects.
            
            It accepts all bound parameters of the calling function and processes the following keys:
            - ReportServerUri
            - Credential
            - Proxy
            - APIVersion
            - CustomAuthentication
            These parameters are passed on to the New-RsWebServiceProxy function, unless Proxy was specified.
            If the bound parameters contain the proxy parameter, the function will return that object.
            All other bound parameters are ignored.
        
        .PARAMETER BoundParameters
            The bound parameters of the calling function
        
        .EXAMPLE
            $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
            Generates or retrieves a proxy object for the reporting services web api.
    #>
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )
    
    if ($BoundParameters["Proxy"])
    {
        return $BoundParameters["Proxy"]
    }
    
    $goodKeys = @("ReportServerUri", "Credential", "ApiVersion", "CustomAuthentication")
    $NewRsWebServiceProxyParam = @{ }
    
    foreach ($key in $BoundParameters.Keys)
    {
        if ($goodKeys -contains $key)
        {
            $NewRsWebServiceProxyParam["$key"] = $BoundParameters["$key"]
        }
    }
    
    New-RsWebServiceProxy @NewRsWebServiceProxyParam
}

function New-RsRestSessionHelper
{
    <#
        .SYNOPSIS
            Internal helper function. Facilitates generating Rest Session objects.
        
        .DESCRIPTION
            Internal helper function. Facilitates generating Rest Session objects.
            
            It accepts all bound parameters of the calling function and processes the following keys:
            - ReportPortalUri
            - RestApiVersion
            - Credential
            - WebSession
            These parameters are passed on to the New-RsRestSession function, unless WebSession was specified.
            If the bound parameters contain the WebSession parameter, the function will return that object.
            All other bound parameters are ignored.
        
        .PARAMETER BoundParameters
            The bound parameters of the calling function
        
        .EXAMPLE
            $RsRestWebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        
            Generates or retrieves a WebSession object for the reporting services REST api.
    #>

    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )

    if ($BoundParameters["WebSession"])
    {
        return $BoundParameters["WebSession"]
    }

    $goodKeys = @("ReportPortalUri", "RestApiVersion", "Credential")
    $NewRsRestSessionParams = @{ }

    foreach ($key in $BoundParameters.Keys)
    {
        if ($goodKeys -contains $key)
        {
            $NewRsRestSessionParams["$key"] = $BoundParameters["$key"]
        }
    }

    New-RsRestSession @NewRsRestSessionParams
}

function Get-RsPortalUriHelper
{
    <#
        .SYNOPSIS
            Internal helper function. Facilitates determining the Portal Uri from WebSession object.
        
        .DESCRIPTION
            Internal helper function. Facilitates determining the Portal Uri from WebSession object.
        
        .PARAMETER WebSession
            The WebSession object returned from executing New-RsRestSession command.
        
        .EXAMPLE
            $reportPortalUri = Get-RsPortalUriHelper -WebSession $mySession
        
            Retrieves the Portal Uri for which this web session was created.
    #>

    [CmdletBinding()]
    Param (
        [AllowNull()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )

    if ($WebSession -ne $null)
    {
        $reportPortalUri = $WebSession.Headers['X-RSTOOLS-PORTALURI']
        if (![String]::IsNullOrEmpty($reportPortalUri))
        {
            if ($reportPortalUri -notlike '*/') 
            {
                $reportPortalUri = $reportPortalUri + '/'
            }
            return $reportPortalUri
        }
    }

    throw "Invalid WebSession specified! Please specify a valid WebSession or run New-RsRestSession to create a new one."
}

function New-RsConfigurationSettingObjectHelper
{
    <#
        .SYNOPSIS
            Internal helper function. Facilitates generating wmi objects.
        
        .DESCRIPTION
            Internal helper function. Facilitates generating wmi objects.
            
            It accepts all bound parameters of the calling function and processes the following keys:
            - ReportServerInstance
            - ReportServerVersion
            - ComputerName
            - Credential
            - MinimumReportServerVersion
            These parameters are passed on to the New-RsConfigurationSettingObject function.
            All other bound parameters are ignored.
        
        .PARAMETER BoundParameters
            The bound parameters of the calling function
        
        .EXAMPLE
            $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
        
            Generates or retrieves a wmi object for administrating a Report Server.
    #>
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )
    
    $goodKeys = @("SqlServerInstance", "ReportServerInstance", "SqlServerVersion", "ReportServerVersion", "ComputerName", "Credential", "MinimumSqlServerVersion", "MinimumReportServerVersion")
    $NewRsConfigurationSettingObjectParam = @{ }
    
    foreach ($key in $BoundParameters.Keys)
    {
        if ($goodKeys -contains $key)
        {
            $NewRsConfigurationSettingObjectParam["$key"] = $BoundParameters["$key"]
        }
    }
    
    New-RsConfigurationSettingObject @NewRsConfigurationSettingObjectParam
}
