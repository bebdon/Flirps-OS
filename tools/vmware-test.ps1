<#
.SYNOPSIS
    Test Flirps OS in a VMware Workstation VM, hands-free: builds the VM, installs Arch,
    runs install.sh from this checkout, and takes showcase screenshots.

.DESCRIPTION
    1. Creates the VM (UEFI, 3D acceleration, 8 GB RAM, 4 cores, 40 GB disk) if it doesn't exist.
    2. Downloads and verifies the latest Arch ISO if you don't pass -Iso.
    3. Boots the ISO and, through VMware's guest tools, wipes the VM disk, installs a minimal
       Arch with your user, copies in this checkout (uncommitted changes included) and runs
       ./install.sh as that user. No typing in the VM needed.
    4. Takes a "Flirps installed" snapshot and boots it.
    5. Screenshots the login screen and a tour of the desktop into docs/screenshots/.

    You are asked once for the VM user's password. It's used to log in to the VM's guest tools
    for the screenshots, and is passed to vmrun on its command line, so use a test-only password.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\vmware-test.ps1 -Timezone Europe/London -Keymap uk -Locale en_GB.UTF-8

.EXAMPLE
    # Only retake the screenshots on the VM from a previous run
    powershell -ExecutionPolicy Bypass -File tools\vmware-test.ps1 -ScreenshotsOnly
#>
[CmdletBinding()]
param(
    [string]$VmDir    = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Virtual Machines\Flirps-Test'),
    [string]$Iso,                         # Arch ISO to boot; downloaded into $VmDir if omitted
    [string]$User     = 'flirps',
    [string]$Timezone = 'UTC',            # e.g. Europe/London
    [string]$Keymap   = 'us',             # text console only, e.g. uk, de
    [string]$Locale   = 'en_US.UTF-8',    # e.g. en_GB.UTF-8
    [int]$MemoryMB    = 8192,
    [int]$Cpus        = 4,
    [int]$DiskGB      = 40,
    [string[]]$Wallpapers = @('anime-e8865l.jpg', 'anime-flower-girl.png', 'anime-red-tactical.png', 'ddg_1774781658663966193.jpg', 'ddg_1774734326903598045.jpg', 'ddg_1785828995460261051.jpg'),  # one 'look' screenshot each; panels use the first
    [switch]$NoScreenshots,
    [switch]$ScreenshotsOnly
)
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$Repo  = Split-Path $PSScriptRoot -Parent
$Name  = Split-Path $VmDir -Leaf
$Vmx   = Join-Path $VmDir "$Name.vmx"
$Shots = Join-Path $Repo 'docs\screenshots'

function Say($msg) { Write-Host "`n==> $msg" -ForegroundColor Magenta }

# --- VMware tools on the host -------------------------------------------------
$vmwareDir = $null
foreach ($key in 'HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation', 'HKLM:\SOFTWARE\VMware, Inc.\VMware Workstation') {
    if (Test-Path $key) { $vmwareDir = (Get-ItemProperty $key).InstallPath; if ($vmwareDir) { break } }
}
if (-not $vmwareDir) { $vmwareDir = 'C:\Program Files\VMware\VMware Workstation' }
$vmrun = Join-Path $vmwareDir 'vmrun.exe'
$vdisk = Join-Path $vmwareDir 'vmware-vdiskmanager.exe'
if (-not (Test-Path $vmrun)) { throw "VMware Workstation not found (looked for $vmrun)." }

# Run vmrun; $Cmd is the vmrun command and its arguments, $Auth the guest login (if any).
function Vm([string[]]$Cmd, [string[]]$Auth = @(), [switch]$NoThrow) {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = & $vmrun -T ws @Auth @Cmd 2>&1 | Out-String
    $code = $LASTEXITCODE
    $ErrorActionPreference = $old
    if ($NoThrow) { return ($code -eq 0) }
    if ($code -ne 0) { throw "vmrun $($Cmd[0]) failed: $($out.Trim())" }
}
# Live ISO: root with no password. Installed system: the user.
$LiveAuth = @('-gu', 'root', '-gp', '""')
function Live([string[]]$Cmd)   { Vm $Cmd $LiveAuth }
function AsUser([string[]]$Cmd) { Vm $Cmd $script:UserAuth }

