#include <stdio.h>
#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "nvs_flash.h"
#include "state_machine.h"
#include "io_map.h"

// Basit iskelet: IO ayarı, durum makinesi ve görev stub’ları.

#define AP_TIMEOUT_MS 1500
#define RP_TIMEOUT_MS 1500
#define X_TIMEOUT_MS  1500
#define POLL_DELAY_MS 10

static sm_ctx_t g_sm;

static void configure_gpio_inputs(void) {
    // Aktif-low girişler için pull-up, aktif-high fault girişleri (hb/vk) için pull-down.
    const int inputs_pullup[] = {
        IO_MAP.estop, IO_MAP.start_btn, IO_MAP.reset_btn, IO_MAP.mode_auto,
        IO_MAP.stop_btn, IO_MAP.aps_down, IO_MAP.aps_up, IO_MAP.rps_down,
        IO_MAP.rps_up, IO_MAP.xl_limit, IO_MAP.xr_limit, IO_MAP.rxs1,
        IO_MAP.rxs2, IO_MAP.ubs};
    const int inputs_pulldown[] = {IO_MAP.hb_switch, IO_MAP.vk_switch};

    gpio_config_t cfg = {
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    for (size_t i = 0; i < sizeof(inputs_pullup) / sizeof(inputs_pullup[0]); i++) {
        cfg.pin_bit_mask = 1ULL << inputs_pullup[i];
        gpio_config(&cfg);
    }

    cfg.pull_up_en = GPIO_PULLUP_DISABLE;
    cfg.pull_down_en = GPIO_PULLDOWN_ENABLE;
    for (size_t i = 0; i < sizeof(inputs_pulldown) / sizeof(inputs_pulldown[0]); i++) {
        cfg.pin_bit_mask = 1ULL << inputs_pulldown[i];
        gpio_config(&cfg);
    }
}

static void configure_gpio_outputs(void) {
    const int outputs[] = {
        IO_MAP.solenoid_ap_down, IO_MAP.solenoid_ap_up, IO_MAP.solenoid_rp_down,
        IO_MAP.solenoid_rp_up, IO_MAP.x_step, IO_MAP.x_dir, IO_MAP.x_en,
        IO_MAP.transfer_out, IO_MAP.buzzer};
    gpio_config_t cfg = {
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    for (size_t i = 0; i < sizeof(outputs) / sizeof(outputs[0]); i++) {
        cfg.pin_bit_mask = 1ULL << outputs[i];
        gpio_config(&cfg);
        gpio_set_level(outputs[i], 0);
    }
}

static void safety_task(void *arg) {
    while (1) {
        // hb/vk aktif-high fault: 3.3V = fault, GND = OK
        const bool hb_fault = gpio_get_level(IO_MAP.hb_switch) == 1;
        const bool vk_fault = gpio_get_level(IO_MAP.vk_switch) == 1;
        const bool estop = gpio_get_level(IO_MAP.estop) == 1;

        if (hb_fault) {
            sm_apply_event(&g_sm, EVT_FAULT_HBK);
        } else if (vk_fault) {
            sm_apply_event(&g_sm, EVT_FAULT_VK);
        } else if (estop) {
            sm_apply_event(&g_sm, EVT_ESTOP);
        }
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}

static bool wait_levels(int pin_down, int expect_down, int pin_up, int expect_up, int timeout_ms) {
    const TickType_t deadline = xTaskGetTickCount() + pdMS_TO_TICKS(timeout_ms);
    while (xTaskGetTickCount() < deadline) {
        const int d = gpio_get_level(pin_down);
        const int u = gpio_get_level(pin_up);
        if (d == expect_down && u == expect_up) {
            return true;
        }
        vTaskDelay(pdMS_TO_TICKS(POLL_DELAY_MS));
    }
    return false;
}

// Start verildiğinde pistonları yukarı al ve limit değişimlerini doğrula.
static bool ensure_ana_piston_up(void) {
    gpio_set_level(IO_MAP.solenoid_ap_down, 0);
    gpio_set_level(IO_MAP.solenoid_ap_up, 1);

    // Beklenen: aşağı switch NO->NC (1'den 0'a), yukarı switch NC->NO (0'dan 1'e)
    const bool ok = wait_levels(IO_MAP.aps_down, 0, IO_MAP.aps_up, 1, AP_TIMEOUT_MS);

    gpio_set_level(IO_MAP.solenoid_ap_up, 0); // işi bitince bırak
    return ok;
}

static bool ensure_ragle_piston_up(void) {
    gpio_set_level(IO_MAP.solenoid_rp_down, 0);
    gpio_set_level(IO_MAP.solenoid_rp_up, 1);

    const bool ok = wait_levels(IO_MAP.rps_down, 0, IO_MAP.rps_up, 1, RP_TIMEOUT_MS);

    gpio_set_level(IO_MAP.solenoid_rp_up, 0);
    return ok;
}

// X ekseni limitleri de NC->NO geçiş mantığında; start öncesi limitler kapalı (NC=0) olmalı.
static bool check_x_limits_idle(void) {
    const TickType_t deadline = xTaskGetTickCount() + pdMS_TO_TICKS(X_TIMEOUT_MS);
    while (xTaskGetTickCount() < deadline) {
        const int xl = gpio_get_level(IO_MAP.xl_limit);
        const int xr = gpio_get_level(IO_MAP.xr_limit);
        if (xl == 0 && xr == 0) {
            return true; // ikisi de NC (kapalı) durumda
        }
        vTaskDelay(pdMS_TO_TICKS(POLL_DELAY_MS));
    }
    return false;
}

static void motion_task(void *arg) {
    while (1) {
        // Manuel buton taraması
        if (gpio_get_level(IO_MAP.reset_btn) == 0) {
            sm_apply_event(&g_sm, EVT_RESET);
        }
        if (gpio_get_level(IO_MAP.stop_btn) == 0) {
            sm_apply_event(&g_sm, EVT_STOP);
        }

        switch (g_sm.state) {
        case SM_HOME:
            // TODO: home prosedürü (sol limit arama, pistonları yukarı kaldırma)
            sm_apply_event(&g_sm, EVT_RESET);
            break;
        case SM_READY:
            // Start butonuna basılırsa önce pistonların yukarı kalktığını sensörle doğrula
            if (gpio_get_level(IO_MAP.start_btn) == 0) {
                const bool ap_ok = ensure_ana_piston_up();
                if (!ap_ok) {
                    sm_apply_event(&g_sm, EVT_FAULT_AP);
                    break;
                }
                const bool rp_ok = ensure_ragle_piston_up();
                if (!rp_ok) {
                    sm_apply_event(&g_sm, EVT_FAULT_RP);
                    break;
                }
                const bool x_ok = check_x_limits_idle();
                if (!x_ok) {
                    sm_apply_event(&g_sm, EVT_FAULT_X);
                    break;
                }
                sm_apply_event(&g_sm, EVT_START);
            }
            vTaskDelay(pdMS_TO_TICKS(20));
            break;
        case SM_AUTO_CYCLE1:
            // TODO: 1. döngü adımları (piston aşağı, ragle aşağı, x eksen sağa, piston yukarı, band hareketi, ragle yukarı, ek 20mm)
            sm_apply_event(&g_sm, EVT_NONE);
            vTaskDelay(pdMS_TO_TICKS(10));
            break;
        case SM_AUTO_CYCLE2:
            // TODO: 2. döngü adımları (ters yön)
            sm_apply_event(&g_sm, EVT_NONE);
            vTaskDelay(pdMS_TO_TICKS(10));
            break;
        case SM_MANUAL:
        case SM_FAULT:
        default:
            vTaskDelay(pdMS_TO_TICKS(50));
            break;
        }
    }
}

static void telemetry_task(void *arg) {
    while (1) {
        // TODO: Telemetri anlık değerleri hazırla, API veya UART üzerinden yayınla
        vTaskDelay(pdMS_TO_TICKS(200));
    }
}

static void api_task(void *arg) {
    while (1) {
        // TODO: HTTPS + mTLS endpoint’leri; /telemetry, /params, /ota/start, /logs
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

void app_main(void) {
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ESP_ERROR_CHECK(nvs_flash_init());
    }

    configure_gpio_inputs();
    configure_gpio_outputs();
    sm_init(&g_sm);

    xTaskCreatePinnedToCore(safety_task, "safety", 4096, NULL, 10, NULL, 0);
    xTaskCreatePinnedToCore(motion_task, "motion", 4096, NULL, 9, NULL, 1);
    xTaskCreate(telemetry_task, "telemetry", 4096, NULL, 5, NULL);
    xTaskCreate(api_task, "api", 4096, NULL, 4, NULL);
}
