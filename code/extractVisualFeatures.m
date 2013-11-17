% for filepath in fbimg/*.jpg; do filename=$(basename $filepath); mkdir conceptFolders/"${filename%,*}"; cp $filepath conceptFolders/"${filename%,*}"; done

% set the demo type to 'tiny' for less computationally expensive settings
opts.demoType = 'tiny';

data.prefix = 'bovw';
data.dir = '/Users/eliabruni/work/2014/personalityRecog';
for pass = 1:2
    data.resultDir = fullfile(data.dir, data.prefix);
    data.imagePathsPath = fullfile(data.resultDir, 'imagePaths.mat');
    data.annotationsPath = fullfile(data.resultDir, 'annotations.mat');
    data.conceptListPath = fullfile(data.resultDir, 'conceptList.mat');
    data.encoderPath = fullfile(data.resultDir, 'encoder.mat');
    data.conceptSpacePath = fullfile(data.resultDir, 'space.txt');
    data.diaryPath = fullfile(data.resultDir, 'diary.txt');
    data.cacheDir = fullfile(data.resultDir, 'cache');
end

% image dataset and annotation folders
opts.datasetParams = {...
    'inputFormat', 'conceptFolder', ...
    'imageDir', '/Users/eliabruni/work/2014/personalityRecog/conceptFolders'};

% feature extraction and encoding parameters
opts.encoderParams = {...
    'type', 'bovw', ...
    'numWords', 4096, ...
    'layouts', {'1x1'}, ...
    'geometricExtension', 'xy', ...
    'numPcaDimensions', 100, ...
    'whitening', true, ...
    'whiteningRegul', 0.01, ...
    'renormalize', true, ...
    'extractorFn', @(x) getDenseSIFT(x, ...
    'step', 4, ...
    'scales', 2.^(1:-.5:-3))};

% concept extraction parameters
opts.conceptExtractParams = {'localization', 'global',...
    'verbose', false};

% tiny settings
if strcmpi(opts.demoType, 'tiny')
    opts.encoderParams = {...
        'type', 'bovw', ...
        'numWords', 128, ...
        'extractorFn', @(x) getDenseSIFT(x, ...
        'step', 4, ...
        'scales', 2.^(1:-.5:-3))};
    % maximum number of images used
    opts.imageLimit = 200;
end



% read dataset
[imagePaths, annotations, conceptList] = ...
    readDataset(opts.datasetParams{:});
save(data.imagePathsPath, 'imagePaths');
save(data.annotationsPath, 'annotations');
save(data.conceptListPath, 'conceptList');


if strcmpi(opts.demoType, 'tiny')
    [imagePaths, annotations] = ...
        randomDatasetSubset(opts.imageLimit, imagePaths, annotations);
end

vl_xmkdir(data.cacheDir);
diary(data.diaryPath); diary on;
disp('options:' ); disp(opts);

if exist(data.encoderPath)
    encoder = load(data.encoderPath);
else
    encoder = trainEncoder(imagePaths, ...
        opts.encoderParams{:});
    save(data.encoderPath, '-struct', 'encoder');
    fprintf('Traning encoder done!\n');
    diary off;
    diary on;
end

% extract the concept space
conceptSpace = extractConcepts(encoder, imagePaths, annotations, ...
    conceptList, opts.conceptExtractParams{:});

writeConceptSpace(conceptSpace, data.conceptSpacePath);


diary off;
diary on;
