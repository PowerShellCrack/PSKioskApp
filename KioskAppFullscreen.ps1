#set app settings
$AppTitle = 'Kiosk Full Screen'
$AppVersion = '1.1.0'
$AppTitlePosition = 'TopCenter'
$BackgroundImage = 'C:\Windows\Web\Wallpaper\CorporateWallpaper.jpg'
#set app controls
$AppOnTop = $False
$HideVersion = $false
$AllowDetailsHotkey = $true
$EnableTaskbarControl = $true


<#
# DISCLAIMER
This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  **THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE**.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys’ fees, that arise or result
from the use or distribution of the Sample Code.

This posting is provided "AS IS" with no warranties, and confers no rights. Use
of included script samples are subject to the terms specified
at https://www.microsoft.com/en-us/legal/copyright.

#>
#*=============================================
##* Runtime Function - REQUIRED
##*=============================================
#region FUNCTION: Check if running in ISE
Function Test-IsISE {
    # try...catch accounts for:
    # Set-StrictMode -Version latest
    try {
        return ($null -ne $psISE);
    }
    catch {
        return $false;
    }
}
#endregion

#region FUNCTION: Check if running in Visual Studio Code
Function Test-VSCode{
    if($env:TERM_PROGRAM -eq 'vscode') {
        return $true;
    }
    Else{
        return $false;
    }
}
#endregion

#region FUNCTION: Find script path for either ISE or console
Function Get-ScriptPath {
    <#
        .SYNOPSIS
            Finds the current script path even in ISE or VSC
        .LINK
            Test-VSCode
            Test-IsISE
    #>
    param(
        [switch]$Parent
    )

    Begin{}
    Process{
        if ($PSScriptRoot -eq "")
        {
            if (Test-IsISE)
            {
                $ScriptPath = $psISE.CurrentFile.FullPath
            }
            elseif(Test-VSCode){
                $context = $psEditor.GetEditorContext()
                $ScriptPath = $context.CurrentFile.Path
            }Else{
                $ScriptPath = (Get-location).Path
            }
        }
        else
        {
            $ScriptPath = $PSCommandPath
        }
    }
    End{

        If($Parent){
            Split-Path $ScriptPath -Parent
        }Else{
            $ScriptPath
        }
    }

}
#endregion
Function Show-KioskApp{
    #Slower method to present form for non modal (no popups)
    #$KioskApp.ShowDialog() | Out-Null

    # Allow input to window for TextBoxes, etc
    [Void][System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($KioskApp)

    #for ISE testing only: Add ESC key as a way to exit UI
    $code1 = {
        [System.Windows.Input.KeyEventArgs]$keyup = $args[1]
        if ($keyup.Key -eq 'F8')
        {
            If($KioskApp_grdDevice.Visibility -ne 'Visible'){
                $KioskApp_grdDevice.Visibility = 'Visible'
                If($HideVersion){$KioskApp_lblVersion.Visibility = 'Visible'}
            }Else{
                $KioskApp_grdDevice.Visibility = 'Hidden'
                If($HideVersion){$KioskApp_lblVersion.Visibility = 'Hidden'}
            }
        }
    }

    If($AllowDetailsHotkey){
        $null = $KioskApp.add_KeyUp($code1)
    }


    $KioskApp.Add_Closing({
        [System.Windows.Forms.Application]::Exit()
    })

    $async1 = $KioskApp.Dispatcher.InvokeAsync({

        #make sure this display on top of every window
        $KioskApp.Topmost = $true
        # Running this without $appContext & ::Run would actually cause a really poor response.
        $KioskApp.Show() | Out-Null
        # This makes it pop up
        $KioskApp.Activate() | Out-Null

        #$KioskApp.window.ShowDialog()
    })
    $async1.Wait() | Out-Null

    ## Force garbage collection to start form with slightly lower RAM usage.
    [System.GC]::Collect() | Out-Null
    [System.GC]::WaitForPendingFinalizers() | Out-Null

    # Create an application context for it to all run within.
    # This helps with responsiveness, especially when Exiting.
    $appContext1 = New-Object System.Windows.Forms.ApplicationContext
    [void][System.Windows.Forms.Application]::Run($appContext1)

    #[Environment]::Exit($ExitCode);
}
Function Convert-ImagetoBase64String{
    Param([String]$path)
    [convert]::ToBase64String((get-content $path -encoding byte))
}

Function Get-PlatformInfo {
    # Returns device Manufacturer, Model and BIOS version, populating global variables for use in other functions/ validation
    # Note that platformType is appended to psobject by Get-PlatformValid - type is manually defined by user to ensure accuracy
    [CmdletBinding()]
    [OutputType([PsObject])]
    Param()
    try{
        $CIMSystemEncloure = Get-CIMInstance Win32_SystemEnclosure -ErrorAction Stop
        $CIMComputerSystem = Get-CIMInstance CIM_ComputerSystem -ErrorAction Stop
        $CIMBios = Get-CIMInstance Win32_BIOS -ErrorAction Stop

        $NetAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.Ipaddress.length -gt 1}

        [boolean]$Is64Bit = [boolean]((Get-WmiObject -Class 'Win32_Processor' | Where-Object { $_.DeviceID -eq 'CPU0' } | Select-Object -ExpandProperty 'AddressWidth') -eq 64)
        If ($Is64Bit) { [string]$envOSArchitecture = '64-bit' } Else { [string]$envOSArchitecture = '32-bit' }

        New-Object -TypeName PsObject -Property @{
            "ComputerName" = [system.environment]::MachineName
            "ComputerDomain" = $CIMComputerSystem.Domain
            "PlatformBIOS" = $CIMBios.SMBIOSBIOSVersion
            "PlatformManufacturer" = $CIMComputerSystem.Manufacturer
            "PlatformModel" = $CIMComputerSystem.Model
            "AssetTag" = $CIMSystemEncloure.SMBiosAssetTag
            "SerialNumber" = $CIMBios.SerialNumber
            "Architecture" = $envOSArchitecture
            'IPAddress' = $NetAdapter.ipaddress[0]
            'MACAddress' = $NetAdapter.macaddress[0]
            }
    }
    catch{Write-Output "CRITICAL" "Failed to get information from Win32_Computersystem/ Win32_BIOS"}
}
#endregion

