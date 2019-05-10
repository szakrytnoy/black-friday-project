% P R A C T I C A L
% A S S I G N M E N T
% *********************************************************
% *********************************************************

%% Import data and define categorical variables

% Import Existing Data
bf=importBlackFriday('BlackFriday.csv');
names = bf.Properties.VarNames;
% Convert all the categorical variables into nominal arrays
[nrows, ncols] = size(bf);
category = false(1,ncols);
for i = 1:ncols
    if isa(bf.(names{i}),'cell') 
        category(i) = true;
        bf.(names{i}) = categorical(bf.(names{i}));
    end
end
clear category nrows ncols
%% dataset adjustments
% The data shows all purchase made by the customer, each row represent a
% product id. For our purposed analysis we want to have a dataset where
% each customer is being represented by a row. For this we have to
% determine a set of rules.
% 1. Each product is categorize in three product categories, we are going
% to analize the first category since it represents the most suitable group
% for the product. To achieve this we are going to drop variables
% Product_Category_2 and Product_category_3.
keepVar={'User_ID','Gender','Age','Occupation','City_Category',...
	'Stay_In_Current_City_Years','Marital_Status','Product_Category_1',...
	'Purchase'};
X=bf(:,keepVar);

% 2. Group data by user_ID. To do this we are going to aggregate the
% Purchase variable as a sum of the product category purchased.
Xgrp=grpstats(X,keepVar(1:end-1),{'sum'},'DataVars','Purchase');

% 3. Now we want to define what is the prefered product category and a
% second prefered category as new variables. To do this we are going to
% compare the categories by the value of the purchase; if a product
% category has higher amount of purchase then we are assuming it means that
% the user is willing to spent more in that particular category which we
% consider as a preference than the other. If a user only has one product
% category then we are going to create another variable representing this
% information, 'one_cat' with value 1 if TRUE and 0 if FALSE, and set the
% second prefered category equal as the first.

% Sort data by User_ID and Purchase value
Xgrp=sortrows(Xgrp,{'User_ID','sum_Purchase'},{'ascend','descend'});
% Define top two prefered categories
Xgrp.numCat=0;
Xgrp.numCat(1)=1;
for i=2:size(Xgrp,1)
	if Xgrp.User_ID(i)==Xgrp.User_ID(i-1)
		Xgrp.numCat(i)=Xgrp.numCat(i-1)+1;
	else
		Xgrp.numCat(i)=1;
	end
end
Xgrp2=Xgrp(find(Xgrp.numCat<3),:);
% Define new variable prefCat1 and prefCat2
Xgrp2.prefCat1=Xgrp2.Product_Category_1;
Xgrp2.prefCat2=Xgrp2.Product_Category_1;
% Determine prefered categories purchase value
Xgrp2.totPurchase=0;
Xgrp2.prefCount=0;
% if user only bought 1 type of product
Xgrp2.oneProduct=0;

for i=1:size(Xgrp2,1)
	if Xgrp2.numCat(i)==2
		Xgrp2.prefCat2(i-1)=Xgrp2.prefCat2(i);
		Xgrp2.totPurchase(i-1)=Xgrp2.sum_Purchase(i)+Xgrp2.sum_Purchase(i-1);
		Xgrp2.prefCount(i-1)=Xgrp2.GroupCount(i)+Xgrp2.GroupCount(i-1);
	else
		Xgrp2.totPurchase(i)=Xgrp2.sum_Purchase(i);
		Xgrp2.prefCount(i)=Xgrp2.GroupCount(i);
	end
end
keepXgrp2={'User_ID','Gender','Age','Occupation','City_Category',...
	'Stay_In_Current_City_Years','Marital_Status',...
	'totPurchase','oneProduct','prefCat1','prefCat2','prefCount'};
% create new dataset
Xgrp3=Xgrp2(find(Xgrp2.numCat<2),keepXgrp2);
% add total purchase and total products
Xgrp3=join(Xgrp3,grpstats(X,'User_ID',{'sum'},'DataVars','Purchase'));
% clean and order dataset
Xgrp3.Properties.ObsNames=[];
Xgrp3.Properties.VarNames{8} = 'prefPurchase';
Xgrp3.Properties.VarNames{13} = 'totCount';
Xgrp3.Properties.VarNames{14} = 'totPurchase';
Xgrp3.Properties.VarNames{6} = 'CityYears';
newCityYears={'0','1','2','3','4gt'};
Xgrp3.CityYears=renamecats(Xgrp3.CityYears,newCityYears);
newAge={'0_17','18_25','26_35','36_45','46_50','51_55','55gt'};
Xgrp3.Age=renamecats(Xgrp3.Age,newAge);
clear newCityYears newAge;

% create to ratio variables between number of products and purchase value
Xgrp3.preftotPurchase=Xgrp3.prefPurchase./Xgrp3.totPurchase;
Xgrp3.preftotCount=Xgrp3.prefCount./Xgrp3.totCount;
Xgrp3=Xgrp3(:,[1 2 3 4 5 6 7 10 11 9 12 13 16 8 14 15]);

