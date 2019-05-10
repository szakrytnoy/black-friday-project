clc, clear all, close all;

% Parse the csv file with processed data into a dataset
data = dataset('File','databfNorm.csv','ReadVarNames',true,...
               'Delimiter',',');
n = length(data);

% List the variables that represent classes, separate them
classes = {'prefCat1_1','prefCat1_5','prefCat1_8','prefCat1_19'};
X = data;
X(:,ismember(X.Properties.VarNames,classes)) = [];
y_vector = double(data(:, classes));

% Create vector of class labels
y = zeros(n, 1);
for i = 1:n
    [~, y(i)] = max(y_vector(i, :));
end

% Train-test split
train_p = 0.6 ; % Size of the test set
idx = randperm(n); % Randomize index

X_train = X(idx(1:round(train_p*n)), :);
y_train = y(idx(1:round(train_p*n)));
X_test = X(idx(round(train_p*n)+1:end), :);
y_test = y(idx(round(train_p*n)+1:end));

% Growing a tree
tree = fitctree(X_train, y_train); % Fit on training data
imp = predictorImportance(tree);

% Plot importance of predictors
figure;
bar(imp);
title('Predictor Importance Estimates');
ylabel('Importance'); xlabel('Predictors');
h = gca;
set(h,'xtick',1:length(tree.PredictorNames));
h.XTickLabel = tree.PredictorNames;
h.XTickLabelRotation = 45;

y_pred = predict(tree, X_test); % Predict

% Measure accuracy = % of succesful classification
accuracy = sum(y_test == y_pred)/length(y_test)