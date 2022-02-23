function data2ismrmrd(data,BARTcmd, filename)

if(nargin<2)
    filename = 'Calibdata.h5';
    BARTcmd ='ecalib -k 6 -t 0.00001 -m 2';
end

% Create an empty ismrmrd dataset
if exist(filename,'file')
    warning(['File ' filename ' already exists.  overwriting'])
    delete(filename)
end
dset = ismrmrd.Dataset(filename);

% Synthesize the object
[nX,nY,nZ,nCoils,nRep]=size(data);

% It is very slow to append one acquisition at a time, so we're going
% to append a block of acquisitions at a time.
% In this case, we'll do it one repetition at a time to show off this
% feature.  Each block has nY aquisitions
acqblock = ismrmrd.Acquisition(nY*nZ*nRep);

% Set the header elements that don't change
acqblock.head.version(:) = 1;
acqblock.head.number_of_samples(:) = nX;
acqblock.head.center_sample(:) = floor(nX/2);
acqblock.head.active_channels(:) = nCoils;
acqblock.head.read_dir  = repmat([1 0 0]',[1 nY*nZ]);
acqblock.head.phase_dir = repmat([0 1 0]',[1 nY*nZ]);
acqblock.head.slice_dir = repmat([0 0 1]',[1 nY*nZ]);

% Loop over the acquisitions, set the header, set the data and append

for acqno = 1:nY*nZ*nRep
    
    % Set the header elements that change from acquisition to the next
    % c-style counting
    [iy,iz, rep]=ind2sub([nY nZ nRep],acqno);
    acqblock.head.scan_counter(acqno) = (rep-1)*nY*nZ + acqno-1;
    acqblock.head.idx.kspace_encode_step_1(acqno) = iy-1;
    acqblock.head.idx.kspace_encode_step_2(acqno) = iz-1;
    acqblock.head.idx.repetition(acqno) = 0;
    
    % Set the flags
    acqblock.head.flagClearAll(acqno);
    if acqno == 1
        acqblock.head.flagSet('ACQ_FIRST_IN_ENCODE_STEP1', acqno);
        acqblock.head.flagSet('ACQ_FIRST_IN_SLICE', acqno);
        acqblock.head.flagSet('ACQ_FIRST_IN_REPETITION', acqno);
    elseif acqno==nY*nZ
        acqblock.head.flagSet('ACQ_LAST_IN_ENCODE_STEP1', acqno);
        acqblock.head.flagSet('ACQ_LAST_IN_SLICE', acqno);
        acqblock.head.flagSet('ACQ_LAST_IN_REPETITION', acqno);
    end
    
    % fill the data
    acqblock.data{acqno} = squeeze(data(:,iy,iz,:,rep));
end


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
