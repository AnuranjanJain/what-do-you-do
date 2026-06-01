$ErrorActionPreference = "Stop"

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class NativeActivity {
  [DllImport("user32.dll")]
  public static extern IntPtr GetForegroundWindow();

  [DllImport("user32.dll")]
  public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);

  [DllImport("user32.dll")]
  public static extern int GetWindowTextLength(IntPtr hWnd);

  [DllImport("user32.dll")]
  public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

  [StructLayout(LayoutKind.Sequential)]
  public struct LASTINPUTINFO {
    public uint cbSize;
    public uint dwTime;
  }

  [DllImport("user32.dll")]
  public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

  [DllImport("kernel32.dll")]
  public static extern uint GetTickCount();
}
"@

$handle = [NativeActivity]::GetForegroundWindow()
$length = [NativeActivity]::GetWindowTextLength($handle)
$builder = New-Object System.Text.StringBuilder ([Math]::Max($length + 1, 256))
[void][NativeActivity]::GetWindowText($handle, $builder, $builder.Capacity)

$processId = 0
[void][NativeActivity]::GetWindowThreadProcessId($handle, [ref]$processId)

$processName = "Unknown"
$processPath = $null
try {
  $process = Get-Process -Id $processId -ErrorAction Stop
  $processName = $process.ProcessName
  try {
    $processPath = $process.Path
  } catch {
    $processPath = $null
  }
} catch {
  $processName = "Unknown"
}

$lastInput = New-Object NativeActivity+LASTINPUTINFO
$lastInput.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($lastInput)
[void][NativeActivity]::GetLastInputInfo([ref]$lastInput)
$idleMs = [NativeActivity]::GetTickCount() - $lastInput.dwTime

[PSCustomObject]@{
  capturedAt = (Get-Date).ToUniversalTime().ToString("o")
  platform = "windows"
  foregroundWindowTitle = $builder.ToString()
  processId = $processId
  processName = $processName
  processPath = $processPath
  idleMs = [int64]$idleMs
  rawContentStored = $false
} | ConvertTo-Json -Compress
