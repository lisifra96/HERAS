function y = physconst(x)
% PHYSCONST  Return physical constants in SI units
% Syntax: y = physconst(x);
%
% x == 'LightSpeed' is currently the only valid input, in which case the 
% vacuum speed of light in units of [m/s] is returned.

switch x 
case 'LightSpeed'
    y = 299792458.0
otherwise
    error('Invalid input')
end

end