% exploratory analysis
figure;
histogram(double(Xgrp3.prefCat1));
title('Highest category preference');
figure;
histogram(Xgrp3.prefCat2);
% Based on the histograms, users prefer categories 1,5 and 8. For easy
% handling, we are going to define this three groups and the rest as 19
% since there are only 18 classes.
Xgrp3.prefCat1((Xgrp3.prefCat1~=categorical(1) & ...
	Xgrp3.prefCat1~=categorical(5) & ...
	Xgrp3.prefCat1~=categorical(8)))=categorical(19);
Xgrp3.prefCat2((Xgrp3.prefCat2~=categorical(1) & ...
	Xgrp3.prefCat2~=categorical(5) & ...
	Xgrp3.prefCat2~=categorical(8)))=categorical(19);
Xgrp3.oneProduct=Xgrp3.prefCat1==Xgrp3.prefCat2;
figure;
histogram(Xgrp3.oneProduct)
figure;
histogram(Xgrp3.preftotCount)
xlabel('% preferred product category')
ylabel('count')
title('% Preferred category of total')
figure;
histogram(Xgrp3.preftotPurchase)
xlabel('% preferred product category purchase')
ylabel('count')
title('% Preferred category purchase of total')

% Create new dataset with dummy variables for each categorical variable
Xgrp4=Xgrp3;
varnm={'Age'};
B=cat2vars(Xgrp4,varnm);
Xgrp4=[Xgrp4 B(:,[2:end])];
varnm={'City_Category'};
B=cat2vars(Xgrp4,varnm);
Xgrp4=[Xgrp4 B(:,[2:end])];
varnm={'CityYears'};
B=cat2vars(Xgrp4,varnm);
Xgrp4=[Xgrp4 B(:,[2:end])];
varnm={'prefCat1'};
B=cat2vars(Xgrp4,varnm);
Xgrp4=[Xgrp4 B(:,[2:end])];
varnm={'prefCat2'};
B=cat2vars(Xgrp4,varnm);
Xgrp4=[Xgrp4 B(:,[2:end])];
clear B varnm
% change logical variables to numbers
Xgrp4.Gender=double(Xgrp4.Gender=='M');
Xgrp4.Marital_Status=double(Xgrp4.Marital_Status=='1');
Xgrp4.oneProduct=double(Xgrp4.oneProduct);

% cluster analysis

% Xgrp4.Properties.VarNames(32:end-4)';
% data=Xgrp4(:,[2 7 10:13 16:end]); % no purchase value
% data=Xgrp4(:,[2 7 10:end]); % all data
data=Xgrp4(:,[13:26 32:end-4]);% DEFINITIVE: no logical values and
% second preferred
data = dataset2table(data);
% data=normalize(data);
% data=normalize(data,'scale');
data=normalize(data,'range');
data=table2array(data);
rng(14,'twister')
noclust=2:10;
[cidx2 cmeans2 sumd2]=...
	kmeans(data,noclust(1),'dist','sqeuclidean','replicates',10);
[cidx3 cmeans3 sumd3]=...
	kmeans(data,noclust(2),'dist','sqeuclidean','replicates',10);
[cidx4 cmeans4 sumd4]=...
	kmeans(data,noclust(3),'dist','sqeuclidean','replicates',10);
[cidx5 cmeans5 sumd5]=...
	kmeans(data,noclust(4),'dist','sqeuclidean','replicates',10);
[cidx6 cmeans6 sumd6]=...
	kmeans(data,noclust(5),'dist','sqeuclidean','replicates',10);
[cidx7 cmeans7 sumd7]=...
	kmeans(data,noclust(6),'dist','sqeuclidean','replicates',10);
[cidx8 cmeans8 sumd8]=...
	kmeans(data,noclust(7),'dist','sqeuclidean','replicates',10);
[cidx9 cmeans9 sumd9]=...
	kmeans(data,noclust(8),'dist','sqeuclidean','replicates',10);
[cidx10 cmeans10 sumd10]=...
	kmeans(data,noclust(9),'dist','sqeuclidean','replicates',10);

% silhouette analysis to determine number of clusters
% [S2,H2] = silhouette(data, cidx2,'sqeuclid');
S2 = silhouette(data, cidx2,'sqeuclid');
S3 = silhouette(data, cidx3,'sqeuclid');
S4 = silhouette(data, cidx4,'sqeuclid');
S5 = silhouette(data, cidx5,'sqeuclid');
S6 = silhouette(data, cidx6,'sqeuclid');
S7 = silhouette(data, cidx7,'sqeuclid');
S8 = silhouette(data, cidx8,'sqeuclid');
S9 = silhouette(data, cidx9,'sqeuclid');
S10 = silhouette(data, cidx10,'sqeuclid');

