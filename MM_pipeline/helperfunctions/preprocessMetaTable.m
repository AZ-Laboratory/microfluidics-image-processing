function meta = preprocessMetaTable(metaname)
% Read and preprocess the metadata table
opts = detectImportOptions(metaname);
% Define columns and their desired types
charColumns = {'Exclude', 'Note', 'register', 'stardist', 'stardist_fails', 'delta', 'delta_fails'};
doubleColumns = {'MaxFr', 'Process', 'StageX', 'StageY', 'PxinUmX', 'PxinUmY',...
    'MiddleRow', 'Top1Bot0FRow', 'nchambers', 'rotation', 'firstframe', 'prerotate',...
    'rep2firstframe','rep2startdifferencemin','rep2delaymin'};

% Update VariableTypes for specified columns
for colName = [charColumns, doubleColumns]
    colType = 'char';
    if ismember(colName, doubleColumns)
        colType = 'double';
    end
    opts.VariableTypes{strcmp(opts.VariableNames, colName)} = colType;
end
meta = readtable(metaname, opts);
meta = sortrows(meta, {'replicate', 'pos'}, 'ascend');
end