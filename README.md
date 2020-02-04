# network_shared_folder_access_checker
Powershell Script to check if user has access to a Network Shared Folder and SQL Server

```cmd   
Get-Help .\src\NetworkSharedFolderAccessChecker.ps1 -Detailed

NAME
    D:\Github\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1

SYNOPSIS
    Powershell Script to check if user has access to a Network Shared Folder and SQL Server


SYNTAX
    D:\Github\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1 [-networkShareFolders] <String[]>   
    [-sqlServerName] <String> [-sqlDatabase] <String> [-sqlUsername] <String> [-sqlPassword] <String> [-smtpServer] <String>    
    [-smtpPort] <Int32> [-smtpSSL] <String> [-smtpUsername] <String> [-smtpPassword] <String> [-emailFrom] <String>
    [-emailList] <String[]> [[-emailSubject] <String>] [[-emailBody] <String>] [<CommonParameters>]


DESCRIPTION
    Powershell Script that checks access to every Network Shared Folder and SQL Server provided by user,
    check if he is able to create a file and if not,
    notifies a email list about Access permission issues over those Network Shared Folders


PARAMETERS
    -networkShareFolders <String[]>
        Network Shared Folders (eg. \\temp\test,\\temp\sample) - Required

    -sqlServerName <String>
        SQL Server Name - Required

    -sqlDatabase <String>
        SQL Database - Required

    -sqlUsername <String>
        SQL Username - Required

    -sqlPassword <String>
        SQL Password - Required

    -smtpServer <String>
        SMTP Server (eg. smtp.mailtrap.io) - Required

    -smtpPort <Int32>
        SMTP Port (eg. 587) - Required

    -smtpSSL <String>
        SMTP SSL (eg. true or false) - Required

    -smtpUsername <String>
        SMTP Username - Required

    -smtpPassword <String>
        SMTP Password - Required

    -emailFrom <String>
        Email Sender (eg. first.last@company.com) - Required

    -emailList <String[]>
        Email Recipients (eg. first.last@company.com,second.last@company.com) - Required

    -emailSubject <String>
        Email Subject, Default = [Checkmarx] Cannot Access to Shared Folder - Optional

    -emailBody <String>
        Email Body (HTML), Default = Hi,</br></br>Impossible to access to the following shared
        folders:</br></br>#SHARED_FOLDERS#DATABASE</br></br>Best Regards,</br>Checkmarx - Optional

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

REMARKS
    To see the examples, type: "get-help
    D:\Github\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1 -examples".
    For more information, type: "get-help
    D:\Github\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1 -detailed".
    For technical information, type: "get-help
    D:\Github\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1 -full".
```

# Output

If any connection get a fail state an email like this will be sent to the user:
```html
Hi,

Impossible to access to the following shared folders:

- \\test\XPTO\test1
- test
- \\test\XPTO


Impossible to access SQL Server Database:

- localhost\CHECKMARX:CxDBdsf


Best Regards,
Checkmarx
```

# License

MIT License

Copyright (c) 2020 CX PS EMEA