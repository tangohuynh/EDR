# Get Basic Host Info Script
# By Scott Rich
# Sentinel One (3/2019)
#
# The purpose of this script is to automate the gathering of detailed host info for an
# active investigation or to demonstrate the capabilities of the remote shell in Windows.
# 
# ****  This script MUST be run with admin privileges!!  ****
# 
# When run locally on a host, it will create multiple .txt files that will be compressed into an archive named,
# <hostname>_SystemInfo.zip in the same directory where it is run.
#

# Get detailed host information
$hostname = hostname
Write-Host 'Gathering Detailed Information on Host: ' $hostname
Write-Host 'Getting Operating System Information...'
$osinfo = Get-WmiObject Win32_OperatingSystem | Format-List *
Write-Host 'Getting Logical Disk Information...'
$diskinfo = Get-WmiObject -Class Win32_LogicalDisk | Format-Table
Write-Host 'Getting Share Information...'
$shareinfo = Get-WmiObject Win32_Share | Format-Table
Write-Host 'Getting Local User Account Information...'
$useraccounts = Get-WmiObject Win32_UserAccount -Namespace "root\cimv2" | Format-Table
Write-Host 'Getting Installed Application Information...'
$installedapps = Get-WmiObject -Class Win32_Product | Select Name, Vendor, Version, Caption | Format-Table

# Get a list of all installed services and status.
Write-Host 'Getting Service Information...'
$serviceTable = Get-WmiObject -Class Win32_Service -Property * | Format-Table

# Create the results data table for storing open network connections.
$networkTable = New-Object System.Data.DataTable
$networkTable.Columns.Add("LocalAddress", [string])
$networkTable.Columns.Add("LocalPort", [string])
$networkTable.Columns.Add("RemoteAddress", [string])
$networkTable.Columns.Add("RemotePort", [string])
$networkTable.Columns.Add("State", [string])
$networkTable.Columns.Add("OwningProcessID", [string])
$networkTable.Columns.Add("OwningProcessName", [string])

# Get current TCP activity and map to running process name
Write-Host 'Getting Network Socket Information and Mapping PID to Process Name'
$tcpActivity = Get-NetTCPConnection
foreach ($t in $tcpActivity)
{
    $op = $t | Select -ExpandProperty OwningProcess
    $processName = Get-Process -Id $op | Select -ExpandProperty ProcessName

    $row = $networkTable.NewRow()
    $row.LocalAddress = $t | Select -ExpandProperty LocalAddress
    $row.LocalPort = $t | Select -ExpandProperty LocalPort
    $row.RemoteAddress = $t | Select -ExpandProperty RemoteAddress
    $row.RemotePort = $t | Select -ExpandProperty RemotePort
    $row.State = $t | Select -ExpandProperty State
    $row.LocalAddress = $t | Select -ExpandProperty LocalAddress
    $row.OwningProcessID = $t | Select -ExpandProperty OwningProcess
    $row.OwningProcessName = $processName
    $networkTable.Rows.Add($row)
}

# Generate the Output Files and Archive them into .zip file.
Write-Host 'Generating Files and Creating Archive in Current, Working Directory.'
$osinfo + $diskinfo + $shareinfo + $useraccounts + $installedapps | Out-File -FilePath $hostname'_SystemInfo.txt'
$serviceTable | Out-File -FilePath $hostname'_Services.txt'
$networkTable | Format-Table | Out-File -FilePath $hostname'_NetworkInfo.txt'

Compress-Archive $hostname* $hostname'_SystemInfo.zip'
rm $hostname*.txt

Write-Host "COMPLETE!`n`r .ZIP File has been created in current working directory."