#include "state_machine.h"

static void set_fault(sm_ctx_t *ctx, sm_event_t evt, uint32_t code) {
    ctx->state = SM_FAULT;
    ctx->last_event = evt;
    ctx->fault_code = code;
}

void sm_init(sm_ctx_t *ctx) {
    if (!ctx) return;
    ctx->state = SM_HOME;
    ctx->last_event = EVT_NONE;
    ctx->production_count = 0;
    ctx->target_count = 0;
    ctx->fault_code = 0;
}

void sm_apply_event(sm_ctx_t *ctx, sm_event_t evt) {
    if (!ctx) return;
    ctx->last_event = evt;

    switch (ctx->state) {
    case SM_HOME:
        if (evt == EVT_FAULT_HBK || evt == EVT_FAULT_VK) {
            set_fault(ctx, evt, evt);
        } else if (evt == EVT_RESET || evt == EVT_START) {
            ctx->state = SM_READY;
        }
        break;
    case SM_READY:
        if (evt == EVT_FAULT_HBK || evt == EVT_FAULT_VK) {
            set_fault(ctx, evt, evt);
        } else if (evt == EVT_START) {
            ctx->state = SM_AUTO_CYCLE1;
        } else if (evt == EVT_STOP) {
            ctx->state = SM_READY;
        }
        break;
    case SM_MANUAL:
        if (evt == EVT_FAULT_HBK || evt == EVT_FAULT_VK) {
            set_fault(ctx, evt, evt);
        } else if (evt == EVT_STOP) {
            ctx->state = SM_READY;
        }
        break;
    case SM_AUTO_CYCLE1:
        if (evt == EVT_FAULT_HBK || evt == EVT_FAULT_VK || evt == EVT_FAULT_AP || evt == EVT_FAULT_RP || evt == EVT_FAULT_X) {
            set_fault(ctx, evt, evt);
        } else if (evt == EVT_STOP) {
            ctx->state = SM_READY;
        } else {
            // Döngü 1 tamamlandı varsayımıyla
            ctx->state = SM_AUTO_CYCLE2;
        }
        break;
    case SM_AUTO_CYCLE2:
        if (evt == EVT_FAULT_HBK || evt == EVT_FAULT_VK || evt == EVT_FAULT_AP || evt == EVT_FAULT_RP || evt == EVT_FAULT_X) {
            set_fault(ctx, evt, evt);
        } else if (evt == EVT_STOP) {
            ctx->state = SM_READY;
        } else {
            ctx->production_count++;
            if (ctx->target_count > 0 && ctx->production_count >= ctx->target_count) {
                set_fault(ctx, EVT_TARGET_DONE, EVT_TARGET_DONE);
            } else {
                ctx->state = SM_AUTO_CYCLE1;
            }
        }
        break;
    case SM_FAULT:
        if (evt == EVT_RESET) {
            ctx->fault_code = 0;
            ctx->state = SM_READY;
        }
        break;
    case SM_BOOT:
    default:
        ctx->state = SM_HOME;
        break;
    }
}