function Set-VmxOption([string]$Key, [string]$Value) {
    $lines = [IO.File]::ReadAllLines($Vmx) | Where-Object { $_ -notmatch "^\s*$([regex]::Escape($Key))\s*=" }
    if ($null -ne $Value) { $lines += "$Key = `"$Value`"" }
    [IO.File]::WriteAllLines($Vmx, [string[]]$lines)
}
function Test-Running { @(& $vmrun list) -contains $Vmx }
function Wait-Tools([int]$Seconds = 300) {
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) {
        if ((& $vmrun -T ws checkToolsState $Vmx) -eq 'running') { Start-Sleep 3; return }
        Start-Sleep 3
    }
    throw "VMware guest tools didn't start in the VM within $Seconds s."
}
# Copy a text file from the repo into the guest with Linux line endings
function Copy-Text([string]$Src, [string]$Dest, [string[]]$Auth) {
    $tmp = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText($tmp, ([IO.File]::ReadAllText($Src) -replace "`r`n", "`n"))
    try { Vm @('CopyFileFromHostToGuest', $Vmx, $tmp, $Dest) $Auth } finally { Remove-Item $tmp }
}
function Read-Password {
    while ($true) {
        $a = Read-Host "Password for '$User' in the VM (test-only)" -AsSecureString
        $b = Read-Host 'Same again' -AsSecureString
        $pa = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($a))
        $pb = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($b))
        if ($pa -and $pa -eq $pb -and $pa -notmatch '[\s"]') { return $pa }
        Write-Warning "Passwords are empty, don't match, or contain spaces/quotes. Try again."
    }
}

$Password = Read-Password
$script:UserAuth = @('-gu', $User, '-gp', $Password)

