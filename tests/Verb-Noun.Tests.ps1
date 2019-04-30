<#
    We have a constants.ps1 file that contains some special script level variables that are utilized for various reasons in our Pester tests.
    If you have a need to add anything simply request/or discuss in the Slack channel.

    The repository under sqlcollaborative\appveyor-lab contains files we utilize for certain intergration testing.
    These are mainly for testing commands where the object required cannot easily be created on the fly (e.g. certificates, database backups, etc.).

    Key script level items to remember are utilized for the Appveyor environment:
        $script:instance1 (SQL Server 2008 R2 Express Edition [SP2] Appveyor instance - localhost\sql2008r2sp2)
        $script:instance2 (SQL Server 2016 Developer Edition - localhost\sql2016)
        $instances (array of both instances noted above)
        $ssisserver (SQL Server Integration Service 2016 Developer Edition)
#>

<#
    The below statement stays in for every test you build.
#>
$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

<#
    Unit test is required for any command added
#>
Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'Computer', 'SqlInstance', 'SqlCredential', 'Credential', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}
<#
    Integration test are custom to the command you are writing it for,
        but something similar to below should be included if applicable.

    The below examples are by no means set in stone and there are already
        a number of test that you can pull examples from in how they are done.
#>

# Add-DbaNoun
Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    Context "XYZ is added properly" {
        $results = Add-DbaXyz <# your specific parameters and values #> -Confirm:$false

        It "Should show the proper LMN has been added" {
            $results.Property1 | Should Be "daper dan"
        }

        It "Should be in SomeSpecificLocation" {
            $results.PSParentPath | Should Be "51°16'25.7 N + 30°13'37.7 E"
        }
    }
}

# New-DbaNoun
Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    Context "Can generate/create a new XYZ" {
        BeforeAll {
            $results = New-DbaXyz <# your specific parameters #> -Silent
        }
        AfterAll {
            Remove-DbaXyz <# your specific parameters #> -Confirm:$false
        }
        It "Returns the right UGY" {
            "$($results.Property1)" -match 'SqlServer' | Should Be $true
        }
    }
}

# Get-DbaNoun
Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    Context "Command actually works" {
        $results = Get-DbaXyz -ComputerName $script:instance1, $script:instance2
        It "Should have correct properties" {
            $ExpectedProps = 'ComputerName,InstanceName,SqlInstance,Property1,Property2,Property3'.Split(',')
            ($results.PsObject.Properties.Name | Sort-Object) | Should Be ($ExpectedProps | Sort-Object)
        }

        It "Shows only one type of value" {
            foreach ($result in $results) {
                $result.Property1 | Should BeLike "*FilterValue*"
            }
        }
    }
}

# Invoke-DbaNoun
Describe "$CommandName Integration Test" -Tag "IntegrationTests" {
    $results = Invoke-DbaXyz -SqlInstance $script:instance1 -Type SpecialValue
    Context "Validate output" {
        It "Should have correct properties" {
            $ExpectedProps = 'ComputerName,InstanceName,SqlInstance,LogType,IsSuccessful,Notes'.Split(',')
            ($results.PsObject.Properties.Name | Sort-Object) | Should Be ($ExpectedProps | Sort-Object)
        }
        It "Should cycle instance error log" {
            $results.LogType | Should Be "instance"
        }
    }
}
