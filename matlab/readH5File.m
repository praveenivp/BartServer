function [data,header,file_info]=readH5File(fileName)
%[data,header,file_info]=readH5File(fileName)
% limited reader for reading ISMRMRD image data only!

file_info=h5info(fullfile(fileName));

temp=file_info;
while(isempty(temp.Datasets))
    temp=temp.Groups(end); %read the last one
end

%%
data=cell(length(temp.Datasets),1);
for i=1:length(temp.Datasets)
data{i}=h5read(fileName,strcat(temp.Name,'/',temp.Datasets(i).Name));
end
if(length(data)==3 && isfield(data{2},'real'))
    header=data{3};
    data=complex(data{2}.real,data{2}.imag);

else
    header='should be in data{2}';
end

end