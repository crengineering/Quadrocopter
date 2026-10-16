function r = propulsion_rig_run3(mdFile, varargin)
%PROPULSION_RIG_RUN3  Propulsion parameters from thrust-rig run 3 (proposal support).
%
%   r = PROPULSION_RIG_RUN3()  parses the run-3 step table straight out of
%   QuadSE/evidence/thrust_rig_runs.md (no numbers retyped), derives the
%   plant parameters for quad_params.m and prints the old-vs-new comparison.
%   Nothing is written; quad_params.m is not touched.
%
%   Provenance: evidence INDEX row BB9B34CB480DCC42 (rig run 3, 2026-10-15,
%   X2216-III 880 KV + HQProp 10x4.5, D = 254 mm, U = 14.8 V CV supply,
%   motor_kv 860, ESC ch. 3). Measured at a stiff lab supply, NOT a sagging pack.
%
%   NAME-VALUE
%     'm'      aircraft mass for the hover point  [kg]   (default 1.20 = quad_params.m)
%     'eta'    overall power->shaft efficiency (ESC+motor), [lo mid hi]
%              default [0.60 0.70 0.80]  -- ASSUMPTION, not measured
%
%   LEGEND (all SI, rotation in rad/s unless "rpm")
%     sp      DShot throttle value                       [-]
%     rpm     mechanical prop speed (KISS eRPM/7)        [1/min]
%     w       prop angular speed = rpm*2*pi/60           [rad/s]
%     T       static thrust (scale reading, g * 9.81e-3) [N]
%     kT      thrust coefficient, T = kT*w^2             [N/(rad/s)^2]
%     Q       prop shaft torque                          [Nm]
%     kQ      torque coefficient, Q = kQ*w^2             [Nm/(rad/s)^2]
%     eta     (shaft power)/(supply power U*I)           [-]
%     Pnet    U*I minus the standby draw at sp 50        [W]
%     Ct, Cp  thrust / power coefficient, T=Ct*rho*n^2*D^4, P=Cp*rho*n^3*D^5
%     n       prop speed in rev/s; D = 0.254 m; rho = 1.225 kg/m^3
%     w_max   top of the measured sweep (SWE1-MDL-003 definition)

p = inputParser;
addParameter(p,'m',1.20);
addParameter(p,'eta',[0.60 0.70 0.80]);
parse(p,varargin{:});
m = p.Results.m;  eta = p.Results.eta;

if nargin < 1 || isempty(mdFile)
    mdFile = 'C:/Users/chris/Projects/QuadSE/evidence/thrust_rig_runs.md';
end
g = 9.81;  D = 0.254;  rho = 1.225;

% ---- parse the run-3 table ---------------------------------------------
txt  = fileread(mdFile);
i0   = strfind(txt, '## Run 3');   i1 = strfind(txt, '**Fit (points');
assert(~isempty(i0) && ~isempty(i1), 'run-3 section not found in %s', mdFile);
lines = strsplit(txt(i0(1):i1(1)-1), newline);
rows = [];
for k = 1:numel(lines)
    c = strtrim(strsplit(strtrim(lines{k}), '|'));
    c = c(~cellfun(@isempty,c));
    if numel(c) == 11 && ~isnan(str2double(c{1}))
        v = str2double(strrep(c,'*',''));      % '—' and '14.8*' handled
        rows(end+1,:) = v; %#ok<AGROW>
    end
end
assert(size(rows,1) == 17, 'expected 17 sweep rows, got %d', size(rows,1));
sp = rows(:,1); rpm = rows(:,2); U = rows(:,4); I = rows(:,5);
scale_g = rows(:,6); Pin = rows(:,9);
assert(all(isfinite([sp;rpm;U;I;scale_g;Pin])), 'NaN in parsed table');
w  = rpm*2*pi/60;
T  = scale_g*g/1000;                                  % N
n  = rpm/60;

r.sp = sp; r.rpm = rpm; r.w = w; r.T = T;

% ---- kT: LS fit (reproduces the note) and hover secant -----------------
sel = rpm >= 2000;
kT_ls = sum(w(sel).^2 .* T(sel)) / sum(w(sel).^4);
pf = polyfit(log(rpm(sel)), log(T(sel)), 1);          % exponent
r.kT_ls = kT_ls;  r.exponent = pf(1);
Ct = T ./ (rho*n.^2*D^4);
r.Ct_range = [min(Ct(sel)) max(Ct(sel))];

% hover point: thrust per motor = m*g/4, rpm by interpolation of the measured curve
T_h  = m*g/4;
rpm_h = interp1(T(sel), rpm(sel), T_h, 'pchip');
w_h   = rpm_h*2*pi/60;
kT_h  = T_h / w_h^2;
r.T_hover = T_h; r.rpm_hover = rpm_h; r.w_hover = w_h; r.kT_hover = kT_h;
% same for the 1.0 kg / 245 g point of the note
T_h1 = 1.0*g/4; rpm_h1 = interp1(T(sel), rpm(sel), T_h1, 'pchip');
r.kT_hover_1kg = T_h1/(rpm_h1*2*pi/60)^2;  r.rpm_hover_1kg = rpm_h1;

