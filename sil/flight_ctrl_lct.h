/* flight_ctrl_lct.h
 *
 * Deklarationen der Wrapper-Funktionen fuer das Legacy Code Tool.
 */

#ifndef FLIGHT_CTRL_LCT_H
#define FLIGHT_CTRL_LCT_H

#include "flight_ctrl.h"

#ifdef __cplusplus
extern "C" {
#endif

void pos_ctrl_lct(const real32_T p_ned_soll[3],
                  const real32_T p_ned_ist[3],
                  const real32_T v_b_ist[3],
                  real32_T psi_soll,
                  real32_T T_soll[1],
                  real32_T phi_soll[3]);

void att_ctrl_lct(const real32_T phi_soll[3],
                  const real32_T phi_ist[3],
                  real32_T om_soll[3]);

/* Zustandsfrei: der Integratorzustand wird herein- und herausgereicht.
 * In Simulink schliesst ein Unit Delay (Ts, IC = 0) die Schleife von
 * tau_I_out zurueck auf tau_I_in. */
void rate_ctrl_lct(const real32_T om_soll[3],
                   const real32_T om_ist[3],
                   const real32_T tau_I_in[3],
                   real32_T tau_soll[3],
                   real32_T tau_I_out[3]);

void mixer_lct(real32_T T_soll,
               const real32_T tau_soll[3],
               real32_T w_cmd[4]);

#ifdef __cplusplus
}
#endif

#endif /* FLIGHT_CTRL_LCT_H */
