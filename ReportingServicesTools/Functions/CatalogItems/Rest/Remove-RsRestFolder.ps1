# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Remove-RsRestFolder
{
    <#
        .SYNOPSIS
            This script deletes a folder from the Report Server

        .DESCRIPTION
            This script deletes a folder from the Report Server

        .PARAMETER RsFolder
            Specify the location of the folder to be deleted.

        .PARAMETER ReportPortalUri
            Specify the Report Portal URL to your SQL Server Reporting Services Instance.

        .PARAMETER RestApiVersion
            Specify the version of REST Endpoint to use. Valid values are: "v2.0".

        .PARAMETER Credential
            Specify the credentials to use when connecting to the Report Server.

        .PARAMETER WebSession
            Specify the session to be used when making calls to REST Endpoint.

        .EXAMPLE
            Remove-RsRestFolder -RsFolder /MyFolder

            Description
            -----------
            Deletes "/MyFolder" folder from Report Server.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

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
        $foldersUri = $ReportPortalUri + "api/$RestApiVersion/Folders(Path='{0}')"
    }
    Process
    {
        if ($Force) {
            $ConfirmPreference = 'None'
        }
        
        if ($RsFolder -eq '/')
        {
            throw "Root folder cannot be deleted!"
        }

        if ($PSCmdlet.ShouldProcess($RsFolder, "Delete the folder"))
        {
            try
            {
                Write-Verbose "Deleting folder $RsFolder..."
                $foldersUri = [String]::Format($foldersUri, $RsFolder)

                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $foldersUri -Method Delete -WebSession $WebSession -Credential $Credential -UseBasicParsing -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $foldersUri -Method Delete -WebSession $WebSession -UseDefaultCredentials -UseBasicParsing -Verbose:$false | Out-Null
                }

                Write-Verbose "Folder $RsFolder was deleted successfully!"
            }
            catch
            {
                throw (New-Object System.Exception("Failed to delete folder '$RsFolder': $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}