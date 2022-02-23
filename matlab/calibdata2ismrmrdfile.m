%% we need two paramters
%ref
% ref=r1.twix.refscan('');
% ref2=removeOS(permute(ref,[1 3 4 2]));
% load('C:\Users\pvalsala\Documents\Packages2\ecalib gadget\data\ref.mat')
% ref2=ref2(:,:,:,1:4);
% ImSize=[64 64 16 4];

data2ismrmrd(calib(:,:,:,:),'ecalib -m 1 -t 0.00001 -k 7:7:7 -r 24:24:24' ,'calib.h5')

%% send to BART
cmdStr{1}='C:\Users\pvalsala\Documents\Packages2\BartServer\IsmrmrdClient-win10-x64-Release\gadgetron_ismrmrd_client ';
cmdStr{2}=' -f ..\matlab\calib.h5 ';
cmdStr{3}=' -C ..\gadgetron\ecalib.xml ';
cmdStr{4}=' -a 10.41.60.157 -p 9020 ';
cmdStr{5}=' -o out_m1.h5 ';
[status,cmdout] = system(strcat(cmdStr{:}));

%% get bask the data

[csm1,header,file_info]=readH5File('out.h5');
