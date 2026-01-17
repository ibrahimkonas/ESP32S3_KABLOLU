#pragma once

// IO pin ve rollerini tek noktadan tanımlamak için basit header.
// Gerektikçe genişletebilirsiniz; üretim için optokuplör/izolasyon şart.

typedef struct {
    int hb_switch;   // Hava basınç switch (aktif-high fault: 3.3V = fault, GND = OK)
    int vk_switch;   // Vakum switch (aktif-high fault: 3.3V = fault, GND = OK)
    int estop;       // Acil stop (dijital, aktif = kesik)
    int start_btn;   // Start buton (dijital)
    int reset_btn;   // Reset buton (dijital)
    int mode_auto;   // Otomatik mod seçici (dijital, 1=auto)
    int stop_btn;    // Yazılımsal stop (dijital)

    int aps_down;    // Ana piston aşağı konum sensörü
    int aps_up;      // Ana piston yukarı konum sensörü
    int rps_down;    // Ragle piston aşağı konum sensörü
    int rps_up;      // Ragle piston yukarı konum sensörü
    int xl_limit;    // X sol limit
    int xr_limit;    // X sağ limit
    int rxs1;        // Ragle X konum sensörü 1
    int rxs2;        // Ragle X konum sensörü 2
    int ubs;         // Ürün bandı sensörü

    int solenoid_ap_down; // Ana piston aşağı sürüş çıkışı
    int solenoid_ap_up;   // Ana piston yukarı sürüş çıkışı
    int solenoid_rp_down; // Ragle piston aşağı sürüş çıkışı
    int solenoid_rp_up;   // Ragle piston yukarı sürüş çıkışı

    int x_step;  // TB6600 step
    int x_dir;   // TB6600 dir
    int x_en;    // TB6600 enable

    int transfer_out; // Transfer bandı sürücü tetik çıkışı
    int buzzer;       // Opsiyonel uyarı
} io_map_t;

static const io_map_t IO_MAP = {
    .hb_switch = 4,
    .vk_switch = 5,
    .estop = 6,
    .start_btn = 7,
    .reset_btn = 8,
    .mode_auto = 9,
    .stop_btn = 10,
    .aps_down = 11,
    .aps_up = 12,
    .rps_down = 13,
    .rps_up = 14,
    .xl_limit = 15,
    .xr_limit = 16,
    .rxs1 = 17,
    .rxs2 = 18,
    .ubs = 19,
    .solenoid_ap_down = 20,
    .solenoid_ap_up = 21,
    .solenoid_rp_down = 47,
    .solenoid_rp_up = 48,
    .x_step = 38,
    .x_dir = 39,
    .x_en = 40,
    .transfer_out = 41,
    .buzzer = 42,
};