% thrust error of a constant kT over the measured range
for kk = {'kT_ls','kT_hover'}
    kt = r.(kk{1});
    e  = (kt*w.^2 - T) ./ T * 100;
    r.(['err_' kk{1}]) = e;
end
r.max_err_hover_pct = max(abs(r.err_kT_hover(rpm>=2900)));   % >= 100 g
r.max_err_ls_pct    = max(abs(r.err_kT_ls(rpm>=2900)));

% ---- w_max (SWE1-MDL-003: top of accepted sweep) ------------------------
r.w_max = max(w);  r.T_max = max(T);

% ---- sp -> rpm (linear above 2000 rpm), 14.8 V -------------------------
c = polyfit(sp(sel), rpm(sel), 1);
res = rpm(sel) - polyval(c, sp(sel));
r.rpm_of_sp = c;                       % rpm = c(1)*sp + c(2)
r.rpm_of_sp_maxres = max(abs(res));
r.sp_hover = (rpm_h - c(2))/c(1);

% ---- kQ ESTIMATE from electrical power ---------------------------------
% Q*w = eta*Pnet  ->  kQ = eta*Pnet/w^3. NOT measured: no torque sensor.
Pidle = Pin(1);                        % sp 50, 129 rpm: standby draw
Pnet  = max(U.*I - Pidle, 0);
r.Pidle = Pidle;
kQ_pt = @(e) e*Pnet./w.^3;
kQ_h  = zeros(size(eta)); kQ_ls = kQ_h; Cp_h = kQ_h;
for j = 1:numel(eta)
    q   = kQ_pt(eta(j));
    kQ_h(j)  = interp1(rpm(sel), q(sel), rpm_h, 'pchip');
    Qj  = eta(j)*Pnet./w;
    kQ_ls(j) = sum(w(sel).^2 .* Qj(sel)) / sum(w(sel).^4);
    Cp_h(j)  = eta(j)*interp1(rpm(sel),Pnet(sel),rpm_h,'pchip') / (rho*(rpm_h/60)^3*D^5);
end
r.eta = eta; r.kQ_hover = kQ_h; r.kQ_ls = kQ_ls; r.Cp_hover = Cp_h;
Ct_h = T_h/(rho*(rpm_h/60)^2*D^4);   r.Ct_hover = Ct_h;
r.CpCt_hover = Cp_h / Ct_h;
r.kQkT_ratio = kQ_h / kT_h;            % [m]; = D*Cp/(2*pi*Ct)
% loss budget at hover and at the top (datasheet R_ll = 0.089 Ohm, I0 = 0.5 A @ 10 V)
KV = 880; Ke = 60/(2*pi*KV);           % V/(rad/s)
for tag = {'hover','top'}
    if strcmp(tag{1},'hover'), rr = rpm_h; Ib = interp1(rpm(sel),I(sel),rpm_h,'pchip');
    else, rr = max(rpm); Ib = I(end); end
    ww = rr*2*pi/60; Vemf = Ke*ww; Iph = Ib*14.8/Vemf;
    Pcu = Iph^2*0.089; Pi0 = 0.5*Vemf; Pesc = 0.03*14.8*Ib;
    r.(['eta_budget_' tag{1}]) = 1 - (Pcu+Pi0+Pidle+Pesc)/(14.8*Ib);
end
% what the existing fit_motor_coeffs kQ method (Q = Kt*(I-I0), bus current) gives
Kt = 9.55/KV;  Qold = max(Kt*(I - I(1)),0);
r.kQ_fitscript = sum(w(sel).^2.*Qold(sel))/sum(w(sel).^4);

% ---- acceptance gates of SWE1-MDL-003 on this data (kT only) -----------
res = analysis_gate(sp, rpm, scale_g, U, I);
r.gate = res;

% ---- old vs new ---------------------------------------------------------
old = struct('kT',5.0e-6,'kQ',5.0e-8,'tau',0.05,'w_max',1200);
r.old = old;
r.new = struct('kT',kT_h,'kQ',kQ_h(2),'tau',0.05,'w_max',r.w_max);
for s = {'old','new'}
    q = r.(s{1});
    q.w_hover   = sqrt(m*g/(4*q.kT));
    q.rpm_hover = q.w_hover*60/(2*pi);
    q.hover_frac_wmax = q.w_hover/q.w_max;
    q.T_max_total = 4*q.kT*q.w_max^2;          % model thrust at w_max, N
    q.TW_max = q.T_max_total/(m*g);
    q.hover_frac_Tmax = (m*g)/q.T_max_total;
    q.yaw_per_w2 = q.kQ/q.kT;
    r.(s{1}) = q;
