function [sweep, truth, stepResponse] = synth_motor_sweep(varargin)
%SYNTH_MOTOR_SWEEP  Generate a synthetic bench thrust-rig sweep with known
%   ground-truth kT/kQ/tau, for validating FIT_MOTOR_COEFFS against a
%   planted answer before any real bench data exists (SWR-MDL-003,
%   dispatch/R-012.md §8 acceptance: "script runs on a synthetic sweep").
%
%   [sweep, truth, stepResponse] = SYNTH_MOTOR_SWEEP(...) returns:
%     sweep        : table with columns throttle, erpm, thrust_g, vbat_V,
%                    esc_I_A -- the same shape FIT_MOTOR_COEFFS expects.
%     truth        : struct with the planted kT, kQ, tau, w_max, KV,
%                    PolePairs used to generate it.
%     stepResponse : Nx2 [t, erpm] synthetic first-order throttle-step
%                    transient with the planted tau.
%
%   NAME-VALUE ARGS (defaults span the datasheet-corroborated range for the
%   decided drive -- SunnySky X2216-III V3 KV880 / HQProp 10x4.5, see
%   procurement/datasheets/motor-sunnysky-x2216-iii-v3-880kv.md):
%     'kT'         (default 1.5e-5)  N/(rad/s)^2, planted thrust coefficient
%     'kQ'         (default 1.5e-7)  Nm/(rad/s)^2, planted torque coefficient
%     'KV'         (default 880)     rpm/V
%     'PolePairs'  (default 7)
%     'Vbat'       (default 16.0)    V, nominal pack voltage during the sweep
%     'NSteps'     (default 10)
%     'ThrottleMax' (default 0.95)   fraction of full throttle for the top step
%     'tau'        (default 0.05)    s, planted motor+ESC time constant
%     'NoiseSeed'  (default 1)       RNG seed, for repeatable test runs
%     'ThrustNoise_g' (default 0.1)  digital-scale resolution (1 sigma), g
%     'CurrentNoise_A' (default 0.05) ESC current sense noise, 1 sigma, A
%     'ErpmNoise_frac' (default 0.003) eRPM measurement noise, fraction, 1 sigma
%     'InjectNaNRow'  (default false) inject one row with a NaN channel, to
%                     exercise the NaN guard
%     'InjectNonmonotonic' (default false) corrupt one row to break thrust
%                     monotonicity, to exercise the sanity check
%
%   Model: T = kT*omega^2, Q = kQ*omega^2 shaft torque, electrical current
%   I = Q/Kt + I0 with Kt = 9.55/KV [Nm/A] and a small no-load current I0,
%   consistent with the same relation FIT_MOTOR_COEFFS uses for kQ. No-load
%   rpm bound omega_noload = KV*Vbat*2*pi/60; loaded omega at each throttle
%   step is a fraction of that, capped by ThrottleMax at the top step.
%
%   See also FIT_MOTOR_COEFFS, TEST_FIT_MOTOR_COEFFS.

p = inputParser;
p.addParameter('kT', 1.5e-5);
p.addParameter('kQ', 1.5e-7);
p.addParameter('KV', 880);
p.addParameter('PolePairs', 7);
p.addParameter('Vbat', 16.0);
p.addParameter('NSteps', 10);
p.addParameter('ThrottleMax', 0.95);
p.addParameter('tau', 0.05);
p.addParameter('NoiseSeed', 1);
p.addParameter('ThrustNoise_g', 0.1);
p.addParameter('CurrentNoise_A', 0.05);
p.addParameter('ErpmNoise_frac', 0.003);
p.addParameter('InjectNaNRow', false);
p.addParameter('InjectNonmonotonic', false);
p.parse(varargin{:});
o = p.Results;

rng(o.NoiseSeed);
g = 9.81;
Kt = 9.55 / o.KV;
I0 = 0.5 * sqrt(o.Vbat/10); % no-load current scales roughly with sqrt(V), datasheet gives 0.5 A @ 10 V

omega_noload = o.KV * o.Vbat * 2*pi/60;
throttle = linspace(0.15, o.ThrottleMax, o.NSteps)';
% Loaded omega rises less than proportionally with throttle near the top
% (current-limited); a simple concave map is enough for a synthetic sweep.
omega_true = omega_noload * (throttle.^0.9) * 0.62; % scale factor lands the
                                                     % top step in a plausible
                                                     % loaded-vs-no-load ratio

erpm_true   = omega_true * 60*o.PolePairs / (2*pi);
thrust_true = o.kT * omega_true.^2;              % N
Q_true      = o.kQ * omega_true.^2;              % Nm
I_true      = Q_true/Kt + I0;                    % A

n = o.NSteps;
sweep = table;
sweep.throttle = throttle;
sweep.erpm     = erpm_true .* (1 + o.ErpmNoise_frac*randn(n,1));
sweep.thrust_g = (thrust_true/g*1000) + o.ThrustNoise_g*randn(n,1);
sweep.vbat_V   = o.Vbat - 0.15*throttle + 0.02*randn(n,1); % sag under load
sweep.esc_I_A  = I_true + o.CurrentNoise_A*randn(n,1);

if o.InjectNaNRow
    sweep.thrust_g(3) = NaN;
end
if o.InjectNonmonotonic
    sweep.thrust_g(end-1) = sweep.thrust_g(end-1) * 1.6; % implausible spike
end

truth = struct('kT', o.kT, 'kQ', o.kQ, 'tau', o.tau, 'KV', o.KV, ...
               'PolePairs', o.PolePairs, 'w_max', max(omega_true), ...
               'Kt', Kt, 'I0', I0);

% ---- synthetic step response for the tau fit ---------------------------
% Convention: t = 0 is the moment of the throttle step; row 1 (t=0) is the
% pre-step steady-state value, and erpm relaxes first-order toward the new
% steady state from there -- matches what FIT_MOTOR_COEFFS assumes (y(1) is
% the pre-step baseline, the last samples are the new steady state).
t = (0:0.002:0.5)';
omega_ss_before = omega_true(round(n/2));
omega_ss_after  = omega_true(end);
erpm0 = omega_ss_before * 60*o.PolePairs/(2*pi);
erpmf = omega_ss_after  * 60*o.PolePairs/(2*pi);
erpm_step = erpm0 + (erpmf-erpm0) * (1 - exp(-t/o.tau));
erpm_step = erpm_step + o.ErpmNoise_frac*erpmf*randn(size(t));
stepResponse = [t, erpm_step];

end
