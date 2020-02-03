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
        HelpMessage = "Network Shared Folders (eg. \\temp\test,\\temp\sample)"
    )][string[]] $networkShareFolders,
    [Parameter(
        Position = 1,
        Mandatory = $true,
        HelpMessage = "SMTP Server (eg. smtp.mailtrap.io)"
    )][string] $smtpServer,
    [Parameter(
        Position = 2,
        Mandatory = $true,
        HelpMessage = "SMTP Port (eg. 25 or 465 or 587 or 2525)"
    )][int] $smtpPort,
    [Parameter(
        Position = 3,
        Mandatory = $true,
        HelpMessage = "SMTP SSL (eg. true or false)"
    )][string] $smtpSSL,
    [Parameter(
        Position = 4,
        Mandatory = $true,
        HelpMessage = "SMTP Username"
    )][string] $smtpUsername,
    [Parameter(
        Position = 5,
        Mandatory = $true,
        HelpMessage = "SMTP Password"
    )][string] $smtpPassword,
    [Parameter(
        Position = 6,
        Mandatory = $true,
        HelpMessage = "Email Sender (eg. first.last@company.com)"
    )][string] $emailFrom,
    [Parameter(
        Position = 7,
        Mandatory = $true,
        HelpMessage = "Email Recipients (eg. first.last@company.com,second.last@company.com)"
    )][string[]] $emailList,
    [Parameter(
        Position = 8,
        Mandatory = $false,
        HelpMessage = "Email Subject"
    )][string] $emailSubject = "[Checkmarx] Cannot Access to Shared Folder",
    [Parameter(
        Position = 9,
        Mandatory = $false,
        HelpMessage = "Email Body (HTML)"
    )][string] $emailBody = "Hi,</br></br>Impossible to access to the following shared folders:</br></br>#SHARED_FOLDERS</br></br>Best Regards,</br>Checkmarx"
)

<#
This is the method for checking the network access to a shared folder
on the network.

Error codes and corresponding checks
    - 00 :: No Error
    - 01 :: String is not a network address
    - 02 :: Failed to read/access from remote share
    - 03 :: Failed to write to remote share
    - 10 :: Network Access Failure
#>
function folderCheck {
    Param(
        [string]$networkPath
    )
    try {

        # Creating temporary variables
        $tempFile = "test.txt"
        $tempPath = $networkPath

        # Check Shared Network Folders pattern
        if ( $networkPath -notmatch "^(\\)(\\[A-Za-z0-9-_]+){1,}(\\?)$" ) {
            Write-Error "'${networkPath}' is not a valid Network Shared Folder. Please check the path of this shared folder, it should be valid for this regex expression: ^(\\)(\\[A-Za-z0-9-_]+){1,}(\\?)$"
            return 1
        }
        Write-Host "Checking access to: ${networkPath}"

        # Concatenate with temporary filename
        if ($networkPath -notmatch '\\$') {
            $tempPath += "\${tempFile}"
        }
        else {
            $tempPath += $tempFile
        }
        Write-Host "Creating temporary file : ${tempPath}"

        # Check and cleanup existing file (might fail if we don't have the permissions)
        if (Test-Path -Path $tempPath) { 
            Remove-Item -Path $tempPath 
        }
        Add-Content -Path $tempPath -Value "TestString" -ErrorAction Stop

        if (Test-Path -Path $tempPath) {
            Write-Host "File ${tempPath} was created with success !"
        }
        else {
            Write-Error "File ${tempPath} was NOT created with success !"
            return 1
        }
        # Clean up if file was written to disk
        Write-Host "Removing temporary file: ${tempPath}"
        Remove-Item -Path $tempPath
        
        Write-Host "Access to ${networkPath} is granted !`n"
    }
    catch [System.IO.IOException] {
        # Failed to write to remote share
        Write-Error $_
        return 3
    }
    return 0
}

<#
This is the method for sending an email if access to a network share is not available.

Error codes and corresponding checks
    - 00 :: No Error
#>
function sendEmail {
    Param(
        [string]$server,
        [int] $port,
        [string] $ssl,
        [string] $username,
        [SecureString] $password,
        [string] $from,
        [string[]] $to,
        [string] $subject,
        [string] $body,
        [string[]] $sharedFolders
    )
        $sharedFoldersBody = ""
        foreach($sharedFolder in $sharedFolders){
            $sharedFoldersBody += "<li>${sharedFolder}</li>"
        }
        $body = $body.Replace("#SHARED_FOLDERS", $sharedFoldersBody)
    try {
        $smtpClient = New-Object Net.Mail.SmtpClient($server, $port)
        $smtpClient.EnableSsl = $ssl
        $smtpClient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
    
        $message = New-Object System.Net.Mail.MailMessage($from, $to)
        $message.From = $from
        $message.IsBodyHtml = $true
        $message.Subject = $subject
        $message.Body = $body
    
        foreach ($emailTo in $to) {
            $smtpClient.Send($message)
            Write-Host "Email was sent to: ${emailTo}"
        }
    }
    catch {
        
    }
}

$notAccessList = @()
$countNetworkShares = $networkShareFolders.Count
Write-Host "Checking access to ${countNetworkShares} Network Shared Folders:"
foreach ($networkShare in $networkShareFolders) {
    $hasAccess = folderCheck $networkShare
    if ($hasAccess -ne 0) {
        $notAccessList += $networkShare
    } 
}

if ($notAccessList.Count -gt 0) {
    $countNoAccess = $notAccessList.Count
    Write-Host "No access to ${countNoAccess} Network Shared Folders. Sending email notification..."
    $ssl = $False

    if ($smtpSSL -eq "true") {
        $ssl = $True
    }
    else {
        $ssl = $False
    }
    $secureSmtpPassword = ConvertTo-SecureString -String $smtpPassword -AsPlainText -Force
    sendEmail $smtpServer $smtpPort $ssl $smtpUsername $secureSmtpPassword $emailFrom $emailList $emailSubject $emailBody $notAccessList
}