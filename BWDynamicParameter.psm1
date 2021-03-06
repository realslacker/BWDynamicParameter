﻿<#
.SYNOPSIS
Helper function to simplify creating dynamic parameters

.DESCRIPTION
Helper function to simplify creating dynamic parameters

Example use cases:
    Include parameters only if your environment dictates it
    Include parameters depending on the value of a user-specified parameter
    Provide tab completion and intellisense for parameters, depending on the environment

Please keep in mind that all dynamic parameters you create will not have corresponding variables created.
    One of the examples illustrates a generic method for populating appropriate variables from dynamic parameters
    Alternatively, manually reference $PSBoundParameters for the dynamic parameter value

.NOTES
Credit to http://jrich523.wordpress.com/2013/05/30/powershell-simple-way-to-add-dynamic-parameters-to-advanced-function/
    Added logic to make option set optional
    Added logic to add RuntimeDefinedParameter to existing DPDictionary
    Added a little comment based help

Credit to BM for alias and type parameters and their handling

.PARAMETER Name
The Name of the dynamic parameter.

Note: If -DPDictionary is not specified you must use this same name when adding the parameter to the dictionary.

.PARAMETER Mandatory
Make the parameter mandatory.

.PARAMETER Position
The Position of the parameter.

.PARAMETER ParameterSetName
The ParameterSet the attribute belongs to.

.PARAMETER Type
Type for the parameter.  Default is [string].

.PARAMETER Alias
One or more aliases to assign to the parameter.

.PARAMETER ValidateLength
Length validation for this parameter. Takes two arguments: Min, Max

.PARAMETER ValidateRange
Range validation for this parameter. Takes two arguments: Min, Max

.PARAMETER ValidatePattern
Regex pattern validation for this parameter.

.PARAMETER ValidateScript
Script validation for this parameter.

.PARAMETER ValidateCount
Count validation for this parameter. Takes two arguments: Min, Max

.PARAMETER ValidateSet
Validate that arguments belong to a set. Takes at least one argument.

.PARAMETER ValidateTrustedData
Validate that the variable has not been manipulated outside of the local scope in ConstrainedLanguageMode.

See: https://github.com/MicrosoftDocs/PowerShell-Docs/issues/3288

.PARAMETER ValidateDrive
Validate that the path provided in the parameter is in one of the specified drive letters.

.PARAMETER ValidateNotNull
Validate that the parameter value is not null.

.PARAMETER ValidateNotNullOrEmpty
Validate that the parameter value is not null or empty.

.PARAMETER ValueFromPipeline
Allow the parameter to be populated by values from the pipeline.

.PARAMETER ValueFromPipelineByPropertyName
Allow the parameter to be populated by object property names from the pipeline.

.PARAMETER ValueFromRemainingArguments
Allow the parameter to be populated by the remaining arguments.

.PARAMETER ArgumentCompleter
Argument completer script block.

See: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-argumentcompleter?view=powershell-7

.PARAMETER DontShow
Hide the parameter from auto-complete.

.PARAMETER HelpMessage
Show a short help message.

.PARAMETER HelpMessageBaseName
The base type name where the help message should be populated from. Requires -HelpMessageResourceId be set.

.PARAMETER HelpMessageResourceId
The resource in the -HelpMessageBaseName to use.

.PARAMETER DPDictionary
Optionally append the parameter to a DPDictionary object.

.EXAMPLE

PS C:\ > $Param1 = New-DynamicParameter -Name Param1 -ValidateSet 1,2 -Mandatory

.FUNCTIONALITY
PowerShell Language

