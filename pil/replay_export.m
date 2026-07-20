function rp = replay_export(out, Ts)
%REPLAY_EXPORT  Extrahiert Ein- und Referenzausgaenge aus einem SiL-Lauf.
%
%   rp = replay_export(out)        Ts = 0.001 (Default)
%   rp = replay_export(out, Ts)
%
%   'out' ist das Simulink-Ergebnis (Simulink.SimulationOutput) eines Laufs
%   mit der C-Code-Variante. Alle benoetigten Signale muessen benannt und
%   mit Log-Haken markiert sein:
%
%     Eingaenge      p_ned_soll, p_ned, v_b, phi, om
%     Referenzen     T_soll, phi_soll, om_soll, tau_soll, w_cmd, tau_I
%
%   Rueckgabe rp mit Feldern:
%     t     [N x 1]   Zeitvektor auf dem Ts-Raster
%     u     [N x 16]  Eingaenge, Spaltenreihenfolge wie im UDP-Paket
%     yref  [N x 17]  Referenzausgaenge aus der SiL-Simulation
%
%   Spaltenbelegung u:
%     1:3   p_ned_soll      4:6   p_ned_ist     7:9   v_b_ist
%     10    psi_soll        11:13 phi_ist       14:16 om_ist
%
%   Spaltenbelegung yref:
%     1     T_soll          2:4   phi_soll      5:7   om_soll
%     8:10  tau_soll        11:14 w_cmd         15:17 tau_I

if nargin < 2, Ts = 0.001; end

% --- Zeitraster aufbauen -------------------------------------------
ts_ref = getsig(out, 'p_ned');
t0 = ts_ref.Time(1);
t1 = ts_ref.Time(end);
t  = (t0:Ts:t1).';

% --- Eingaenge ------------------------------------------------------
p_soll = resamp(out, 'p_ned_soll', t, 3);
p_ist  = resamp(out, 'p_ned',      t, 3);
v_b    = resamp(out, 'v_b',        t, 3);
phi    = resamp(out, 'phi',        t, 3);
om     = resamp(out, 'om',         t, 3);

psi_soll = zeros(numel(t), 1);          % feste Fuehrungsgroesse

rp.u = [p_soll, p_ist, v_b, psi_soll, phi, om];   % [N x 16]

% --- Referenzausgaenge ---------------------------------------------
T_soll   = resamp(out, 'T_soll',   t, 1);
phi_soll = resamp(out, 'phi_soll', t, 3);
om_soll  = resamp(out, 'om_soll',  t, 3);
tau_soll = resamp(out, 'tau_soll', t, 3);
w_cmd    = resamp(out, 'w_cmd',    t, 4);
tau_I    = resamp(out, 'tau_I',    t, 3);

rp.yref = [T_soll, phi_soll, om_soll, tau_soll, w_cmd, tau_I];   % [N x 17]
rp.t    = t;
rp.Ts   = Ts;

fprintf('Replay-Vektoren: %d Takte, %.2f s\n', numel(t), t(end)-t(1));
end

% =====================================================================

function v = resamp(out, name, t, n)
%RESAMP  Signal auf das Ts-Raster bringen, als [numel(t) x n].
ts = getsig(out, name);
d  = ts.Data;
if ndims(d) == 3
    d = squeeze(d).';                    % [3x1xN] -> [N x 3]
end
if size(d,2) ~= n
    d = reshape(d, [], n);
end
v = interp1(ts.Time, d, t, 'previous', 'extrap');   % ZOH, wie im Regler
end

function ts = getsig(out, name)
el = out.logsout.get(name);
if isempty(el)
    error('replay:nolog', ...
        'Signal "%s" ist nicht geloggt (benennen + Log-Haken setzen).', name);
end
if isa(el, 'Simulink.SimulationData.Dataset'), el = el{1}; end
ts = el.Values;
end
