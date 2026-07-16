function results = run_all_tests
%RUN_ALL_TESTS  Fuehrt die 6-DoF-MiL-Testsuite aus und fasst das Ergebnis zusammen.
%   Aufruf:  run_all_tests            (Bericht in der Konsole)
%            r = run_all_tests;       (zusaetzlich Ergebnistabelle)
%
%   Erwartete Ablage: run_all_tests.m und die Testdateien im Unterordner tests/,
%   quad_run.m / quad_params.m in der Projektwurzel. Die Signalzugriffs-Helfer
%   (getsig/getcomp) sind lokale Funktionen in jeder Testdatei.

here = fileparts(mfilename('fullpath'));
addpath(here, fileparts(here));             % tests/ + Projektwurzel auf den Pfad

% Testliste in Ausfuehrungsreihenfolge:
tests = { @test_T1_freefall, 'T1  Freier Fall'
          @test_T2_hover,    'T2  Schwebeflug'
          @test_T3_climb,    'T3  Steigflug'
          @test_T4_roll,     'T4  Roll-Vorzeichen'
          @test_T5_pitch,    'T5  Pitch-Vorzeichen'
          @test_T6_yaw,      'T6  Yaw-Vorzeichen'
          @test_T7_yawrate,  'T7  Drallerhaltung'
          @test_T8_energy,   'T8  Energieerhaltung' };

n      = size(tests,1);
status = strings(n,1);
msg    = strings(n,1);

fprintf('\n=== QUAD 6-DoF MiL-Testsuite ===\n\n');
for k = 1:n
    name = tests{k,2};
    try
        tests{k,1}();
        status(k) = "PASS";
        fprintf('  [PASS]  %s\n', name);
    catch e
        if strcmp(e.identifier, 'quad:skip')
            status(k) = "SKIP";  msg(k) = string(e.message);
            fprintf('  [SKIP]  %s   ->  %s\n', name, e.message);
        else
            status(k) = "FAIL";  msg(k) = string(e.message);
            fprintf('  [FAIL]  %s   ->  %s\n', name, e.message);
        end
    end
end

evalin('base','quad_params;');               % Base Workspace auf Defaults zuruecksetzen

nP = sum(status=="PASS");
nF = sum(status=="FAIL");
nS = sum(status=="SKIP");

fprintf('\n--------------------------------------------------\n');
fprintf('  Bestanden: %d/%d    Fehlgeschlagen: %d    Uebersprungen: %d\n', nP, n, nF, nS);
if nF > 0
    fprintf('  Fehlgeschlagen: %s\n', strjoin(tests(status=="FAIL",2), ', '));
end
if nS > 0
    fprintf('  Uebersprungen:  %s\n', strjoin(tests(status=="SKIP",2), ', '));
end
fprintf('--------------------------------------------------\n\n');

if nargout > 0
    results = table((1:n)', string(tests(:,2)), status, msg, ...
        'VariableNames', {'Nr','Test','Status','Meldung'});
end
end
