# OTA (Over-The-Air) Güncelleme Özeti

- Amaç: Firmware’ı uzaktan, fiziksel erişim olmadan güncellemek.
- Güvenlik: İmzalı paket, HTTPS ile indirme, mümkünse mTLS. Secure Boot + Flash Encryption açık olduğunda sahte firmware çalıştırılması zorlaşır.
- A/B bank: İki uygulama bölümü (ota_0, ota_1). Yeni paket yan bank’a yazılır, boot flag oraya alınır. Başarısız boot’ta rollback yapılır.
- Akış (öneri):
  1) Sunucuya imzalı `.bin` ve SHA-256 hash koyulur.
  2) Cihaz API’si `/ota/start` ile hedef URL ve imza bilgisi alır.
  3) ESP32-S3 HTTPS üzerinden indirir, hash + imza doğrular, yan bank’a yazar.
  4) Reboot, yeni bank açılır. Boot sonrası kendini sağlıklı bildirirse flag kalıcı olur; aksi halde eski bank’a döner.
- İmza: RSA/ECDSA; imza doğrulamasını firmware içinde yapın. IDF’in `esp_https_ota` + kendi imza kontrolünüz önerilir.
- Sertifikalar: Sunucu cert’i veya CA pin’lenmeli; istemci cert’i (mTLS) ile kimlik doğrulama yapılmalı.
