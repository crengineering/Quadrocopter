function build_sfun
%BUILD_SFUN  Erzeugt vier S-Function-Bloecke aus dem Regler-C-Code.
%
%   Voraussetzung: MinGW-Compiler installiert (mex -setup C).
%   Ablage: flight_ctrl.c/.h und flight_ctrl_lct.c/.h im selben Ordner.
%
%   Aufruf:  build_sfun
%
%   Ergebnis: vier Bloecke sfun_pos_ctrl, sfun_att_ctrl, sfun_rate_ctrl,
%   sfun_mixer, jeweils als kompilierte mex-Datei plus ein Simulink-Modell
%   mit den maskierten Bloecken zum Hineinkopieren.

here = fileparts(mfilename('fullpath'));
cd(here);

Ts = 0.001;                      % Abtastzeit, muss zu flight_ctrl_lct.c passen
src = {'flight_ctrl.c', 'flight_ctrl_lct.c'};
hdr = {'flight_ctrl_lct.h'};

% ---------------------------------------------------------------
% 1) Positionsregler
% ---------------------------------------------------------------
d(1) = legacy_code('initialize');
d(1).SFunctionName = 'sfun_pos_ctrl';
d(1).OutputFcnSpec = ['void pos_ctrl_lct(single u1[3], single u2[3], ' ...
                      'single u3[3], single u4, single y1[1], single y2[3])'];
d(1).HeaderFiles   = hdr;
d(1).SourceFiles   = src;
d(1).SampleTime    = Ts;

% ---------------------------------------------------------------
% 2) Lageregler
% ---------------------------------------------------------------
d(2) = legacy_code('initialize');
d(2).SFunctionName = 'sfun_att_ctrl';
d(2).OutputFcnSpec = 'void att_ctrl_lct(single u1[3], single u2[3], single y1[3])';
d(2).HeaderFiles   = hdr;
d(2).SourceFiles   = src;
d(2).SampleTime    = Ts;

% ---------------------------------------------------------------
% 3) Ratenregler
%    Zustandsfrei: u3 = Integratorzustand herein, y2 = heraus.
%    In Simulink schliesst ein Unit Delay (Ts, IC = 0) die Schleife
%    von y2 zurueck auf u3.
% ---------------------------------------------------------------
d(3) = legacy_code('initialize');
d(3).SFunctionName = 'sfun_rate_ctrl';
d(3).OutputFcnSpec = ['void rate_ctrl_lct(single u1[3], single u2[3], ' ...
                      'single u3[3], single y1[3], single y2[3])'];
d(3).HeaderFiles   = hdr;
d(3).SourceFiles   = src;
d(3).SampleTime    = Ts;

% ---------------------------------------------------------------
% 4) Mixer
% ---------------------------------------------------------------
d(4) = legacy_code('initialize');
d(4).SFunctionName = 'sfun_mixer';
d(4).OutputFcnSpec = 'void mixer_lct(single u1, single u2[3], single y1[4])';
d(4).HeaderFiles   = hdr;
d(4).SourceFiles   = src;
d(4).SampleTime    = Ts;

% ---------------------------------------------------------------
% Generieren, kompilieren, Bloecke anlegen
% ---------------------------------------------------------------
for k = 1:numel(d)
    fprintf('--- %s ---\n', d(k).SFunctionName);
    legacy_code('sfcn_cmex_generate', d(k));
    legacy_code('compile',            d(k));
end

legacy_code('slblock_generate', d);      % oeffnet Modell mit den Bloecken

fprintf('\nFertig. Die vier Bloecke liegen im geoeffneten Modell.\n');
fprintf('Von dort in quad_model_control kopieren.\n');
end
