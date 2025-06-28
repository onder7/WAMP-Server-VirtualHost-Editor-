<#
.SYNOPSIS
    WAMP Server VirtualHost Yöneticisi
.DESCRIPTION
    Bu script WAMP Server'da yeni VirtualHost oluşturur, mevcutları listeler veya kaldırır.
    WAMP Server'ın C:\wamp64\ dizininde kurulu olduğunu varsayar.
.NOTES
    File Name      : WampVirtualHost.ps1
    Prerequisite   : PowerShell 5.1+, WAMP Server 64-bit
    Code           : Önder AKÖz onder7@gmail.com
#>

# WAMP Server yapılandırma dosyaları
$httpdConf = "C:\wamp64\bin\apache\apache2.4.62.1\conf\httpd.conf"
$httpdVhosts = "C:\wamp64\bin\apache\apache2.4.62.1\conf\extra\httpd-vhosts.conf"
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"

function Show-Menu {
    Clear-Host
    Write-Host "===================================="
    Write-Host " WAMP Server VirtualHost Yöneticisi "
    Write-Host "===================================="
    Write-Host "1. Yeni VirtualHost Ekle"
    Write-Host "2. VirtualHost Listele"
    Write-Host "3. VirtualHost Kaldır"
    Write-Host "4. Çıkış"
    Write-Host "===================================="
}

function Add-VirtualHost {
    param (
        [string]$domain,
        [string]$projectPath
    )
    
    # Proje dizini oluştur
    if (-not (Test-Path $projectPath)) {
        New-Item -ItemType Directory -Path $projectPath | Out-Null
        Write-Host "Proje dizini oluşturuldu: $projectPath"
    }
    
    # httpd-vhosts.conf dosyasına ekleme yap
    $vhostConfig = @"

<VirtualHost *:80>
    ServerName $domain
    DocumentRoot "$projectPath"
    <Directory "$projectPath">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

"@
    
    Add-Content -Path $httpdVhosts -Value $vhostConfig
    Write-Host "VirtualHost yapılandırması eklendi."
    
    # hosts dosyasına ekleme yap (yönetici yetkisi gerektirir)
    try {
        Add-Content -Path $hostsFile -Value "127.0.0.1 $domain" -Force
        Write-Host "Hosts dosyası güncellendi."
    }
    catch {
        Write-Host "HATA: Hosts dosyası güncellenemedi. Yönetici olarak çalıştırın." -ForegroundColor Red
    }
    
    # httpd.conf'da vhosts dosyasının include edildiğinden emin ol
    $includeCheck = Get-Content $httpdConf | Select-String "httpd-vhosts.conf"
    if (-not $includeCheck) {
        Add-Content -Path $httpdConf -Value "Include conf/extra/httpd-vhosts.conf"
        Write-Host "httpd.conf dosyası güncellendi."
    }
    
    Write-Host "VirtualHost başarıyla eklendi. WAMP Server'ı yeniden başlatın." -ForegroundColor Green
}

function Get-VirtualHosts {
    $vhosts = Select-String -Path $httpdVhosts -Pattern "<VirtualHost \*:80>" -Context 0,10
    if ($vhosts) {
        Write-Host "Mevcut VirtualHost'lar:"
        Write-Host "-----------------------"
        foreach ($vhost in $vhosts) {
            $serverName = ($vhost.Context.PostContext | Select-String "ServerName (\S+)").Matches.Groups[1].Value
            $docRoot = ($vhost.Context.PostContext | Select-String 'DocumentRoot "(.+?)"').Matches.Groups[1].Value
            Write-Host "Domain: $serverName"
            Write-Host "Dizin: $docRoot"
            Write-Host "-----------------------"
        }
    }
    else {
        Write-Host "Kayıtlı VirtualHost bulunamadı." -ForegroundColor Yellow
    }
}

function Remove-VirtualHost {
    param (
        [string]$domain
    )
    
    $content = Get-Content $httpdVhosts
    $newContent = @()
    $inVhost = $false
    $removed = $false
    
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match "<VirtualHost \*:80>") {
            $blockStart = $i
            $serverName = $null
            $inVhost = $true
        }
        
        if ($inVhost -and $content[$i] -match "ServerName $domain") {
            $serverName = $domain
        }
        
        if ($inVhost -and $content[$i] -match "</VirtualHost>") {
            $inVhost = $false
            if ($serverName -ne $domain) {
                $newContent += $content[$blockStart..$i]
            }
            else {
                $removed = $true
            }
        }
        
        if (-not $inVhost -and $content[$i] -notmatch "<VirtualHost \*:80>" -and $content[$i] -notmatch "</VirtualHost>") {
            $newContent += $content[$i]
        }
    }
    
    if ($removed) {
        Set-Content -Path $httpdVhosts -Value $newContent
        
        # hosts dosyasından da kaldır
        try {
            $hostsContent = Get-Content $hostsFile
            $newHostsContent = $hostsContent | Where-Object { $_ -notmatch "127.0.0.1 $domain" }
            Set-Content -Path $hostsFile -Value $newHostsContent -Force
            Write-Host "VirtualHost ve hosts kaydı kaldırıldı. WAMP Server'ı yeniden başlatın." -ForegroundColor Green
        }
        catch {
            Write-Host "HATA: Hosts dosyası güncellenemedi. Yönetici olarak çalıştırın." -ForegroundColor Red
        }
    }
    else {
        Write-Host "Belirtilen domain ile VirtualHost bulunamadı." -ForegroundColor Yellow
    }
}

# Ana program
do {
    Show-Menu
    $selection = Read-Host "Seçiminiz (1-4)"
    
    switch ($selection) {
        '1' {
            $domain = Read-Host "Domain adı (örnek: test.local)"
            $folderName = Read-Host "Proje klasör adı (www altında oluşturulacak)"
            $projectPath = "C:\wamp64\www\$folderName"
            
            Add-VirtualHost -domain $domain -projectPath $projectPath
            pause
        }
        '2' {
            Get-VirtualHosts
            pause
        }
        '3' {
            $domain = Read-Host "Kaldırılacak domain adı"
            Remove-VirtualHost -domain $domain
            pause
        }
        '4' {
            Write-Host "Çıkış yapılıyor..."
            exit
        }
        default {
            Write-Host "Geçersiz seçim. Lütfen 1-4 arasında bir sayı girin." -ForegroundColor Red
            pause
        }
    }
} while ($true)
