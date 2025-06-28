Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Yönetici kontrolü fonksiyonu
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# WAMP yollarını dinamik olarak bul
function Get-WampPaths {
    $wampBase = "C:\wamp64"
    if (-not (Test-Path $wampBase)) {
        throw "WAMP64 bulunamadı: $wampBase"
    }
    


    
    return @{
        HttpdConf = "$wampBase\bin\apache\apache2.4.62.1\conf\httpd.conf"
        HttpdVhosts = "$wampBase\bin\apache\apache2.4.62.1\conf\extra\httpd-vhosts.conf"
        HostsFile = "C:\Windows\System32\drivers\etc\hosts"
        WwwRoot = "$wampBase\www"
    }
}

# Yolları al ve kontrol et
try {
    $paths = Get-WampPaths
    foreach ($path in $paths.Values) {
        if (-not (Test-Path $path -PathType Leaf) -and $path -notmatch "www$") {
            throw "Dosya bulunamadı: $path"
        }
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("WAMP yapılandırması bulunamadı:`n$_", "Hata", "OK", "Error")
    exit
}

# Ana form oluştur
$form = New-Object System.Windows.Forms.Form
$form.Text = "WAMP Server VirtualHost Yöneticisi"
$form.Size = New-Object System.Drawing.Size(600,500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Sekme kontrolü
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = "Fill"
$form.Controls.Add($tabControl)

## Yeni VirtualHost Ekleme Sekmesi ##
$tabAdd = New-Object System.Windows.Forms.TabPage
$tabAdd.Text = "Yeni Ekle"
$tabControl.Controls.Add($tabAdd)

# Domain etiketi ve metin kutusu
$lblDomain = New-Object System.Windows.Forms.Label
$lblDomain.Text = "Domain Adı:"
$lblDomain.Location = New-Object System.Drawing.Point(20,20)
$lblDomain.Size = New-Object System.Drawing.Size(100,20)
$tabAdd.Controls.Add($lblDomain)

$txtDomain = New-Object System.Windows.Forms.TextBox
$txtDomain.Location = New-Object System.Drawing.Point(130,20)
$txtDomain.Size = New-Object System.Drawing.Size(200,20)
$tabAdd.Controls.Add($txtDomain)

# Proje Klasörü etiketi ve metin kutusu
$lblFolder = New-Object System.Windows.Forms.Label
$lblFolder.Text = "Proje Klasörü:"
$lblFolder.Location = New-Object System.Drawing.Point(20,50)
$lblFolder.Size = New-Object System.Drawing.Size(100,20)
$tabAdd.Controls.Add($lblFolder)

$txtFolder = New-Object System.Windows.Forms.TextBox
$txtFolder.Location = New-Object System.Drawing.Point(130,50)
$txtFolder.Size = New-Object System.Drawing.Size(200,20)
$tabAdd.Controls.Add($txtFolder)

# WWW kökü bilgisi
$lblWwwRoot = New-Object System.Windows.Forms.Label
$lblWwwRoot.Text = "www dizini içinde oluşturulacak"
$lblWwwRoot.Location = New-Object System.Drawing.Point(340,50)
$lblWwwRoot.Size = New-Object System.Drawing.Size(200,20)
$lblWwwRoot.ForeColor = [System.Drawing.Color]::Gray
$tabAdd.Controls.Add($lblWwwRoot)

# Ekle butonu
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "VirtualHost Ekle"
$btnAdd.Location = New-Object System.Drawing.Point(130,90)
$btnAdd.Size = New-Object System.Drawing.Size(120,30)
$btnAdd.Add_Click({
    if (-not (Test-Administrator)) {
        [System.Windows.Forms.MessageBox]::Show("Bu işlem için yönetici yetkisi gerekli!", "Yetki Hatası", "OK", "Error")
        return
    }
    
    if (-not $txtDomain.Text -or -not $txtFolder.Text) {
        [System.Windows.Forms.MessageBox]::Show("Lütfen tüm alanları doldurun!", "Uyarı", "OK", "Warning")
        return
    }
    
    # Domain adı doğrulaması
    if ($txtDomain.Text -notmatch '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' -and $txtDomain.Text -notmatch '^[a-zA-Z0-9.-]+\.local$') {
        [System.Windows.Forms.MessageBox]::Show("Geçerli bir domain adı girin (örn: test.local)", "Geçersiz Domain", "OK", "Warning")
        return
    }
    
    $domain = $txtDomain.Text.Trim()
    $folderName = $txtFolder.Text.Trim()
    $projectPath = Join-Path $paths.WwwRoot $folderName
    
    try {
        # Mevcut domain kontrolü
        $existingHosts = Get-Content $paths.HostsFile -ErrorAction SilentlyContinue
        if ($existingHosts -and ($existingHosts | Where-Object { $_ -match "127\.0\.0\.1\s+$domain" })) {
            [System.Windows.Forms.MessageBox]::Show("Bu domain zaten mevcut!", "Domain Çakışması", "OK", "Warning")
            return
        }
        
        # Proje dizini oluştur
        if (-not (Test-Path $projectPath)) {
            New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
        }
        
        # Basit index.html oluştur
        $indexHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>$domain</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>$domain Çalışıyor!</h1>
    <p>VirtualHost başarıyla kuruldu.</p>
</body>
</html>
"@
        Set-Content -Path (Join-Path $projectPath "index.html") -Value $indexHtml -Encoding UTF8
        
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
    ErrorLog "logs/$($domain)_error.log"
    CustomLog "logs/$($domain)_access.log" common
</VirtualHost>
"@
        Add-Content -Path $paths.HttpdVhosts -Value $vhostConfig -Encoding UTF8
        
        # hosts dosyasına ekleme yap
        Add-Content -Path $paths.HostsFile -Value "`n127.0.0.1`t$domain" -Encoding ASCII
        
        # httpd.conf'da vhosts dosyasının include edildiğinden emin ol
        $httpdContent = Get-Content $paths.HttpdConf
        $includePattern = "Include conf/extra/httpd-vhosts.conf"
        $hasActiveInclude = $httpdContent | Where-Object { $_ -eq $includePattern -and $_ -notmatch '^\s*#' }
        
        if (-not $hasActiveInclude) {
            # Eğer commented include varsa aktif et
            $commentedInclude = $httpdContent | Where-Object { $_ -match '^\s*#.*httpd-vhosts\.conf' }
            if ($commentedInclude) {
                $newContent = $httpdContent -replace '^\s*#(.*)httpd-vhosts\.conf', '$1httpd-vhosts.conf'
                Set-Content -Path $paths.HttpdConf -Value $newContent -Encoding UTF8
            } else {
                Add-Content -Path $paths.HttpdConf -Value "`n$includePattern" -Encoding UTF8
            }
        }
        
        [System.Windows.Forms.MessageBox]::Show("VirtualHost başarıyla eklendi!`n`nDomain: $domain`nDizin: $projectPath`n`nWAMP Server'ı yeniden başlatın.", "Başarılı", "OK", "Information")
        $txtDomain.Text = ""
        $txtFolder.Text = ""
        
        # Listeyi güncelle
        Update-HostList
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Hata oluştu: $($_.Exception.Message)", "Hata", "OK", "Error")
    }
})
$tabAdd.Controls.Add($btnAdd)

## VirtualHost Listesi Sekmesi ##
$tabList = New-Object System.Windows.Forms.TabPage
$tabList.Text = "VirtualHost Listesi"
$tabControl.Controls.Add($tabList)

# Liste kutusu
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(20,20)
$listView.Size = New-Object System.Drawing.Size(540,350)
$listView.View = "Details"
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Columns.Add("Domain", 200) | Out-Null
$listView.Columns.Add("Dizin", 340) | Out-Null
$tabList.Controls.Add($listView)

# Yenile butonu
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Listeyi Yenile"
$btnRefresh.Location = New-Object System.Drawing.Point(20,380)
$btnRefresh.Size = New-Object System.Drawing.Size(120,30)
$btnRefresh.Add_Click({
    Update-HostList
})
$tabList.Controls.Add($btnRefresh)

# Kaldır butonu
$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "Seçileni Kaldır"
$btnRemove.Location = New-Object System.Drawing.Point(150,380)
$btnRemove.Size = New-Object System.Drawing.Size(120,30)
$btnRemove.Add_Click({
    if (-not (Test-Administrator)) {
        [System.Windows.Forms.MessageBox]::Show("Bu işlem için yönetici yetkisi gerekli!", "Yetki Hatası", "OK", "Error")
        return
    }
    
    if ($listView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Lütfen kaldırmak için bir VirtualHost seçin!", "Uyarı", "OK", "Warning")
        return
    }
    
    $selectedDomain = $listView.SelectedItems[0].Text
    
    $result = [System.Windows.Forms.MessageBox]::Show("'$selectedDomain' VirtualHost'unu kaldırmak istediğinize emin misiniz?", "Onay", "YesNo", "Question")
    if ($result -eq "Yes") {
        try {
            Remove-VirtualHost -Domain $selectedDomain
            [System.Windows.Forms.MessageBox]::Show("VirtualHost kaldırıldı!`nWAMP Server'ı yeniden başlatın.", "Başarılı", "OK", "Information")
            Update-HostList
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Hata oluştu: $($_.Exception.Message)", "Hata", "OK", "Error")
        }
    }
})
$tabList.Controls.Add($btnRemove)

# Durum bilgisi
$isAdmin = Test-Administrator
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Yönetici olarak çalıştırıldı: $isAdmin"
$lblStatus.Location = New-Object System.Drawing.Point(20,420)
$lblStatus.Size = New-Object System.Drawing.Size(300,20)
$lblStatus.ForeColor = if ($isAdmin) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
$tabList.Controls.Add($lblStatus)

# VirtualHost kaldırma fonksiyonu
function Remove-VirtualHost {
    param([string]$Domain)
    
    # VirtualHost konfigürasyonunu kaldır
    $content = Get-Content $paths.HttpdVhosts
    $newContent = @()
    $i = 0
    
    while ($i -lt $content.Length) {
        if ($content[$i] -match '<VirtualHost \*:80>') {
            $vhostStart = $i
            $vhostContent = @($content[$i])
            $i++
            
            # VirtualHost bloğunu tamamen oku
            while ($i -lt $content.Length -and $content[$i] -notmatch '</VirtualHost>') {
                $vhostContent += $content[$i]
                $i++
            }
            
            if ($i -lt $content.Length) {
                $vhostContent += $content[$i] # </VirtualHost> satırını ekle
            }
            
            # Bu VirtualHost'un ServerName'ini kontrol et
            $serverNameLine = $vhostContent | Where-Object { $_ -match "ServerName\s+$Domain" }
            
            if (-not $serverNameLine) {
                # Bu bizim aradığımız domain değil, koru
                $newContent += $vhostContent
            }
        } else {
            $newContent += $content[$i]
        }
        $i++
    }
    
    Set-Content -Path $paths.HttpdVhosts -Value $newContent -Encoding UTF8
    
    # hosts dosyasından kaldır
    $hostsContent = Get-Content $paths.HostsFile
    $newHostsContent = $hostsContent | Where-Object { $_ -notmatch "127\.0\.0\.1\s+$Domain" }
    Set-Content -Path $paths.HostsFile -Value $newHostsContent -Encoding ASCII
}

# VirtualHost listesini güncelleme fonksiyonu
function Update-HostList {
    $listView.Items.Clear()
    
    try {
        if (-not (Test-Path $paths.HttpdVhosts)) {
            return
        }
        
        $content = Get-Content $paths.HttpdVhosts
        $i = 0
        
        while ($i -lt $content.Length) {
            if ($content[$i] -match '<VirtualHost \*:80>') {
                $vhostContent = @()
                $i++
                
                # VirtualHost içeriğini oku
                while ($i -lt $content.Length -and $content[$i] -notmatch '</VirtualHost>') {
                    $vhostContent += $content[$i]
                    $i++
                }
                
                # ServerName ve DocumentRoot'u bul
                $serverName = ($vhostContent | Where-Object { $_ -match 'ServerName\s+(.+)' } | Select-Object -First 1)
                $docRoot = ($vhostContent | Where-Object { $_ -match 'DocumentRoot\s+"(.+?)"' } | Select-Object -First 1)
                
                if ($serverName -and $docRoot) {
                    $serverName = [regex]::Match($serverName, 'ServerName\s+(.+)').Groups[1].Value.Trim()
                    $docRoot = [regex]::Match($docRoot, 'DocumentRoot\s+"(.+?)"').Groups[1].Value.Trim()
                    
                    $item = New-Object System.Windows.Forms.ListViewItem($serverName)
                    $item.SubItems.Add($docRoot) | Out-Null
                    $listView.Items.Add($item) | Out-Null
                }
            }
            $i++
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("VirtualHost listesi alınırken hata oluştu: $($_.Exception.Message)", "Hata", "OK", "Error")
    }
}

# İlk listeyi yükle
Update-HostList

# Formu göster
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
