function identify_feather(s)
% First check that the board is a uDACS
[subfunc,desc] = get_subfunction(s);
if subfunc ~= 18
  error('Expected subfunction 18 for Feather M4 CAN Express. Reported %d', subfunc);
end
BoardID = read_subbus(s,2);
Build = read_subbus(s,3);
[SerialNo,SNack] = read_subbus(s,4);
[InstID,InstIDack] = read_subbus(s,5);

% Rev set to A for uDACS16 until Rev B
Rev = 'A';

if BoardID == 0
  BdCfg = 'Test';
elseif BoardID == 1
  BdCfg = 'FOCAL Gas Deck Shield'
elseif BoardID == 2
  BdCfg = 'FOCAL CO2 Optical Enclosure Shield';
elseif BoardID == 3
  BdCfg = 'FOCAL CH4 Optical Enclosure Shield';
elseif BoardID == 4
  BdCfg = 'FOCAL Bay Shield';
elseif BoardID == 5
  BdCfg = 'FOCAL GPS';
elseif BoardID == 6
  BdCfg = 'FOCAL Accelerometer';
else
  BdCfg = 'Test';
end

fprintf(1, 'Attached to Feather M4 CAN Express S/N %d Build # %d\n', SerialNo, Build);
fprintf(1, 'Board is Rev %s configured as "%s"\n', Rev, BdCfg);
fprintf(1, 'The description is "%s"\n', desc);


rm_obj = read_multi_prep([8,40,9,0]);
[vals,~] = read_multi(s,rm_obj);
even = mod(vals(2:end),256);
odd = floor(vals(2:end)/256);
il = [even odd]';
il = il(:)';
nc = find(il == 0,1);
il = il(1:(nc-1));
desc = char(il);
fprintf(1,'Description from FIFO is: %s\n', desc);
%fprintf(1, 'Now figure out how to interpret the result\n');
