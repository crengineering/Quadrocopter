function result = fit_motor_coeffs(sweep, varargin)
%FIT_MOTOR_COEFFS  Fit kT, kQ, tau, w_max from one logged bench thrust-rig sweep.
%
%   result = FIT_MOTOR_COEFFS(sweep) fits the propeller thrust coefficient
%   kT (T = kT*omega^2) and the reaction-torque coefficient kQ from one
%   bench sweep: throttle held at ~10 steady-state steps from spin-up to the
%   current limit. Also returns w_max (top of the accepted sweep) and,
%   if a step-response transient is supplied, the motor+ESC time constant
%   tau. Design for SWE1-MDL-003 (parent SYS2-MEC-004, SYS1-007); see
%   QuadSE/requirements/SWE1_SWR.md and dispatch/SYS1-012.md §6.
%
%   INPUT
%     sweep : table or struct array, one row per held throttle step, with
%             fields/variables (case-insensitive):
%               throttle    [-]     commanded throttle, any consistent unit
%               erpm        [1/min] ESC bidirectional-DShot electrical RPM
%               thrust_g    [g]     digital-scale thrust reading
%               vbat_V      [V]     pack voltage during the hold
%               esc_I_A     [A]     ESC current during the hold
%             Rows must already be steady-state averages over the hold
%             window -- this function does not itself segment a raw
%             high-rate log.
%
%   NAME-VALUE ARGS
%     'PolePairs'    (default 7)   erpm -> mechanical rpm divisor.
%                                  SunnySky X2216-III V3 (12N14P) => 7.
%     'KV'           (default 880) motor velocity constant [rpm/V]; used
%                                  only for the kQ current-based estimate
%                                  (Kt = 9.55/KV [Nm/A], the datasheet
%                                  relation in
%                                  procurement/datasheets/motor-sunnysky-x2216-iii-v3-880kv.md).
%                                  kQ is therefore a datasheet-dependent
%                                  engineering estimate of shaft torque, not
%                                  a measured one (see the kQ fit comment
%                                  below); a no-load-current row added to
%                                  the sweep protocol would remove the I0
%                                  bias it is currently built on.
%     'StepResponse' ([])          optional Nx2 [t (s), erpm] transient
%                                  recorded on one throttle step, used only
%                                  for the tau fit. Leave empty to skip it
%                                  (result.tau = NaN, not a guessed value).
%     'MinSteps'     (default 8)   minimum accepted rows for adoption
%                                  (SWE1-MDL-003 acceptance).
%     'MinR2'        (default 0.98) minimum kT R^2 for adoption.
%     'MaxRelResidual' (default 0.05) maximum kT residual RMS, normalized
%                                  by mean thrust, for adoption. R^2 alone
%                                  is NOT enough here: validated against a
%                                  synthetic sweep, a sweep whose thrust
%                                  actually follows omega^2.3 instead of the
%                                  physical omega^2 (a bad/wrong-model prop)
%                                  still scores R^2 = 0.992 -- comfortably
%                                  above 0.98 -- because the wide dynamic
%                                  range from spin-up to current limit
%                                  dominates the sum-of-squares and swamps a
%                                  ~15% shape error. Its normalized residual
%                                  is 7.0%, against 0.4% for a genuinely
%                                  noisy-but-correct sweep -- this is the
%                                  metric that actually separates them.
%
%   OUTPUT  result (struct) -- every field below is present, with the same
%   name and field order, on every return path (too-few-steps rejection,
%   monotonic/R2/residual/tau rejection, or acceptance), so a batch of
%   results concatenates cleanly, e.g. [r1 r2 ...] across many sweeps.
%     kT, kQ, w_max                NaN whenever accepted is false -- a
%                                   caller that ignores `accepted` cannot
%                                   use a rejected fit silently; the
%                                   fitted-but-rejected numbers are kept in
%                                   rejected_fit (below) for diagnosis
%     kT_R2, kT_residual_rms, kT_residual_rel [N/(rad/s)^2], fit quality
%                                   (kept even on rejection, for diagnosis)
%     kQ_R2, kQ_residual_rms       [Nm/(rad/s)^2] (also kept on rejection)
%     tau                          [s]; NaN if no StepResponse was given
%                                   (undetermined -- not a failure), or if
%                                   one was given but could not be fitted
%                                   (a failure -- see reason, accepted is
%                                   then false; a supplied-but-unusable
%                                   transient rejects the sweep, it never
%                                   leaves tau silently missing)
%     rejected_fit.kT/kQ/w_max     the fitted numbers stashed here when
%                                   accepted is false; NaN while accepted
%                                   is true
%     n_used, n_rejected           row counts after the NaN/validity guard
%     monotonic                    logical, thrust non-decreasing in
%                                   throttle. NOT EVALUATED (pre-seeded
%                                   false) on the too-few-steps early
%                                   return, i.e. only meaningful when
%                                   n_used >= MinSteps -- check `reason`
%                                   (or n_used vs MinSteps) before reading
%                                   it; pre-seeded false rather than NaN
%                                   because `if r.monotonic` / `~r.monotonic`
%                                   treat NaN as a nonzero, truthy value in
%                                   MATLAB (NaN ~= 0), which would silently
%                                   read as "monotonic ok"
%     accepted                     logical -- SWE1-MDL-003 acceptance verdict
%     reason                       string explaining a rejection (or "ok");
%                                   'tauFitFailed:<why>' for an unusable
%                                   supplied StepResponse
%
%   ACCEPTANCE (SWE1-MDL-003): a sweep is adopted into quad_params.m only if,
%   after the guard, >= MinSteps rows remain, thrust is monotonic (within a
%   small noise tolerance) in throttle, kT_R2 >= MinR2 AND the normalized kT
%   residual <= MaxRelResidual (R^2 alone is not enough -- see
%   MaxRelResidual below), and -- when a StepResponse transient was supplied
%   -- it could actually be fitted. Anything short of that comes back with
%   accepted = false and a reason -- NaN and outlier rows are counted, never
%   silently dropped without a trace, and a rejected sweep is never
%   substituted with a vendor number (see PROP_TO_FIRMWARE.md §2 and §5 --
%   no invented numbers go into quad_params.m).
%
%   See also SYNTH_MOTOR_SWEEP, TEST_FIT_MOTOR_COEFFS.

