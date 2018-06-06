function [x,y,z,s1,n,m] = MakefromSPH(SPHterms, dirs, N)
%% generate dirs covering a uniform sampling of the collection angle (Currently Just a Hemisphere)
[a,~] = size(dirs);
m = sqrt(a);
n = m;
Y_N = getSH(N, dirs, 'real'); % calculate spherical harmonic terms
F_N = SPHterms;
testf = Y_N*F_N; %sample sph distribution at desired angles
[xtest,ytest,ztest] = sph2cart(dirs(:,1)-pi,dirs(:,2)+pi/2,testf);

x = reshape(xtest,m,n);
y = reshape(ytest,m,n);
z = reshape(ztest,m,n);

s1(:,:,1) = x;
s1(:,:,2) = y;
s1(:,:,3) = z;
end

