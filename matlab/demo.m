%% Load the twix file and get calibration data out
[fn, pathname, ~] = uigetfile(strcat(path,'\*.dat'), 'Pick a DATA file');
twix = mapVBVD(fullfile(pathname,fn));

twix.refscan.flagRemoveOS=1;
calibdata=twix.refscan{''};
calibdata=permute(calibdata,[2 1 3 4]); %[COIL x COL x LIN x PAR]

%Noise decorrlate the data
D=calcNoiseDecorrMatrix(twix);
calibdata=performNoiseDecorr(calibdata,D);

% get image size and zeropad the data
sKspace=twix.hdr.Phoenix.sKSpace;
ImSize=[sKspace.lBaseResolution sKspace.lPhaseEncodingLines sKspace.lPartitions];
calibdata=zeropad(calibdata,[size(calibdata,1) ImSize]); %coil first

%% ecalib
dtStr = datetime('now','TimeZone','local','Format','d_MMM_y_HH_mm_ss');
calibfilename=fullfile(getenv('TEMP'),sprintf('Calibdata_%s.h5',dtStr));
outfile=fullfile(getenv('TEMP'),sprintf('csm_%s.h5',dtStr));
BARTcmd='ecalib -m 2 -k 4 -r 24:24:24';
[pathFolder,calibfilename]=data2ismrmrd_2(calibdata,BARTcmd, calibfilename);


cmdStr{1}=fullfile(pathFolder,'..\\IsmrmrdClient-win10-x64-Release\\gadgetron_ismrmrd_client ');
cmdStr{2}=sprintf(' -f %s ',calibfilename);
% cmdStr{3}=sprintf(' -C %s\\..\\gadgetron\\piv_pics.xml ',pathFolder); % local config
cmdStr{3}=sprintf(' -c piv_ecalib.xml '); % remote config
cmdStr{4}=' -a 10.41.60.157 -p 9002 ';
cmdStr{5}=sprintf(' -o %s ',outfile);
 [status,cmdout] = system(strcat(cmdStr{:}));
% read the coil maps back
[csm_test,header,file_info]=readH5File(outfile);
%% pics demo for data with integrated ACS
% BARTcmd should have ecalib and pics command seperated by ; 
ksp_us=calibdata; %undersampled kspace data with ACS

dtStr = datetime('now','TimeZone','local','Format','d_MMM_y_HH_mm_ss');
calibfilename=fullfile(getenv('TEMP'),sprintf('refdata_%s.h5',dtStr));
outfile=fullfile(getenv('TEMP'),sprintf('im_pics_%s.h5',dtStr));
BARTcmd='ecalib -m 2 -k 4 -r 24:24:24; pics -i100 -RW:1:2:0.01';
[pathFolder,calibfilename]=data2ismrmrd_2(ksp_us,BARTcmd, calibfilename);

%assemble gadgetron command
cmdStr{1}=fullfile(pathFolder,'..\\IsmrmrdClient-win10-x64-Release\\gadgetron_ismrmrd_client ');
cmdStr{2}=sprintf(' -f %s ',calibfilename);
% cmdStr{3}=sprintf(' -C %s\\..\\gadgetron\\piv_pics.xml ',pathFolder); % local config
cmdStr{3}=sprintf(' -c piv_pics.xml '); % remote config
cmdStr{4}=' -a 10.41.60.157 -p 9002 ';
cmdStr{5}=sprintf(' -o %s ',outfile);
[status,cmdout] = system(strcat(cmdStr{:}));

% read image
[imout,header,file_info]=readH5File(outfile);

%% Clean up
delete(fullfile(getenv('TEMP'),'Calibdata_*.h5'))
delete(fullfile(getenv('TEMP'),'csm_*.h5'))

%% supporting functions
function data_decorr=performNoiseDecorr(data,D)

sz     = size(data);
data_decorr   = D*data(:,:);
data_decorr    = reshape(data_decorr,sz);
end

function D=calcNoiseDecorrMatrix(twix)
if isfield(twix,'noise')
    noise                = permute(twix.noise(:,obj.flags.CoilSel,:),[2,1,3]);
    noise                = noise(:,:).';
    R                    = cov(noise);
    R(eye(size(R,1))==1) = abs(diag(R));
    scale_factor=1; %dwell time are the same
    Rinv = inv(chol(R,'lower')).';
    obj.D = Rinv*sqrt(2)*sqrt(scale_factor);
else
    obj.D = 1;
end
end