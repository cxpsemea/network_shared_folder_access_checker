# network_shared_folder_access_checker
Powershell Script to check if user has access to a Network Shared Folder

```cmd   
NAME
    ~\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1

SYNOPSIS
    Powershell Script to check if user has access to a Network Shared Folder


SYNTAX
    ~\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1 [-smtpServer] <String> [-smtpPort] <Int32> [-smtpSSL] <String> [-smtpUsername] <String> [-smtpPassword] <String> [-emailFrom] <String> [-emailList] 
    <String[]> [[-emailSubject] <String>] [[-emailBody] <String>] [<CommonParameters>]


DESCRIPTION
    .


PARAMETERS
    -smtpServer <String>

    -smtpPort <Int32>

    -smtpSSL <String>

    -smtpUsername <String>

    -smtpPassword <String>

    -emailFrom <String>

    -emailList <String[]>

    -emailSubject <String>
        
    -emailBody <String>

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

REMARKS
    To see the examples, type: "get-help ~\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1 -examples".
    For more information, type: "get-help ~\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1 -detailed".
    For technical information, type: "get-help ~\network_shared_folder_access_checker\src\NetworkSharedFolderAccessChecker.ps1 -full".
```