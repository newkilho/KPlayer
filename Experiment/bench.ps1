param([string]$Exe, [string]$Video, [string]$Dll, [string]$OutDir, [string[]]$Scenarios, [switch]$Fs, [int]$Warm = 4, [int]$Samples = 8)
$dwm = (Get-Process dwm | Select-Object -First 1)
$cores = [Environment]::ProcessorCount
foreach ($s in $Scenarios) {
  $tag = if ($Fs) { "fs" } else { "win" }
  $args2 = @($s, "`"$Video`"", "`"$Dll`"", "`"$OutDir\$s-$tag`"", ($Warm + $Samples + 4))
  if ($Fs) { $args2 += "fs" }
  $p = Start-Process -FilePath $Exe -ArgumentList $args2 -PassThru
  Start-Sleep $Warm
  $p.Refresh(); $dwm.Refresh()
  $c0 = $p.TotalProcessorTime.TotalSeconds; $d0 = $dwm.TotalProcessorTime.TotalSeconds; $t0 = Get-Date
  $ctr = Get-Counter -Counter "\GPU Engine(*engtype_3D)\Utilization Percentage","\Process(dwm)\% Processor Time" -SampleInterval 1 -MaxSamples $Samples -ErrorAction SilentlyContinue
  $p.Refresh(); $dwm.Refresh()
  $el = ((Get-Date) - $t0).TotalSeconds
  $cpu = ($p.TotalProcessorTime.TotalSeconds - $c0) / $el * 100
  $dcpu = 0
  $gp = 0; $gd = 0
  foreach ($set in $ctr) {
    foreach ($cs in $set.CounterSamples) {
      if ($cs.Path -like "*\process(dwm)\*") { $dcpu += $cs.CookedValue }
      elseif ($cs.InstanceName -like "pid_$($p.Id)_*") { $gp += $cs.CookedValue }
      elseif ($cs.InstanceName -like "pid_$($dwm.Id)_*") { $gd += $cs.CookedValue }
    }
  }
  $gp /= $ctr.Count; $gd /= $ctr.Count; $dcpu /= $ctr.Count
  "{0,-7} {1,-3}  app CPU {2,6:N1}%  app GPU3D {3,5:N1}%  |  dwm CPU {4,5:N1}%  dwm GPU3D {5,5:N1}%" -f $s, $tag, $cpu, $gp, $dcpu, $gd
  if (-not $p.HasExited) { $p.WaitForExit(8000) | Out-Null; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force } }
  Start-Sleep 1
}
