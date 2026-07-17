quad_params;
mdl = 'quad_model';
set_param(mdl,'LoadExternalInput','off');

% Trimm-Zustand holen (liest die Modell-ICs)
xs = Simulink.BlockDiagram.getInitialState(mdl);
x0 = []; for k = 1:xs.numElements, x0 = [x0; xs{k}.Values.Data(:)]; end

% Motoren NUR fuer die Linearisierung auf Hover setzen (Modell bleibt unveraendert)
x0(1:4) = w_hover;

u0 = w_hover*ones(4,1);
[A,B,C,D] = linmod(mdl, x0, u0);

disp(x0(1:4)')     % Kontrolle: muss 767 767 767 767 sein
disp(eig(A))