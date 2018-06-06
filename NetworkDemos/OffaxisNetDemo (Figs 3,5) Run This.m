%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Neural Network Demonstrations
% 
%
% Made By: Caleb Gannon
% June 5 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialization
clc
clear variables
close all

load OffaxisNet.mat 
load offAxisDirectionSamples.mat

%% Net inputs <- Change these values!!!!
x0 =300; %target length (x)
y0 = 300; %target height (y)


designpoints = [x0;y0]; % input parameters into the network
netoutput = net(designpoints);
alpha = netoutput(1);
beta = netoutput(2); % first two net outputs are tilt parameters
SPHterms = netoutput(3:end);

[x2,y2,z2,s2,n,m]  = MakefromSPH(SPHterms, dirs, 10); % build the surface from SPH terms

figure;
surf(x2,y2,z2) % plot the surface

%% Send Surface to LightTools and Raytrace (Wont work if you don't have LightTools!)
% tested on LightTools(65) 8.5.0
lt=actxserver('lighttools.ltapi4');
lm=actxserver('ltcom64.ltapi2');
js=actxserver('ltcom64.jsml');
NewV3D(js,lt);

Lo = 500;
Wo = 500;
Dtarg = 3000; %distance from the source to the target
MakeDummyPlane(js,lt,x0,y0,-Dtarg,0,0,1,'N','Rectangular',2*Lo,2*Wo,'myDummy');
MakeReceiver(js,lt,'myDummy','dummyplane','myreceiver');

%% Define Reciever Boundaries, gridsize and kernel size

MeshWidth = 1.5*Lo;MeshHeight=1.5*Wo;gridsize = 81;
LTDbSet(lm,lt,'receiver[1].mesh[1]','X_Dimension',gridsize);
LTDbSet(lm,lt,'receiver[1].mesh[1]','Y_Dimension',gridsize);
LTDbSet(lm,lt,'receiver[1].mesh[1]','Min_X_Bound',-MeshWidth);
LTDbSet(lm,lt,'receiver[1].mesh[1]','Max_X_Bound',MeshWidth);
LTDbSet(lm,lt,'receiver[1].mesh[1]','Min_Y_Bound',-MeshHeight);
LTDbSet(lm,lt,'receiver[1].mesh[1]','Max_Y_Bound',MeshHeight);
LTDbSet(lm,lt,'receiver[1].mesh[1]','Kernel_Size_N',5);

%% Import the Reflector and define its properties
lt.Cmd('FreeformSheet XYZ 0,0,0 XYZ 0,0,1 XYZ 0,1,0');
reflector=LTDbGet(lm,lt,'solid[@last]','name');
Surface = 'LENS_MANAGER[1].COMPONENTS[Components].SOLID[FreeformEntity_3].FREEFORM_PRIMITIVE[FreeformPrimitive_1].FREEFORM_SURFACE[FreeformSurface]';


lt.SetFreeformSurfacePoints(Surface,s2,49,49);
tiltkey = 'LENS_MANAGER[1].COMPONENTS[Components].SOLID[FreeformEntity_3].FREEFORM_PRIMITIVE[FreeformPrimitive_1]';
LTDbSet(lm,lt,tiltkey,'Alpha_Relative',alpha);
LTDbSet(lm,lt,tiltkey,'Beta_Relative',beta);

 % Setup the Source
source_diameter = 0.01;
source_height = 0.01;
MakeSourceSurfaceCube(js,lt,source_height,source_diameter,source_diameter,'MyLED',0,0,0,0,0,-1);
% x0 = 0; y0 = 0; z0 = 0; %location of the point source
MoveVector(js,lt,'MyLED',0,0,-source_height);
thetamax =85;
SetSourceAimSphere(js,lt,'MyLED','Aim Region','Yes',0,0,0,thetamax);
power = 1;
Num_Rays = 15E4;
SetSourcePower(js,lt,'MyLED',power,'watts','Automatic');
LTDbSet(lm,lt,'MyLED','Direction_Apodizer_Type','Cosine');
LTCmd(lm,lt,'\V3D BeginAllSimulations');
LTDbSet(lm,lt,'LENS_MANAGER[1].ILLUM_MANAGER[Illumination_Manager].SIMULATIONS[ForwardAll]','MaxProgress',Num_Rays);
LTCmd(lm,lt,'\V3D BeginAllSimulations');
