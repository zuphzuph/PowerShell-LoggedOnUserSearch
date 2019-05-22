$Tempscript = {
    $Globalblock = {   
        $InputXML = @"
    <Window
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            mc:Ignorable="d"
            Title="Logged On User Search" Height="600.788" Width="798.5" ResizeMode="CanMinimize">
        <Grid>
            <Grid x:Name="UserInput_Grid" HorizontalAlignment="Left" Height="374" Margin="25,57,0,0" VerticalAlignment="Top" Width="311">
                <GroupBox Header="Admin Credentials" HorizontalAlignment="Left" Height="157" Margin="5,1,0,0" VerticalAlignment="Top" Width="289">
                    <Grid x:Name="Credentials_Grid" HorizontalAlignment="Left" Height="157" Margin="-6,-16,-6,-6" VerticalAlignment="Top" Width="289">
                        <TextBox x:Name="Credential_Username" HorizontalAlignment="Left" VerticalContentAlignment="Center" Height="32" Margin="23,41,0,0" VerticalAlignment="Top" Width="236"/>
                        <TextBlock IsHitTestVisible="False" Text="Enter Username" Foreground="DarkGray" HorizontalAlignment="Left" Width="236" Margin="28,47,0,0" Height="32" VerticalAlignment="Top">
                            <TextBlock.Style>
                                <Style TargetType="{x:Type TextBlock}">
                                    <Setter Property="Visibility" Value="Collapsed"/>
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding Text, ElementName=Credential_Username}" Value="">
                                            <Setter Property="Visibility" Value="Visible"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </TextBlock.Style>
                        </TextBlock>
                        <PasswordBox x:Name="Credential_Password" HorizontalAlignment="Left" VerticalContentAlignment="Center" Height="32" Margin="23,92,0,0" VerticalAlignment="Top" Width="236"/>
                        <TextBlock x:Name="PW_HintText" IsHitTestVisible="False" Text="Enter Password" Foreground="DarkGray" HorizontalAlignment="Left" Width="236" Margin="28,98,0,0" Height="32" VerticalAlignment="Top"/>
                    </Grid>
                </GroupBox>
                <GroupBox Header="Search Criteria" HorizontalAlignment="Left" Height="158" Margin="5,194,0,0" VerticalAlignment="Top" Width="289">
                    <Grid x:Name="Criteria_Grid" HorizontalAlignment="Left" Height="158" Margin="-6,-16,-6,-6" VerticalAlignment="Top" Width="289">
                        <TextBox x:Name="Search_Username" HorizontalAlignment="Left" VerticalContentAlignment="Center" Height="32" Margin="23,41,0,0" VerticalAlignment="Top" Width="236"/>
                        <TextBlock IsHitTestVisible="False" Text="User to Find" Foreground="DarkGray" HorizontalAlignment="Left" Width="236" Margin="28,47,0,0" Height="32" VerticalAlignment="Top">
                            <TextBlock.Style>
                                <Style TargetType="{x:Type TextBlock}">
                                    <Setter Property="Visibility" Value="Collapsed"/>
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding Text, ElementName=Search_Username}" Value="">
                                            <Setter Property="Visibility" Value="Visible"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </TextBlock.Style>
                        </TextBlock>
                        <TextBox x:Name="Search_Filter" HorizontalAlignment="Left" VerticalContentAlignment="Center" Height="32" Margin="23,92,0,0" VerticalAlignment="Top" Width="236"/>
                        <TextBlock IsHitTestVisible="False" Text="Search Filter (ex. WMITLT*)" Foreground="DarkGray" HorizontalAlignment="Left" Width="236" Margin="28,98,0,0" Height="32" VerticalAlignment="Top">
                            <TextBlock.Style>
                                <Style TargetType="{x:Type TextBlock}">
                                    <Setter Property="Visibility" Value="Collapsed"/>
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding Text, ElementName=Search_Filter}" Value="">
                                            <Setter Property="Visibility" Value="Visible"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </TextBlock.Style>
                        </TextBlock>
                    </Grid>
                </GroupBox>
            </Grid>        
            <GroupBox x:Name="Results_Grid" Header="Results" Height="424" Margin="422,58,0,0" VerticalAlignment="Top" HorizontalAlignment="Left" Width="338">
                <TextBox x:Name="Search_Results" Margin="3,3,3,3" TextWrapping="Wrap" BorderBrush="White" IsReadOnly="True" IsTabStop="False"/>
            </GroupBox>
            <Grid x:Name="Progress_Grid" HorizontalAlignment="Left" Height="92" Margin="25,468,0,0" VerticalAlignment="Top" Width="551" Visibility="Hidden">
                <TextBox x:Name="Progress_Text" HorizontalAlignment="Left" Height="31" Margin="10,0,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="387" BorderBrush="White" IsReadOnly="True" VerticalContentAlignment="Center" Focusable="False" IsHitTestVisible="False" IsTabStop="False"/>
                <ProgressBar x:Name="Progress" HorizontalAlignment="Left" Height="32" Margin="10,36,0,0" VerticalAlignment="Top" Width="532"/>
            </Grid>
            <Button x:Name="Action_Button"  Content="Start Search" HorizontalAlignment="Left" Height="32" Margin="614,506,0,0" VerticalAlignment="Top" Width="146" IsDefault="True"/>
        </Grid>
    </Window>