a=[mean(S2),mean(S3),mean(S4),mean(S5),...
	mean(S6),mean(S7),mean(S8),mean(S9),mean(S10)]

[cidx2_cos cmeans2_cos sumd2_cos]=...
	kmeans(data,noclust(1),'dist','cosine','replicates',10);
[cidx3_cos cmeans3_cos sumd3_cos]=...
	kmeans(data,noclust(2),'dist','cosine','replicates',10);
[cidx4_cos cmeans4_cos sumd4_cos]=...
	kmeans(data,noclust(3),'dist','cosine','replicates',10);
[cidx5_cos cmeans5_cos sumd5_cos]=...
	kmeans(data,noclust(4),'dist','cosine','replicates',10);
[cidx6_cos cmeans6_cos sumd6_cos]=...
	kmeans(data,noclust(5),'dist','cosine','replicates',10);
[cidx7_cos cmeans7_cos sumd7_cos]=...
	kmeans(data,noclust(6),'dist','cosine','replicates',10);
[cidx8_cos cmeans8_cos sumd8_cos]=...
	kmeans(data,noclust(7),'dist','cosine','replicates',10);
[cidx9_cos cmeans9_cos sumd9_cos]=...
	kmeans(data,noclust(8),'dist','cosine','replicates',10);
[cidx10_cos cmeans10_cos sumd10_cos]=...
	kmeans(data,noclust(9),'dist','cosine','replicates',10);

% silhouette analysis to determine number of clusters
% [S2,H2] = silhouette(data, cidx2,'cosine');
S2_cos = silhouette(data, cidx2_cos,'cosine');
S3_cos = silhouette(data, cidx3_cos,'cosine');
S4_cos = silhouette(data, cidx4_cos,'cosine');
S5_cos = silhouette(data, cidx5_cos,'cosine');
S6_cos = silhouette(data, cidx6_cos,'cosine');
S7_cos = silhouette(data, cidx7_cos,'cosine');
S8_cos = silhouette(data, cidx8_cos,'cosine');
S9_cos = silhouette(data, cidx9_cos,'cosine');
S10_cos = silhouette(data, cidx10_cos,'cosine');


b=[mean(S2_cos),mean(S3_cos),mean(S4_cos),mean(S5_cos),...
	mean(S6_cos),mean(S7_cos),mean(S8_cos),mean(S9_cos),mean(S10_cos)]

figure;
plot(a)
hold on;
plot(b)
legend('Euclidean','Cosine')
title('No gender, marital and 2nd preferred  - range normalization')
% After running different normalization methods and two distances namely
% squared euclidean and cosine, our silhouette scores shows us that 4
% clusters are the more suitable number for grouping the users using cosine
% distance. However, the value was low and some of the variables were not
% impacting the cluster much. Based on this, we start removing variables
% that their cluster mean was the same and see if we can improve the
% clustering process.
% Finally, we achieved a 0.425 silhouette score with six cluster and the
% following variables:
% ratio of preferable categories respect the total categories purchased
% preferable categories purchase value
% total purchase value
% ratio of preferable purchase value
% age
% city
% preferable category

% It is important to notice that the second preferable category was
% weighting strongly the clustering though with lower silhouette score,
% 0.238.
% Based on the previous results we decide to continue our analysis with 6
% clusters using cosine distance.
centers_clusters=cmeans6_cos;
clusterInd=cidx6_cos;
clear cidx10 cidx10_cos cidx2 cidx2_cos cidx3 cidx3_cos cidx4 cidx4_cos
clear cidx5 cidx5_cos cidx6 cidx6_cos cidx7 cidx7_cos cidx8 cidx8_cos
clear cidx9 cidx9_cos cmeans10 cmeans10_cos cmeans9 cmeans9_cos
clear cmeans8 cmeans8_cos cmeans7 cmeans7_cos cmeans6 cmeans6_cos
clear cmeans5 cmeans5_cos cmeans4 cmeans4_cos cmeans3 cmeans3_cos
clear cmeans2 cmeans2_cos S2 S2_cos S3 S3_cos S4 S4_cos S5 S5_cos
clear S6 S6_cos S7 S7_cos S8 S8_cos S9 S9_cos S10 S10_cos
clear sumd2 sumd2_cos sumd3 sumd3_cos sumd4 sumd4_cos sumd5 sumd5_cos
clear sumd6 sumd6_cos sumd7 sumd7_cos sumd8 sumd8_cos sumd9 sumd9_cos
clear sumd10 sumd10_cos

% Xgrp3.Properties.VarNames;
Xgrp3.Cluster=clusterInd;
% Xgrp3.Cluster(1:20)
figure;
scatter(Xgrp3(:,5),Xgrp3(:,8),[],Xgrp3.Cluster,'filled')
title('City - Prefered Category')
figure;
scatter(Xgrp3(:,6),Xgrp3(:,5),[],Xgrp3.Cluster,'filled')
title('City - Prefered Category')

% additional charts