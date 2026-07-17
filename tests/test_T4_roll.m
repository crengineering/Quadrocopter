function test_T4_roll
%T4  Roll-Vorzeichen: M3,M4 schneller, M1,M2 langsamer -> p>0 (Roll rechts), phi>0.
evalin('base','quad_params;');                     % sauberer Ausgangszustand
wh = evalin('base','w_hover');
assignin('base','w_cmd', wh*[0.95; 0.95; 1.05; 1.05]);   % [M1 M2 M3 M4]

out = quad_run(0.3, 'quad_model_ST');
p  = getcomp(out,'om', 1);
ph = getcomp(out,'phi',1);
assert(p(end)  > 0, 'p nicht > 0 (p_end=%.3f) -- Mixer-Vorzeichen (Roll) pruefen', p(end));
assert(ph(end) > 0, 'phi nicht > 0 (phi_end=%.4f)', ph(end));
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
