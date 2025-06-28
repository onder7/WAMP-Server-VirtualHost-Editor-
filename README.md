
## Windows'ta C:\wamp64\ dizininde kurulu WAMP Server için VirtualHost oluşturmayı ve yönetmeyi kolaylaştıran bir PowerShell scripti

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
