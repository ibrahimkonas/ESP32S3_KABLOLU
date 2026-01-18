#pragma once
#include <stdint.h>

// Basit durum makinesi tanımı. Gerçek zamanlı kontrol main.c içindeki task’lerde yapılır.

typedef enum {
    SM_BOOT = 0,
    SM_HOME,
    SM_READY,
    SM_MANUAL,
    SM_AUTO_CYCLE1,
    SM_AUTO_CYCLE2,
    SM_FAULT
} sm_state_t;

typedef enum {
    EVT_NONE = 0,
    EVT_RESET,
    EVT_START,
    EVT_STOP,
    EVT_ESTOP,
    EVT_FAULT_HBK,
    EVT_FAULT_VK,
    EVT_FAULT_AP,
    EVT_FAULT_RP,
    EVT_FAULT_X,
    EVT_TARGET_DONE,
} sm_event_t;

typedef struct {
    sm_state_t state;
    sm_event_t last_event;
    uint32_t production_count;
    uint32_t target_count;
    uint32_t fault_code; // 0=none, aksi halde hata id’si
} sm_ctx_t;

void sm_init(sm_ctx_t *ctx);
void sm_apply_event(sm_ctx_t *ctx, sm_event_t evt);
