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
          @case_model_mismatch_rejected, 'C7  Wrong power law (omega^2.3) -> rejected by residual, not just R2'
          @case_realistic_noise_repeatability, 'C8  kT recovery across 20 seeds at realistic bench noise (prints achieved bound)'
          @case_result_shape_stable,     'C9  Rejected + accepted results concatenate ([r1 r2]) with identical field set'
          @case_tau_step_down_rejected,  'C10 Step-down transient -> tauFitFailed, sweep rejected (not silent NaN)'
          @case_tau_window_too_short_rejected, 'C11 Too-short tau fit window -> tauFitFailed, sweep rejected'
          @case_scalar_struct_column_vectors,  'C12 Scalar struct of column vectors (MF4-shaped) handled correctly'
          @case_length_mismatch_rejected, 'C13 Mismatched field lengths -> badInput' };

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
% Regression guard: `monotonic` must be a not-evaluated FALSE here, never
% a NaN sentinel -- `if r.monotonic`/`~r.monotonic` treat NaN as truthy in
% MATLAB (NaN ~= 0), which would silently read as "monotonic ok".
assert(islogical(r.monotonic) && r.monotonic == false, ...
    'monotonic must be logical false (not evaluated) on the too-few-steps path, got %s', mat2str(r.monotonic));
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

% ======================================================================
% Cases below added for the flight-reviewer's pass-with-notes verdict on
% SWE1-MDL-003 (2026-09-03): MAJOR 1 (shape stability), MAJOR 2 (silent
% tau failure), MAJOR 3 (scalar-struct input), MAJOR 4 (unreproducible
% 20-seed claim).

function case_realistic_noise_repeatability
% MAJOR 4 fix: the SWE1-MDL-003 status note claimed "kT recovered within
% 0.6%% at realistic bench noise across 20 seeds, R^2 > 0.999" with no
% committed test backing it. "Realistic bench noise" = synth_motor_sweep's
% defaults (ThrustNoise_g=0.1 g digital-scale resolution, CurrentNoise_A
% =0.05 A ESC current-sense noise, ErpmNoise_frac=0.003 eRPM measurement
% noise -- see its docstring), i.e. the same noise level as C1, run across
% 20 seeds instead of one. This prints the achieved max error / min R^2 so
% the item's status note can cite a number that actually came out of a run.
seeds = 1:20;
max_err = 0;
min_R2  = Inf;
for s = seeds
    [sweep, truth] = synth_motor_sweep('NoiseSeed', s);
    r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs);
    assert(r.accepted, 'seed %d: expected acceptance, got: %s', s, r.reason);
    rel_err = abs(r.kT - truth.kT) / truth.kT;
    max_err = max(max_err, rel_err);
    min_R2  = min(min_R2, r.kT_R2);
end
fprintf('        C8 achieved: max |kT error| = %.4f%%, min kT R^2 = %.6f  (seeds 1-%d, realistic noise)\n', ...
    100*max_err, min_R2, numel(seeds));
% Bounds set from the actually-observed run (max 0.58%% err, min R^2
% 0.999689 on seeds 1-20, 2026-09-03) with modest headroom for solver/
% platform noise -- not from the old unverified claim; see the task
% report for the literal numbers this run produced.
assert(max_err < 0.01, 'max kT error %.4f%% across %d seeds exceeds the 1%% bound', ...
    100*max_err, numel(seeds));
assert(min_R2 > 0.999, 'min kT R^2 %.6f across %d seeds does not clear 0.999', ...
    min_R2, numel(seeds));
end

function case_result_shape_stable
% MAJOR 1 fix: a rejected result and an accepted result must have the
% identical field set (and thus concatenate without error) so a batch of
% sweep fits can be tabulated with [r1 r2 ...].
[sweep_rej, truth_rej] = synth_motor_sweep('NoiseSeed', 3, 'NSteps', 6); % too few steps
r1 = fit_motor_coeffs(sweep_rej, 'KV', truth_rej.KV, 'PolePairs', truth_rej.PolePairs);
[sweep_ok, truth_ok] = synth_motor_sweep('NoiseSeed', 1);
r2 = fit_motor_coeffs(sweep_ok, 'KV', truth_ok.KV, 'PolePairs', truth_ok.PolePairs);
assert(~r1.accepted, 'test setup: expected r1 (6-step sweep) to be rejected');
assert(r2.accepted, 'test setup: expected r2 (nominal sweep) to be accepted');
assert(isequal(fieldnames(r1), fieldnames(r2)), ...
    'rejected and accepted results have different field sets');
