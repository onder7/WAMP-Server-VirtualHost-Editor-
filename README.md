
## Windows'ta C:\wamp64\ dizininde kurulu WAMP Server için VirtualHost oluşturmayı ve yönetmeyi kolaylaştıran bir PowerShell scripti


## WampVHostGUI Version

![image](https://github.com/user-attachments/assets/ddc907fa-e8fb-4ff2-bf84-476a8fcf3ec7)

![image](https://github.com/user-attachments/assets/f0c802ee-6c6a-4033-ac0a-1cbb0540cf26)

## Kullanım Talimatları
Bu kodu bir .ps1 dosyasına kaydedin (örneğin WampVHostGUI.ps1)

PowerShell'i yönetici olarak çalıştırın (hosts dosyasını değiştirmek için gerekli)

Scripti çalıştırın: .\WampVHostGUI.ps1

## GUI Özellikleri
Yeni VirtualHost Ekleme Sekmesi:

Domain adı ve proje klasörü girebileceğiniz form

Tek butonla tüm yapılandırmaları otomatik yapar

www dizini içinde otomatik klasör oluşturur

## VirtualHost Listesi Sekmesi:

Mevcut tüm VirtualHost'ları tablo şeklinde gösterir

Seçili VirtualHost'u kaldırma imkanı

Listeyi yenileme butonu

## Yönetici Durum Göstergesi:

Scriptin yönetici yetkileriyle çalışıp çalışmadığını gösterir

## Önemli Notlar
Apache versiyonunuza göre $httpdConf ve $httpdVhosts yollarını güncellemelisiniz.

Scriptin düzgün çalışması için PowerShell Execution Policy ayarlarını kontrol edin:

powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
WAMP Server'da her değişiklikten sonra servisi yeniden başlatmayı unutmayın.

Bu GUI arayüzü, komut satırı versiyonuna göre çok daha kullanıcı dostu ve hatasız bir deneyim sunacaktır.

## ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


![image](https://github.com/user-attachments/assets/dbef477d-6bf1-4f04-ae67-e5d35226b4d4)

![image](https://github.com/user-attachments/assets/52a08282-ffe7-4a79-aa2f-8b3cfaccc16d)


# Kullanım Talimatları
Bu scripti bir .ps1 dosyası olarak kaydedin (örneğin WampVirtualHost.ps1)

PowerShell'i yönetici olarak çalıştırın (hosts dosyasını değiştirmek için gerekli)

Scripti çalıştırın: .\WampVirtualHost.ps1

# Özellikler
Yeni VirtualHost Ekleme:

Domain adı ve proje klasörü belirterek yeni VirtualHost oluşturur

Gerekli tüm yapılandırma dosyalarını (httpd-vhosts.conf, hosts) otomatik günceller

Proje dizinini otomatik oluşturur

# VirtualHost Listeleme:

Mevcut tüm VirtualHost'ları ve ilgili dizinleri listeler

# VirtualHost Kaldırma:

Belirtilen domain'e ait VirtualHost'u ve hosts kaydını kaldırır

# Notlar
Script WAMP Server 3.2.0 (Apache 2.4.46) için test edilmiştir.

Farklı WAMP/Apache versiyonlarında $httpdConf ve $httpdVhosts yollarını güncellemeniz gerekebilir.

Scriptin çalışması için PowerShell Execution Policy'nin RemoteSigned veya Unrestricted olması gerekebilir.


# Olası Sorunlar:

cannot be loaded because running scripts is disabled on this 
system. For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
    + CategoryInfo          : SecurityError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : UnauthorizedAccess
Bu hata PowerShell'in güvenlik politikası nedeniyle oluşuyor. İşte çözüm yolları:

## Çözüm 1: Execution Policy'yi Geçici Olarak Değiştir

**PowerShell'i yönetici olarak aç** ve şu komutu çalıştır:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Sonra scriptini çalıştır:
```powershell
D:\py\host\VirtualHost\WampVirtualHost.ps1
```

## Çözüm 2: Tek Seferlik Bypass (Önerilen)

PowerShell'i yönetici olarak açıp şu komutla çalıştır:

```powershell
powershell -ExecutionPolicy Bypass -File "D:\py\host\VirtualHost\WampVirtualHost.ps1"
```

## Çözüm 3: Mevcut Durumu Kontrol Et

Önce mevcut policy'yi kontrol et:
```powershell
Get-ExecutionPolicy -List
```

## Çözüm 4: Sadece Bu Script İçin İzin Ver

Script dosyasının engelini kaldır:
```powershell
Unblock-File -Path "D:\py\host\VirtualHost\WampVirtualHost.ps1"
```

## Güvenlik Seviyeleri:

- **Restricted**: Hiçbir script çalışmaz (varsayılan)
- **RemoteSigned**: Yerel scriptler çalışır, uzaktan indirilenler imzalı olmalı
- **Unrestricted**: Tüm scriptler çalışır (önerilmez)

## En Güvenli Yöntem:

1. **PowerShell ISE** veya **Visual Studio Code** kullan
2. Script içeriğini kopyala-yapıştır
3. F5 ile çalıştır

## Kalıcı Çözüm (Dikkatli Kullan):

```powershell
# Sadece mevcut kullanıcı için
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Tüm sistem için (önerilmez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

**Not:** Güvenlik nedeniyle **Çözüm 2** (Bypass) veya **Çözüm 4** (Unblock) öneriliyor. Bu şekilde sistem geneli güvenlik ayarlarını değiştirmeden sadece bu script çalışabilir.





