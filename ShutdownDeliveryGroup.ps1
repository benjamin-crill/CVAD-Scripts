asnp citrix.*

$delGroup = Read-Host -Prompt 'Enter delivery group to shutdown'
$broker = "name of your broker here"

Set-BrokerDesktopGroup -AdminAddress $broker -Name $delGroup -InMaintenanceMode $true

$desktops = Get-BrokerDesktop -DesktopGroupName $delGroup

New-BrokerHostingPowerAction -MachineName $desktops.MachineName -Action Shutdown