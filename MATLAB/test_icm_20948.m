%%
clc
% serial_port_clear;
if exist('s') == 1
  clear s
end

[s,port] = serial_port_init('',19200,2);
addr.cmd = 48;
%
identify_feather(s);
%
[icm_mode,icm_fs] = report_icm_mode(s);
%%
thisres = test_fast_mode2(s,0,256); figure; plot(thisres.a);
%%
test_lockup(s,0);
%%
% Fast mode diagnostics: Just look at accumulating FIFO counts without
% actually retrieving them
test_fast_mode(s,0);
%%
test_fast_mode3(s, 0, 250);
%%
test_mode_switch(s,0,0);
%%
test_mode_switches(s);
%%
for fs = 0:3
  test_slow_mode(s,fs);
end
%%
test_slow_mode(s,3)

%%
% serial_port_clear;
clear s

%%
identify_feather(s);
[icm_mode,icm_fs] = report_icm_mode(s);
%% fast2
clear res;
mr_stat =  read_multi_prep(100, 103);
for i=1:-1:1
  [diag,ack] = read_subbus( ...
    s,103); % try to clear diag before test
  thisres = test_fast_mode2(s, 0, 256);
  res(i) = thisres;
  % res(i).Nread = sum(res(i).stats(1:end-1,2));
  while true
    [values,ack] = read_multi(s,mr_stat);
    if values(1) == 0 && values(2) == 0; break; end
    fprintf(1,'+');
  end
