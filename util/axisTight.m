function varargout = axisTight(p)
% Not quite as tight as "axis tight"
% AE 2013-01-23

if ~nargin
    p = 0.05;
end
axis tight
ax = axis;
x = ax(2) - ax(1);
y = ax(4) - ax(3);
ax = ax + p * [-x x -y y];
axis(ax)
if nargout
    varargout{1} = ax;
end