p = inputParser;
p.addParameter('PolePairs', 7, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('KV', 880, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('StepResponse', [], @(x) isempty(x) || (isnumeric(x) && size(x,2)==2));
p.addParameter('MinSteps', 8, @(x) isnumeric(x) && isscalar(x));
p.addParameter('MinR2', 0.98, @(x) isnumeric(x) && isscalar(x));
p.addParameter('MaxRelResidual', 0.05, @(x) isnumeric(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

g = 9.81; % m/s^2 -- consistent with quad_params.m:3

T = table2struct_or_table(sweep);

n_total = numel(T.throttle);

% ---- NaN / validity guard --------------------------------------------
% NaN is a real value here: it must be counted and rejected, never let
% through a comparison silently.
valid = true(n_total, 1);
fields_required = {'throttle','erpm','thrust_g','vbat_V','esc_I_A'};
for k = 1:numel(fields_required)
    v = T.(fields_required{k});
    valid = valid & isfinite(v);
end
valid = valid & (T.erpm > 0) & (T.thrust_g > 0) & (T.vbat_V > 0) & (T.esc_I_A >= 0);

n_used     = sum(valid);
n_rejected = n_total - n_used;

% Pre-seed EVERY output field here, once, so every return path below
% (too-few-steps, monotonic/R2/residual/tau rejection, or acceptance)
% yields an identical field set in the same order -- MAJOR 1 fix: a
% result struct that only grows fields on the "far" return paths breaks
% concatenation ([r1 r2]) of a rejected result with an accepted one.
% `monotonic` is seeded false, not NaN: `if r.monotonic` / `~r.monotonic`
% treat NaN as truthy in MATLAB (NaN ~= 0), so a NaN sentinel here would
% silently read as "monotonic ok" on the too-few-steps path -- see the
% OUTPUT doc above for how to tell "not evaluated" from "evaluated false".
result = struct('kT', NaN, 'kT_R2', NaN, 'kT_residual_rms', NaN, ...
                 'kT_residual_rel', NaN, ...
                 'kQ', NaN, 'kQ_R2', NaN, 'kQ_residual_rms', NaN, ...
                 'tau', NaN, 'w_max', NaN, ...
                 'n_used', n_used, 'n_rejected', n_rejected, ...
                 'monotonic', false, 'accepted', false, 'reason', "", ...
                 'rejected_fit', struct('kT', NaN, 'kQ', NaN, 'w_max', NaN));

if n_used < opt.MinSteps
    result.reason = sprintf('only %d valid steps of %d, need >= %d', ...
        n_used, n_total, opt.MinSteps);
    return
end

thr    = T.throttle(valid);
erpm   = T.erpm(valid);
thrust = T.thrust_g(valid) * g / 1000;   % g -> N
I      = T.esc_I_A(valid);

omega = 2*pi*erpm / (60*opt.PolePairs);  % rad/s, mechanical

% ---- monotonicity check (sanity: bad channel, slipping prop, misfire) --
[~, order] = sort(thr);
thrust_sorted = thrust(order);
tol = 0.02 * max(thrust_sorted); % 2% of max thrust, noise tolerance
monotonic = all(diff(thrust_sorted) >= -tol);
result.monotonic = monotonic;

% ---- kT fit: T = kT * omega^2, least squares through the origin -------
om2 = omega.^2;
kT = sum(om2 .* thrust) / sum(om2.^2);
resid_kT = thrust - kT*om2;
SStot = sum((thrust - mean(thrust)).^2);
SSres = sum(resid_kT.^2);
kT_R2 = 1 - SSres/SStot;

result.kT              = kT;
result.kT_R2            = kT_R2;
result.kT_residual_rms  = sqrt(mean(resid_kT.^2));
result.kT_residual_rel  = result.kT_residual_rms / mean(thrust);
result.w_max            = max(omega);

% ---- kQ fit: motor-current estimate of shaft torque --------------------
% Q ~= Kt*(I - I0), Kt = 9.55/KV [Nm/A] (datasheet relation), I0 = no-load
% current approximated by the lowest-throttle accepted row. Regressed the
% same way as kT: Q = kQ*omega^2, least squares through the origin.
% This is an engineering approximation (ignores copper-loss curvature and
% windage beyond I0) -- documented, not hidden; a torque-sensor rig would
% supersede it, but none is on the buy list.
Kt = 9.55 / opt.KV;
I0 = I(find(thr == min(thr), 1));
Q  = max(Kt * (I - I0), 0);
kQ = sum(om2 .* Q) / sum(om2.^2);
resid_kQ = Q - kQ*om2;
SStot_Q = sum((Q - mean(Q)).^2);
SSres_Q = sum(resid_kQ.^2);
if SStot_Q > 0
    kQ_R2 = 1 - SSres_Q/SStot_Q;
else
    kQ_R2 = NaN;
end
result.kQ             = kQ;
result.kQ_R2          = kQ_R2;
result.kQ_residual_rms = sqrt(mean(resid_kQ.^2));

% ---- tau fit: first-order step response, log-linearized ---------------
% Three distinct states (MAJOR 2 fix -- tau used to stay silently NaN with
% reason='ok'/accepted=true whenever a supplied transient was degenerate):
%   1) no StepResponse given      -> tau = NaN, reason untouched (documented
%                                     above: "undetermined", not a failure)
%   2) StepResponse given, fit ok -> tau numeric
%   3) StepResponse given but unusable (step-down, or too few samples in
%      the fit window) -> tau stays NaN AND the sweep is rejected below
%      (reason = 'tauFitFailed:<why>', accepted = false) -- a supplied
%      transient that cannot be fitted is a rejected sweep, never a
%      silently missing tau.
tau_failed = false;
tau_fail_reason = '';
if ~isempty(opt.StepResponse)
    t    = opt.StepResponse(:,1);
    y    = opt.StepResponse(:,2);
    y0   = y(1);
    yf   = mean(y(max(1,end-4):end)); % steady-state = last 5 samples
    if yf <= y0
        tau_failed = true;
        tau_fail_reason = sprintf('step-down or non-increasing transient (yf=%.4g <= y0=%.4g)', yf, y0);
    else
        z = (yf - y) / (yf - y0);
        % Keep only 0.05 <= z <= 0.95: near t=0, z~1 carries little slope
        % information either; near full settle, measurement noise swamps
        % the signal on a log scale and would dominate an unweighted fit
        % (residual noise on y is roughly constant, but log(z) blows it up
        % as z -> 0). This is a signal-to-noise window, not a data crop
        % chosen to flatter the answer.
        keep = z >= 0.05 & z <= 0.95 & isfinite(z);
        if sum(keep) >= 5
            pfit = polyfit(t(keep), log(z(keep)), 1);
            result.tau = -1/pfit(1);
        else
            tau_failed = true;
            tau_fail_reason = sprintf('too few samples in the 0.05-0.95 fit window (%d < 5)', sum(keep));
        end
    end
end

% ---- acceptance verdict (SWE1-MDL-003) ----------------------------------
reject_reason = '';
if ~monotonic
    reject_reason = 'thrust not monotonic in throttle (beyond noise tolerance)';
elseif kT_R2 < opt.MinR2
    reject_reason = sprintf('kT R^2 = %.4f < required %.4f', kT_R2, opt.MinR2);
elseif result.kT_residual_rel > opt.MaxRelResidual
    reject_reason = sprintf('kT normalized residual = %.4f > allowed %.4f (R^2 alone did not catch this -- see MaxRelResidual)', ...
        result.kT_residual_rel, opt.MaxRelResidual);
elseif tau_failed
    reject_reason = sprintf('tauFitFailed:%s', tau_fail_reason);
end

if ~isempty(reject_reason)
    % A rejected sweep never hands back the fitted kT/kQ/w_max as if they
    % were usable -- stash them in rejected_fit for diagnosis and NaN the
    % primary fields (notes from the flight-reviewer verdict).
    result.reason             = reject_reason;
    result.rejected_fit.kT    = result.kT;
    result.rejected_fit.kQ    = result.kQ;
    result.rejected_fit.w_max = result.w_max;
    result.kT    = NaN;
    result.kQ    = NaN;
    result.w_max = NaN;
    result.accepted = false;
    return
end

result.accepted = true;
result.reason   = 'ok';

end

% ------------------------------------------------------------------------
function s = table2struct_or_table(sweep)
%TABLE2STRUCT_OR_TABLE  Normalize a table, struct array, or scalar struct
%   of column vectors to a plain struct of column vectors, with
%   case-insensitive field/variable name matching.
%
%   MAJOR 3 fix: a scalar struct of column vectors (the natural MF4->struct
%   conversion) used to come out of here transposed to 1xN by the old
%   `[sweep.(f)]'` idiom (correct only for a struct ARRAY, where the same
%   idiom builds a row via comma-separated-list concatenation and the `'`
%   fixes it back to a column) -- callers then hit implicit N x N
%   expansion in the valid & isfinite(v) guard and the logical index died.
%   `v(:)` after the CS-list concatenation normalises both shapes
%   correctly. Field-length mismatches (e.g. a hand-built struct with one
%   short column) are now caught explicitly here rather than silently
%   misaligning rows or exploding in the guard.
    want = {'throttle','erpm','thrust_g','vbat_V','esc_I_A'};
    if istable(sweep)
        names = sweep.Properties.VariableNames;
    elseif isstruct(sweep)
        names = fieldnames(sweep);
    else
        error('fit_motor_coeffs:badInput', ...
            'sweep must be a table or struct array');
    end
    s = struct();
    lens = zeros(1, numel(want));
    for k = 1:numel(want)
        idx = find(strcmpi(names, want{k}), 1);
        if isempty(idx)
            error('fit_motor_coeffs:missingField', ...
                'sweep is missing required field "%s"', want{k});
        end
        if istable(sweep)
            v = double(sweep.(names{idx}));
        else
            v = double([sweep.(names{idx})]);
        end
        v = v(:); % normalise to a column regardless of struct-array (one
                  % row per element) vs scalar-struct-of-column-vectors
                  % input shape
        s.(want{k}) = v;
        lens(k) = numel(v);
    end
    if any(lens ~= lens(1))
        detail = strjoin(arrayfun(@(k) sprintf('%s=%d', want{k}, lens(k)), ...
            1:numel(want), 'UniformOutput', false), ', ');
        error('fit_motor_coeffs:badInput', ...
            'sweep fields have inconsistent lengths: %s', detail);
    end
end