#$bitmapcode = Convert-ImagetoBase64String -path D:\LAB\CBP\CBPLogo.jpg
##*=============================================
##* VARIABLE DECLARATION
##*=============================================


#region VARIABLES: Building paths & values
# Use function to get paths because Powershell ISE & other editors have differnt results
[string]$scriptPath = Get-ScriptPath
[string]$scriptRoot = Split-Path -Path $scriptPath -Parent

#Get wallpaper path
If(Test-Path $BackgroundImage){
    [string]$WallpaperPath = $BackgroundImage
}
ElseIf(Test-Path "$scriptRoot\$BackgroundImage"){
    [string]$WallpaperPath = Join-Path -Path $scriptRoot -ChildPath $BackgroundImage
}
Else{
    [string]$WallpaperPath = $null
}

#get device info
$DeviceInfo = Get-PlatformInfo

#=======================================================
# LOAD ASSEMBLIES
#=======================================================
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration')  | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')      | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  | out-null

$AppBase64Icon_32px = "
AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAAIcdAACHHQAAAAAA
AAAAAADw597/0c7J/5eXlv+Hh4f/h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/
h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eIiP+H
iIj/h4eH/5aVlf/Rzcn/8ejf/9LPyv9eX17/MTIy/y8wMP8vMDD/LzAw/y8wMP8vMDD/LzAw/y8w
MP8vMDD/LzAw/y8wMP8vMDD/LzAw/y8wMP8vMDD/LzAw/y8wMP8vMDD/LzAw/y8wMP8vMDD/LzAw
/y8wMP8vMDD/LzAw/y8wMP8vMDD/MTIy/11eXf/Szsn/mpmY/zEyMv8wMTH/MDEx/zAxMf8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MTIy/5mZmP+HiIj/LzAw/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/
h4iI/4eHh/8vMDD/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/MDEx/y8wMP+Hh4f/h4iI/y8wMP8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/LzAw/4eIiP+HiIj/LzAw/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/h4iI/4eIiP8vMDD/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/y8wMP+H
iIj/h4iI/y8wMP8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8wMTH/LzAw/4eIiP+HiIj/LzAw/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/h4iI/4eIiP8vMDD/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/y8wMP+HiIj/h4iI/y8wMP8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/LzAw/4eI
iP+HiIj/LzAw/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/LzAw/zAxMf8xMjL/MDEx
/y8wMP8yMzP/MDEx/zAxMf8yMzP/MDEx/zAxMf8wMTH/MDEx/zEyMv8wMTH/MDEx/zAxMf8wMTH/
MDEx/zAxMf8vMDD/h4iI/4eIiP8vMDD/MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/Ozw8/25vb/9A
QUH/eHh4/15fX/9WV1f/ZGVl/4WFhf9zdHT/SUpK/3t8fP93d3f/VVZW/1xcXP9zc3P/Tk9P/y8w
MP8wMTH/MDEx/zAxMf8wMTH/MDEx/y8wMP+HiIj/h4iI/y8wMP8wMTH/MDEx/zAxMf8wMTH/MDEx
/y8wMP9BQkL/mZmZ/4yNjf9vcHD/XV5e/31+fv+PkJD/Q0RE/4CBgf9pamr/Zmdn/5SUlP9ubm7/
r7Cw/3l6ev80NTX/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/LzAw/4eIiP+HiIj/LzAw/zAxMf8w
MTH/MDEx/zAxMf8wMTH/LzAw/z9AQP+7u7v/k5SU/y8wMP9cXFz/ent7/46Pj/9QUVH/hoaG/3p7
e/+cnZ3/X2Bg/19gYP+srKz/e3t7/zU2Nv8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/h4iI
/4eIiP8vMDD/MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/QEFB/6Kiov+PkJD/UVJS/0dISP9QUVH/
V1dX/3x9ff9sbGz/P0BA/3BwcP9sbW3/ZGRk/3Bxcf9mZ2f/REVF/y8wMP8wMTH/MDEx/zAxMf8w
MTH/MDEx/y8wMP+HiIj/h4iI/y8wMP8wMTH/MDEx/zAxMf8wMTH/MDEx/y8wMP8+Pz//fH19/1FS
Uv+CgoL/VlZW/09QUP8tLi7/LzAw/y4vL/8vMDD/Li8v/ywuLv9ZWlr/aGlp/ywtLf8wMTH/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/LzAw/4eIiP+HiIj/LzAw/zAxMf8wMTH/MDEx/zAxMf8wMTH/
MDEx/zEyMv81Njb/MDEx/zc4OP83ODj/NTY2/zAxMf8wMTH/MDEx/zAxMf8wMTH/LzAw/zk6Ov88
PT3/LzAw/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/h4iI/4eIiP8vMDD/MDEx/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8wMTH/LzAw/y8wMP8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/y8wMP+HiIj/
h4iI/y8wMP8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/LzAw/4eIiP+HiIj/LzAw/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/h4iI/4eIiP8vMDD/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/y8wMP+HiIj/h4iI/y8wMP8wMTH/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/LzAw/4eIiP+H
iIj/LzAw/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8vMDD/h4iI/4eIiP8vMDD/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/y8wMP+HiIj/h4iI/y8wMP8wMTH/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/LzAw/4eIiP+Hh4f/LzAw/zAxMf8wMTH/
MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8vMDD/h4eH/4eI
iP8vMDD/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx
/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/
MDEx/y8wMP+HiIj/mJiX/zEyMv8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8w
MTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAxMf8wMTH/MDEx/zAx
Mf8wMTH/MDEx/zAxMf8wMTH/MTIy/5iZmf/Rzsv/YGBg/zIzM/8vMDD/LzAw/y8wMP8vMDD/LzAw
/y8wMP8vMDD/LzAw/y8wMP8vMDD/LzAw/y8wMP8vMDD/LzAw/y8wMP8vMDD/LzAw/y8wMP8vMDD/
LzAw/y8wMP8vMDD/LzAw/y8wMP8vMDD/LzAw/zEyMv9eX1//y8rK/+fh3P/Ny8n/mpqZ/4eIiP+H
h4f/h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eI
iP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eIiP+HiIj/h4iI/4eHh/+HiIj/mJiY/8zJyP/j3tr/AAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAA="

