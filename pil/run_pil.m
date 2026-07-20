function res = run_pil(varargin)
%RUN_PIL  Kompletter Vektor-Replay gegen den TC399, reproduzierbar.
%
%   res = run_pil()                     alles mit Defaults
%   res = run_pil('Name', Wert, ...)    einzelne Optionen ueberschreiben
%
%   Ablauf:
%     1. Modell simulieren (C-Code-Variante)
%     2. Ein- und Referenzvektoren extrahieren
%     3. ueber UDP ans Target schicken, Antworten einsammeln
%     4. vergleichen, Laufzeit auswerten, Ergebnis ablegen
%
%   Optionen:
%     Model       Modellname                Default 'quad_model_control'
%     StopTime    Simulationsdauer in s     Default 20
%     IP          Ziel-IP des Targets       Default '192.168.0.10'
%     Port        Ziel-Port                 Default 5556
%     MaxTakte    Begrenzung der Takte      Default inf (alle)
%     ShiftTauI   Integrator um 1 Takt      Default true
%                 verschieben (Simulink loggt I[k-1], Target meldet I[k])
%     Save        Ergebnis als .mat sichern Default true
%     OutDir      Ablageordner              Default 'pil/results'
%
%   Beispiele:
%     res = run_pil();
%     res = run_pil('StopTime', 5, 'MaxTakte', 2000);
%     res = run_pil('IP', '192.168.0.11', 'Save', false);

% ------------------------------------------------------------------
% Optionen
% ------------------------------------------------------------------
p = inputParser;
p.addParameter('Model',     'quad_model_control', @(x)ischar(x)||isstring(x));
p.addParameter('StopTime',  20,        @isnumeric);
p.addParameter('IP',        '192.168.0.10', @(x)ischar(x)||isstring(x));
p.addParameter('Port',      5556,      @isnumeric);
p.addParameter('MaxTakte',  inf,       @isnumeric);
p.addParameter('ShiftTauI', true,      @islogical);
p.addParameter('Save',      true,      @islogical);
p.addParameter('OutDir',    fullfile('pil','results'), @(x)ischar(x)||isstring(x));
p.parse(varargin{:});
o = p.Results;

t_ges = tic;
fprintf('\n========================================\n');
fprintf(' Vektor-Replay  %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('========================================\n\n');

% ------------------------------------------------------------------
% 1  Simulation
% ------------------------------------------------------------------
fprintf('[1/4] Simulation %s, %g s ...\n', o.Model, o.StopTime);
out = quad_run(o.StopTime, char(o.Model));

% ------------------------------------------------------------------
% 2  Vektoren extrahieren
% ------------------------------------------------------------------
fprintf('\n[2/4] Vektoren extrahieren ...\n');
rp = replay_export(out);

if isfinite(o.MaxTakte) && o.MaxTakte < size(rp.u,1)
    n = round(o.MaxTakte);
    rp.t    = rp.t(1:n);
    rp.u    = rp.u(1:n,:);
    rp.yref = rp.yref(1:n,:);
    fprintf('      auf %d Takte begrenzt.\n', n);
end

% ------------------------------------------------------------------
% 3  Replay
% ------------------------------------------------------------------
fprintf('\n[3/4] Replay ans Target ...\n');
cfg = struct('ip', char(o.IP), 'port', o.Port);
[y, t_us] = replay_udp(rp.u, cfg);

% ------------------------------------------------------------------
% 4  Vergleich
% ------------------------------------------------------------------
fprintf('\n[4/4] Vergleich ...\n');

rpc = rp;
yc  = y;
if o.ShiftTauI
    % Simulink loggt den Integrator vor der Aktualisierung (I[k-1]),
    % das Target meldet ihn danach (I[k]). Um einen Takt ausrichten.
    yc(1:end-1, 15:17)   = y(1:end-1, 15:17);
    rpc.yref(1:end-1,15:17) = rp.yref(2:end, 15:17);
    rpc.t    = rp.t(1:end-1);
    rpc.yref = rpc.yref(1:end-1,:);
    yc       = yc(1:end-1,:);
    fprintf('      Integratorzustand um einen Takt ausgerichtet.\n');
end

tab = replay_compare(rpc, yc);

% ------------------------------------------------------------------
% Ergebnis
% ------------------------------------------------------------------
res.zeit        = datestr(now, 'yyyy-mm-dd HH:MM:SS');
res.model       = char(o.Model);
res.stopTime    = o.StopTime;
res.nTakte      = size(rp.u,1);
res.ip          = char(o.IP);
res.port        = o.Port;
res.tabelle     = tab;
res.t_us        = t_us;
res.exec_min    = min(t_us);
res.exec_mean   = mean(t_us);
res.exec_max    = max(t_us);
res.auslastung  = 100*max(t_us)/1000;    % Prozent bei 1 ms Takt
res.nAbweichung = sum(tab.Status == "ABWEICHUNG");
res.rp          = rp;
res.y           = y;

fprintf('\n--- Zusammenfassung ---\n');
fprintf('  Takte            : %d\n', res.nTakte);
fprintf('  Kanaele ausserhalb: %d von %d\n', res.nAbweichung, height(tab));
fprintf('  Laufzeit Target  : min %.1f / mean %.1f / max %.1f us\n', ...
        res.exec_min, res.exec_mean, res.exec_max);
fprintf('  Auslastung 1 ms  : %.1f %%\n', res.auslastung);

if o.Save
    if ~exist(o.OutDir, 'dir'), mkdir(o.OutDir); end
    fn = fullfile(o.OutDir, ...
         sprintf('pil_%s.mat', datestr(now, 'yyyymmdd_HHMMSS')));
    save(fn, 'res');
    fprintf('  Ergebnis         : %s\n', fn);
end

fprintf('  Gesamtdauer      : %.1f s\n\n', toc(t_ges));
end
