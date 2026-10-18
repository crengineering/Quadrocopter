/* flight_ctrl_lct.c
 *
 * Duenne Wrapper-Schicht fuer das Legacy Code Tool.
 * Das LCT kann keine Structs binden, deshalb hier flache Array-
 * Signaturen. Die Parameter liegen als file-static const vor und
 * muessen mit quad_params.m uebereinstimmen.
 *
 * flight_ctrl.c bleibt unveraendert und ist der Code, der spaeter
 * aufs Target geht.
 */

#include "flight_ctrl_lct.h"

/* ------------------------------------------------------------------ */
/* Parametersatz -- Spiegel von quad_params.m                          */
/* ------------------------------------------------------------------ */

static const ctrl_params_t P = {
    /* Physik */
    1.20f,          /* m     */
    9.81f,          /* g     */
    865.0f,         /* w_max = w_lim: 50-A-Kriterium (SYS2-PWR-001), sp 1600 auf vollem Akku = 8257 rpm, 970 g/Motor; Schubstand Run 5 2026-10-18, evidence 4829A25237BFB7C8; NICHT die Motorgrenze (w_motor_max 1080 rad/s) */

    /* Abtastzeit */
    0.001f,         /* Ts    */

    /* Position horizontal */
    1.44f,          /* ned_xy_kP */
    1.92f,          /* ned_xy_kD */

    /* Position vertikal */
    2.7f,           /* ned_z_kP  */
    2.5f,           /* ned_z_kD  */

    /* Lage */
    { 3.0f, 3.0f, 3.0f },                  /* om_kP       */

    /* Raten */
    { 0.100f, 0.100f, 0.216f },            /* tau_kP      */
    { 0.125f, 0.125f, 0.324f },            /* tau_kI      */
    { 1.3f,   1.3f,   0.08f  },            /* tau_sat_up  */
    { -1.3f, -1.3f,  -0.08f  },            /* tau_sat_low */

    /* Mixer-Inverse, Zeilen-Major - kT 1.162e-5 N/(rad/s)^2 (gemessen, Sekante Schwebepunkt),
     * kQ 1.66e-7 Nm/(rad/s)^2 (SCHAETZUNG, eta 0,70), Schubstand Run 3 2026-10-15, evidence
     * BB9B34CB480DCC42; inv(MIX) aus quad_params.m. Zusammen mit quad_params.m und
     * AurixTricore/src/asw/CtrlReplay.c aendern. */
    {
        2.151462995e+04f, -1.352279176e+05f,  1.352279176e+05f,  1.506024096e+06f,
        2.151462995e+04f, -1.352279176e+05f, -1.352279176e+05f, -1.506024096e+06f,
        2.151462995e+04f,  1.352279176e+05f, -1.352279176e+05f,  1.506024096e+06f,
        2.151462995e+04f,  1.352279176e+05f,  1.352279176e+05f, -1.506024096e+06f
    }
};

/* ------------------------------------------------------------------ */

void pos_ctrl_lct(const real32_T p_ned_soll[3],
                  const real32_T p_ned_ist[3],
                  const real32_T v_b_ist[3],
                  real32_T psi_soll,
                  real32_T T_soll[1],
                  real32_T phi_soll[3])
{
    pos_ctrl_step(p_ned_soll, p_ned_ist, v_b_ist, psi_soll,
                  &T_soll[0], phi_soll, &P);
}

void att_ctrl_lct(const real32_T phi_soll[3],
                  const real32_T phi_ist[3],
                  real32_T om_soll[3])
{
    att_ctrl_step(phi_soll, phi_ist, om_soll, &P);
}

/* Zustandsfrei: Integratorzustand kommt herein und geht heraus.
 * Die Schleife schliesst in Simulink ein Unit Delay. */
void rate_ctrl_lct(const real32_T om_soll[3],
                   const real32_T om_ist[3],
                   const real32_T tau_I_in[3],
                   real32_T tau_soll[3],
                   real32_T tau_I_out[3])
{
    ctrl_state_t st;

    st.tau_I[0] = tau_I_in[0];
    st.tau_I[1] = tau_I_in[1];
    st.tau_I[2] = tau_I_in[2];

    rate_ctrl_step(om_soll, om_ist, tau_soll, &st, &P);

    tau_I_out[0] = st.tau_I[0];
    tau_I_out[1] = st.tau_I[1];
    tau_I_out[2] = st.tau_I[2];
}

void mixer_lct(real32_T T_soll,
               const real32_T tau_soll[3],
               real32_T w_cmd[4])
{
    mixer_step(T_soll, tau_soll, w_cmd, &P);
}
