<#
.SYNOPSIS
    Powershell Script to check if user has access to a Network Shared Folder
.DESCRIPTION
    .
.PARAMETER Path
    The path to the .
.PARAMETER LiteralPath
    Specifies a path to one or more locations. Unlike Path, the value of
    LiteralPath is used exactly as it is typed. No characters are interpreted
    as wildcards. If the path includes escape characters, enclose it in single
    quotation marks. Single quotation marks tell Windows PowerShell not to
    interpret any characters as escape sequences.
#>
Param(
    [Parameter(
        Position = 0,
        Mandatory = $true,
        HelpMessage = "SMTP Server (eg. smtp.mailtrap.io)"
    )][string] $smtpServer,
    [Parameter(
        Position = 1,
        Mandatory = $true,
        HelpMessage = "SMTP Port (eg. 25 or 465 or 587 or 2525)"
    )][int] $smtpPort,
    [Parameter(
        Position = 2,
        Mandatory = $true,
        HelpMessage = "SMTP SSL (eg. true or false)"
    )][string] $smtpSSL,
    [Parameter(
        Position = 3,
        Mandatory = $true,
        HelpMessage = "SMTP Username"
    )][string] $smtpUsername,
    [Parameter(
        Position = 4,
        Mandatory = $true,
        HelpMessage = "SMTP Password"
    )][string] $smtpPassword,
    [Parameter(
        Position = 5,
        Mandatory = $true,
        HelpMessage = "Email Sender (eg. first.last@company.com)"
    )][string] $emailFrom,
    [Parameter(
        Position = 6,
        Mandatory = $true,
        HelpMessage = "Email Recipients (eg. first.last@company.com,second.last@company.com)"
    )][string[]] $emailList,
    [Parameter(
        Position = 7,
        Mandatory = $false,
        HelpMessage = "Email Subject"
    )][string] $emailSubject = "[Checkmarx] Cannot Access to Shared Folder",
    [Parameter(
        Position = 8,
        Mandatory = $false,
        HelpMessage = "Email Body"
    )][string] $emailBody = "Hi,</br></br>Impossible to access to the following shared folders:</br></br><li>//folder</li></br></br>Best Regards,</br>Checkmarx",
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Network Folder Share"
    )][string] $networkShare
)

<#
This is the method for checking the network access to a shared folder
on the network.

Error codes and corresponding checks
    - 00 :: No Error
    - 01 :: String is a network address
    - 02 :: Failed to read/access from remote share
    - 03 :: Failed to write to remote share
    - 10 :: Network Access Failure
#>
function folderCheck {
    Param(
        [string]$networkPath
    )
    Try {
        # TODO: Regex check for Network pattern
        if ( $networkPath -notmatch ".*" ) {
            return 1
        }
        Write-Debug "Full Path :: $networkPath"
        # Check and cleanup existing file (might fail if we don't have the permissions)
        if (Test-Path -Path $networkPath) { Remove-Item -Path $networkPath }

        Write-Debug "Testing Write access to network share drive"
        Add-Content -Path $networkPath -Value "TestString" -ErrorAction Stop

        if (Test-Path -Path $networkPath) {
            Write-Debug "Path exists (file was created)"
        } else {
            return 1
        }
        # Clean up if file was written to disk
        Remove-Item -Path $networkPath
    }
    Catch [System.IO.IOException] {
        # Failed to write to remote share
        return 3
    }
    return 0
}


$secureSmtpPassword = ConvertTo-SecureString -String $smtpPassword -AsPlainText -Force
$ssl = $False

if ($smtpSSL -eq "true") {
    $ssl = $True
}
else {
    $ssl = $False
}

$smtpClient = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
$smtpClient.EnableSsl = $ssl
$smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $secureSmtpPassword)

$message = New-Object System.Net.Mail.MailMessage $emailFrom, $emailList
$message.IsBodyHtml = $true
$message.Subject = $emailSubject
$message.Body = $emailBody

if ($emailListCC.Length -gt 0) {
    $message.CC = $emailListCC
}

foreach ($emailTo in $emailList) {
    $smtpClient.Send($message)
    Write-Host "Email was sent to: ${emailTo}"
}