#requires -version 2
<#
.DESCRIPTION
  show accounts that have not authenticated in 90 days
.NOTES
  Environment:    development/test
#>

$UPN = Read-Host 'what is your username?'

#check azad module present
if (!(Get-Module MSOnline -ListAvailable)) { Write-Host -BackgroundColor Red "download MSOnline modules for pwsh first: https://www.powershellgallery.com/packages/MSOnline/"; return }

Import-Module MSOnline
Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse).FullName | ?{ $_ -notmatch "_none_" } | select -First 1)

Connect-MsolService
$EXOSession = New-ExoPSSession -UserPrincipalName $UPN
Import-PSSession $EXOSession -AllowClobber

$startDate = (Get-Date).AddDays(-90).ToString('MM/dd/yyyy')
$endDate = (Get-Date).ToString('MM/dd/yyyy')
$allUsers = @()
$allUsers = Get-MsolUser -All -EnabledFilter EnabledOnly | Select UserPrincipalName
$loggedOnUsers = @()
$loggedOnUsers = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -Operations UserLoggedIn, PasswordLogonInitialAuthUsingPassword, UserLoginFailed -ResultSize 5000
$inactiveInLastThreeMonthsUsers = @()
$inactiveInLastThreeMonthsUsers = $allUsers.UserPrincipalName | where {$loggedOnUsers.UserIds -NotContains $_}

Write-Output "the following accounts have no associated authentication events over the past 90 days"
Write-Output $inactiveInLastThreeMonthsUsers
