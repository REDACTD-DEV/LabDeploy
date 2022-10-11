function Wait-VMResponse {
	[CmdletBinding()]
	param(
        [Parameter()][String]$VMName,
        [Parameter()][String]$CredentialType,
        [Parameter()][String]$DomainNetBIOSName,
        [Parameter()][String]$Password,
        [Parameter()][Switch]$LogonUICheck
	)	
    process {
        if ($CredentialType -eq "Domain") {
            $Username = $DomainNetBIOSName + "\Administrator"
            $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
        }
        if ($CredentialType -eq "Local") {
            $Username = "Administrator"
            $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
        }

        #Wait for $VM to respond to PowerShell Direct
        Write-Host "Wait for $VMWaitingOn to respond to PowerShell Direct" -ForegroundColor Green -BackgroundColor Black
        while ((Invoke-Command -VMName $VMName -Credential $Credential {"Test"} -ea SilentlyContinue) -ne "Test") {
            Write-Host "Still waiting on $VMName..." -ForegroundColor Green -BackgroundColor Black
            Start-Sleep -Seconds 5
        }
        Write-Host "$VMName is up!" -ForegroundColor Green -BackgroundColor Black

        if ($LogonUICheck) {
            Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock {
            while ($null -ne (Get-Process | Where-Object ProcessName -eq "LogonUI")) {
                Start-Sleep 5
                Write-Host "$VMName LogonUI still processing..." -ForegroundColor Green -BackgroundColor Black
            }
            Write-host "LogonUI is down! $VMName is good to go!" -ForegroundColor Green -BackgroundColor Black
            }
        }
    }
}