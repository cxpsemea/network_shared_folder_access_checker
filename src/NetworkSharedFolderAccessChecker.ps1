<#
.SYNOPSIS
    Powershell Script to check if user has access to a Network Shared Folder and SQL Server
.DESCRIPTION
    Powershell Script that checks access to every Network Shared Folder and SQL Server provided by user, 
    check if he is able to create a file and if not, 
    notifies a email list about Access permission issues over those Network Shared Folders
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
    # Network Shared Folders (eg. \\temp\test,\\temp\sample)
    [Parameter(
        Position = 0,
        Mandatory = $true,
        HelpMessage = "Network Shared Folders (eg. \\temp\test,\\temp\sample)"
    )][string[]] $networkShareFolders,
    # SQL Server Name
    [Parameter(
        Position = 1,
        Mandatory = $true,
        HelpMessage = "SQL Server Name"
    )][string] $sqlServerName,
    # SQL Database
    [Parameter(
        Position = 2,
        Mandatory = $true,
        HelpMessage = "SQL Database"
    )][string] $sqlDatabase,
    # SQL Username
    [Parameter(
        Position = 3,
        Mandatory = $true,
        HelpMessage = "SQL Username"
    )][string] $sqlUsername,
    # SQL Password
    [Parameter(
        Position = 4,
        Mandatory = $true,
        HelpMessage = "SQL Password"
    )][string] $sqlPassword,
    # SMTP Server (eg. smtp.mailtrap.io)
    [Parameter(
        Position = 5,
        Mandatory = $true,
        HelpMessage = "SMTP Server (eg. smtp.mailtrap.io)"
    )][string] $smtpServer,
    # SMTP Port (eg. 25 or 465 or 587 or 2525)
    [Parameter(
        Position = 6,
        Mandatory = $true,
        HelpMessage = "SMTP Port (eg. 25 or 465 or 587 or 2525)"
    )][int] $smtpPort,
    # SMTP SSL (eg. true or false)
    [Parameter(
        Position = 7,
        Mandatory = $true,
        HelpMessage = "SMTP SSL (eg. true or false)"
    )][string] $smtpSSL,
    # SMTP Username
    [Parameter(
        Position = 8,
        Mandatory = $true,
        HelpMessage = "SMTP Username"
    )][string] $smtpUsername,
    # SMTP Password
    [Parameter(
        Position = 9,
        Mandatory = $true,
        HelpMessage = "SMTP Password"
    )][string] $smtpPassword,
    # Email Sender (eg. first.last@company.com)
    [Parameter(
        Position = 10,
        Mandatory = $true,
        HelpMessage = "Email Sender (eg. first.last@company.com)"
    )][string] $emailFrom,
    # Email Recipients (eg. first.last@company.com,second.last@company.com)
    [Parameter(
        Position = 11,
        Mandatory = $true,
        HelpMessage = "Email Recipients (eg. first.last@company.com,second.last@company.com)"
    )][string[]] $emailList,
    # Email Subject, Default = [Checkmarx] Cannot Access to Shared Folder
    [Parameter(
        Position = 12,
        Mandatory = $false,
        HelpMessage = "Email Subject"
    )][string] $emailSubject = "[Checkmarx] Cannot Access to Shared Folder",
    # Email Body (HTML), Default = Hi,</br></br>Impossible to access to the following shared folders:</br></br>#SHARED_FOLDERS</br></br>Best Regards,</br>Checkmarx
    [Parameter(
        Position = 13,
        Mandatory = $false,
        HelpMessage = "Email Body (HTML)"
    )][string] $emailBody = "Hi,</br></br>Impossible to access to the following shared folders:</br></br>#SHARED_FOLDERS#DATABASE</br></br>Best Regards,</br>Checkmarx"
)

<#
This is the method for checking the network access to a shared folder
on the network.

Error codes and corresponding checks
    - 00 :: No Error
    - 01 :: String is empty or null
    - 02 :: String is not a network address
    - 03 :: Failed to write to remote share
#>
function folderCheck {
    Param(
        [string]$networkPath
    )
    if ($networkPath -ne $null -and $networkPath.Length -gt 0) {
        try {
            $creationTime = get-date -format "dd_MM_yyyy__HH_mm_ss"
            # Creating temporary variables
            $tempFile = "test_${creationTime}.txt"
            $tempPath = $networkPath

            # Check Shared Network Folders pattern
            if ( $tempPath -notmatch "^(\\)(\\[A-Za-z0-9-_]+){1,}(\\?)$" ) {
                Write-Error "'${tempPath}' is not a valid Network Shared Folder. Please check the path of this shared folder, it should be valid for this regex expression: ^(\\)(\\[A-Za-z0-9-_]+){1,}(\\?)$"
                return 2
            }
            Write-Host "Checking access to: ${tempPath}"

            # Concatenate with temporary filename
            if ($tempPath -notmatch '\\$') {
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
                return 3
            }
            # Clean up if file was written to disk
            Write-Host "Removing temporary file: ${tempPath}"
            Remove-Item -Path $tempPath
        
            Write-Host "Access to ${tempPath} is granted !`n"
        }
        catch {
            # Failed to write to remote share
            Write-Error $_.Exception.Message
            return 3
        }
        return 0
    }
    else {
        Write-Error "Empty or Null Network Shared Folder provided : ${networkPath}"
        return 1
    }
}

