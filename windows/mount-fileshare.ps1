# used to mount azure fileshare (smb2) to azure windows compute

param(
    [string]$storac,
    [string]$fsname,
    [string]$fsfqdn,
    [string]$storkey
)

$connectTestResult = Test-NetConnection -ComputerName $fsfqdn -Port 445

if ($connectTestResult.TcpTestSucceeded) {
    cmd.exe /C "cmdkey /add:`"$fsfqdn`" /user:`"Azure\$storac`" /pass:`"$storkey`""
    New-PSDrive -Name S -PSProvider FileSystem -Root "\\$fsfqdn\$fsname" -Persist -Scope 'Global'
} else {
    Write-Error -Message "unable to reach the storage account via tcp:445"
}
