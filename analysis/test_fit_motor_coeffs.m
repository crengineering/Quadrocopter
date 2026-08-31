function results = test_fit_motor_coeffs
%TEST_FIT_MOTOR_COEFFS  Validate FIT_MOTOR_COEFFS against a synthetic sweep
%   with a planted, known answer (SWE1-MDL-003 unit-level verification;
%   dispatch/SYS1-012.md §8 acceptance for this task: "script runs on a
%   synthetic sweep"). No bench data exists yet -- this is the only
%   evidence available before SYS2-ACT-001 unblocks the real rig.
%
%   Follows the run_all_tests.m PASS/FAIL/SKIP pattern used in tests/.

here = fileparts(mfilename('fullpath'));
addpath(here);

cases = { @case_nominal_recovery,        'C1  Nominal recovery (clean-ish sweep)'
          @case_low_noise_tight_tol,     'C2  Recovery within 2%% at realistic noise'
          @case_nan_guard,               'C3  NaN row guarded and counted, not silently dropped'
          @case_too_few_steps,           'C4  <8 valid steps -> rejected'
          @case_nonmonotonic_rejected,   'C5  Non-monotonic thrust -> rejected'
          @case_tau_recovery,            'C6  tau recovered from step response'
          @case_model_mismatch_rejected, 'C7  Wrong power law (omega^2.3) -> rejected by residual, not just R2' };

n = size(cases,1);
status = strings(n,1);
msg    = strings(n,1);

fprintf('\n=== fit_motor_coeffs -- synthetic-sweep validation ===\n\n');
for k = 1:n
    name = cases{k,2};
    try
        cases{k,1}();
        status(k) = "PASS";
        fprintf('  [PASS]  %s\n', name);
    catch e
        status(k) = "FAIL";
        msg(k) = string(e.message);
        fprintf('  [FAIL]  %s   ->  %s\n', name, e.message);
    end
end

nP = sum(status=="PASS"); nF = sum(status=="FAIL");
fprintf('\n--------------------------------------------------\n');
fprintf('  Bestanden: %d/%d    Fehlgeschlagen: %d\n', nP, n, nF);
fprintf('--------------------------------------------------\n\n');

if nargout > 0
    results = table((1:n)', string(cases(:,2)), status, msg, ...
        'VariableNames', {'Nr','Test','Status','Meldung'});
end
end

% ======================================================================
function case_nominal_recovery
[sweep, truth] = synth_motor_sweep('NoiseSeed', 1);
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs);
assert(r.accepted, 'expected acceptance, got: %s', r.reason);
rel_err = abs(r.kT - truth.kT)/truth.kT;
assert(rel_err < 0.05, 'kT recovered %.3e vs planted %.3e (%.1f%% off)', ...
    r.kT, truth.kT, 100*rel_err);
assert(r.kT_R2 >= 0.98, 'kT R^2 = %.4f below the 0.98 acceptance bar', r.kT_R2);
end

function case_low_noise_tight_tol
% Tighter noise than the nominal case: this is what sets the credible
% 2%%-recovery bar cited in SWE1-MDL-003's unit-verification criterion.
[sweep, truth] = synth_motor_sweep('NoiseSeed', 7, ...
    'ThrustNoise_g', 0.1, 'CurrentNoise_A', 0.03, 'ErpmNoise_frac', 0.002);
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs);
assert(r.accepted, 'expected acceptance, got: %s', r.reason);
rel_err = abs(r.kT - truth.kT)/truth.kT;
assert(rel_err < 0.02, 'kT recovered %.3e vs planted %.3e (%.1f%% off, want <2%%)', ...
    r.kT, truth.kT, 100*rel_err);
end

function case_nan_guard
[sweep, truth] = synth_motor_sweep('NoiseSeed', 2, 'InjectNaNRow', true, 'NSteps', 10);
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs);
assert(r.n_rejected == 1, 'expected exactly 1 rejected row, got %d', r.n_rejected);
assert(r.n_used == 9, 'expected 9 used rows, got %d', r.n_used);
assert(r.accepted, 'a single guarded NaN row should still leave a good fit: %s', r.reason);
end

function case_too_few_steps
[sweep, truth] = synth_motor_sweep('NoiseSeed', 3, 'NSteps', 6);
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs);
assert(~r.accepted, 'expected rejection with only 6 steps');
assert(contains(r.reason, 'valid steps'), 'wrong rejection reason: %s', r.reason);
end

function case_nonmonotonic_rejected
[sweep, truth] = synth_motor_sweep('NoiseSeed', 4, 'InjectNonmonotonic', true);
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs);
assert(~r.monotonic, 'expected the injected spike to fail the monotonic check');
assert(~r.accepted, 'a non-monotonic sweep must not be adopted');
end

function case_model_mismatch_rejected
% A sweep whose thrust actually follows omega^2.3 (a bad/wrong-model prop,
% e.g. stall or a counterfeit part) still scores R^2 = 0.992 on the
% through-origin omega^2 fit -- above the 0.98 bar -- because the wide
% spin-up-to-current-limit dynamic range dominates the sum of squares.
% This is exactly why MaxRelResidual exists as a second gate.
[sweep, truth] = synth_motor_sweep('NoiseSeed', 9);
om = 2*pi*sweep.erpm/(60*truth.PolePairs);
sweep.thrust_g = (truth.kT * om.^2.3 / (max(om)^0.3)) / 9.81 * 1000;
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs);
assert(r.kT_R2 >= 0.98, 'test setup check: expected R^2 to still clear 0.98 (it does, that''s the point), got %.4f', r.kT_R2);
assert(~r.accepted, 'a wrong power law must be rejected even though R^2 alone would pass it');
assert(contains(r.reason, 'residual'), 'expected the residual gate to be the stated reason: %s', r.reason);
end

function case_tau_recovery
[sweep, truth, stepResp] = synth_motor_sweep('NoiseSeed', 5, 'tau', 0.05);
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs, ...
    'StepResponse', stepResp);
assert(~isnan(r.tau), 'tau was not fitted at all');
rel_err = abs(r.tau - truth.tau)/truth.tau;
assert(rel_err < 0.15, 'tau recovered %.4f vs planted %.4f (%.1f%% off)', ...
    r.tau, truth.tau, 100*rel_err);
end