<#
This is the method for sending an email if access to a network share is not available.

Error codes and corresponding checks
    - 00 :: No Error
    - 01 :: Error Sending Email
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
        [string[]] $sharedFolders,
        [bool] $dbAvailable,
        [string] $sqlServer,
        [string] $sqlDatabase
    )
    $sharedFoldersBody = ""
    foreach ($sharedFolder in $sharedFolders) {
        $sharedFolder = $sharedFolder.Replace("<", "")
        $sharedFolder = $sharedFolder.Replace(">", "")
        $sharedFolder = $sharedFolder.Replace("'", "")
        $sharedFolder = $sharedFolder.Replace("/", "")
        $sharedFolder = $sharedFolder.Replace("`"", "")
        $sharedFoldersBody += "<li>${sharedFolder}</li>"
    }
    if($dbAvailable){
        $body = $body.Replace("#DATABASE", "")
    } else {
        $body = $body.Replace("#DATABASE", "</br></br>Impossible to access SQL Server Database:</br></br><li>${sqlServer}:${sqlDatabase}</li>")
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
        }
        $countEmailSent = $to.Length
        
        Write-Host "Email was sent to ${countEmailSent} recipients: ${to}"
        return 0
    }
    catch {
        $exceptionMessage = $_.Exception.Message
        Write-Error "Failing to send a notification email: ${exceptionMessage}"
        return 1
    }
}

<#
This is the method for checking SQL Server Database is accessible.

Error codes and corresponding checks
    - 00 :: No Error
#>
function checkDbConnection {
    Param(
        [string] $server,
        [string] $database,
        [string] $username,
        [string] $password
    )
    try {
        $connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $server, $database, $username, $password
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $sqlConnection.Open()
        $sqlConnection.Close()
        return $true
    } catch{
        $exceptionMessage = $_.Exception.Message
        Write-Error "Failing to connect to SQL Server Database ${server}:${database} : ${exceptionMessage}"
        return $false
    }
}

$startTime = get-date -format "dd/MM/yyyy HH:mm:ss"
Write-Host "`nStart: ${startTime}`n"

Write-Host "INPUTS:"
Write-Host "`tnetworkShareFolders: ${networkShareFolders}"
Write-Host "`tsqlServer: ${sqlServerName}"
Write-Host "`tsqlDatabase: ${sqlDatabase}"
Write-Host "`tsqlUsername: ${sqlUsername}"
Write-Host "`tsqlPassword: ******"
Write-Host "`tsmtpServer: ${smtpServer}"
Write-Host "`tsmtpPort: ${smtpPort}"
Write-Host "`tsmtpSSL: ${smtpSSL}"
Write-Host "`tsmtpUsername: ${smtpUsername}"
Write-Host "`tsmtpPassword: ******"
Write-Host "`temailFrom: ${emailFrom}"
Write-Host "`temailList: ${emailList}"
Write-Host "`temailSubject: ${emailSubject}"
Write-Host "`temailBody: ${emailBody}`n`n"

$dbAvailable = checkDbConnection $sqlServerName $sqlDatabase $sqlUsername $sqlPassword

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
    Write-Host "No access to ${countNoAccess} Network Shared Folders: ${notAccessList}. Sending email notification..."
    $ssl = $False

    if ($smtpSSL -eq "true") {
        $ssl = $True
    }
    else {
        $ssl = $False
    }
    $secureSmtpPassword = ConvertTo-SecureString -String $smtpPassword -AsPlainText -Force
    $emailsSent = sendEmail $smtpServer $smtpPort $ssl $smtpUsername $secureSmtpPassword $emailFrom $emailList $emailSubject $emailBody $notAccessList $dbAvailable $sqlServerName $sqlDatabase
}
else {
    Write-Host "Access to every Network Shared Folder is OK !"
}

$endTime = get-date -format "dd/MM/yyyy HH:mm:ss"
$nts = New-TimeSpan -Start $startTime -End $endTime
Write-Host "`nStart: ${startTime}"
Write-Host "End: ${endTime}"
Write-Host "Total Duration: ${nts}"