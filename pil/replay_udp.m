function [y, t_us] = replay_udp(u, cfg)
%REPLAY_UDP  Schickt Eingangsvektoren ans Target und sammelt die Antworten.
%
%   [y, t_us] = replay_udp(u)
%   [y, t_us] = replay_udp(u, cfg)
%
%   u     [N x 16]  Eingaenge aus replay_export
%   y     [N x 17]  Reglerausgaenge des Targets
%   t_us  [N x 1]   gemessene Ausfuehrungszeit je Takt in Mikrosekunden
%
%   cfg-Felder (alle optional):
%     ip        Ziel-IP des TC399           Default '192.168.0.10'
%     port      Ziel-Port                   Default 5556
%     localPort lokaler Port                Default 0 (frei waehlen lassen)
%     timeout   Sekunden pro Antwort        Default 1.0
%     reset     Reset vorab senden          Default true
%
%   Protokoll (CtrlReplay.c auf dem Target, laengenbasiertes Framing):
%     STEP     64 Bytes  = 16 x single, little endian
%       Antwort 72 Bytes = 17 x single + 1 x uint32 (Ticks a 10 ns)
%     RESET     1 Byte   = 0x00
%       Antwort  1 Byte  = 0x00
%     NAK       1 Byte   = 0xEE bei ungueltiger Framelaenge
%
%   Transport ueber java.net.DatagramSocket, damit keine Instrument
%   Control Toolbox noetig ist.

if nargin < 2, cfg = struct(); end
if ~isfield(cfg,'ip'),        cfg.ip        = '192.168.0.10'; end
if ~isfield(cfg,'port'),      cfg.port      = 5556;  end
if ~isfield(cfg,'localPort'), cfg.localPort = 0;     end
if ~isfield(cfg,'timeout'),   cfg.timeout   = 1.0;   end
if ~isfield(cfg,'reset'),     cfg.reset     = true;  end

N_IN     = 16;
N_OUT    = 17;
LEN_STEP = N_IN  * 4;        % 64
LEN_RESP = N_OUT * 4 + 4;    % 72
TICK_US  = 0.01;             % 1 Tick = 10 ns

if size(u,2) ~= N_IN
    error('replay:dim', 'u muss %d Spalten haben, hat aber %d.', N_IN, size(u,2));
end

N    = size(u,1);
y    = zeros(N, N_OUT);
t_us = zeros(N, 1);

sock = java.net.DatagramSocket(cfg.localPort);
c    = onCleanup(@() sock.close());
sock.setSoTimeout(round(cfg.timeout * 1000));

addr  = java.net.InetAddress.getByName(cfg.ip);
rxBuf = zeros(1, LEN_RESP, 'int8');
rxPkt = java.net.DatagramPacket(rxBuf, LEN_RESP);

% --- Reset ----------------------------------------------------------
if cfg.reset
    sock.send(java.net.DatagramPacket(int8(0), 1, addr, cfg.port));
    try
        sock.receive(rxPkt);
    catch
        error('replay:noreset', ...
              ['Keine Antwort auf das Reset-Paket. Port %d erreichbar? ' ...
               'Firmware laeuft?'], cfg.port);
    end
    ack = typecast(rxPkt.getData(), 'uint8');
    if rxPkt.getLength() ~= 1 || ack(1) ~= 0
        error('replay:reset', 'Reset quittiert mit 0x%02X statt 0x00.', ack(1));
    end
    rxPkt.setLength(LEN_RESP);
    fprintf('Reset quittiert.\n');
end

% --- Replay ---------------------------------------------------------
fprintf('Sende %d Takte an %s:%d ...\n', N, cfg.ip, cfg.port);
tStart = tic;
for k = 1:N
    txBytes = typecast(single(u(k,:)), 'uint8');
    sock.send(java.net.DatagramPacket(typecast(txBytes,'int8'), ...
                                      LEN_STEP, addr, cfg.port));
    try
        sock.receive(rxPkt);
    catch
        error('replay:timeout', 'Keine Antwort bei Takt %d von %d.', k, N);
    end

    n   = rxPkt.getLength();
    raw = typecast(rxPkt.getData(), 'uint8');

    if n == 1 && raw(1) == 238            % 0xEE
        error('replay:nak', ...
              'Takt %d: Target meldet NAK. Framelaenge %d Bytes stimmt nicht.', ...
              k, LEN_STEP);
    end
    if n ~= LEN_RESP
        error('replay:size', ...
              'Takt %d: %d Bytes empfangen, erwartet %d.', k, n, LEN_RESP);
    end

    y(k,:)  = double(typecast(raw(1:N_OUT*4), 'single'));
    t_us(k) = double(typecast(raw(N_OUT*4+1 : LEN_RESP), 'uint32')) * TICK_US;

    rxPkt.setLength(LEN_RESP);

    if mod(k, 1000) == 0
        fprintf('  %d / %d\n', k, N);
    end
end

el = toc(tStart);
fprintf('Fertig in %.1f s (%.2f ms je Takt inkl. Roundtrip).\n', el, 1000*el/N);
fprintf('Ausfuehrungszeit auf dem Target: min %.1f us, mean %.1f us, max %.1f us\n', ...
        min(t_us), mean(t_us), max(t_us));
fprintf('Auslastung bei 1 ms Takt: %.1f %% (max)\n', 100*max(t_us)/1000);
end
