% GPFA analysis
% AE 2012-11-20


%% Covariance explained
% this analysis looks at the norm of the difference between observed
% covariance matrix and that predicted by the GPFA model
covExpl('subject_id IN (9, 11)', 'sort_method_num = 5', 'kfold_cv = 2', 'transform_num = 2')
