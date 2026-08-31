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
%   OUTPUT  result (struct)
%     kT, kT_R2, kT_residual_rms, kT_residual_rel [N/(rad/s)^2], fit quality
%     kQ, kQ_R2, kQ_residual_rms   [Nm/(rad/s)^2]
%     tau                          [s], NaN if no StepResponse given
%     w_max                        [rad/s], top of the accepted sweep
%     n_used, n_rejected           row counts after the NaN/validity guard
%     monotonic                    logical, thrust non-decreasing in throttle
%     accepted                     logical -- SWE1-MDL-003 acceptance verdict
%     reason                       string explaining a rejection (or "ok")
%
%   ACCEPTANCE (SWE1-MDL-003): a sweep is adopted into quad_params.m only if,
%   after the guard, >= MinSteps rows remain, thrust is monotonic (within a
%   small noise tolerance) in throttle, and kT_R2 >= MinR2. Anything short
%   of that comes back with accepted = false and a reason -- NaN and outlier
%   rows are counted, never silently dropped without a trace, and a rejected
%   sweep is never substituted with a vendor number (see PROP_TO_FIRMWARE.md
%   §2 and §5 -- no invented numbers go into quad_params.m).
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

result = struct('kT', NaN, 'kT_R2', NaN, 'kT_residual_rms', NaN, ...
                 'kQ', NaN, 'kQ_R2', NaN, 'kQ_residual_rms', NaN, ...
                 'tau', NaN, 'w_max', NaN, ...
                 'n_used', n_used, 'n_rejected', n_rejected, ...
                 'monotonic', false, 'accepted', false, 'reason', "");

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
if ~isempty(opt.StepResponse)
    t    = opt.StepResponse(:,1);
    y    = opt.StepResponse(:,2);
    y0   = y(1);
    yf   = mean(y(max(1,end-4):end)); % steady-state = last 5 samples
    if yf > y0
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
        end
    end
end

% ---- acceptance verdict (SWE1-MDL-003) ----------------------------------
if ~monotonic
    result.reason = 'thrust not monotonic in throttle (beyond noise tolerance)';
    return
end
if kT_R2 < opt.MinR2
    result.reason = sprintf('kT R^2 = %.4f < required %.4f', kT_R2, opt.MinR2);
    return
end
if result.kT_residual_rel > opt.MaxRelResidual
    result.reason = sprintf('kT normalized residual = %.4f > allowed %.4f (R^2 alone did not catch this -- see MaxRelResidual)', ...
        result.kT_residual_rel, opt.MaxRelResidual);
    return
end

result.accepted = true;
result.reason   = 'ok';

end

% ------------------------------------------------------------------------
function s = table2struct_or_table(sweep)
%TABLE2STRUCT_OR_TABLE  Normalize a table or struct array to a plain struct
%   of column vectors, with case-insensitive field/variable name matching.
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
    for k = 1:numel(want)
        idx = find(strcmpi(names, want{k}), 1);
        if isempty(idx)
            error('fit_motor_coeffs:missingField', ...
                'sweep is missing required field "%s"', want{k});
        end
        if istable(sweep)
            s.(want{k}) = double(sweep.(names{idx}));
        else
            s.(want{k}) = double([sweep.(names{idx})]');
        end
    end
end
