# Raspberry Pi Endüstriyel Bağlantı Rehberi

Bu not, sahada saklayabileceğiniz kısa bir rehberdir. Odak: güvenli ve doğru seviyelenmiş bağlantılar.

## Hızlı Özet
- Minimum öneri: Raspberry Pi 4 (2GB/4GB); Pi 3B+ çalışır ama uzun süreli stabilite için 4 tercih edin. Pi 5 varsa daha yüksek kripto/I-O performansı.
- GPIO 3.3V toleranslıdır; 5V/12V/24V doğrudan bağlanmaz. İzolasyon/level-shift şart.
- Endüstriyel sinyaller için HAT/dönüştürücü: optokuplörlü dijital giriş, röle çıkış, RS-485/RS-232 adaptör, ADC (4-20mA/0-10V için), CAN vb.
- Güç: kararlı 5V (Pi 4 için 3A, Pi 5 için 5V/5A PD), tercihen izolasyonlu buck ve UPS HAT.
- Ağ/güvenlik: SSH anahtar tabanlı, mümkünse VPN/tunnel; yalnızca gereken outbound portları açık.

## Bağlantı Tipleri ve Örnekler
### Dijital I/O (buton, sınır anahtarı, röle tetikleme)
- Seviye: Pi GPIO 3.3V. Endüstriyel 12/24V girişler için optokuplörlü kart kullanın.
- Çıkış (yük sürme): Röle veya SSR kartı; bobinler/indüktif yüklerde diyot veya snubber ekleyin.
- Basit şema (izole kart ile):
  - Saha giriş sinyali (+24V) → optokuplörlü giriş kartı → 3.3V GPIO.
  - Pi GPIO çıkışı → SSR/röle kartı (3.3V uyumlu) → saha yükü.
- Python örneği (libgpiod):
```python
import gpiod
import time
chip = gpiod.Chip('gpiochip0')
out = chip.get_line(17)  # BCM17
out.request(consumer='out', type=gpiod.LINE_REQ_DIR_OUT, default_vals=[0])
for _ in range(3):
    out.set_value(1)
    time.sleep(1)
    out.set_value(0)
    time.sleep(1)
```

### Analog Sensör (4-20mA, 0-10V)
- Pi'de yerleşik ADC yok. Örnek ADC: ADS1115 (I2C, 16 bit), MCP3008 (SPI, 10 bit).
- 4-20mA: shunt (ör. 120Ω) ile 0.48–2.4V; gerekirse op-amp/izolasyon. 0-10V için bölücü + izolasyon.
- Python ADS1115 okuma (Adafruit ADS1x15):
```python
from adafruit_ads1x15.analog_in import AnalogIn
from adafruit_ads1x15.ads1115 import ADS1115
import board, busio

i2c = busio.I2C(board.SCL, board.SDA)
ads = ADS1115(i2c)
chan = AnalogIn(ads, ADS1115.P0)
print(chan.voltage)
```

### Seri Haberleşme
- RS-485/Modbus RTU: USB-RS485 dönüştürücü veya RS-485 HAT.
- RS-232: USB-RS232 dönüştürücü; TTL pinlerini doğrudan saha cihazına vermeyin.
- Örnek Modbus RTU (pymodbus):
```python
from pymodbus.client import ModbusSerialClient
client = ModbusSerialClient(method="rtu", port="/dev/ttyUSB0", baudrate=9600, parity='N', stopbits=1, bytesize=8, timeout=1)
if client.connect():
    rr = client.read_holding_registers(0, 2, unit=1)
    print(rr.registers)
    client.close()
```

### Fieldbus / Diğer
- CAN: MCP2515 tabanlı HAT veya Pi 4/5'in yerleşik CAN PHY'sini etkinleştirme (varsa) + uygun transceiver.
- Ethernet/TCP protokolleri: Modbus TCP, OPC-UA; ağ izolasyonu ve VLAN/ACL tercih edin.
- Kamera: CSI modülü veya USB kamera; EMI için görece kısa ve korumalı kablo kullanın.

## Güç ve Korumalar
- Besleme: 24V saha → izolasyonlu buck → 5V Pi. Pi 4: 5V/3A; Pi 5: 5V/5A PD adaptör.
- UPS: Ani kesinti için UPS HAT veya harici mini-UPS.
- Koruma: TVS diyot, sigorta, doğru topraklama. Uzun kabloda ferit halka ve ekranlı kablo.

## Güvenlik (Saha + Ağ)
- GPIO koruma: Optik izolasyon, seviye dönüştürücü; 5V/12V/24V doğrudan vermeyin.
- SSH: parola kapalı, anahtar tabanlı giriş; mümkünse yalnızca VPN/tunnel içinden erişim.
- Firewall: ufw/iptables ile inbound kapalı tut; gereken outbound portlarını aç.
- Güncellemeler: otomatik güvenlik güncellemesi (unattended-upgrades) ve düzenli restart planı.
- Disk: Güvenli boot/immutable imaj (imzalı imaj), gerekiyorsa tam disk şifreleme (Pi 4/5).

## Fiziksel Kurulum
- Muhafaza: DIN raylı kutu veya metal/pasif soğutmalı kasa; 7/24 için soğutma gerekli.
- Kablo yönetimi: ekranlı kablo, kısa topraklama yolu, gürültülü kablodan ayrım.
- Depolama: USB SSD tercihi; SD kartta A2 sınıfı, yedek imaj.

## Parça Örneği (tipik senaryo)
- Raspberry Pi 4 (4GB) + soğutma + kaliteli 5V/3A adaptör.
- Optokuplörlü dijital giriş kartı (24V→3.3V, izolasyonlu, DIN ray).
- 4-8 kanal SSR/röle kartı (3.3V uyumlu, snubber/diyotlu).
- RS-485 HAT veya USB-RS485 dönüştürücü.
- ADS1115 ADC modülü + shunt/bölücü + opsiyonel izolasyon.
- İzolasyonlu buck (24V→5V), sigorta + TVS.
- DIN ray kutu, terminal blok, ekranlı kablo, ferit halka.

## Adım Adım Başlangıç
1) Saha sinyallerini listeleyin: dijital/analog/seri, gerilim/akım, akış yönü.
2) Uygun dönüştürücü/HAT seçin (RS-485, ADC, optokuplörlü giriş, röle/SSR).
3) Besleme ve izolasyon şemasını çizin (24V→buck→5V Pi, UPS var mı?).
4) Pano yerleşimi ve topraklama/kablo rotasını planlayın.
5) Protokolü netleştirin (Modbus RTU/TCP, OPC-UA); sürücü/kütüphaneyi seçin.
6) Test: önce boşta güç, sonra tek kanal dijital giriş/çıkış testi, ardından analog/seri.
7) Ağ/güvenlik: SSH anahtar, firewall, güncelleme ayarı, gerekirse VPN.

## Ek Notlar
- 3.3V GPIO threshold: lojik 1 genelde >2.0V; 5V sinyal doğrudan bağlanmaz.
- Ortak GND gerekebilir; izolasyon kullanılan noktada saha ve Pi topraklarını ayırın.
- Endüktif yüklerde (röle, motor, vana) diyot/snubber şart; aksi halde GPIO/HAT zarar görebilir.
- EMI sahada yüksekse optik izolasyon ve kısa, ekranlı kablo büyük fark yaratır.

Bu dosyayı gerektiğinde güncelleyebilir ve sahada referans olarak kullanabilirsiniz.