end
r.new.T_max_meas_total = 4*r.T_max;            % measured 770 g x 4
r.new.TW_max_meas = 4*r.T_max/(m*g);
print_report(r, m);
end

% ======================================================================
function res = analysis_gate(sp, rpm, scale_g, U, I)
if exist('fit_motor_coeffs','file') ~= 2
    res = struct('accepted',NaN,'reason',"fit_motor_coeffs not on path"); return
end
sw = struct('throttle',num2cell(sp),'erpm',num2cell(rpm*7),'thrust_g',num2cell(scale_g), ...
            'vbat_V',num2cell(U),'esc_I_A',num2cell(I));
sw = sw(:);
rr = fit_motor_coeffs(sw);
res = struct('accepted',rr.accepted,'reason',string(rr.reason),'kT',rr.kT,'kT_R2',rr.kT_R2, ...
             'kT_res_rel',rr.kT_residual_rel,'w_max',rr.w_max,'n_used',rr.n_used);
end

function print_report(r, m)
f = @(varargin) fprintf(varargin{:});
f('\n=== propulsion_rig_run3: X2216 880 KV + HQProp 10x4.5 (D = 254 mm), rig run 3, 14.8 V CV supply ===\n');
f('kT LS fit (>=2000 rpm)  : %.3f uN/(rad/s)^2  exponent %.2f  Ct %.3f..%.3f\n', r.kT_ls*1e6, r.exponent, r.Ct_range);
f('Hover m=%.2f kg         : T=%.1f g/motor  -> %.0f rpm = %.1f rad/s  -> secant kT_hover = %.3f uN/(rad/s)^2\n', ...
  m, r.T_hover/9.81*1e3, r.rpm_hover, r.w_hover, r.kT_hover*1e6);
f('Hover m=1.00 kg (note)  : %.0f rpm, secant kT = %.3f uN/(rad/s)^2\n', r.rpm_hover_1kg, r.kT_hover_1kg*1e6);
f('Const-kT thrust error, 100..770 g: kT_hover max %.1f %% | kT_LS max %.1f %%\n', r.max_err_hover_pct, r.max_err_ls_pct);
f('w_max (top of sweep)    : %.1f rad/s (%.0f rpm), T = %.0f g, sweep top only, NOT a motor limit\n', r.w_max, r.w_max*60/(2*pi), r.T_max/9.81*1e3);
f('rpm(sp) >=2000 rpm      : rpm = %.3f*sp + %.1f   max resid %.0f rpm   hover sp = %.0f   (14.8 V CV!)\n', r.rpm_of_sp, r.rpm_of_sp_maxres, r.sp_hover);
f('Standby draw sp 50      : %.2f W (subtracted from U*I)\n', r.Pidle);
f('kQ ESTIMATE (eta*Pnet/w^3), eta = [%s]:\n', num2str(r.eta));
f('   at hover point      : %s e-8 Nm/(rad/s)^2\n', num2str(r.kQ_hover*1e8,'%.1f '));
f('   LS over >=2000 rpm  : %s e-8\n', num2str(r.kQ_ls*1e8,'%.1f '));
f('   Cp at hover         : %s  (Ct %.3f)  Cp/Ct = %s\n', num2str(r.Cp_hover,'%.4f '), r.Ct_hover, num2str(r.CpCt_hover,'%.3f '));
f('   kQ/kT               : %s mm\n', num2str(r.kQkT_ratio*1e3,'%.1f '));
f('   eta loss budget     : hover %.2f, top %.2f (datasheet R, I0)\n', r.eta_budget_hover, r.eta_budget_top);
f('   fit_motor_coeffs kQ method (bus current as phase current): %.1f e-8 (biased low)\n', r.kQ_fitscript*1e8);
g = r.gate;
f('SWE1-MDL-003 gate on run 3: accepted=%d reason="%s" n=%d kT=%.3f uN R2=%.5f relres=%.3f\n', ...
  g.accepted, g.reason, g.n_used, g.kT*1e6, g.kT_R2, g.kT_res_rel);
f('\n%-26s %12s %12s\n', ['m = ' num2str(m) ' kg'], 'old', 'new');
for fld = {'kT','kQ','tau','w_max','w_hover','rpm_hover','hover_frac_wmax','T_max_total','TW_max','hover_frac_Tmax','yaw_per_w2'}
    f('%-26s %12.4g %12.4g\n', fld{1}, r.old.(fld{1}), r.new.(fld{1}));
end
f('measured top: 4 x %.0f g = %.1f N -> T/W %.2f\n', r.T_max/9.81*1e3, r.new.T_max_meas_total, r.new.TW_max_meas);
end
