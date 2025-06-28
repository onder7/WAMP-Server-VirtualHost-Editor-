Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# WAMP Server yapılandırma dosyaları (Apache versiyonunuza göre güncelleyin)
$httpdConf = "C:\wamp64\bin\apache\apache2.4.62.1\conf\httpd.conf"
$httpdVhosts = "C:\wamp64\bin\apache\apache2.4.62.1\conf\extra\httpd-vhosts.conf"
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"

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
    if (-not $txtDomain.Text -or -not $txtFolder.Text) {
        [System.Windows.Forms.MessageBox]::Show("Lütfen tüm alanları doldurun!", "Uyarı", "OK", "Warning")
        return
    }
    
    $domain = $txtDomain.Text
    $projectPath = "C:\wamp64\www\" + $txtFolder.Text
    
    try {
        # Proje dizini oluştur
        if (-not (Test-Path $projectPath)) {
            New-Item -ItemType Directory -Path $projectPath | Out-Null
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
        
        # hosts dosyasına ekleme yap
        Add-Content -Path $hostsFile -Value "127.0.0.1 $domain" -Force
        
        # httpd.conf'da vhosts dosyasının include edildiğinden emin ol
        $includeCheck = Get-Content $httpdConf | Select-String "httpd-vhosts.conf"
        if (-not $includeCheck) {
            Add-Content -Path $httpdConf -Value "Include conf/extra/httpd-vhosts.conf"
        }
        
        [System.Windows.Forms.MessageBox]::Show("VirtualHost başarıyla eklendi!`nWAMP Server'ı yeniden başlatın.", "Başarılı", "OK", "Information")
        $txtDomain.Text = ""
        $txtFolder.Text = ""
        
        # Listeyi güncelle
        Update-HostList
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Hata oluştu: $_`nYönetici olarak çalıştırdığınızdan emin olun.", "Hata", "OK", "Error")
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
$listView.Columns.Add("Dizin", 400) | Out-Null
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
    if ($listView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Lütfen kaldırmak için bir VirtualHost seçin!", "Uyarı", "OK", "Warning")
        return
    }
    
    $selectedDomain = $listView.SelectedItems[0].Text
    
    $result = [System.Windows.Forms.MessageBox]::Show("'$selectedDomain' VirtualHost'unu kaldırmak istediğinize emin misiniz?", "Onay", "YesNo", "Question")
    if ($result -eq "Yes") {
        try {
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
                
                if ($inVhost -and $content[$i] -match "ServerName $selectedDomain") {
                    $serverName = $selectedDomain
                }
                
                if ($inVhost -and $content[$i] -match "</VirtualHost>") {
                    $inVhost = $false
                    if ($serverName -ne $selectedDomain) {
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
                $hostsContent = Get-Content $hostsFile
                $newHostsContent = $hostsContent | Where-Object { $_ -notmatch "127.0.0.1 $selectedDomain" }
                Set-Content -Path $hostsFile -Value $newHostsContent -Force
                
                [System.Windows.Forms.MessageBox]::Show("VirtualHost kaldırıldı!`nWAMP Server'ı yeniden başlatın.", "Başarılı", "OK", "Information")
                Update-HostList
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Hata oluştu: $_`nYönetici olarak çalıştırdığınızdan emin olun.", "Hata", "OK", "Error")
        }
    }
})
$tabList.Controls.Add($btnRemove)

# Durum bilgisi
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Yönetici olarak çalıştırıldı: $([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem)"
$lblStatus.Location = New-Object System.Drawing.Point(20,420)
$lblStatus.Size = New-Object System.Drawing.Size(300,20)
$lblStatus.ForeColor = if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
$tabList.Controls.Add($lblStatus)

# VirtualHost listesini güncelleme fonksiyonu
function Update-HostList {
    $listView.Items.Clear()
    
    try {
        $vhosts = Select-String -Path $httpdVhosts -Pattern "<VirtualHost \*:80>" -Context 0,10
        if ($vhosts) {
            foreach ($vhost in $vhosts) {
                $serverName = ($vhost.Context.PostContext | Select-String "ServerName (\S+)").Matches.Groups[1].Value
                $docRoot = ($vhost.Context.PostContext | Select-String 'DocumentRoot "(.+?)"').Matches.Groups[1].Value
                
                $item = New-Object System.Windows.Forms.ListViewItem($serverName)
                $item.SubItems.Add($docRoot) | Out-Null
                $listView.Items.Add($item)
            }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("VirtualHost listesi alınırken hata oluştu: $_", "Hata", "OK", "Error")
    }
}

# İlk listeyi yükle
Update-HostList

# Formu göster
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
