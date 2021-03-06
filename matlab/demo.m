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
calibdata=zeropad(calibdata,[size(calibdata,1) ImSize]);
%% write calib file and sen it to bart/gadgetron
dtStr = datetime('now','TimeZone','local','Format','d_MMM_y_HH_mm_ss');
calibfilename=fullfile(getenv('TEMP'),sprintf('Calibdata_%s.h5',dtStr));
outfile=fullfile(getenv('TEMP'),sprintf('csm_%s.h5',dtStr));
BARTcmd='ecalib -m 2 -k 6:6:6 -r 24:24:24';
[pathFolder,calibfilename]=data2ismrmrd(calibdata,BARTcmd, calibfilename);


cmdStr{1}=fullfile(pathFolder,'..\\IsmrmrdClient-win10-x64-Release\\gadgetron_ismrmrd_client ');
cmdStr{2}=sprintf(' -f %s ',calibfilename);
cmdStr{3}=sprintf(' -C %s\\..\\gadgetron\\ecalib.xml ',pathFolder);
cmdStr{4}=' -a 10.41.60.157 -p 9002 ';
cmdStr{5}=sprintf(' -o %s ',outfile);
[status,cmdout] = system(strcat(cmdStr{:}));
%% read the coil maps back
[csm_test,header,file_info]=readH5File(outfile);

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
    noise                = permute(twix.noise(:,:,:),[2,1,3]);
    noise                = noise(:,:).';
    R                    = cov(noise);
    R                    = R./mean(abs(diag(R)));
    R(eye(size(R,1))==1) = abs(diag(R));
    D               = sqrtm(inv(R)).';
else
    D = 1;
end
end