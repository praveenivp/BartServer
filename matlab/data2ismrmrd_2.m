function [pathFolder,filename]=data2ismrmrd_2(data,BARTcmd, filename)
% [pathFolder,filename]=data2ismrmrd(data,BARTcmd, filename)
%
%data: Reference scan data [COIL x COL x LIN x PAR]
% This version only stores non-zero acqusitions: good for streaming and
% storage requirements
assert(ndims(data)<5,'4D dataset expected [COIL x COL x LIN x PAR]');
if(nargin<2)
    filename = 'Calibdata.h5';
    BARTcmd ='ecalib -k 6 -t 0.00001 -m 2';
end

pathFolder=mfilename('fullpath');
[pathFolder, ~, ~] = fileparts(pathFolder);
% Create an empty ismrmrd dataset
if exist(filename,'file')
    warning(['File ' filename ' already exists.  overwriting'])
    delete(filename)
end
dset = ismrmrd.Dataset(filename);

% permute and get number of non-zero acquistions
data=permute(data,[2 3 4 1]);
[nX,nY,nZ,nCoils,nRep]=size(data);
mask=squeeze(abs(sum(data,[1 4])))>0;
Nacq=sum(mask,'all');

% It is very slow to append one acquisition at a time, so we're going
% to append a block of acquisitions at a time.
% In this case, we'll do it one repetition at a time to show off this
% feature.  Each block has nY aquisitions
acqblock = ismrmrd.Acquisition(Nacq);


% Set the header elements that don't change
acqblock.head.version(:) = 1;
acqblock.head.number_of_samples(:) = nX;
acqblock.head.center_sample(:) = floor(nX/2);
acqblock.head.active_channels(:) = nCoils;
acqblock.head.read_dir  = repmat([1 0 0]',[1 Nacq]);
acqblock.head.phase_dir = repmat([0 1 0]',[1 Nacq]);
acqblock.head.slice_dir = repmat([0 0 1]',[1 Nacq]);

% Loop over the acquisitions, set the header, set the data and append
counter=1;
for acqno = 1:nY*nZ*nRep
    [iy,iz, rep]=ind2sub([nY nZ nRep],acqno);
    if(sum(data(:,iy,iz,:,rep),'all')==0 )
        continue;
    end

    % Set the header elements that change from acquisition to the next
    % c-style counting

    acqblock.head.scan_counter(counter) = (rep-1)*nY*nZ + acqno-1;
    acqblock.head.idx.kspace_encode_step_1(counter) = iy-1;
    acqblock.head.idx.kspace_encode_step_2(counter) = iz-1;
    acqblock.head.idx.repetition(counter) = rep-1;

    % Set the flags
    acqblock.head.flagClearAll(counter);

    % fill the data
    acqblock.data{counter} = squeeze(data(:,iy,iz,:,rep));
    counter=counter+1;
end
assert(counter-1==Nacq,'Number of acquistions doesnot match');
acqblock.head.flagSet('ACQ_FIRST_IN_ENCODE_STEP1', 1);
acqblock.head.flagSet('ACQ_FIRST_IN_SLICE', 1);
acqblock.head.flagSet('ACQ_FIRST_IN_REPETITION', 1);

acqblock.head.flagSet('ACQ_LAST_IN_ENCODE_STEP1', Nacq);
acqblock.head.flagSet('ACQ_LAST_IN_SLICE', Nacq);
acqblock.head.flagSet('ACQ_LAST_IN_REPETITION', Nacq);

% Append the acquisition block
dset.appendAcquisition(acqblock);



%%%%%%%%%%%%%%%%%%%%%%%%
%% Fill the xml header %
%%%%%%%%%%%%%%%%%%%%%%%%
% We create a matlab struct and then serialize it to xml.
% Look at the xml schema to see what the field names should be

header = [];

% Experimental Conditions (Required)
header.experimentalConditions.H1resonanceFrequency_Hz = 128000000; % 3T

% Acquisition System Information (Optional)
header.acquisitionSystemInformation.systemVendor = 'ISMRMRD Labs';
header.acquisitionSystemInformation.systemModel = 'Virtual Scanner';
header.acquisitionSystemInformation.receiverChannels = nCoils;

% The Encoding (Required)
header.encoding.trajectory = 'cartesian';
header.encoding.encodedSpace.fieldOfView_mm.x = nX;
header.encoding.encodedSpace.fieldOfView_mm.y = nY;
header.encoding.encodedSpace.fieldOfView_mm.z = nZ;
header.encoding.encodedSpace.matrixSize.x = size(data,1);
header.encoding.encodedSpace.matrixSize.y = size(data,2);
header.encoding.encodedSpace.matrixSize.z = size(data,3);
% Recon Space
% (in this case same as encoding space)
header.encoding.reconSpace = header.encoding.encodedSpace;
% Encoding Limits
header.encoding.encodingLimits.kspace_encoding_step_0.minimum = 0;
header.encoding.encodingLimits.kspace_encoding_step_0.maximum = nX-1;
header.encoding.encodingLimits.kspace_encoding_step_0.center = floor(nX/2);
header.encoding.encodingLimits.kspace_encoding_step_1.minimum = 0;
header.encoding.encodingLimits.kspace_encoding_step_1.maximum = nY-1;
header.encoding.encodingLimits.kspace_encoding_step_1.center = floor(nY/2);
header.encoding.encodingLimits.kspace_encoding_step_2.minimum = 0;
header.encoding.encodingLimits.kspace_encoding_step_2.maximum = nZ-1;
header.encoding.encodingLimits.kspace_encoding_step_2.center = floor(nZ/2);
header.encoding.encodingLimits.repetition.minimum = 0;
header.encoding.encodingLimits.repetition.maximum = 0;
header.encoding.encodingLimits.repetition.center = 0;
header.userParameters.userParameterString(1).name = 'BARTcmd';
header.userParameters.userParameterString(1).value = BARTcmd;
header.userParameters.userParameterString(2).name = 'deafult';
header.userParameters.userParameterString(2).value = 'ecalib -k 6 -t 0.00001 -m 2';
%% Serialize and write to the data set
xmlstring = ismrmrd.xml.serialize(header);
dset.writexml(xmlstring);

%% Write the dataset
dset.close();

end