end
fprintf(1,'\nMean Nread is %.1f +/- %.1f\n', mean([res.Nread]), std([res.Nread]));
%%
thisres = test_fast_mode2(s,0,256); figure; plot(thisres.a);
%%
test_fast_mode3(s, 0, 250);
%%
function test_fast_mode3(s, fs, N)
  % test_fast_mode2(s, fs. N);
  % s werial object
  % fs full scale code 0-3
  % N number of samples per plot
  % res.stats cols are:
  %   toc values
  %   mode (0x64)
  %   internal diagnostic (0x67)
  %   FIFO count (0x65)
  %   nrows (FIFO count/3)
  fig = figure;
  opts.start = 1;
  opts.fs = 0;
  fig.UserData = opts;
  uimenu(fig,'Text','Stop', ...
          'Callback', @(s,e)set_opt(fig,0,0), ...
          'Interruptible', 'off');
  ax = axes(fig);
  res.a = zeros(N,3);
  res.stats = zeros(N,5);
  Nread = 0;
  res.Nstats = 0;
  res.Nread = 0;
  % ICM FIFO N Bytes, uDACS FIFO N Words, FIFO Contents
  rm_obj = read_multi_prep(100, 103, [101 495 102 0]);
  % rm_obj = read_multi_prep(100, 103, 101);
  write_subbus_v(s, 48, 50+fs);
  write_subbus_v(s, 48, 40+2);
  Fs = 515; % Should calibrate this...
  N2 = floor(N/2);
  x = 1:N2;
  f = x*Fs/N;
  leftover = [];
  n_leftover = 0;
  max_amp = 0;
  Nmem = 20;
  mem = zeros(N2,Nmem);
  imem = 1;
  
  tic;
  cur_time = toc;
  while fig.UserData.start
    [values,ack] = read_multi(s, rm_obj);
    if ack ~= 1; break; end
    nwords = length(values) - 3 + n_leftover;
    remainder = mod(nwords,3);
    nrows = (nwords-remainder)/3;
    stats = [values(1:3)' nrows];
    if any(stats ~= [2+(fs*8) 0 0 0])
      res.Nstats = res.Nstats+1;
      res.stats(res.Nstats,:) = [toc stats];
    end
    if values(1) ~= 2
      break;
    end
    vals = values(4:end);
    Vneg = vals >= 32768;
    if any(Vneg)
      vals(Vneg) = vals(Vneg)-65536;
    end
    if Nread + nrows > N
      remainder = remainder + (Nread+nrows-N)*3;
      nrows = N-Nread;
    end
    res.a(Nread+(1:nrows),:) = ...
      reshape([leftover; vals(1:end-remainder)],3,[])';
    Nread = Nread + nrows;
    res.Nread = Nread;
    if Nread == N
      res.a = res.a * 2^(fs+1) / 32768;
      A = res.a - ones(length(res.a),1)*mean(res.a);
      YA = fft(A)/N;
      VA = vecnorm(YA,2,2);
      maxVA = max(VA);
      if maxVA > max_amp
        max_amp = maxVA;
      end
      mem(:,imem) = VA(x);
      max_mem = max(mem,[],2);
      imem = mod(imem,Nmem)+1;
      plot(ax,f,VA(x,:),f,max_mem,'.');
      set(ax,'ylim',[0 max_amp],'xgrid','on','ygrid','on');
      % plot(ax,res.a);
      title(ax, sprintf('T = %.1f',cur_time));
      drawnow;
      Nread = 0;
    end
    if remainder
      leftover = vals(end-remainder+(1:remainder));
    else
      leftover = [];
    end
    n_leftover = remainder;
    cur_time = toc;
  end
  res.fin_fin_ack = write_subbus_v(s, 48, 40);
  delete(fig);
end

function set_opt(fig, start, fs)
  fig.UserData.start = start;
  fig.UserData.fs = fs;
end

function res = test_fast_mode2(s, fs, N)
  % res = test_fast_mode2(s, fs. N);
  % res.stats cols are:
  %   toc values
  %   mode (0x64)
  %   internal diagnostic (0x67)
  %   FIFO count (0x65)
  %   nrows (FIFO count/3)
  fprintf(1, 'test_fast_mode2(%d,%d)\n', fs, N);
  res.a = zeros(N,3);
  res.stats = zeros(N,5);
  Nread = 0;
  res.Nstats = 0;
  res.Nread = 0;
  % ICM FIFO N Bytes, uDACS FIFO N Words, FIFO Contents
  rm_obj = read_multi_prep(100, 103, [101 495 102 0]);
  % rm_obj = read_multi_prep(100, 103, 101);
  write_subbus_v(s, 48, 50+fs);
  write_subbus_v(s, 48, 40+2);
  tic;

  leftover = [];
  n_leftover = 0;
  while Nread < N && res.Nstats < N
    [values,ack] = read_multi(s, rm_obj);
    if ack ~= 1; break; end
    nwords = length(values) - 3 + n_leftover;
    remainder = mod(nwords,3);
    nrows = (nwords-remainder)/3;
    stats = [values(1:3)' nrows];
    if any(stats ~= [2+(fs*8) 0 0 0])
      res.Nstats = res.Nstats+1;
      res.stats(res.Nstats,:) = [toc stats];
    end
    if bitand(values(1),7) ~= 2
      break;
    end
    vals = values(4:end-remainder);
    if ~isempty(vals)
      try
        Vneg = vals >= 32768;
        if any(Vneg)
          vals(Vneg) = vals(Vneg)-65536;
        end
        res.a(Nread+(1:nrows),:) = ...
          reshape([leftover; vals],3,[])';
      catch
        fprintf(1,'Error on reshape: nwords:%d remainder:%d nrows:%d\n', nwords, remainder, nrows);
        return;
      end
    end
    Nread = Nread + nrows;
    res.Nread = Nread;
    if remainder
      try
        leftover = vals(end-remainder+(1:remainder));
      catch
        fprintf(1,'leftover\n');
      end
    else
      leftover = [];
    end
    n_leftover = remainder;
  end
  res.a = res.a * 2^(fs+1) / 32768;
  res.stats = res.stats(1:res.Nstats,:);
  res.dur = toc;
  res.fin_ack = ack;
  res.fin_fin_ack = write_subbus_v(s, 48, 40);
end

function ack = write_subbus_v(s, addr, value)
  [ack,line] = write_subbus(s, addr, value);
  if ack == -2
    fprintf(1,'ack -2 on write_subbus: "%s"\n', line);
  end
end

function test_lockup(s, fs)
  % Just 
  fprintf(1, '\ntest_lockup(%d)\n', fs);
  write_subbus(s, 48, 50+fs);
  write_subbus(s, 48, 40+2);
end

function test_fast_mode(s, fs)
  fprintf(1, '\ntest_fast_mode(%d)\n', fs);
  % n_FIFO0 = read_subbus(s, 103); %
  n_FIFO = read_subbus(s, 101); % 0x65
  fprintf(1, '  n_FIFO: %d\n', n_FIFO);
  write_subbus(s, 48, 50+fs);
  dur = 0;
  tic;
  last_report = toc;
  write_subbus(s, 48, 40+2);
  n_FIFO0 = 0;
  increasing = 1;
  mode_nonzero = false;
  while 1
    % n_FIFO0 = read_subbus(s, 103); %
    n_FIFO = read_subbus(s, 101); % 0x65
    mode = bitand(read_subbus(s, 100),7);
    this_report = toc;
    if (~increasing) && (n_FIFO > n_FIFO0)
      last_report = this_report;
      fprintf(1, '%f: mode: %d n_FIFO: %d increasing\n', last_report, mode, n_FIFO);
      increasing = 1;
    elseif increasing && n_FIFO == n_FIFO0
      last_report = this_report;
      fprintf(1, '%f: mode: %d n_FIFO: %d stopped\n', last_report, mode, n_FIFO);
      increasing = 0;
    elseif this_report > last_report+30
      fprintf(1, '%f: mode: %d n_FIFO: %d\n', this_report, mode, n_FIFO);
      last_report = last_report+30;
    end
    n_FIFO0 = n_FIFO;
    if ~mode_nonzero && (mode ~= 0)
      mode_nonzero = true;
    end
    if mode_nonzero && (mode == 0)
      dur = toc;
      break;
    end
    if this_report > 100 && mode == 0
      fprintf(1, '%f: mode: %d n_FIFO: %d\n', last_report, mode, n_FIFO);
    end
    pause(1);
    % fprintf(1, '  %2d: n_FIFO: %d mode: %d\n', i, n_FIFO, mode);
  end
  if dur == 0
    dur = toc;
  end
  write_subbus(s, 48, 40);
  n_FIFO = read_subbus(s, 101); % 0x65
  fprintf(1, '  n_FIFO: %d mode: %d dT = %f\n', n_FIFO, mode, dur);
end

function [icm_mode,icm_fs] = report_icm_mode(s, quiet)
  if nargin < 2
    quiet = 0;
  end
  [icm_mode_fs,ack] = read_subbus(s, 100); % 0x64
  if ~ack
    fprintf(1,'No ACK for ICM Mode: Vibration Sensor apparently not supported\n');
    icm_mode = 0;
    icm_fs = 0;
  else
    icm_mode = bitand(icm_mode_fs,7);
    icm_fs = bitand(icm_mode_fs,24)/8; % (icm_mode_fs%0x18)>>3
    switch icm_mode
      case 0
        mode_text = 'Idle';
      case 1
        mode_text = 'Slow';
      case 2
        mode_text = 'Fast';
      otherwise
        mode_text = 'Unknown';
    end
    if ~quiet
      fprintf(1,'  ICM Mode %d: %s\n', icm_mode, mode_text);
      full_scale = 2*2^icm_fs;
      fprintf(1,'  ICM Full Scale is %d g\n', full_scale);
    end
    % pause(0.5);
    % [accel_cfg_rb,ack] = read_subbus(s, 103); % 0x67
    % fprintf(1,'  ACCEL_CONFIG: %02X\n', accel_cfg_rb);
  end
end

function test_slow_mode(s, fs)
  fprintf(1,'\nTesting Slow Mode operation with fs %d:\n', fs);
  full_scale = 2*2^fs;
  fprintf(1,'  Setting full scale to %d g\n', full_scale);
  ack = write_subbus(s, 48, 50+fs);
  [icm_mode,icm_fs] = report_icm_mode(s);
  fprintf(1,'  Selecting Slow Mode\n');
  ack = write_subbus(s, 48, 41);
  while icm_mode ~= 1
    [icm_mode,icm_fs] = report_icm_mode(s);
  end
  if icm_mode == 1 && icm_fs == fs
    fprintf(1,'  Acquiring data slowly:\n');
    rm_obj = read_multi_prep([hex2dec('61') 1 hex2dec('63')]);
    N = 100;
    tbl = zeros(N,3);
    for i=1:N
      [values,ack] = read_multi(s,rm_obj);
      if ack == 1 && length(values) == 3
        V = values>32767;
        if any(V)
          values(V) = values(V) - 65536;
        end
        if ack == 1
          tbl(i,:) = values;
        end
      else
        fprintf(1,'ack=%d length(values)=%d\n', ack, length(values));
      end
    end
    tbl = full_scale*tbl/32768;
    ax = nsubplots(tbl);
    title(ax(1), sprintf('Full Scale = %d g', full_scale));
  else
    fprintf(1,'Mode:fs values are %d:%d expected %d:%d\n', icm_mode, icm_fs, 1, fs);
  end
  fprintf(1,'\nReturning to No Mode:\n');
  ack = write_subbus(s, 48, 50);
  ack = write_subbus(s, 48, 40);
  [icm_mode,icm_fs] = report_icm_mode(s);
end

function test_mode_switch(s, mode, fs)
  % test_mode_switch(s);
  % s is a serialport object
  write_subbus(s, 48, 50 + fs);
  write_subbus(s, 48, 40 + mode);
  pause(1 );
  icm_i2c_status = read_subbus(s,96); % 0x60
  icm_mode_fs = read_subbus(s, 100); % 0x64
  icm_accel_cfg = read_subbus(s, 103); % 0x67
  fprintf(1, '  %d,%d: mode: 0x%02X  ACCEL_CONFIG: 0x%02X I2c:0x%02X\n', ...
      mode, fs, icm_mode_fs, icm_accel_cfg, icm_i2c_status);
  pause(1);
end

function test_mode_switches(s)
  fprintf(1, '\ntest_mode_switches():\n');
  for mode = 0:1 % skipping fast mode for the moment
    for fs = 0:3
      test_mode_switch(s,mode,fs);
    end
  end
  test_mode_switch(s,0,0);
end
