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

Function Show-App1{
    #Slower method to present form for non modal (no popups)
    #$App1.ShowDialog() | Out-Null

    # Allow input to window for TextBoxes, etc
    [Void][System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($App1)

    #for ISE testing only: Add ESC key as a way to exit UI
    $code1 = {
        [System.Windows.Input.KeyEventArgs]$esc = $args[1]
        if ($esc.Key -eq 'ESC')
        {
            $App1.Close()
            [System.Windows.Forms.Application]::Exit()
            #this will kill ISE
            [Environment]::Exit($ExitCode);
        }
    }
    $null = $App1.add_KeyUp($code1)


    $App1.Add_Closing({
        [System.Windows.Forms.Application]::Exit()
    })

    $async1 = $App1.Dispatcher.InvokeAsync({

        #make sure this display on top of every window
        $App1.Topmost = $true
        # Running this without $appContext & ::Run would actually cause a really poor response.
        $App1.Show() | Out-Null
        # This makes it pop up
        $App1.Activate() | Out-Null

        #$App1.window.ShowDialog()
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
##*===============================================
##* VARIABLE DECLARATION
##*===============================================
[string]$AppAuthor = 'Dick Tracy II'
[string]$AppTitle = 'Kiosk App'
[string]$AppVersion = '1.0.0.0'
# UI Controls
[string]$AppUIQuickAccessPosition = 'TopCenter'

# Get Menu Configurations
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

#==========================================
# LOAD HIDE APP XAML (Built by Visual Studio 2015)
#==========================================
$xamlpath = @"
<Window x:Class="KioskApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" 
        Name="KioskApp"
        Height="100" Width="80"
        WindowStyle="ToolWindow"
        ResizeMode="NoResize"
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
    <Grid HorizontalAlignment="Center" VerticalAlignment="Center">
        <Button Background="#313130" x:Name="btnHideApp" HorizontalAlignment="Left" VerticalAlignment="Top" Width="60" Height="60">
            <TextBlock x:Name="btntxtHideApp" Text="Kiosk Mode" FontSize="12" TextWrapping="WrapWithOverflow" TextAlignment="Center" Width="50"/>
        </Button>
    </Grid>
</Window>

"@
[xml]$HXAML = $xamlpath -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'

$AppHideReader=(New-Object System.Xml.XmlNodeReader $HXAML)
try{
    $App1=[Windows.Markup.XamlReader]::Load($AppHideReader)
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

$HXAML.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name "App1$($_.Name)" -Value $App1.FindName($_.Name)}


$AboutFormIcon = New-Object System.Windows.Media.Imaging.BitmapImage
$AboutFormIcon.BeginInit()
$AboutFormIcon.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($AppBase64Icon_32px)
$AboutFormIcon.EndInit()
$AboutFormIcon.Freeze()
$App1.Icon = $AboutFormIcon
#================================
# LOAD FORMS - NOTIFY IN TASKBAR
#================================
Remove-Event BalloonClicked_event -ea SilentlyContinue
Unregister-Event -SourceIdentifier BalloonClicked_event -ea silentlycontinue
Remove-Event BalloonClosed_event -ea SilentlyContinue
Unregister-Event -SourceIdentifier BalloonClosed_event -ea silentlycontinue #Create the notification object

## PROCESS NOTIFY ICON NEXT
# Create a streaming image by streaming the base64 string to a bitmap streamsource
$NotifyBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$NotifyBitmap.BeginInit()
$NotifyBitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($AppBase64Icon_32px)
$NotifyBitmap.EndInit()
$NotifyBitmap.Freeze()

# Convert the bitmap into an icon
$image = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($NotifyBitmap.StreamSource)
$icon = [System.Drawing.Icon]::FromHandle($image.GetHicon())
 
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
    #$App1.Hide()
	$notifyicon.Visible = $false
	$App1.Close()
    [System.Windows.Forms.Application]::Exit($null)
})

#$SeperatorItem = New-Object System.Windows.Forms.SplitContainer
$SeperatorItem1 = New-Object System.Windows.Forms.MenuItem
$SeperatorItem1.Text = "-"

$contextmenu = New-Object System.Windows.Forms.ContextMenu
$notifyicon.ContextMenu = $contextmenu
$notifyicon.contextMenu.MenuItems.AddRange(@($SeperatorItem1,$ExitItem))


#$notifyicon.add_Click({Show-App1})
#$notifyicon.add_DoubleClick({Show-App1})

##*==============================
##* LOAD FORM - Open / Hide App Button
##*==============================


$App1.Topmost = $True

Switch ($AppUIQuickAccessPosition) 
        {
            "BottomLeft" 
            {
                $App1.Left = 20
                $App1.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$App1.Height)-15
            }
            "BottomCenter" 
            {
                $App1.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$App1.Width)/2
                $App1.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$App1.Height)-15
            }
            "BottomRight" 
            {
                $App1.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$App1.Width)-20
                $App1.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$App1.Height)-15
            }
            "TopLeft" 
            {
                $App1.Left = 20
                $App1.Top = 30
            }
            "TopCenter" 
            {
                $App1.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$App1.Width)/2
                $App1.Top = 30
            }
            "TopRight" 
            {
                $App1.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$App1.Width)-20
                $App1.Top = 30
            }
            "LeftCenter" 
            {
                $App1.Left = 20
                $App1.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$App1.Height)/2
            }
            "RightCenter" 
            {

                $App1.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$App1.Width)-20
                $App1.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$App1.Height)/2
            }

        }

#$App1btnHideApp.add_Click({Show-App2})

##*==============================
##* LOAD FORM - APP CONTENT AND BUTTONS 
##*==============================
#Console control
# Credits to - http://powershell.cz/2013/04/04/hide-and-show-console-window-from-gui/

$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)


Show-App1