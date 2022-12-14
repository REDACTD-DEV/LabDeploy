#BitLocker requires DVD drives to be removed from VM
Write-Host "Eject DVD drives from all VMs" -ForegroundColor Green -BackgroundColor Black
Get-VM | Get-VMDvdDrive | Set-VMDvdDrive -Path $null | Out-Null

#Make sure all the computers are up before we remote in and configure BitLocker
$Computers = $DC01.Name, $DC02.Name, $GW01.Name, $DHCP.Name, $FS01.Name, $WEB01.Name #CL01 already has Bitlocker installed. Just the servers need this
foreach ($Computer in $Computers) {Wait-VMResponse -VMName "$Computer" -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password}
foreach ($Computer in $Computers) {
    Invoke-Command -VMName $Computer -Credential $DomainCred -ScriptBlock {
        Write-Host "Enable BitLocker feature on" $using:Computer -ForegroundColor Blue -BackgroundColor Black
        Enable-WindowsOptionalFeature -Online -FeatureName BitLocker -All -NoRestart
        Restart-Computer -Force
    }
}

#Make sure all the computers are up before we remote in and start encrypting
$Computers = $DC02.Name, $GW01.Name, $DHCP.Name, $FS01.Name, $WEB01.Name, $CL01.Name, $DC01.Name
foreach ($Computer in $Computers) {Wait-VMResponse -VMName $Computer -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password}
foreach ($Computer in $Computers) {
    Invoke-Command -VMName $Computer -Credential $DomainCred -ScriptBlock {
        Write-Host "Run GPUpdate on" $using:Computer -ForegroundColor Blue -BackgroundColor Black
        gpupdate /force
        Start-Sleep -Seconds 5
        Write-Host "Encrypt disk on" $using:Computer -ForegroundColor Blue -BackgroundColor Black
        Enable-BitLocker -MountPoint "C:" -RecoveryPasswordProtector -UsedSpaceOnly
        if ($ENV:COMPUTERNAME -eq $using:FS01.Name) {Enable-BitLocker -MountPoint "F:" -RecoveryPasswordProtector -UsedSpaceOnly}
        Restart-Computer -Force
    }
}