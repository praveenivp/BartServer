%% we need two paramters
%ref
% ref=r1.twix.refscan('');
% ref2=removeOS(permute(ref,[1 3 4 2]));
% load('C:\Users\pvalsala\Documents\Packages2\ecalib gadget\data\ref.mat')
% ref2=ref2(:,:,:,1:4);
% ImSize=[64 64 16 4];
sig=permute(fmobj_bw930.reco_obj.twix.image(:,:,:,:,1),[2 1 3 4 ]);
D=calcNoiseDecorrMatrix(fmobj_bw930.reco_obj.twix);

calib=permute(performNoiseDecorr(sig,D),[2 3 4 1]);
data2ismrmrd(single(calib(:,:,:,:)),'ecalib -m 2 -k 7:7:7 -r 24:24:24' ,'calib_fm930.h5')

%% send to BART
cmdStr{1}='C:\Users\pvalsala\Documents\Packages2\BartServer\IsmrmrdClient-win10-x64-Release\gadgetron_ismrmrd_client ';
cmdStr{2}=' -f ..\matlab\calib_fm930.h5 ';
cmdStr{3}=' -C ..\gadgetron\ecalib.xml ';
cmdStr{4}=' -a 10.41.60.157 -p 9020 ';
cmdStr{5}=' -o csm_fm930_c24_k7.h5 ';
[status,cmdout] = system(strcat(cmdStr{:}))

%% get bask the data

[csm_test,header,file_info]=readH5File('csm_fm930_c24_k7.h5');


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