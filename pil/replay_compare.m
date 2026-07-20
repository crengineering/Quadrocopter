function res = replay_compare(rp, y, tol)
%REPLAY_COMPARE  Vergleicht Target-Ausgaben gegen die SiL-Referenz.
%
%   res = replay_compare(rp, y)
%   res = replay_compare(rp, y, tol)
%
%   rp   Struktur aus replay_export (Felder t, yref)
%   y    [N x 17] Antworten aus replay_udp
%   tol  Struktur mit absoluten Toleranzen je Signalgruppe, optional
%
%   Rueckgabe: Tabelle mit max. Abweichung je Kanal und Bewertung.

if nargin < 3, tol = struct(); end
if ~isfield(tol,'T'),   tol.T   = 1e-3;  end     % N
if ~isfield(tol,'phi'), tol.phi = 1e-4;  end     % rad
if ~isfield(tol,'om'),  tol.om  = 1e-3;  end     % rad/s
if ~isfield(tol,'tau'), tol.tau = 1e-5;  end     % Nm
if ~isfield(tol,'w'),   tol.w   = 1e-2;  end     % rad/s
if ~isfield(tol,'I'),   tol.I   = 1e-5;  end     % Nm

names = { 'T_soll', ...
          'phi_soll(1)','phi_soll(2)','phi_soll(3)', ...
          'om_soll(1)','om_soll(2)','om_soll(3)', ...
          'tau_soll(1)','tau_soll(2)','tau_soll(3)', ...
          'w_cmd(1)','w_cmd(2)','w_cmd(3)','w_cmd(4)', ...
          'tau_I(1)','tau_I(2)','tau_I(3)' };

tolvec = [tol.T, repmat(tol.phi,1,3), repmat(tol.om,1,3), ...
          repmat(tol.tau,1,3), repmat(tol.w,1,4), repmat(tol.I,1,3)];

d      = y - rp.yref;
maxabs = max(abs(d), [], 1).';
status = strings(numel(names),1);
for k = 1:numel(names)
    if maxabs(k) <= tolvec(k)
        status(k) = "ok";
    else
        status(k) = "ABWEICHUNG";
    end
end

res = table(string(names).', maxabs, tolvec.', status, ...
    'VariableNames', {'Signal','MaxAbw','Toleranz','Status'});

nBad = sum(status == "ABWEICHUNG");
fprintf('\n=== Vektor-Replay: Target gegen SiL ===\n');
disp(res);
if nBad == 0
    fprintf('Alle %d Kanaele innerhalb der Toleranz.\n\n', numel(names));
else
    fprintf('%d von %d Kanaelen ausserhalb der Toleranz.\n\n', nBad, numel(names));
end

% --- Plots ----------------------------------------------------------
groups = { 1,        'Schub T';
           2:4,      'Lage-Sollwinkel';
           5:7,      'Soll-Drehraten';
           8:10,     'Soll-Momente';
           11:14,    'Motordrehzahlen';
           15:17,    'Integratorzustand' };

figure('Name','Vektor-Replay: Abweichung Target - SiL');
for g = 1:size(groups,1)
    subplot(3,2,g);
    plot(rp.t, d(:, groups{g,1}));
    grid on; title(groups{g,2});
    xlabel('t [s]'); ylabel('Abweichung');
end
end