# LOAD APP XAML (Built by Visual Studio 2019)
#==========================================
$xamlpath = @"
<Window x:Class="KioskApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        Name="KioskApp"
        WindowState="Maximized"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        ShowInTaskbar="True">
    <Window.Resources>
        <Style TargetType="{x:Type Button}">
            <!-- This style is used for buttons, to remove the WPF default 'animated' mouse over effect -->
            <Setter Property="OverridesDefaultStyle" Value="True"/>
            <Setter Property="Foreground" Value="#FFEAEAEA"/>
            <Setter Property="Background" Value="#313130"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button" >

                        <Border Name="border"
                                    BorderThickness="1"
                                    Padding="4,2"
                                    BorderBrush="#FFEAEAEA"
                                    CornerRadius="5"
                                    Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center"
                                                  VerticalAlignment="Center"
                                                  TextBlock.FontSize="10px"
                                                  TextBlock.TextAlignment="Center"
                                                  />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#FF919191" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Window.Background>
        <SolidColorBrush Opacity="0.8" Color="White"/>
    </Window.Background>
    <Grid  Background="#000000">
        <Label x:Name="lbltitle" Content="Kiosk Full Screen" FontSize="36" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Top" VerticalContentAlignment="Center" HorizontalContentAlignment="Center" Margin="0,0,1,0" Width="762"/>
        <Image x:Name="imgWallpaper" HorizontalAlignment="Left" VerticalAlignment="Center" Panel.ZIndex="-1"/>
        <Grid Margin="0" Name="grdDevice" Grid.Column="0" HorizontalAlignment="Right" VerticalAlignment="Top" Height="216" Background="Black" Width="305">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="auto" MinWidth="121"></ColumnDefinition>
                <ColumnDefinition></ColumnDefinition>
                <ColumnDefinition Width="auto"></ColumnDefinition>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition></RowDefinition>
                <RowDefinition></RowDefinition>
                <RowDefinition></RowDefinition>
                <RowDefinition></RowDefinition>
                <RowDefinition></RowDefinition>
                <RowDefinition></RowDefinition>
                <RowDefinition></RowDefinition>
            </Grid.RowDefinitions>
            <Label Content="Device Name:" Grid.Column="0" Grid.Row="0" HorizontalAlignment="Right" FontSize="16"  VerticalAlignment="Center" Foreground="White" Height="31" Width="121" HorizontalContentAlignment="Right"/>
            <TextBox x:Name="txtDeviceName" Grid.Column="1" Grid.Row="0" HorizontalAlignment="Left" TextWrapping="NoWrap" FontSize="18" IsReadOnly="True" Margin="0,5,0,4" Width="174" BorderBrush="Black" Background="Black" Foreground="DarkGray" />
            <Label Content="Manufacturer:" Grid.Column="0" Grid.Row="1" HorizontalAlignment="Right" FontSize="16"  VerticalAlignment="Center" Foreground="White" Height="31" Width="121" HorizontalContentAlignment="Right"/>
            <TextBox x:Name="txtMake" Grid.Column="1" Grid.Row="1" HorizontalAlignment="Left" TextWrapping="NoWrap" FontSize="18" IsReadOnly="True" Margin="0,5,0,4" Width="174" BorderBrush="Black" Background="Black" Foreground="DarkGray" />
            <Label Content="Model:"  Grid.Column="0" Grid.Row="2" HorizontalAlignment="Right" FontSize="16" VerticalAlignment="Center" Foreground="White" Height="31" Width="121" HorizontalContentAlignment="Right"/>
            <TextBox x:Name="txtModel" Grid.Column="1" Grid.Row="2" HorizontalAlignment="Left" TextWrapping="NoWrap" FontSize="18" IsReadOnly="True" Margin="0,4,0,5" Width="174" BorderBrush="Black" Background="Black" Foreground="DarkGray" />
            <Label Content="Asset Tag:" Grid.Column="0" Grid.Row="3" HorizontalAlignment="Right" FontSize="16" VerticalAlignment="Center" Foreground="White" Height="31" Width="121" HorizontalContentAlignment="Right"/>
            <TextBox x:Name="txtAssetTag" Grid.Column="1" Grid.Row="3" HorizontalAlignment="Left" TextWrapping="NoWrap" FontSize="18" IsReadOnly="True" Margin="0,4,0,5" Width="174" BorderBrush="Black" Background="Black" Foreground="DarkGray" />
            <Label Content="Serial Number:" Grid.Column="0" Grid.Row="4" HorizontalAlignment="Right" FontSize="16" VerticalAlignment="Center" Foreground="White" Height="31" Width="121" HorizontalContentAlignment="Right"/>
            <TextBox x:Name="txtSerialNumber" Grid.Column="1" Grid.Row="4" HorizontalAlignment="Left" TextWrapping="NoWrap" FontSize="18" IsReadOnly="True" Margin="0,4,0,5" Width="174" BorderBrush="Black" Background="Black" Foreground="DarkGray" />
            <Label Content="Mac Address:" Grid.Column="0" Grid.Row="5" HorizontalAlignment="Right" FontSize="16" VerticalAlignment="Center" Foreground="White" Height="31" Width="121" HorizontalContentAlignment="Right"/>
            <TextBox x:Name="txtMacAddress" Grid.Column="1" Grid.Row="5" HorizontalAlignment="Left" TextWrapping="NoWrap" FontSize="18" IsReadOnly="True" Margin="0,5,0,4" Width="174" BorderBrush="Black" Background="Black" Foreground="DarkGray" />
            <Label Content="IP Address:" Grid.Column="0" Grid.Row="6" HorizontalAlignment="Right" FontSize="16" VerticalAlignment="Center" Foreground="White" Height="31" Width="121" HorizontalContentAlignment="Right"/>
            <TextBox x:Name="txtIPAddress" Grid.Column="1" Grid.Row="6" HorizontalAlignment="Left" TextWrapping="NoWrap" FontSize="18" IsReadOnly="True" Margin="0,4,0,5" Width="174" BorderBrush="Black" Background="Black" Foreground="DarkGray" />
        </Grid>
        <Label x:Name="lblVersion" FontSize="10" HorizontalAlignment="Right" VerticalAlignment="Bottom" HorizontalContentAlignment="Right" Width="96" Foreground="DarkGray"/>
    </Grid>
