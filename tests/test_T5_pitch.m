function test_T5_pitch
%T5  Pitch-Vorzeichen: M1,M4 (vorn) schneller -> q>0 (Nase hoch), theta>0.
evalin('base','quad_params;');                     % sauberer Ausgangszustand
wh = evalin('base','w_hover');
assignin('base','w_cmd', wh*[1.05; 0.95; 0.95; 1.05]);

out = quad_run(0.3);
q  = getcomp(out,'om', 2);
th = getcomp(out,'phi',2);
assert(q(end)  > 0, 'q nicht > 0 (q_end=%.3f) -- Mixer-Vorzeichen (Pitch) pruefen', q(end));
assert(th(end) > 0, 'theta nicht > 0 (theta_end=%.4f)', th(end));
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
