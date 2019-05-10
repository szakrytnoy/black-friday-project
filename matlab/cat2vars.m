function newdataset=cat2vars(xc,varnm)
% cat2vars creates a dataset with additional dummy variables representing
% the corresponding categorical variable.
% xc is the dataset
% varnm is the name of the categorical variable
	[~,ind,~]=intersect(xc.Properties.VarNames,varnm);
	newdataset=xc(:,ind);
	cats=unique(xc.(varnm{1}));
	for i=1:size(cats,1)
		cv=double(xc.(varnm{1})== cats(i));
		ct=strcat(varnm{1},'_',char(cats(i)));
		A=table(cv);
		A.Properties.VariableNames{1}=ct;
		newdataset=[newdataset table2dataset(A)];
	end
end