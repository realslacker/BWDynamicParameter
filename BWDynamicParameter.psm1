<#
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

# This example illustrates the creation of many dynamic parameters using New-DynamicParam
# You must create a RuntimeDefinedParameterDictionary object ($dictionary here)
# To each New-DynamicParameter call, add the -DPDictionary parameter pointing to this RuntimeDefinedParameterDictionary
# At the end of the DynamicParam block, return the RuntimeDefinedParameterDictionary
# Initialize all bound parameters using the provided block or similar code

function Test-DynamicParameter {

    [CmdletBinding()]
    param(

        [switch]
        $ChangeParams
        
    )
        
    dynamicparam {

        DynamicParameterDictionary {

            DynamicParameter -Name AlwaysParam -ValidateSet @( gwmi win32_volume | %{$_.driveletter} | sort )

            #Add dynamic parameters to $DPDictionary
            if ( $ChangeParams.IsPresent ) {

                DynamicParameter -Name Param1 -ValidateSet 1,2 -mandatory
                DynamicParameter -Name Param2
                DynamicParameter -Name Param3 -Type DateTime
            
            } else {

                DynamicParameter -Name Param4 -Mandatory
                DynamicParameter -Name Param5
                DynamicParameter -Name Param6 -Type DateTime
            
            }

        }

    }

    begin {

        # this standard block of code loops through bound parameters...
        # if no corresponding variable exists, one is created

        # get common parameters
        $CommonParameters = { function _temp { [CmdletBinding()]param() }; ( Get-Command _temp | Select-Object -ExpandProperty Parameters ).Keys }.Invoke()

        # pick out bound parameters not in that set
        $PSBoundParameters.Keys |
            Where-Object { $_ -notin $CommonParameters } |
            Where-Object { -not( Get-Variable -Name $_ -Scope 0 -ErrorAction SilentlyContinue ) } |
            ForEach-Object { New-Variable -Name $_ -Value $PSBoundParameters[$_] }
    }

    process {

        #Appropriate variables should now be defined and accessible
        Get-Variable -scope 0 |
            Where-Object { $_.Name -in $PSBoundParameters.Keys }

    }
}

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

            Write-Information 'Processing scriptblock...'

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

New-Alias -Name DynamicParameter -Value New-DynamicParam
New-Alias -Name DynamicParameterDictionary -Value New-DynamicParameterDictionary
