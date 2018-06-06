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

load goodrectnet.mat 
load varlist.mat
load directionSamples.mat
load spheresurface.mat

%% Net inputs <- Change these values!!!!
Lo =1200; %target half length (x/2) Trained between 1000 and 2000
Wo = 1200; %target half height (y/2) Trained between 1000 and 2000 
Dtarg = 700; %distance from the source to the target, trained between 1000 and 1500

designpoints = [Lo;Wo;Dtarg]; % vector that is input to the network
netoutput = net(designpoints);
SPHterms(varlist)=netoutput; %add zeros for terms removed due to symmetry

[x2,y2,z2,s2,n,m]  = MakefromSPH(SPHterms', dirs, 10); % build the surface

figure;
surf(x2,y2,z2)

%% Send Surface to LightTools and Raytrace (Wont work if you don't have LightTools!)
% tested on LightTools(65) 8.5.0

lt=actxserver('lighttools.ltapi4'); %ltapi4 enables freeform surfaces
lm=actxserver('ltcom64.ltapi2');
js=actxserver('ltcom64.jsml');
NewV3D(js,lt);

%% Setup the Reciever
MakeDummyPlane(js,lt,0,0,Dtarg,0,0,-1,'N','Rectangular',2*Lo,2*Wo,'myDummy');
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
lt.Cmd('FreeformSolid XYZ 0,0,0 XYZ 0,0,1 XYZ 0,1,0');
lens=LTDbGet(lm,lt,'solid[@last]','name');
LTDbSet(lm,lt,lens,'Material','PMMA');
RearSurface = 'LENS_MANAGER[1].COMPONENTS[Components].SOLID[FreeformEntity_3].FREEFORM_PRIMITIVE[FreeformPrimitive_1].FREEFORM_SURFACE[RearSurface]';
FrontSurface = 'LENS_MANAGER[1].COMPONENTS[Components].SOLID[FreeformEntity_3].FREEFORM_PRIMITIVE[FreeformPrimitive_1].FREEFORM_SURFACE[FrontSurface]';
lt.SetFreeformSurfacePoints(RearSurface,s1,81,81);
lt.SetFreeformSurfacePoints(FrontSurface,s2,n,m);

 % Setup the Source
source_diameter = 0.01;
source_height = 0.01;
MakeSourceSurfaceCube(js,lt,source_height,source_diameter,source_diameter,'MyLED',0,0,0,0,0,-1);
x0 = 0; y0 = 0; z0 = 0; %location of the point source
MoveVector(js,lt,'MyLED',x0,y0,z0-source_height);
thetamax =70;
SetSourceAimSphere(js,lt,'MyLED','Aim Region','Yes',0,0,0,thetamax);
power = 1;
Num_Rays = 15E4;
SetSourcePower(js,lt,'MyLED',power,'watts','Automatic');
LTDbSet(lm,lt,'MyLED','Direction_Apodizer_Type','Cosine');

% Set The Number of Rays to Trace and initialize simulations 
LTCmd(lm,lt,'\V3D BeginAllSimulations');
LTDbSet(lm,lt,'LENS_MANAGER[1].ILLUM_MANAGER[Illumination_Manager].SIMULATIONS[ForwardAll]','MaxProgress',Num_Rays);
LTCmd(lm,lt,'\V3D BeginAllSimulations');