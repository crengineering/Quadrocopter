function test_T6_yaw
%T6  Yaw-Vorzeichen: CCW-Motoren M1,M3 schneller -> r>0 (Nase rechts), psi>0.
evalin('base','quad_params;');                     % sauberer Ausgangszustand
wh = evalin('base','w_hover');
assignin('base','w_cmd', wh*[1.05; 0.95; 1.05; 0.95]);

out = quad_run(0.3, 'quad_model_ST');
r  = getcomp(out,'om', 3);
ps = getcomp(out,'phi',3);
assert(r(end)  > 0, 'r nicht > 0 (r_end=%.3f) -- Mixer-Vorzeichen (Yaw/kQ) pruefen', r(end));
assert(ps(end) > 0, 'psi nicht > 0 (psi_end=%.4f)', ps(end));
end

% ---- Lokale Helfer (Signalzugriff) ----------------------------------------
function ts = getsig(out, name)
%GETSIG  Geloggtes Signal 'name' als timeseries aus out.logsout holen.
el = out.logsout.get(name);
if isempty(el)
    error('quad:signal', ...
        'Signal ''%s'' nicht in logsout gefunden -- Logging im Modell pruefen.', name);
end
if isa(el, 'Simulink.SimulationData.Dataset')      % doppelte Signalnamen
    el = el{1};
end
ts = el.Values;
end

function x = getcomp(out, name, i)
%GETCOMP  i-te Komponente des Signals 'name' ueber der Zeit (Spaltenvektor).
ts = getsig(out, name);
d  = ts.Data;
if ndims(d) == 3                                   % Logform [3x1xN]
    x = squeeze(d(i,1,:));
else                                               % Logform [Nx3]
    x = d(:,i);
end
x = x(:);                                          % immer Spaltenvektor
end
