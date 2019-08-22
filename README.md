# BWDynamicParameter
Easily create dynamic parameters with extended validation.

# Examples

## Generating a Dynamic Parameter

This example shows creating a new Dynamic Parameter and storing it in the $EmailParam variable. This parameter is **mandatory**, is validated against a regex for formatting, and uses validate script to verify the domain has a valid MX.

```PowerShell
C:\ > $EmailParam = New-DynamicParameter -Name 'Email' -Mandatory -Alias 'Mail' -ValidatePattern '^.+@.+\..+$' -ValidateScript { [bool](Resolve-DnsName -Type MX -Name $_.Split('@', 2)[1]) -ErrorAction SilentlyContinue }
```

## Generating a Dynamic Parameter Dictionary

You can create a basic DP Dictionary by calling New-DynamicParameterDictionary

```PowerShell
C:\ > $DPDictionary = New-DynamicParameterDictionary
```

You can also include previously generated parameters in the command line

```PowerShell
C:\ > New-DynamicParameterDictionary -DynamicParameters $EmailParam
```

Finally, you can supply a script block allowing logic in the definition

```Powershell
DynamicParameterDictionary {

    DynamicParameter -Name 'Email' -Mandatory -Alias 'Mail' -ValidatePattern '^.+@.+\..+$' -ValidateScript { [bool](Resolve-DnsName -Type MX -Name $_.Split('@', 2)[1]) -ErrorAction SilentlyContinue }
    
}
```

## Basic Script Example

This script shows how you might use this module in your script.

```PowerShell
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
        
        # expands $PSBoundParameters into the current scope
        $CommonParameters = { function _temp { [CmdletBinding()] param() }; (Get-Command _temp | Select-Object -ExpandProperty Parameters).Keys }.Invoke()
        $PSBoundParameters.Keys |
            Where-Object { $CommonParameters -notcontains $_ } |
            Where-Object { -not( Get-Variable -Name $_ -Scope 0 -ErrorAction SilentlyContinue ) } |
            ForEach-Object { New-Variable -Name $_ -Scope 0 -Value $PSBoundParameters[$_] }
        
    }
    
    process {
        
        #Appropriate variables should now be defined and accessible
        Get-Variable -scope 0 |
            Where-Object { $_.Name -in $PSBoundParameters.Keys }
        
    }
}
```