both = [r1 r2]; %#ok<NASGU>  -- must not error (this is the actual assertion)
assert(numel(both) == 2, 'concatenated result array has the wrong length');
assert(isscalar(r1.kT_residual_rel) && isnan(r1.kT_residual_rel), ...
    'kT_residual_rel must be a well-defined scalar NaN on a too-few-steps rejection');
end

function case_tau_step_down_rejected
% MAJOR 2 fix: a supplied StepResponse that steps DOWN (yf <= y0) used to
% leave tau silently NaN with reason='ok'/accepted=true. It must now
% reject the whole sweep with a stated reason.
[sweep, truth] = synth_motor_sweep('NoiseSeed', 5);
t = (0:0.002:0.5)';
stepDown = [t, 7000 - 2000*(1 - exp(-t/0.05))]; % decreasing erpm: yf < y0
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs, ...
    'StepResponse', stepDown);
assert(isnan(r.tau), 'tau must stay NaN on a step-down transient');
assert(~r.accepted, 'a sweep with an unusable supplied transient must be rejected');
assert(contains(r.reason, 'tauFitFailed'), 'expected a tauFitFailed reason, got: %s', r.reason);
end

function case_tau_window_too_short_rejected
% MAJOR 2 fix: an increasing (valid-direction) transient that settles so
% fast relative to its sample spacing that fewer than 5 samples land in
% the 0.05<=z<=0.95 fit window must also reject the sweep, not silently
% leave tau NaN with reason='ok'.
[sweep, truth] = synth_motor_sweep('NoiseSeed', 5);
t = (0:0.01:0.5)';
y0 = 3000; yf = 8000; tau_fast = 0.005; % settles in ~2 samples at this dt
y = y0 + (yf - y0) * (1 - exp(-t/tau_fast));
r = fit_motor_coeffs(sweep, 'KV', truth.KV, 'PolePairs', truth.PolePairs, ...
    'StepResponse', [t y]);
assert(isnan(r.tau), 'tau must stay NaN when the fit window is too short');
assert(~r.accepted, 'a sweep with an unusable supplied transient must be rejected');
assert(contains(r.reason, 'tauFitFailed'), 'expected a tauFitFailed reason, got: %s', r.reason);
end

function case_scalar_struct_column_vectors
% MAJOR 3 fix: a scalar struct of column vectors (the natural MF4->struct
% conversion) must not silently transpose and explode the validity mask.
[sweep_tbl, truth] = synth_motor_sweep('NoiseSeed', 6);
s = struct();
s.throttle = sweep_tbl.throttle;
s.erpm     = sweep_tbl.erpm;
s.thrust_g = sweep_tbl.thrust_g;
s.vbat_V   = sweep_tbl.vbat_V;
s.esc_I_A  = sweep_tbl.esc_I_A;
r = fit_motor_coeffs(s, 'KV', truth.KV, 'PolePairs', truth.PolePairs);
assert(r.n_used == numel(sweep_tbl.throttle), 'expected all %d rows used, got %d', ...
    numel(sweep_tbl.throttle), r.n_used);
assert(r.accepted, 'expected acceptance on a scalar-struct-of-column-vectors input, got: %s', r.reason);
rel_err = abs(r.kT - truth.kT) / truth.kT;
assert(rel_err < 0.05, 'kT recovered %.3e vs planted %.3e (%.1f%% off)', ...
    r.kT, truth.kT, 100*rel_err);
end

function case_length_mismatch_rejected
% MAJOR 3 fix: mismatched field lengths in a struct input must be caught
% explicitly (badInput), not silently misaligned or crashed on with an
% opaque implicit-expansion error.
[sweep_tbl, ~] = synth_motor_sweep('NoiseSeed', 6);
s = struct();
s.throttle = sweep_tbl.throttle;
s.erpm     = sweep_tbl.erpm(1:end-1);   % one row short -- deliberate mismatch
s.thrust_g = sweep_tbl.thrust_g;
s.vbat_V   = sweep_tbl.vbat_V;
s.esc_I_A  = sweep_tbl.esc_I_A;
threw = false;
try
    fit_motor_coeffs(s);
catch e
    threw = true;
    assert(strcmp(e.identifier, 'fit_motor_coeffs:badInput'), ...
        'expected fit_motor_coeffs:badInput, got %s', e.identifier);
end
assert(threw, 'expected a length-mismatch input to be rejected as badInput');
end
