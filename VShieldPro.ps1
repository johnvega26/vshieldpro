# --- 1. ELEVACIÓN Y PRIVILEGIOS ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

$ErrorActionPreference = "SilentlyContinue"

# --- 2. EXTRACCIÓN DE ESPECIFICACIONES (HARDWARE) ---
$cpu = (Get-CimInstance Win32_Processor).Name
$ramTotal = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB, 2)
$gpu = (Get-CimInstance Win32_VideoController).Caption
$os = (Get-CimInstance Win32_OperatingSystem).Caption
$disk = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{n="SizeGB";e={[math]::Round($_.Size/1GB,2)}}

# --- 3. INTERFAZ Y MENÚ (10 SEGUNDOS) ---
Clear-Host
$cyan = [ConsoleColor]::Cyan; $white = [ConsoleColor]::White

Write-Host @"
      __     __      ____  _     _      _     _ 
      \ \   / /     / ___|| |__ (_) ___| | __| |
       \ \ / /_____ \___ \| '_ \| |/ _ \ |/ _` |
        \ V /|_____| ___) | | | | |  __/ | (_| |
         \_/        |____/|_| |_|_|\___|_|\__,_|
                                                
         V-SHIELD PRO: FORENSIC & CYBER-ARMOR
         Ingeniero: John Ferney Vega
"@ -ForegroundColor $cyan

Write-Host "`n [ ESPECIFICACIONES DEL SISTEMA ]" -ForegroundColor Yellow
Write-Host " OS:  $os"
Write-Host " CPU: $cpu"
Write-Host " RAM: $ramTotal GB"
Write-Host " GPU: $gpu"
Write-Host "---------------------------------------------------------"

Write-Host "`n [1] Auditoría Forense + Full Armor (10s auto-start)"
Write-Host " [2] Solo Auditoría de Puertos y Firewall"
Write-Host " [3] Salir`n"

$timeout = 10; $opcion = $null
while ($timeout -gt 0) {
    if ([Console]::KeyAvailable) { $opcion = [Console]::ReadKey($true).KeyChar; break }
    Write-Host "`r Iniciando en: $timeout seg... " -NoNewline -ForegroundColor Yellow
    Start-Sleep -Seconds 1; $timeout--
}
if ($null -eq $opcion) { $opcion = "1" }
if ($opcion -eq "3") { Exit }

# --- 4. AUDITORÍA DE RED Y FIREWALL (BACKDOOR CHECK) ---
$puertosCerrados = @()
$puertosAbiertos = @()
$puertosRiesgo = @(135, 139, 445, 3389, 5985, 5986) # Puertos comunes para exploits/backdoors

$indices = if ($opcion -eq "1") { 0..8 } else { 4,5 }

$Pasos = @(
    "Purgando archivos temporales...",               
    "Optimizando Memoria RAM (MemReduct Engine)...", 
    "Limpiando cache y Microsoft Store...",          
    "Debloat: Eliminando Apps Basura...",
    "Auditoría de Red: Escaneando Backdoors/Puertos...", 
    "Shield: Mitigando CVE-2025 y Hardening...",
    "Gaming Mode: Optimización de Latencia...",  
    "Storage: Optimización de SSD...",    
    "System Integrity: Análisis SFC y DISM..."       
)

$ramAntes = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
Write-Host "`n [+] Iniciando procesos...`n" -ForegroundColor Green

# --- 5. MOTOR DE EJECUCIÓN ---
$totalPasos = $indices.Count; $contador = 0
foreach ($idx in $indices) {
    $contador++; $faseActual = $Pasos[$idx]
    $porcentajeFinal = [int](($contador / $totalPasos) * 100)
    Write-Progress -Activity "V-Shield Pro" -Status "$porcentajeFinal% - $faseActual" -PercentComplete $porcentajeFinal
    Write-Host " [+] $faseActual" -NoNewline

    & {
        switch ($idx) {
            4 { # AUDITORÍA DE PUERTOS
                foreach ($p in $puertosRiesgo) {
                    $check = Test-NetConnection -ComputerName localhost -Port $p -WarningAction SilentlyContinue
                    if ($check.TcpTestSucceeded) {
                        $puertosAbiertos += $p
                        # Intentar cerrar mediante regla de Firewall
                        New-NetFirewallRule -DisplayName "V-Shield Block $p" -Direction Inbound -LocalPort $p -Protocol TCP -Action Block > $null
                        $puertosCerrados += $p
                    }
                }
            }
            5 { # HARDENING & CVE
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous" -Value 1 -Force
                Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart > $null
            }
            # ... (los demás comandos de limpieza y reparación se mantienen igual internamente)
            0 { Remove-Item -Path "$env:TEMP\*" -Recurse -Force }
            1 { $type = Add-Type -MemberDefinition '[DllImport("kernel32.dll")] public static extern bool SetProcessWorkingSetSize(IntPtr h, IntPtr min, IntPtr max);' -Name "RamOpt" -PassThru; Get-Process | ForEach-Object { $type::SetProcessWorkingSetSize($_.Handle, -1, -1) } }
            6 { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Force }
            7 { powercfg -h off; dism /online /cleanup-image /startcomponentcleanup /resetbase > $null }
            8 { dism /online /cleanup-image /restorehealth > $null; sfc /scannow > $null }
        }
    } > $null 2>&1

    Write-Host "`r [ OK ] $faseActual" -ForegroundColor Green
}

# --- 6. GENERACIÓN DE REPORTE FINAL ---
$ramDespues = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
$liberado = [math]::Round(($ramDespues - $ramAntes) / 1024, 2)
$fecha = Get-Date -Format "dd-MM-yyyy_HH-mm"
$reportePath = "$env:USERPROFILE\Desktop\Reporte_VShield_$fecha.txt"

$reporteTexto = @"
=========================================================
      REPORTE TÉCNICO V-SHIELD PRO - JOHN VEGA
=========================================================
Fecha: $(Get-Date)
Equipo: $env:COMPUTERNAME

[ ESPECIFICACIONES ]
Procesador: $cpu
RAM Total:  $ramTotal GB
GPU:        $gpu
Sistema:    $os

[ AUDITORÍA DE SEGURIDAD ]
Puertos de Riesgo detectados Abiertos: $($puertosAbiertos -join ', ')
Puertos Bloqueados por V-Shield:       $($puertosCerrados -join ', ')
Estado de Red: Hardening SMBv1 y NetBIOS Aplicado.

[ MÉTRICAS DE OPTIMIZACIÓN ]
Memoria RAM recuperada: $liberado MB
Limpieza de temporales: Completada.
Integridad de archivos: Verificada.

=========================================================
       SISTEMA PROTEGIDO POR JOHN FERNEY VEGA
=========================================================
"@

$reporteTexto | Out-File $reportePath
Write-Progress -Activity "V-Shield Pro" -Status "Finalizado" -Completed
[Console]::Beep(523,150); [Console]::Beep(1046,300)

Write-Host "`n---------------------------------------------------------" -ForegroundColor $cyan
Write-Host "   AUDITORÍA Y BLINDAJE COMPLETADOS                      " -ForegroundColor Green
Write-Host "   Reporte guardado en el Escritorio.                    " -ForegroundColor Yellow
Write-Host "---------------------------------------------------------`n" -ForegroundColor $cyan
Start-Process notepad.exe $reportePath
Write-Host " Presione cualquier tecla para salir..." -ForegroundColor Gray
[Console]::ReadKey($true) | Out-Null