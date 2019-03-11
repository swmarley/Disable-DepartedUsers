Add-Type -AssemblyName PresentationFramework
$webURL = #Insert URL to site containing JSON data
$jsonContent = Invoke-WebRequest $webURL
$employeePSObject = ConvertFrom-Json -InputObject $jsonContent
$employeeHash = @{}

foreach ($entry in $employeePSObject) {
        #The three variables below are based on JSON object keys that correspond to standard AD user account attributes. You may need to modify the attributes accordingly.
        [datetime]$departure = $entry.DepartureDate
        $employee = $entry.PreferredName
        $userName = $entry.Alias

        if (-not ([string]::IsNullOrEmpty($userName)))
            {$employeeHash.add($userName, $($departure.ToString("MM-dd-yyyy")))}
        else {$employeeHash.Add($employee, "Alias not found")}       
}

$messageContent = $employeeHash.keys | sort Value | Out-String 

$messageBox = [System.Windows.MessageBox]::Show("The following user accounts are scheduled to be disabled:`n`n$($messageContent)", "Disable User Accounts","YesNoCancel","Question")

switch ($messageBox) {
    'Yes' {
        $successArray = @()
        foreach($key in $employeeHash.Keys){
          try {
            if (Get-ADUser $($key)){
                Disable-ADAccount $key
                $accountStatus = Get-ADUser $($key) | Select Name, Enabled
                $successArray += "$($accountStatus)`n"
            }
          }

          catch{
            Write-Warning "$($key) does not exist in Active Directory."
          }
        }

        $emailBody = $successArray | out-string

        $sender = #Insert sender e-mail address
        $recipient = #Insert recipient e-mail address
        $smtpServer = #Insert SMTP server hostname

        Send-MailMessage -From $sender -To $recipient -SmtpServer $smtpServer -Subject "Departed Employees Have Been Disabled in AD by $($sender)" -Body $emailBody
     }

    'No'{
        Write-warning "Users not disabled - Program ended."
        break
    }

    'Cancel'{
        Write-Output "Program canceled."
        break
    }
}