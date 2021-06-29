# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function Export-RsSubscriptionXml {
    <#
        .SYNOPSIS
            This script exports one or more subscriptions that have been retrieved via Get-RsSubscription.
        
        .DESCRIPTION
            This script exports subscriptions to an XML file using Export-CliXml with a -Depth of 3.
            Use Import-RsSubscriptionXml to later re-import the subscriptions as valid subscription objects
            for use with Set-RsSubscription to implement in SRSS.
                    
        .PARAMETER Path
            The path to save the XML formatted file that will contain the exported subscription/s. 
        
        .PARAMETER Subscription
            One or more subscription objects, typically retrieved via Get-RsSubscription.

        .EXAMPLE
            Get-RsSubscription -path '/path/to/my/report' | Export-RsSubscriptionXml .\MySubscriptions.xml

            Description
            -----------
            This command will export the current set of subscriptions contained in '/path/to/my/report' to an 
            XML file named MySubscriptions.xml.
    #>
        
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory=$True,Position=0)]
        [string]
        $Path,

        [Parameter(Mandatory = $True, ValueFromPipeline=$true)]
        [object]
        $Subscription,

        [switch]
        $Force
    )

    Begin {
        $Subscriptions = @()
    }
    Process {
        $Subscriptions = $Subscriptions + $Subscription
    }
    End {
        
        if ($Force) {
            $ConfirmPreference = 'None'
        }
        
        if ($PSCmdlet.ShouldProcess($Path, "Exporting subscriptions")) 
        {
            Write-Verbose "Exporting subscriptions to $Path..."
            $Subscriptions | Export-Clixml $Path -Depth 3
        }
    }
}