if (-not $ScreenshotsOnly) {
    # --- The Arch ISO ---------------------------------------------------------
    New-Item -ItemType Directory -Force $VmDir | Out-Null
    if (-not $Iso) {
        $Iso = Join-Path $VmDir 'archlinux-x86_64.iso'
        $mirror = 'https://geo.mirror.pkgbuild.com/iso/latest'
        $sums = (Invoke-WebRequest "$mirror/sha256sums.txt" -UseBasicParsing).Content
        $want = ([regex]::Match($sums, '(?m)^([0-9a-f]{64})\s+archlinux-x86_64\.iso$')).Groups[1].Value
        if (-not $want) { throw "Couldn't read the ISO checksum from $mirror." }
        if (-not (Test-Path $Iso) -or (Get-FileHash $Iso -Algorithm SHA256).Hash -ne $want.ToUpper()) {
            Say "Downloading the Arch ISO (~1.3 GB)"
            & curl.exe -fL --progress-bar -o $Iso "$mirror/archlinux-x86_64.iso"
            if ($LASTEXITCODE -ne 0) { throw 'ISO download failed.' }
            if ((Get-FileHash $Iso -Algorithm SHA256).Hash -ne $want.ToUpper()) { throw 'ISO checksum mismatch.' }
        }
    }
    $Iso = (Resolve-Path $Iso).Path

    # --- The VM ---------------------------------------------------------------
    if (Test-Running) { Say 'Stopping the running VM'; Vm @('stop', $Vmx, 'hard'); Start-Sleep 3 }
    if (-not (Test-Path $Vmx)) {
        Say "Creating the VM in $VmDir"
        & $vdisk -c -s "${DiskGB}GB" -a lsilogic -t 0 (Join-Path $VmDir "$Name.vmdk") | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Creating the virtual disk failed.' }
        $vmxLines = @(
            '.encoding = "UTF-8"', 'config.version = "8"', 'virtualHW.version = "21"',
            "displayName = `"$Name`"", 'guestOS = "other6xlinux-64"', 'firmware = "efi"',
            "memsize = `"$MemoryMB`"", "numvcpus = `"$Cpus`"", 'cpuid.coresPerSocket = "1"',
            'mks.enable3d = "TRUE"', 'svga.graphicsMemoryKB = "8388608"',
            'pciBridge0.present = "TRUE"',
            'pciBridge4.present = "TRUE"', 'pciBridge4.virtualDev = "pcieRootPort"', 'pciBridge4.functions = "8"',
            'pciBridge5.present = "TRUE"', 'pciBridge5.virtualDev = "pcieRootPort"', 'pciBridge5.functions = "8"',
            'vmci0.present = "TRUE"', 'hpet0.present = "TRUE"',
            'scsi0.present = "TRUE"', 'scsi0.virtualDev = "lsilogic"',
            'scsi0:0.present = "TRUE"', "scsi0:0.fileName = `"$Name.vmdk`"",
            'sata0.present = "TRUE"', 'sata0:1.present = "TRUE"', 'sata0:1.deviceType = "cdrom-image"',
            'ethernet0.present = "TRUE"', 'ethernet0.connectionType = "nat"', 'ethernet0.virtualDev = "e1000"',
            'ethernet0.addressType = "generated"',
            'usb.present = "TRUE"', 'ehci.present = "TRUE"', 'sound.present = "TRUE"', 'sound.autoDetect = "TRUE"',
            'floppy0.present = "FALSE"', 'tools.syncTime = "FALSE"'
        )
        [IO.File]::WriteAllLines($Vmx, [string[]]$vmxLines)
    }
    # Boot the ISO this time, even though the disk may already have a system on it
    Set-VmxOption 'sata0:1.fileName' $Iso
    Set-VmxOption 'sata0:1.startConnected' 'TRUE'
    Set-VmxOption 'bios.bootOrder' 'cdrom,hdd'

    Say 'Booting the Arch live ISO'
    Vm @('start', $Vmx, 'gui')
    Wait-Tools

    # --- This checkout, uncommitted changes included, as a git bundle ---------
    Say 'Packing this checkout'
    Push-Location $Repo
    $ErrorActionPreference = 'Continue'
    try {
        $commit = (git stash create) | Out-String
        $commit = $commit.Trim()
        if ($commit) { Write-Host 'Including your uncommitted changes.' } else { $commit = (git rev-parse HEAD).Trim() }
        $Label = (git rev-parse --short HEAD).Trim() + $(if ((git status --porcelain)) { '+changes' } else { '' })
        $Remote = (git remote get-url origin).Trim()
        $bundle = Join-Path $env:TEMP 'flirps.bundle'
        git branch -f flirps-vm-test $commit | Out-Null
        git bundle create -q $bundle flirps-vm-test
        if ($LASTEXITCODE -ne 0) { throw 'git bundle failed.' }
        git branch -D flirps-vm-test | Out-Null
    } finally { Pop-Location; $ErrorActionPreference = 'Stop' }

    # --- Run the install inside the VM ----------------------------------------
    $envFile = [IO.Path]::GetTempFileName()
    $pwFile  = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText($envFile, "USERNAME='$User'`nTIMEZONE='$Timezone'`nKEYMAP='$Keymap'`nLOCALE='$Locale'`nHOSTNAME='flirps-test'`nREMOTE='$Remote'`n")
    [IO.File]::WriteAllText($pwFile, "${User}:$Password`n")
    try {
        Live @('CopyFileFromHostToGuest', $Vmx, $envFile, '/root/flirps-test.env')
        Live @('CopyFileFromHostToGuest', $Vmx, $pwFile, '/root/flirps-pw')
    } finally { Remove-Item $envFile, $pwFile }
    Live @('CopyFileFromHostToGuest', $Vmx, $bundle, '/root/flirps.bundle')
    Remove-Item $bundle
    Copy-Text (Join-Path $PSScriptRoot 'vm-guest-install.sh') /root/vm-guest-install.sh $LiveAuth
    Live @('runProgramInGuest', $Vmx, '-noWait', '/bin/bash', '/root/vm-guest-install.sh')

    Say 'Installing (10-20 minutes). Progress:'
    $log = Join-Path $env:TEMP 'flirps-test.log'
    $shown = 0; $result = $null
    while (-not $result) {
        Start-Sleep 10
        if (-not (Vm @('CopyFileFromGuestToHost', $Vmx, '/root/flirps-test.log', $log) $LiveAuth -NoThrow)) { continue }
        $lines = @(Get-Content $log)
        foreach ($l in $lines[$shown..($lines.Count - 1)]) {
            if ($l -match '^(###|==>|\x1b\[1;35m==>|!!|FLIRPS_RESULT)') { Write-Host ($l -replace '\x1b\[[0-9;]*m', '') }
        }
        $shown = $lines.Count
        $m = $lines | Select-String '^FLIRPS_RESULT=(.*)' | Select-Object -Last 1
        if ($m) { $result = $m.Matches[0].Groups[1].Value }
    }
    if ($result -ne 'ok') {
        $keep = Join-Path $VmDir 'install-failed.log'
        Copy-Item $log $keep -Force
        throw "Install failed ($result). Full log: $keep"
    }

    # --- Boot the installed system --------------------------------------------
    Say 'Installed. Shutting down, detaching the ISO and taking a snapshot'
    Vm @('stop', $Vmx, 'soft')
    Start-Sleep 3
    Set-VmxOption 'sata0:1.startConnected' 'FALSE'
    Set-VmxOption 'bios.bootOrder' $null
    $snap = "Flirps installed ($Label, $(Get-Date -Format "yyyy-MM-dd HH.mm"))"
    Vm @('snapshot', $Vmx, $snap)
    Write-Host "Snapshot: $snap"
    Vm @('start', $Vmx, 'gui')
}
elseif (-not (Test-Running)) { Vm @('start', $Vmx, 'gui') }

# --- Screenshots ----------------------------------------------------------------
if (-not $NoScreenshots) {
    Say "Taking screenshots into $Shots"
    New-Item -ItemType Directory -Force $Shots | Out-Null
    Wait-Tools
    Start-Sleep 15   # let the login screen settle

    function Shot([string]$File) {
        AsUser @('captureScreen', $Vmx, (Join-Path $Shots $File))
        Write-Host "  $File"
    }
    function Run([string]$Cmd, [switch]$NoThrow) {   # run shell commands inside the Hyprland session
        $tmp = [IO.Path]::GetTempFileName()
        [IO.File]::WriteAllText($tmp, "$Cmd`n")
        try {
            AsUser @('CopyFileFromHostToGuest', $Vmx, $tmp, '/tmp/flirps-cmd.sh')
            Vm @('runProgramInGuest', $Vmx, '/bin/bash', '/tmp/vm-session.sh', 'bash', '/tmp/flirps-cmd.sh') $script:UserAuth -NoThrow:$NoThrow
        } finally { Remove-Item $tmp }
    }

    # Saves logs from the desktop session to $VmDir\diagnostics.txt (vmrun ignores the guest's exit
    # codes, so results come back as files)
    function Save-Diagnostics {
        Copy-Text (Join-Path $PSScriptRoot 'vm-diagnose.sh') /tmp/vm-diagnose.sh $script:UserAuth
        Run 'bash /tmp/vm-diagnose.sh > /tmp/flirps-diag.txt 2>&1' -NoThrow | Out-Null
        $diag = Join-Path $VmDir 'diagnostics.txt'
        if (Vm @('CopyFileFromGuestToHost', $Vmx, '/tmp/flirps-diag.txt', $diag) $script:UserAuth -NoThrow) {
            Write-Host "Session logs: $diag"
        }
    }

    Shot '01-login.png'

    Copy-Text (Join-Path $PSScriptRoot 'vm-session.sh') /tmp/vm-session.sh $script:UserAuth
    if ($ScreenshotsOnly) {
        # Bring the VM tweaks that install.sh writes up to date with this checkout
        $m = [regex]::Match([IO.File]::ReadAllText((Join-Path $Repo 'install.sh')), "(?s)<<'LUA'\r?\n(.*?)\r?\nLUA")
        if ($m.Success) {
            $tmp = [IO.Path]::GetTempFileName()
            [IO.File]::WriteAllText($tmp, ($m.Groups[1].Value -replace "`r`n", "`n") + "`n")
            try { AsUser @('CopyFileFromHostToGuest', $Vmx, $tmp, "/home/$User/.config/hypr/config/machine.lua") } finally { Remove-Item $tmp }
        }
    }
    # A neutral weather location, so screenshots don't show where the VM's internet connection is
    Run ('printf ''{"name": "Reykjavik", "lat": 64.15, "lon": -21.94, "tz": "Atlantic/Reykjavik", "unit": "celsius"}\n'' > ~/.config/quickshell/panels/location.json; ' +
         'rm -f ~/.cache/quickshell/weather.json') | Out-Null
    AsUser @('runProgramInGuest', $Vmx, '/usr/bin/sudo', '/usr/local/bin/flirps-showcase', 'login')
    $ready = Join-Path $env:TEMP 'flirps-ready'
    $end = (Get-Date).AddSeconds(90)
    do {
        Start-Sleep 3
        Run 'rm -f /tmp/flirps-ready; qs -c panels ipc call launcher close && touch /tmp/flirps-ready' -NoThrow | Out-Null
        $up = Vm @('CopyFileFromGuestToHost', $Vmx, '/tmp/flirps-ready', $ready) $script:UserAuth -NoThrow
    } until ($up -or (Get-Date) -gt $end)
    if (-not $up) {
        Save-Diagnostics
        throw "The desktop shell didn't come up after auto-login (see diagnostics.txt)."
    }
    # Warm up: wallpaper thumbnails, and the picker's sort-by-colour pass (slow the first time)
    Run 'wallpaper-thumbs; qs-panel wallpapers' | Out-Null
    Start-Sleep 30
    Run 'qs -c panels ipc call wallpapers close' | Out-Null

    # The panels, on the first wallpaper
    Run "wallpaper set ~/Pictures/Wallpapers/$($Wallpapers[0])"
    Start-Sleep 8;  Shot '02-desktop.png'
    Run 'setsid -f kitty --hold fastfetch >/dev/null 2>&1'
    Start-Sleep 8;  Shot '03-terminal.png'
    Run 'pkill -x kitty; qs-panel launcher'; Start-Sleep 3; Shot '04-launcher.png'
    Run 'qs-panel dashboard';     Start-Sleep 3;  Shot '05-dashboard.png'
    Run 'qs-panel quicksettings'; Start-Sleep 3;  Shot '06-quick-settings.png'
    Run 'qs-panel wallpapers';    Start-Sleep 15; Shot '07-wallpapers.png'
    Run 'qs-panel power';         Start-Sleep 3;  Shot '10-power-menu.png'

    # One look per wallpaper: the desktop with Quick Settings open, both recolored
    $n = 0
    foreach ($w in $Wallpapers) {
        $n++
        Run "qs -c panels ipc call quicksettings close; qs -c panels ipc call power close; wallpaper set ~/Pictures/Wallpapers/$w"
        Start-Sleep 8
        Run 'qs-panel quicksettings'
        Start-Sleep 3
        Shot ('look-{0}.png' -f $n)
    }

    Save-Diagnostics

    # Back to the normal login screen (turns auto-login off again)
    AsUser @('runProgramInGuest', $Vmx, '/usr/bin/sudo', '/usr/local/bin/flirps-showcase', 'logout')
}

Say 'Done!'
Write-Host "The VM is at the login screen: log in as '$User' to try it."
if (-not $NoScreenshots) { Write-Host "Screenshots: $Shots" }
