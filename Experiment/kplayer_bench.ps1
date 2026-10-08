param([string]$Exe, [string]$Video, [string]$Shot, [int]$Warm = 5, [int]$Samples = 8)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Collections.Generic;
public static class W {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  public static int Dismiss(uint pid) {
    IntPtr big = Biggest(pid); int n = 0;
    EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid && h != big && IsWindowVisible(h)) { RECT r; GetWindowRect(h, out r);
        if ((r.R - r.L) > 200 && (r.B - r.T) > 100) { PostMessage(h, 0x0010, IntPtr.Zero, IntPtr.Zero); n++; } }
      return true; }, IntPtr.Zero);
    return n;
  }
  public static IntPtr Biggest(uint pid) {
    IntPtr best = IntPtr.Zero; long area = 0;
    EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid && IsWindowVisible(h)) { RECT r; GetWindowRect(h, out r); long a = (long)(r.R - r.L) * (r.B - r.T); if (a > area) { area = a; best = h; } }
      return true; }, IntPtr.Zero);
    return best;
  }
}
"@
$p = Start-Process -FilePath $Exe -ArgumentList "`"$Video`"" -PassThru
$dis = 0
for ($i = 0; $i -lt 40; $i++) { Start-Sleep -Milliseconds 500; $dis += [W]::Dismiss([uint32]$p.Id); if ($dis -gt 0 -and $i -ge $Warm * 2) { break } }
"dialogs dismissed: $dis"
Start-Sleep 1
$h = [W]::Biggest([uint32]$p.Id); $r = New-Object W+RECT; [W]::GetWindowRect($h, [ref]$r) | Out-Null
"window {0}x{1} at {2},{3}" -f ($r.R-$r.L), ($r.B-$r.T), $r.L, $r.T
$cx = [int](($r.L + $r.R) / 2); $cy = [int](($r.T + $r.B) / 2)
$k = 0
foreach ($mode in "visible", "hidden", "visible") {
  if ($mode -eq "hidden") { [W]::SetCursorPos($r.R + 50, $r.B + 50) | Out-Null; if ($r.R + 50 -ge 1280) { [W]::SetCursorPos(5, 1070) | Out-Null }; Start-Sleep 4 }
  else { [W]::SetCursorPos($cx, $cy) | Out-Null; Start-Sleep 1 }
  $p.Refresh(); $c0 = $p.TotalProcessorTime.TotalSeconds; $t0 = Get-Date
  $gp = 0; $gd = 0; $dc = 0; $n = 0
  $dwmId = (Get-Process dwm | Select-Object -First 1).Id
  for ($i = 0; $i -lt $Samples; $i++) {
    if ($mode -eq "visible") { [W]::SetCursorPos($cx + (($i % 2) * 40 - 20), $cy) | Out-Null }
    $set = Get-Counter -Counter "\GPU Engine(*engtype_3D)\Utilization Percentage","\Process(dwm)\% Processor Time" -MaxSamples 1 -ErrorAction SilentlyContinue
    foreach ($cs in $set.CounterSamples) {
      if ($cs.Path -like "*\process(dwm)\*") { $dc += $cs.CookedValue }
      elseif ($cs.InstanceName -like "pid_$($p.Id)_*") { $gp += $cs.CookedValue }
      elseif ($cs.InstanceName -like "pid_$($dwmId)_*") { $gd += $cs.CookedValue }
    }
    $n++
    if ($i -eq 2 -and $Shot) {
      $bmp = New-Object System.Drawing.Bitmap ($r.R-$r.L), ($r.B-$r.T)
      $g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
      $bmp.Save("$Shot-$mode-$k.png"); $g.Dispose(); $bmp.Dispose()
    }
  }
  $k++
  $p.Refresh(); $el = ((Get-Date) - $t0).TotalSeconds
  "{0,-8} app CPU {1,6:N1}%  app GPU3D {2,5:N1}%  |  dwm CPU {3,5:N1}%  dwm GPU3D {4,5:N1}%" -f $mode, (($p.TotalProcessorTime.TotalSeconds - $c0) / $el * 100), ($gp / $n), ($dc / $n), ($gd / $n)
}
Stop-Process -Id $p.Id -Force