</Window>
"@

[xml]$HXAML = $xamlpath -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'

$AppHideReader=(New-Object System.Xml.XmlNodeReader $HXAML)
try{
    $KioskApp=[Windows.Markup.XamlReader]::Load($AppHideReader)
}
catch{
    $ErrorMessage = $_.Exception.Message
    Write-Host "Unable to load Windows.Markup.XamlReader for $xamlpathH. Some possible causes for this problem include:
    - .NET Framework is missing
    - PowerShell must be launched with PowerShell -sta
    - invalid XAML code was encountered
    - The error message was [$ErrorMessage]" -ForegroundColor White -BackgroundColor Red
    Exit
}

$HXAML.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name "KioskApp_$($_.Name)" -Value $KioskApp.FindName($_.Name)}

#================================
# SET PROPERTY IN APP
#================================
[string]$KioskApp_lbltitle.Content = $AppTitle
[string]$KioskApp_lblVersion.Content = "Version $AppVersion"
If($HideVersion){$KioskApp_lblVersion.Visibility = 'Hidden'}Else{$KioskApp_lblVersion.Visibility = 'Visible'}

If(-Not[string]::IsNullOrEmpty($WallpaperPath) ){
    $KioskApp_imgWallpaper.source = $WallpaperPath
}
[string]$KioskApp_grdDevice.Visibility = 'hidden'