"@
    
        $InputXML = $InputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
        [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
        [xml]$XAML = $inputXML
      
        $reader=(New-Object System.Xml.XmlNodeReader $xaml)
        $Global:syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
        [xml]$XAML = $xaml
        $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object{
        #Find all of the form types and add them as members to the synchash
        $Global:syncHash.Add($_.Name,$Global:syncHash.Window.FindName($_.Name) ) }
        $Global:syncHash.Window.Add_Closed({
            $Global:JobCleanup.flag = $null
            Taskkill /PID $PID /F
        })
        $Global:syncHash.Credential_Username.Focus() | Out-Null
        #region Create runspace pool
        $PoolSize = 7
        $hash = [hashtable]::Synchronized(@{})
        $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
        $runspacepool = [runspacefactory]::CreateRunspacePool(1, $PoolSize, $sessionstate, $Host)
        $runspacepool.ApartmentState = "STA"
        $runspacepool.ThreadOptions = "ReuseThread"
        $runspacepool.Open()
        #endregion    
    
        #region Scriptblocks
        $RunspaceCleanup = {
            #Routine to handle completed runspaces
            Param($Global:runspaces,$Global:jobCleanup)
            Do {    
                Foreach($Global:runspace in $Global:runspaces) {            
                    If ($Global:runspace.Runspace.isCompleted) {
                        [void]$Global:runspace.powershell.EndInvoke($Global:runspace.Runspace)
                        $Global:runspace.powershell.dispose()
                        $Global:runspace.Runspace = $null
                        $Global:runspace.powershell = $null               
                    } 
                }
                #Clean out unused runspace jobs
                $temphash = $Global:runspaces.clone()
                $temphash | Where-Object {
                    $_.runspace -eq $Null
                } | ForEach-Object {
                    $Global:runspaces.remove($_)
                }        
                Start-Sleep -Seconds 1     
            } while ($Global:jobCleanup.Flag)
        }
    
        $ProgressMonitor = {
            Param(
                $Global:syncHash,
                $Global:ScannedPCList
            )
            Function Update-Window {
                Param (
                    $Object,
                    $Property,
                    $Value
                )
                $Global:syncHash.window.Dispatcher.invoke([action]{
                    $Global:syncHash.$Object.$Property = "$Value"
                },"Normal")
            }
            $Progress_Completed = 0
            $Progress_Check = 0
            
            $Global:syncHash.ButtonState = "Cancel Search"
            Update-Window -Object Action_Button -Property Content -Value "Cancel Search"
            Update-Window -Object Progress_Grid -Property Visibility -Value Visible
            Do{
                Do{
                    Start-Sleep -Seconds 1
                    $Progress_Check = $Global:ScannedPCList.Count
                    If($Progress_Completed -lt $Progress_Check){
                        $Progress_Completed = $Progress_Check
                    }
                }
                Until(($Progress_Completed -eq $Progress_Check) -and ($Progress_Check -ne 0))
                    If($Global:syncHash.Action -eq "Run"){
                        Update-Window -Object Progress_Text -Property Text -Value "Scanned $($Global:ScannedPCList.Count) of $($Global:syncHash.PC_Count) computers:"
                    }
                    Elseif($Global:syncHash.Action -eq "Cancel"){
                        Update-Window -Object Progress_Text -Property Text -Value "Cancelling scan, please wait..."
                    }
                    Update-Window -Object Progress -Property Value -Value (($Global:ScannedPCList.Count/$Global:syncHash.PC_Count)*100)
            }
            Until($Global:ScannedPCList.Count -eq $Global:syncHash.PC_Count)
            If($Global:syncHash.PC_Count -eq $Global:ScannedPCList.Count){
                Update-Window -Object Progress -Property Value -Value (($Global:ScannedPCList.Count/$Global:syncHash.PC_Count)*100)
                If($Global:syncHash.Action -ne "Cancel"){
                    Update-Window -Object Progress_Text -Property Text -Value "Scanning completed for $($Global:syncHash.PC_Count) computers:"
                }
                Start-Sleep -Seconds 2
                #Cleanup process
                Update-Window -Object Progress_Grid -Property Visibility -Value Hidden
                Update-Window -Object Action_Button -Property Content -Value "Start Search"
                $Global:syncHash.ButtonState = "Start Search"
                Update-Window -Object Progress -Property Value -Value 0
                Update-Window -Object Progress_Text -Property Text -Value ""
                $Global:ScannedPCList.Clear()
                $Global:syncHash.Action = $null
            }
        }
    
        $ScanForLogons = {
            Param(
                $Global:syncHash,
                $Global:ScannedPCList,
                $ADComputer
            )
            Function Update-Window {
                Param (
                    $Object,
                    $Property,
                    $Value
                )
                $Global:syncHash.window.Dispatcher.invoke([action]{
                    $Global:syncHash.$Object.AppendText($Value)
                    $Global:syncHash.$Object.AppendText("`n")
                    $Global:syncHash.$Object.ScrollToEnd()
                },"Normal")
            }
            If($Global:syncHash.Action -eq "Run"){            
                If(Test-Connection $ADComputer -Count 1 -Quiet){
                    If($ADComputer -eq $env:COMPUTERNAME){
                        $Processes = Get-WmiObject win32_process -ErrorAction SilentlyContinue -computer $ADComputer -Filter "Name = 'explorer.exe'"
                    }
                    Else{
                        $Password = $Global:syncHash.Credential_Password.SecurePassword
                        $Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $Global:syncHash.CredUsername,$Password
                        $Processes = Get-WmiObject win32_process -ErrorAction SilentlyContinue -Credential $Global:syncHash.Credential -computer $ADComputer -Filter "Name = 'explorer.exe'"
                    }
                    If(!([string]::IsNullOrEmpty($Processes))){
                        $SearchUser = $Global:syncHash.VerifiedUser
                        foreach ($Process in $Processes){
                            $Temp = ($Process.GetOwner()).User
                            If ($Temp -eq $SearchUser){
                                Update-Window -Object "Search_Results" -Property "Text" -Value "User $SearchUser is logged onto $ADComputer"
                                Break
                            }
                        }
                    }
                    $Global:ScannedPCList.$ADComputer = "Complete"
                }
                Else{
                    $Global:ScannedPCList.$ADComputer = "Unavailable"
                }
            }
            Else{
                $Global:ScannedPCList.$ADComputer = "Canceled"
            }
        }
        #endregion
    
        #region Functions   
        Function Add-Runspace {
            Param($RSName,$Block,$Arg1,$Arg2,$Arg3)
            $powershell = [powershell]::Create().AddScript($Block).AddArgument($Arg1).AddArgument($Arg2).AddArgument($Arg3)
            $powershell.RunspacePool = $runspacepool
            $temp = "" | Select-Object PowerShell,Runspace,Name
            $Temp.Name = $RSName
            $Temp.PowerShell = $powershell
            $Temp.Runspace = $powershell.BeginInvoke()
            $runspaces.Add($temp) | Out-Null
        }
        Function Get-Username {
            $Error.Clear()
            $Global:syncHash.VerifiedUser = $null
            $SearchUser = $Global:syncHash.Search_Username.Text
            $UserCheck = Get-ADUser $SearchUser
            if ($Error){
                (new-object -ComObject wscript.shell).Popup($Error[0],0,"ERROR")
            }
            If($Error.Count -eq 0){
                $Global:syncHash.VerifiedUser = $UserCheck.SamAccountName
                #(new-object -ComObject wscript.shell).Popup("$($Global:syncHash.Search_Username.Text)",0,"Credentials...",64)
            }
        }
        #endregion
    
        #region Create runspaces
        Add-Runspace -RSName "Cleanup" -Block $RunspaceCleanup -Arg1 $Global:runspaces -Arg2 $Global:JobCleanup
        #endregion
    
        #region PasswordBox hint text
        #There is currently no purely XAML way to accomplish this.
        $Global:syncHash.Credential_Password.Add_PasswordChanged({
            $Global:syncHash.PW_HintText.Visibility="Hidden"
        })
        $Global:syncHash.Credential_Password.Add_PasswordChanged({
            If($Global:syncHash.Credential_Password.Password){
                $Global:syncHash.PW_HintText.Visibility="Hidden"
            }
            Else{
                $Global:syncHash.PW_HintText.Visibility="Visible"
            }
        })
        #endregion
    
        #region Button Functionality
        Import-Module ActiveDirectory  
        $Global:syncHash.Action_Button.Add_Click({
            If($Global:syncHash.ButtonState -like "Start Search"){
                $Global:syncHash.Action = "Run"
                If($Global:syncHash.Credential_Username.Text -and $Global:syncHash.Credential_Password.SecurePassword -and $Global:syncHash.Search_UserName.Text){
                    $Global:syncHash.Search_Results.Text = $null
                    Get-Username
                    If($Global:syncHash.VerifiedUser){
                        If(!$Global:syncHash.Search_Filter.Text){
                            $Filter = "*"
                        }
                        Else{
                            #Add an '*' to the end of the filter if it does not exist already
                            If($Global:syncHash.Search_Filter.Text -match '.+?\*$'){
                                $Filter = $Global:syncHash.Search_Filter.Text
                            }
                            Else{
                                $Filter = "$($Global:syncHash.Search_Filter.Text)*"
                            }
                        }
                        $Global:syncHash.CredUsername = $Global:syncHash.Credential_Username.Text
                        $Global:syncHash.SearchUser = $Global:syncHash.Search_User.Text
                        $ADComputers = Get-ADComputer -Filter {(Enabled -eq 'true') -and (SamAccountName -like $Filter)} | Sort-Object Name
                        #If there is only 1 PC returned by the filter, it does not return a count
                        If(!$ADComputers.Count){
                            $Global:syncHash.PC_Count = "1"
                        }
                        Else{
                            $Global:syncHash.PC_Count = $ADComputers.count
                        }
                        Add-Runspace -RSName "Progress_Monitor" -Block $ProgressMonitor -Arg1 $Global:syncHash -Arg2 $Global:ScannedPCList
                        foreach($ADComputer in $ADComputers.Name){                     
                            Add-Runspace -RSName "PCSearch_$ADComputer" -Block "$ScanForLogons" -Arg1 $Global:syncHash -Arg2 $Global:ScannedPCList -Arg3 $ADComputer
                        }
                    }
                    
                }
            }
            ElseIf($Global:syncHash.ButtonState -like "Cancel Search"){
                $Global:syncHash.Action = "Cancel"
            }
        })
    
        #endregion
    
        $Global:syncHash.Window.ShowDialog() | Out-Null
        $Global:syncHash.Error = $Global:error
    }
    
    $Global:syncHash = [hashtable]::Synchronized(@{})
    $Global:JobCleanup = [hashtable]::Synchronized(@{})
    $Global:ScannedPCList = [hashtable]::Synchronized(@{})
    $Global:runspaces = New-Object System.Collections.ArrayList 
    $Global:JobCleanup.Flag = $True
    $Global:syncHash.ButtonState = "Start Search"
    $newRunspace =[runspacefactory]::CreateRunspace()
    $newRunspace.ApartmentState = "STA"
    $newRunspace.ThreadOptions = "ReuseThread"         
    $newRunspace.Open()
    $newRunspace.SessionStateProxy.SetVariable("syncHash",$Global:syncHash)
    $newRunspace.SessionStateProxy.SetVariable("Global:JobCleanup",$Global:JobCleanup)
    $newRunspace.SessionStateProxy.SetVariable("Global:runspaces",$runspaces)
    $newRunspace.SessionStateProxy.SetVariable("Global:ScannedPCList",$Global:ScannedPCList)
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    $psCmd = [PowerShell]::Create()
    $psCmd.AddScript($Globalblock)
    $psCmd.Runspace = $newRunspace
    $data = $psCmd.BeginInvoke()
    }
    $TempScript | Out-file $ENV:TEMP\LoggedOnUserSearch.ps1 -Width 4096 -Force
    Start-Process Powershell -Verb runas -ArgumentList "-NoExit -WindowStyle Hidden -ExecutionPolicy Bypass -file $ENV:TEMP\LoggedOnUserSearch.ps1"