#>
function New-DynamicParameter {
    
    [CmdletBinding(DefaultParameterSetName='Default')]
    [OutputType([System.Management.Automation.RuntimeDefinedParameter], ParameterSetName='Default')]
    [OutputType([void], ParameterSetName='AppendToDictionary')]
    param(
    
        [Parameter(Mandatory=$true, Position=1)]
        [string]
        $Name,
    
        [switch]
        $Mandatory,
    
        [ValidateNotNullOrEmpty()]
        [int]
        $Position,
    
        [ValidateNotNullOrEmpty()]
        [string]
        $ParameterSetName = '__AllParameterSets',
    
        [System.Type]
        $Type = [string],

        [ValidateCount( 1, 4096 )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Alias,

        [ValidateCount( 2, 2 )]
        [int[]]
        $ValidateLength,

        [ValidateCount( 2, 2 )]
        [int[]]
        $ValidateRange,

        [ValidateNotNullOrEmpty()]
        [regex]
        $ValidatePattern,

        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $ValidateScript,

        [ValidateCount( 2, 2 )]
        [int[]]
        $ValidateCount,

        [ValidateCount( 1, 4096 )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ValidateSet,

        [switch]
        $ValidateTrustedData,

        [ValidateCount( 1, 4096 )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ValidateDrive,

        [switch]
        $ValidateNotNull,

        [switch]
        $ValidateNotNullOrEmpty,
    
        [switch]
        $ValueFromPipeline,
    
        [switch]
        $ValueFromPipelineByPropertyName,

        [switch]
        $ValueFromRemainingArguments,

        [scriptblock]
        $ArgumentCompleter,

        [switch]
        $DontShow,
    
        [ValidateNotNullOrEmpty()]
        [string]
        $HelpMessage,

        [ValidateNotNullOrEmpty()]
        [string]
        $HelpMessageBaseName,

        [ValidateNotNullOrEmpty()]
        [string]
        $HelpMessageResourceId,

        [Parameter(Mandatory=$true, ParameterSetName='AppendToDictionary')]
        [System.Management.Automation.RuntimeDefinedParameterDictionary]
        $DPDictionary
 
    )

    # the collection of parameter attributes
    $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
    
    # primary parameter configuration
    $ParameterAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute

    $ParameterAttribute.ParameterSetName                                      = $ParameterSetName
    $ParameterAttribute.Mandatory                                             = $Mandatory.IsPresent
    $ParameterAttribute.ValueFromPipeline                                     = $ValueFromPipeline.IsPresent
    $ParameterAttribute.ValueFromPipelineByPropertyName                       = $ValueFromPipelineByPropertyName.IsPresent
    $ParameterAttribute.ValueFromRemainingArguments                           = $ValueFromRemainingArguments.IsPresent
    $ParameterAttribute.DontShow                                              = $DontShow.IsPresent
    if ( $Position              ) { $ParameterAttribute.Position              = $Position              }
    if ( $HelpMessage           ) { $ParameterAttribute.HelpMessage           = $HelpMessage           }
    if ( $HelpMessageBaseName   ) { $ParameterAttribute.HelpMessageBaseName   = $HelpMessageBaseName   }
    if ( $HelpMessageResourceId ) { $ParameterAttribute.HelpMessageResourceId = $HelpMessageResourceId }
 
    $AttributeCollection.Add( $ParameterAttribute )

    # create a lenth validation
    if ( $ValidateLength -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateLengthAttribute').Type ) {
    
        $ParameterValidateLength = New-Object -TypeName System.Management.Automation.ValidateLengthAttribute -ArgumentList $ValidateLength

        $AttributeCollection.Add( $ParameterValidateLength )

    }

    # create a range validation
    if ( $ValidateRange -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateRangeAttribute').Type ) {
    
        $ParameterValidateRange = New-Object -TypeName System.Management.Automation.ValidateRangeAttribute -ArgumentList $ValidateRange

        $AttributeCollection.Add( $ParameterValidateRange )

    }

    # create a pattern validation
    if ( $ValidatePattern -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidatePatternAttribute').Type ) {

        $ParameterValidatePattern = New-Object -TypeName System.Management.Automation.ValidatePatternAttribute -ArgumentList $ValidatePattern

        $AttributeCollection.Add( $ParameterValidatePattern )

    }

    # create a script validation
    if ( $ValidateScript -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateScriptAttribute').Type ) {

        $ParameterValidateScript = New-Object -TypeName System.Management.Automation.ValidateScriptAttribute -ArgumentList $ValidateScript

        $AttributeCollection.Add( $ParameterValidateScript )

    }

    # create a count validation
    if ( $ValidateCount -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateCountAttribute').Type ) {

        $ParameterValidateCount = New-Object -TypeName System.Management.Automation.ValidateCountAttribute -ArgumentList $ValidateCount

        $AttributeCollection.Add( $ParameterValidateCount )

    }

    # create a validation set
    if ( $ValidateSet -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateSetAttribute').Type ) {

        $ParameterValidateSet = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet

        $AttributeCollection.Add( $ParameterValidateSet )
    
    }

    # create a trusted data validation
    if ( $ValidateTrustedData.IsPresent -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateTrustedDataAttribute').Type ) {

        $ParameterValidateTrustedData = New-Object -TypeName System.Management.Automation.ValidateTrustedDataAttribute

        $AttributeCollection.Add( $ParameterValidateTrustedData )

    }

    # create a drive validation
    if ( $ValidateDrive -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateDriveAttribute').Type ) {

        $ParameterValidateDrive = New-Object -TypeName System.Management.Automation.ValidateDriveAttribute -ArgumentList $ValidateDrive

        $AttributeCollection.Add( $ParameterValidateDrive )

    }

    # create a not null validation
    if ( $ValidateNotNull.IsPresent -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateNotNullAttribute').Type ) {

        $ParameterValidateNotNull = New-Object -TypeName System.Management.Automation.ValidateNotNullAttribute

        $AttributeCollection.Add( $ParameterValidateNotNull )

    }

    # create a not null or empty validation
    if ( $ValidateNotNullOrEmpty.IsPresent -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ValidateNotNullOrEmptyAttribute').Type ) {

        $ParameterValidateNotNullOrEmpty = New-Object -TypeName System.Management.Automation.ValidateNotNullOrEmptyAttribute

        $AttributeCollection.Add( $ParameterValidateNotNullOrEmpty )

    }

    # create aliases if specified
    if( $Alias ) {

        $ParameterAlias = New-Object -TypeName System.Management.Automation.AliasAttribute -ArgumentList $Alias

        $AttributeCollection.Add( $ParameterAlias )
    
    }

    # create argument completer if specified
    if ( $ArgumentCompleter -and [bool]([System.Management.Automation.PSTypeName]'System.Management.Automation.ArgumentCompleterAttribute').Type ) {

        $ParameterArgumentCompleter = New-Object -TypeName System.Management.Automation.ArgumentCompleterAttribute ( $ArgumentCompleter )

        $AttributeCollection.Add( $ParameterArgumentCompleter )

    }

    # create the parameter object
    $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @( $Name, $Type, $AttributeCollection )

    #Add the dynamic parameter to an existing dynamic parameter dictionary, or create the dictionary and add it
    if( $DPDictionary ) {

        $DPDictionary.Add( $Name, $Parameter )
    
    } else {

        Write-Output $Parameter

    }

}

<#
.SYNOPSIS
Creates a dictionary of dynamic parameters.
 
.DESCRIPTION
Creates a RuntimeDefinedParameterDictionary of 0 or more DynamicParameters.
 
.PARAMETER DynamicParameters
Dynamic parameters to be included.

.PARAMETER ScriptBlock
Script block to execute to generate the Dynamic Parameters.
 
.EXAMPLE

DynamicParameterDictionary {
    DynamicParameter -Name Param1 -Mandatory
    DynamicParameter -Name Param2 -ValidateSet 'Item1', 'Item2'
}

.EXAMPLE

$Param1 = DynamicParameter -Name Param1 -Mandatory
$Param2 = DynamicParameter -Name Param2 -ValidateSet 'Item1', 'Item2'

DynamicParameterDictionary $Param1, $Param2

#>
function New-DynamicParameterDictionary {

    [CmdletBinding(DefaultParameterSetName='Default')]
    [OutputType([System.Management.Automation.RuntimeDefinedParameterDictionary])]
    param(
        
        [Parameter(Mandatory=$false, Position=0, ParameterSetName='Default')]
        [System.Management.Automation.RuntimeDefinedParameter[]]
        $DynamicParameters,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='ScriptBlock')]
        [scriptblock]
        $ScriptBlock
    
    )

    begin {

        $DynamicParameterDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        if ( $PSCmdlet.ParameterSetName -eq 'ScriptBlock' ) {

            $DynamicParameters = $ScriptBlock.Invoke()

        }

    }
    
    process {

        foreach ( $DynamicParameterItem in $DynamicParameters ) {
        
            $DynamicParameterDictionary.Add( $DynamicParameterItem.Name, $DynamicParameterItem) > $null
        
        }

    }

    end {

        Write-Output $DynamicParameterDictionary

    }

}

New-Alias -Name DynamicParameter -Value New-DynamicParameter
New-Alias -Name DynamicParameterDictionary -Value New-DynamicParameterDictionary

# SIG # Begin signature block
# MIIesgYJKoZIhvcNAQcCoIIeozCCHp8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULCiRiCXRl54uY0fW8u2koZrk
# awqgghm9MIIEhDCCA2ygAwIBAgIQQhrylAmEGR9SCkvGJCanSzANBgkqhkiG9w0B
# AQUFADBvMQswCQYDVQQGEwJTRTEUMBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNV
# BAsTHUFkZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRU
# cnVzdCBFeHRlcm5hbCBDQSBSb290MB4XDTA1MDYwNzA4MDkxMFoXDTIwMDUzMDEw
# NDgzOFowgZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2Fs
# dCBMYWtlIENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8G
# A1UECxMYaHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNF
# UkZpcnN0LU9iamVjdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM6q
# gT+jo2F4qjEAVZURnicPHxzfOpuCaDDASmEd8S8O+r5596Uj71VRloTN2+O5bj4x
# 2AogZ8f02b+U60cEPgLOKqJdhwQJ9jCdGIqXsqoc/EHSoTbL+z2RuufZcDX65OeQ
# w5ujm9M89RKZd7G3CeBo5hy485RjiGpq/gt2yb70IuRnuasaXnfBhQfdDWy/7gbH
# d2pBnqcP1/vulBe3/IW+pKvEHDHd17bR5PDv3xaPslKT16HUiaEHLr/hARJCHhrh
# 2JU022R5KP+6LhHC5ehbkkj7RwvCbNqtMoNB86XlQXD9ZZBt+vpRxPm9lisZBCzT
# bafc8H9vg2XiaquHhnUCAwEAAaOB9DCB8TAfBgNVHSMEGDAWgBStvZh6NLQm9/rE
# JlTvA73gJMtUGjAdBgNVHQ4EFgQU2u1kdBScFDyr3ZmpvVsoTYs8ydgwDgYDVR0P
# AQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wEQYDVR0gBAowCDAGBgRVHSAAMEQG
# A1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9BZGRUcnVz
# dEV4dGVybmFsQ0FSb290LmNybDA1BggrBgEFBQcBAQQpMCcwJQYIKwYBBQUHMAGG
# GWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEFBQADggEBAE1C
# L6bBiusHgJBYRoz4GTlmKjxaLG3P1NmHVY15CxKIe0CP1cf4S41VFmOtt1fcOyu9
# 08FPHgOHS0Sb4+JARSbzJkkraoTxVHrUQtr802q7Zn7Knurpu9wHx8OSToM8gUmf
# ktUyCepJLqERcZo20sVOaLbLDhslFq9s3l122B9ysZMmhhfbGN6vRenf+5ivFBjt
# pF72iZRF8FUESt3/J90GSkD2tLzx5A+ZArv9XQ4uKMG+O18aP5cQhLwWPtijnGMd
# ZstcX9o+8w8KCTUi29vAPwD55g1dZ9H9oB4DK9lA977Mh2ZUgKajuPUZYtXSJrGY
# Ju6ay0SnRVqBlRUa9VEwggTmMIIDzqADAgECAhBiXE2QjNVC+6supXM/8VQZMA0G
# CSqGSIb3DQEBBQUAMIGVMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVVQxFzAVBgNV
# BAcTDlNhbHQgTGFrZSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdv
# cmsxITAfBgNVBAsTGGh0dHA6Ly93d3cudXNlcnRydXN0LmNvbTEdMBsGA1UEAxMU
# VVROLVVTRVJGaXJzdC1PYmplY3QwHhcNMTEwNDI3MDAwMDAwWhcNMjAwNTMwMTA0
# ODM4WjB6MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEg
# MB4GA1UEAxMXQ09NT0RPIFRpbWUgU3RhbXBpbmcgQ0EwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCqgvGEqVvYcbXSXSvt9BMgDPmb6dGPdF5u7uspSNjI
# vizrCmFgzL2SjXzddLsKnmhOqnUkcyeuN/MagqVtuMgJRkx+oYPp4gNgpCEQJ0Ca
# WeFtrz6CryFpWW1jzM6x9haaeYOXOh0Mr8l90U7Yw0ahpZiqYM5V1BIR8zsLbMaI
# upUu76BGRTl8rOnjrehXl1/++8IJjf6OmqU/WUb8xy1dhIfwb1gmw/BC/FXeZb5n
# OGOzEbGhJe2pm75I30x3wKoZC7b9So8seVWx/llaWm1VixxD9rFVcimJTUA/vn9J
# AV08m1wI+8ridRUFk50IYv+6Dduq+LW/EDLKcuoIJs0ZAgMBAAGjggFKMIIBRjAf
# BgNVHSMEGDAWgBTa7WR0FJwUPKvdmam9WyhNizzJ2DAdBgNVHQ4EFgQUZCKGtkqJ
# yQQP0ARYkiuzbj0eJ2wwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8C
# AQAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwEQYDVR0gBAowCDAGBgRVHSAAMEIGA1Ud
# HwQ7MDkwN6A1oDOGMWh0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9VVE4tVVNFUkZp
# cnN0LU9iamVjdC5jcmwwdAYIKwYBBQUHAQEEaDBmMD0GCCsGAQUFBzAChjFodHRw
# Oi8vY3J0LnVzZXJ0cnVzdC5jb20vVVROQWRkVHJ1c3RPYmplY3RfQ0EuY3J0MCUG
# CCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEB
# BQUAA4IBAQARyT3hBeg7ZazJdDEDt9qDOMaSuv3N+Ntjm30ekKSYyNlYaDS18Ash
# U55ZRv1jhd/+R6pw5D9eCJUoXxTx/SKucOS38bC2Vp+xZ7hog16oYNuYOfbcSV4T
# p5BnS+Nu5+vwQ8fQL33/llqnA9abVKAj06XCoI75T9GyBiH+IV0njKCv2bBS7vzI
# 7bec8ckmONalMu1Il5RePeA9NbSwyVivx1j/YnQWkmRB2sqo64sDvcFOrh+RMrjh
# JDt77RRoCYaWKMk7yWwowiVp9UphreAn+FOndRWwUTGw8UH/PlomHmB+4uNqOZrE
# 6u4/5rITP1UDBE0LkHLU6/u8h5BRsjgZMIIE/jCCA+agAwIBAgIQK3PbdGMRTFpb
# MkryMFdySTANBgkqhkiG9w0BAQUFADB6MQswCQYDVQQGEwJHQjEbMBkGA1UECBMS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFD
# T01PRE8gQ0EgTGltaXRlZDEgMB4GA1UEAxMXQ09NT0RPIFRpbWUgU3RhbXBpbmcg
# Q0EwHhcNMTkwNTAyMDAwMDAwWhcNMjAwNTMwMTA0ODM4WjCBgzELMAkGA1UEBhMC
# R0IxGzAZBgNVBAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBwwHU2FsZm9y
# ZDEYMBYGA1UECgwPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDDCJTZWN0aWdvIFNI
# QS0xIFRpbWUgU3RhbXBpbmcgU2lnbmVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAv1I2gjrcdDcNeNV/FlAZZu26GpnRYziaDGayQNungFC/aS42Lwpn
# P0ChSopjNZvQGcx0qhcZkSu1VSAZ+8AaOm3KOZuC8rqVoRrYNMe4iXtwiHBRZmns
# d/7GlHJ6zyWB7TSCmt8IFTcxtG2uHL8Y1Q3P/rXhxPuxR3Hp+u5jkezx7M5ZBBF8
# rgtgU+oq874vAg/QTF0xEy8eaQ+Fm0WWwo0Si2euH69pqwaWgQDfkXyVHOaeGWTf
# dshgRC9J449/YGpFORNEIaW6+5H6QUDtTQK0S3/f4uA9uKrzGthBg49/M+1BBuJ9
# nj9ThI0o2t12xr33jh44zcDLYCQD3npMqwIDAQABo4IBdDCCAXAwHwYDVR0jBBgw
# FoAUZCKGtkqJyQQP0ARYkiuzbj0eJ2wwHQYDVR0OBBYEFK7u2WC6XvUsARL9jo2y
# VXI1Rm/xMA4GA1UdDwEB/wQEAwIGwDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQM
# MAoGCCsGAQUFBwMIMEAGA1UdIAQ5MDcwNQYMKwYBBAGyMQECAQMIMCUwIwYIKwYB
# BQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMEIGA1UdHwQ7MDkwN6A1oDOG
# MWh0dHA6Ly9jcmwuc2VjdGlnby5jb20vQ09NT0RPVGltZVN0YW1waW5nQ0FfMi5j
# cmwwcgYIKwYBBQUHAQEEZjBkMD0GCCsGAQUFBzAChjFodHRwOi8vY3J0LnNlY3Rp
# Z28uY29tL0NPTU9ET1RpbWVTdGFtcGluZ0NBXzIuY3J0MCMGCCsGAQUFBzABhhdo
# dHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQUFAAOCAQEAen+pStKw
# pBwdDZ0tXMauWt2PRR3wnlyQ9l6scP7T2c3kGaQKQ3VgaoOkw5mEIDG61v5MzxP4
# EPdUCX7q3NIuedcHTFS3tcmdsvDyHiQU0JzHyGeqC2K3tPEG5OfkIUsZMpk0uRlh
# dwozkGdswIhKkvWhQwHzrqJvyZW9ljj3g/etfCgf8zjfjiHIcWhTLcuuquIwF4Mi
# KRi14YyJ6274fji7kE+5Xwc0EmuX1eY7kb4AFyFu4m38UnnvgSW6zxPQ+90rzYG2
# V4lO8N3zC0o0yoX/CLmWX+sRE+DhxQOtVxzhXZIGvhvIPD+lIJ9p0GnBxcLJPufF
# cvfqG5bilK+GLjCCBUwwggQ0oAMCAQICEQCV7K1bRdp1yZPPBYrFbG8VMA0GCSqG
# SIb3DQEBCwUAMHwxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNo
# ZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRl
# ZDEkMCIGA1UEAxMbU2VjdGlnbyBSU0EgQ29kZSBTaWduaW5nIENBMB4XDTE5MTAx
# NTAwMDAwMFoXDTIwMTAwNzIzNTk1OVowgZQxCzAJBgNVBAYTAlVTMQ4wDAYDVQQR
# DAU2MDEyMDERMA8GA1UECAwISWxsaW5vaXMxDjAMBgNVBAcMBUVsZ2luMRowGAYD
# VQQJDBExMjg3IEJsYWNraGF3ayBEcjEaMBgGA1UECgwRU2hhbm5vbiBHcmF5YnJv
# b2sxGjAYBgNVBAMMEVNoYW5ub24gR3JheWJyb29rMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEA1A3wiJRalXGleCYOLaKdlD5iZrswpu4ChSnCx8XvkWeL
# R/XBQSvebJXpF99sdVwwUeouEk1i5EA2AIU88DoEw0+1XxC6DAUwYAVXmo3M+dkv
# OwNXHrWwSRqNwmhABHVejGOInKsi1jYa3DPI2dFBL19Trg0ez0oXkMVwbKGDpwt9
# U7WbbjveLcAPnpvR65dk3Jhb9bmCMirCnALjaOOnFzlCUiagx9nDszzw7fYRAlf6
# EJNnicwwBujOmA59q9urwAuEA7/VXTAMpE2wmhVsM4xqscbzAPs7PSVgkOTrZR6a
# 51r1HSCzrULISVZKxF0mD4/6qOElqM/X/nd7q7dmSQIDAQABo4IBrjCCAaowHwYD
# VR0jBBgwFoAUDuE6qFM6MdWKvsG7rWcaA4WtNA4wHQYDVR0OBBYEFJHiTLW7XSJv
# Xn/hpQzh7bxSIUZ2MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBABgNVHSAEOTA3MDUG
# DCsGAQQBsjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29t
# L0NQUzBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLnNlY3RpZ28uY29tL1Nl
# Y3RpZ29SU0FDb2RlU2lnbmluZ0NBLmNybDBzBggrBgEFBQcBAQRnMGUwPgYIKwYB
# BQUHMAKGMmh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWdu
# aW5nQ0EuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAm
# BgNVHREEHzAdgRtzaGFubm9uLmdyYXlicm9va0BnbWFpbC5jb20wDQYJKoZIhvcN
# AQELBQADggEBACNm23H5GuT8THomfaxBDdgN/4g4FgsClLsxhAyRyWxqnE4udxre
# x1Dq3FQtdXoeXFPaaFYVH/zvmEFuh+oz65Ejomo2WPSOVKiF6NbLpxScHW2c1+yO
# NHDqn/TGtx0+RrfUgOFgao/AzuRqxei90CotgUe73cpmG0JPdmV1+hnMAhojoO4g
# bhfdb69y8fCaDzLoTmybz1JOfcinR12TLntNV+Def2CXaNoOV2VNKpauAiIh2BkK
# 7LoabyBtMNQbMNCY33dyNq9V7tvVxdYOlPRoANB3SfATPtKQCrix7T85qrFoRHBC
# SxTfYFHsyGQVno6lmMfQstJ6q+TQJz1gFcUwggX1MIID3aADAgECAhAdokgwb5sm
# GNCC4JZ9M9NqMA0GCSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNVBAoTFVRo
# ZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xODExMDIwMDAwMDBaFw0zMDEyMzEyMzU5
# NTlaMHwxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIx
# EDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEkMCIG
# A1UEAxMbU2VjdGlnbyBSU0EgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAhiKNMoV6GJ9J8JYvYwgeLdx8nxTP4ya2JWYpQIZU
# RnQxYsUQ7bKHJ6aZy5UwwFb1pHXGqQ5QYqVRkRBq4Etirv3w+Bisp//uLjMg+gwZ
# iahse60Aw2Gh3GllbR9uJ5bXl1GGpvQn5Xxqi5UeW2DVftcWkpwAL2j3l+1qcr44
# O2Pej79uTEFdEiAIWeg5zY/S1s8GtFcFtk6hPldrH5i8xGLWGwuNx2YbSp+dgcRy
# QLXiX+8LRf+jzhemLVWwt7C8VGqdvI1WU8bwunlQSSz3A7n+L2U18iLqLAevRtn5
# RhzcjHxxKPP+p8YU3VWRbooRDd8GJJV9D6ehfDrahjVh0wIDAQABo4IBZDCCAWAw
# HwYDVR0jBBgwFoAUU3m/WqorSs9UgOHYm8Cd8rIDZsswHQYDVR0OBBYEFA7hOqhT
# OjHVir7Bu61nGgOFrTQOMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdJQQWMBQGCCsGAQUFBwMDBggrBgEFBQcDCDARBgNVHSAECjAIMAYG
# BFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC51c2VydHJ1c3QuY29t
# L1VTRVJUcnVzdFJTQUNlcnRpZmljYXRpb25BdXRob3JpdHkuY3JsMHYGCCsGAQUF
# BwEBBGowaDA/BggrBgEFBQcwAoYzaHR0cDovL2NydC51c2VydHJ1c3QuY29tL1VT
# RVJUcnVzdFJTQUFkZFRydXN0Q0EuY3J0MCUGCCsGAQUFBzABhhlodHRwOi8vb2Nz
# cC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBNY1DtRzRKYaTb3moq
# jJvxAAAeHWJ7Otcywvaz4GOz+2EAiJobbRAHBE++uOqJeCLrD0bs80ZeQEaJEvQL
# d1qcKkE6/Nb06+f3FZUzw6GDKLfeL+SU94Uzgy1KQEi/msJPSrGPJPSzgTfTt2Sw
# piNqWWhSQl//BOvhdGV5CPWpk95rcUCZlrp48bnI4sMIFrGrY1rIFYBtdF5KdX6l
# uMNstc/fSnmHXMdATWM19jDTz7UKDgsEf6BLrrujpdCEAJM+U100pQA1aWy+nyAl
# EA0Z+1CQYb45j3qOTfafDh7+B1ESZoMmGUiVzkrJwX/zOgWb+W/fiH/AI57SHkN6
# RTHBnE2p8FmyWRnoao0pBAJ3fEtLzXC+OrJVWng+vLtvAxAldxU0ivk2zEOS5LpP
# 8WKTKCVXKftRGcehJUBqhFfGsp2xvBwK2nxnfn0u6ShMGH7EezFBcZpLKewLPVdQ
# 0srd/Z4FUeVEeN0B3rF1mA1UJP3wTuPi+IO9crrLPTru8F4XkmhtyGH5pvEqCgul
# ufSe7pgyBYWe6/mDKdPGLH29OncuizdCoGqC7TtKqpQQpOEN+BfFtlp5MxiS47V1
# +KHpjgolHuQe8Z9ahyP/n6RRnvs5gBHN27XEp6iAb+VT1ODjosLSWxr6MiYtaldw
# HDykWC6j81tLB9wyWfOHpxptWDGCBF8wggRbAgEBMIGRMHwxCzAJBgNVBAYTAkdC
# MRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQx
# GDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEkMCIGA1UEAxMbU2VjdGlnbyBSU0Eg
# Q29kZSBTaWduaW5nIENBAhEAleytW0XadcmTzwWKxWxvFTAJBgUrDgMCGgUAoHgw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQx
# FgQU4oTPa2PvI1rt56LIk9LYQSCVt1AwDQYJKoZIhvcNAQEBBQAEggEALxqMgP3Z
# C6rk7cCzdv2qf36W/Gdf1WUp+kTwycI8+HLYEktjCl7HL8AlwY0A8u4Zrq45Bl+t
# siToLA0yDtGLlwsltTc1T0z+r2ROL7yQcTv6+Sa6yjwdnbGfsyL/dpKWckmJ49NX
# W31NsY1FcQcxy/ckA+S2BiAfX1q87H6fHez6R/KrhpYWMHcOPGdcJ9UNFdXiDlJ/
# 64G+TBo+Rute/x+ED0U5XyJBVX3wUrU9fo8X9ZQqUqAheMaNVy2Z8z6QdFaUeEw/
# IRKQCTs2y/tkgw8ZlFe6utvj1z3SWr38gQ5v0dbBhiapMexhOS1pBqkqaHL+BYdf
# eT9PlrzytMo8lKGCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB6MQsw
# CQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQH
# EwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEgMB4GA1UEAxMX
# Q09NT0RPIFRpbWUgU3RhbXBpbmcgQ0ECECtz23RjEUxaWzJK8jBXckkwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTIwMDEyMzE2MDY1MVowIwYJKoZIhvcNAQkEMRYEFH7r/B4CobLsa4kbYO3Vyhwn
# Oqn4MA0GCSqGSIb3DQEBAQUABIIBAFeL4LHM53Yk2XmdYXjM4CK3lqlFeKXj+cHh
# FruyMAve7UIfeJqH+hCJX3knvhsMCLCAfZuisPcQQu3JL3O9SzNvxK1cFS1Ecv1D
# uztJSvqAH74ygJRCXQDRtbaAsiOpkrqoZfAkCj67uw32dVSOyCA+kTSrQTf33rgC
# mwe+FKhLRcL4e7OIL5US++8PjIuXLxYk8+n5Rs+q7BL5DEtGzsJD2ZSCYdWSDKB4
# KxvAM2H8DkRn8UMo9sPrseYeqJsg8pOP/5T3vcpxQTf9K5N/kk1Iz8r6yJBj3UIA
# qgK32lp6bbykf7Ie0WrEKrohRkh1e5EMZbVp+dTYkMfrEvB3H3k=
# SIG # End signature block