[string]$KioskApp_txtDeviceName.Text = $DeviceInfo.ComputerName
[string]$KioskApp_txtSerialNumber.Text = $DeviceInfo.SerialNumber
[string]$KioskApp_txtAssetTag.Text = $DeviceInfo.AssetTag
[string]$KioskApp_txtIPAddress.Text = $DeviceInfo.IPAddress
[string]$KioskApp_txtMacAddress.Text = $DeviceInfo.MacAddress
[string]$KioskApp_txtModel.Text = $DeviceInfo.PlatformModel
[string]$KioskApp_txtMake.Text = $DeviceInfo.PlatformManufacturer


#Build APP ICON

#================================
# ADD TO TASKBAR
#================================
If($EnableTaskbarControl){
    ## PROCESS NOTIFY ICON NEXT
    # Create a streaming image by streaming the base64 string to a bitmap streamsource
    $NotifyBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $NotifyBitmap.BeginInit()
    $NotifyBitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($AppBase64Icon_32px)
    $NotifyBitmap.EndInit()
    $NotifyBitmap.Freeze()

    # Convert the bitmap into an icon
    $BackgroundImage = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($NotifyBitmap.StreamSource)
    $icon = [System.Drawing.Icon]::FromHandle($BackgroundImage.GetHicon())

    $notifyicon = New-Object System.Windows.Forms.NotifyIcon
    $notifyicon.Text = $AppTitle
    $notifyicon.Icon = $icon
    $notifyicon.Visible = $true

    #Display title of balloon window
    $notifyicon.BalloonTipTitle = "Menu Available in Taskbar"

    #Type of balloon icon
    $notifyicon.BalloonTipIcon = "Info"

    #Notification message
    $BalloonMsg = "$AppTitle is still running, You can access this menu or the quick access menu from the taskbar at anytime"
    $notifyicon.BalloonTipText = $BalloonMsg

    #Call the balloon notification
    $ExitItem = New-Object System.Windows.Forms.MenuItem
    $ExitItem.Text = "Exit"
    # When Exit is clicked, close everything and kill the PowerShell process
    $ExitItem.add_Click({
        #$KioskApp.Hide()
    	$notifyicon.Visible = $false
    	$KioskApp.Close()
        [System.Windows.Forms.Application]::Exit($null)
    })

    #$SeperatorItem = New-Object System.Windows.Forms.SplitContainer
    $SeperatorItem1 = New-Object System.Windows.Forms.MenuItem
    $SeperatorItem1.Text = "-"

    $contextmenu = New-Object System.Windows.Forms.ContextMenu
    $notifyicon.ContextMenu = $contextmenu
    $notifyicon.contextMenu.MenuItems.AddRange(@($SeperatorItem1,$ExitItem))
}

$KioskApp.Topmost = $AppOnTop

Switch ($AppTitlePosition)
{
    "Center"
    {
        $KioskApp_lbltitle.HorizontalAlignment="Center"
        $KioskApp_lbltitle.VerticalAlignment="Center"
    }
    "BottomCenter"
    {
        $KioskApp_lbltitle.HorizontalAlignment="Center"
        $KioskApp_lbltitle.VerticalAlignment="Bottom"
    }
    "TopCenter"
    {
        $KioskApp_lbltitle.HorizontalAlignment="Center"
        $KioskApp_lbltitle.VerticalAlignment="Top"
    }
}
##*==============================
##* LOAD FORM - APP CONTENT AND BUTTONS
##*==============================
#Console control
# Credits to - http://powershell.cz/2013/04/04/hide-and-show-console-window-from-gui/
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)

Show-KioskApp
