Connect-VIServer -Server 'x.x.x.x' -User 'username' -Password 'passwd'
$vms = Get-VM
$report = @()
foreach($vm in $vms)
   {
     $row = "" | Select Name, "HDD Size", UsedSpace, RAM, CPU, "Last Login Date"
     $row.Name = $vm.Name
     $row."HDD Size" = ($vm | Get-HardDisk | Measure-Object CapacityGB -Sum).Sum
     $row.UsedSpace = "{0:N2}" -f $vm.UsedSpaceGB
     $row.RAM = $vm.ExtensionData.Config.Hardware.MemoryMB
     $row.CPU = $vm.ExtensionData.Config.Hardware.NumCPU

     $ip = $vm.ExtensionData.Guest.IpAddress

     if ((Get-VMGuest -VM $vm).OSFullName -match 'Windows')
         {

            $QueryString = Get-WinEvent -comp $ip -FilterHashtable @{Logname='Security';ID=4672} -MaxEvents 1
            $last_login = $QueryString.TimeCreated

         }

      else
         {

           New-SshSession -ComputerName $ip -Username root -Password 'password'
           $out = Invoke-SshCommand -ComputerName $ip -Command "last | head -n1" 
           $last_login = ($out -split "\s+")[5] + '-' + ($out -split "\s+")[4] + '-' + '2017'
         }

      $row."Last Login Date" = (New-TimeSpan -Start $last_login).Days

      $report += $row
    }

$report | Export-Csv New.csv
