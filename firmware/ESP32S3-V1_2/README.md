# ESP32-S3 Firmware Skeleton (ESP32S3-V1_2)

Bu klasör, önceki `firmware/esp32s3` iskeletinin aynı içeriğini yeni isimle barındırır. ESP-IDF tabanlıdır ve serigrafi makinesi için FreeRTOS görevleri, durum makinesi ve IO haritası şablonu içerir.

## Derleme
```
cd firmware/ESP32S3-V1_2
idf.py set-target esp32s3
idf.py build
idf.py -p COM5 flash monitor
```

## Not
- IO pinlerini `main/io_map.h` içinde kendi donanımınıza göre güncelleyin.
- Secure Boot + Flash Encryption ve mTLS/OTA henüz eklenmedi; menuconfig ve ek bileşenlerle açılabilir.
