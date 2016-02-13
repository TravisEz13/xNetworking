$Global:DSCModuleName   = 'xNetworkAdapterName'
$Global:DSCResourceName = 'MSFT_xNetworkAdapterName'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:DSCResourceName {
    
        # Create the Mock Objects that will be used for running tests
        $MockNetAdapter = [PSCustomObject] @{
            Name                    = 'Ethernet'
            MacAddress              = '00-0D-3A-60-8C-C9'
        }
        
        $MockMultipleNetAdapter = @(
            [PSCustomObject] @{
                Name                    = 'Ethernet1'
                MacAddress              = '00-0D-3A-60-8C-C9'
            },
            [PSCustomObject] @{
                Name                    = 'MyEthernet'
                MacAddress              = '00-0D-3A-60-8C-D9'
            }
        )

        $TestAdapterKeys = @{
            Name                           = 'MyEthernet'
            MacAddress              = '00-0D-3A-60-8C-C9'
        } 
  
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
    
            Context 'Adapter does not exist' {
                
                Mock Get-NetAdapter
    
                It 'should return absent adapter' {
                    $Result = Get-TargetResource @TestAdapterKeys
                    $Result.Name | Should Be $null
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                } 
            }
    
            Context 'Adapter does exist' {
                
                Mock Get-NetAdapter -MockWith { $MockNetAdapter }
    
                It 'should return correct Route' {
                    $Result = Get-TargetResource @TestAdapterKeys
                    $Result.Name | Should Be 'Ethernet'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
            Context 'Multiple Adapters exist' {
                
                Mock Get-NetAdapter -MockWith { $MockMultipleNetAdapter }
    
                It 'should return correct Route' {
                    $Result = Get-TargetResource `
                        @TestAdapterKeys
                    $Result.Name | Should Be 'Ethernet1'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
    
            Context 'Adapter does not exist' {
                
                Mock Get-NetAdapter
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        $Splat.MacAddress = 'FF-0D-3A-60-8C-C9'
                        Set-TargetResource @Splat
                    } | Should Throw 'A NetAdapter matching the properties was not found. Please correct the properties and try again.'
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 0
                }
            }
    
            Context 'Adapter exists and should be renamed' {
                
                Mock Get-NetAdapter -MockWith { $MockNetAdapter }
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 1
                }
            }
            Context 'Multiple matching adapter exists name matches' {
                
                Mock Get-NetAdapter -MockWith { $MockMultipleNetAdapter }
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        $Splat.Name = 'Ethernet1'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 0
                }
            }
            Context 'Multiple matching adapter exists and name mismatches' {
                
                Mock Get-NetAdapter -MockWith { $MockMultipleNetAdapter }
                Mock Rename-NetAdapter
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestAdapterKeys.Clone()
                        $Splat.Name = 'MyEthernet2'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                    Assert-MockCalled -commandName Rename-NetAdapter -Exactly 1
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {

            Context 'NetAdapter does not exist' {
                
                Mock Get-NetAdapter -MockWith { $MockNetAdapter }
    
                It 'should return false' {
                    $Splat = $TestAdapterKeys.Clone()
                    Test-TargetResource @Splat | Should Be $False
                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
    
            Context 'NetAdapter exists and should but renamed' {
                
                Mock Get-NetAdapter -MockWith { $MockNetAdapter }
    
                It 'should return false' {
                    { 
                       $Splat = $TestAdapterKeys.Clone()
                        Test-TargetResource @Splat | Should Be $False
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }
            }
    
        }

        Describe "$($Global:DSCResourceName)\Test-ResourceProperty" {
      
            Context 'TBD' {
  
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
