function test_T8_energy
%T8  Energieerhaltung (reibungsfrei): 1/2*v^2 muss g*Fallhoehe entsprechen.
evalin('base','quad_params;');                     % sauberer Ausgangszustand
assignin('base','Cd', zeros(3));
assignin('base','w_cmd', [0;0;0;0]);               % freier Fall aus Ruhe

out = quad_run(1, 'quad_model_ST');
w = getcomp(out,'v_b',  3);
z = getcomp(out,'p_ned',3);
g = evalin('base','g');

KE = 0.5*w(end)^2;                                  % kinetische Energie / Masse
PE = g*(z(end)-z(1));                               % z waechst nach unten -> Fallhoehe > 0
assert(abs(KE - PE)/max(PE,eps) < 1e-3, ...
    'Energie inkonsistent: 1/2 v^2=%.4f, g*dh=%.4f', KE, PE);
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
