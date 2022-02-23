function [data,header,file_info]=readH5File(fn)

file_info=h5info(fullfile(fn));


temp=file_info;
while(isempty(temp.Datasets))
    temp=temp.Groups(end); %read the last one
end

%%
data=cell(length(temp.Datasets),1);
for i=1:length(temp.Datasets)
data{i}=h5read(fn,strcat(temp.Name,'/',temp.Datasets(i).Name));
end
if(length(data)==3 && isfield(data{2},'real'))
    header=data{3};
    data=complex(data{2}.real,data{2}.imag);

else
    header='should be in data{2}';
end

end