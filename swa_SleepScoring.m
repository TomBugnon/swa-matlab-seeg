% -- Manual Sleep Scoring GUI -- %
function swa_SleepScoring(varargin)
% GUI to score sleep stages and save the results for further
% processing (e.g. travelling waves analysis)

% Author: Armand Mensen

DefineInterface

function DefineInterface
handles.fig = figure(...
    'Name',         'Sleep Scoring',...
    'NumberTitle',  'off',...
    'Color',        'w',...
    'MenuBar',      'none',...
    'Units',        'normalized',...
    'Outerposition',[0 0.04 .5 0.96]);
% set(handles.fig, 'CloseRequestFcn', {@fcn_close_request});

%% Menus
handles.menu.File = uimenu(handles.fig, 'Label', 'File');
handles.menu.LoadEEG = uimenu(handles.menu.File,...
    'Label', 'Load EEG',...
    'Accelerator', 'L');
handles.menu.SaveEEG = uimenu(handles.menu.File,...
    'Label', 'Save EEG',...
    'Accelerator', 'S');

handles.menu.Options     = uimenu(handles.fig, 'Label', 'Options');
handles.menu.EpochLength = uimenu(handles.menu.Options,...
    'Label', 'Epoch Length');
handles.menu.StartTime   = uimenu(handles.menu.Options,...
    'Label', 'Start Time');
handles.menu.ColorScheme = uimenu(handles.menu.Options,...
    'Label', 'Color Scheme',...
    'Enable', 'off');

handles.menu.Montage      = uimenu(handles.fig, 'Label', 'Montage', 'Enable', 'off');

handles.menu.Export = uimenu(handles.fig, 'Label', 'Export', 'Enable', 'off');
handles.menu.N2  = uimenu(handles.menu.Export,'Label', 'N2');
handles.menu.N3  = uimenu(handles.menu.Export,'Label', 'N3');
handles.menu.REM = uimenu(handles.menu.Export,'Label', 'REM');

handles.menu.Statistics = uimenu(handles.fig, 'Label', 'Statistics', 'Enable', 'off');
% can use html labels here to alter fonts

% menu callbacks
set(handles.menu.LoadEEG,...
    'Callback', {@menu_LoadEEG});
set(handles.menu.SaveEEG,...
    'Callback', {@menu_SaveEEG});

% option callbacks
set(handles.menu.EpochLength,...
    'Callback', {@fcn_options, 'EpochLength'});
set(handles.menu.StartTime,...
    'Callback', {@fcn_options, 'StartTime'});

% montage
set(handles.menu.Montage,...
    'Callback', {@updateMontage, handles.fig});

% set export callbacks
set(handles.menu.N2,...
    'Callback', {@menu_Export, 2});
set(handles.menu.N3,...
    'Callback', {@menu_Export, 3});
set(handles.menu.REM,...
    'Callback', {@menu_Export, 5});

%% Status Bar
handles.StatusBar = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'text',...    
    'String',   'Status Updates',...
    'Units',    'normalized',...
    'Position', [0 0 1 0.03],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);

% get the java handle of the status bar
jStatusBar = findjobj(handles.StatusBar);  
% set the status bar alignments
jStatusBar.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
jStatusBar.setHorizontalAlignment(javax.swing.SwingConstants.LEFT);

% Hidden epoch tracker
% ````````````````````
handles.cEpoch = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'text',...
    'Visible',  'off',...
    'Value',    1);
    
% Create axes
% ``````````````````````````
handles.channel_axes = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.05 0.275, 0.85, 0.675],...
    'nextPlot',     'add'                   ,...
    'color',        [1, 1, 1]         ,...
    'xtick',        []                      ,...
    'ytick',        []                      );

% invisible name axis
handles.label_axes = axes(...
    'parent',       handles.fig             ,...
    'position',     [0 0.275, 0.1, 0.675]   ,...
    'visible',      'off');

% use the third axes to mark arousals
% set(handles.channel_axes(3), 'buttondownfcn', {@fcn_select_events, handles.channel_axes(3), 'buttondown'})

% Scoring Buttons
% ```````````````
handles.bg_Scoring = uibuttongroup(...
    'Title','Stage',...
    'FontName', 'Century Gothic',...
    'FontSize', 11,...
    'FontWeight', 'bold',...
    'BackgroundColor', 'w',...
    'Position',[0.92 0.375 0.05 0.5]);

% Create radio buttons in the button group.
handles.rb(1) = uicontrol('Style','radiobutton',...
    'String','wake','UserData', 0,...
    'Units', 'normalized', 'Position',[0.1 11/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(2) = uicontrol('Style','radiobutton',...
    'String','nrem1','UserData', 1,...
    'Units', 'normalized', 'Position',[0.1 9/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(3) = uicontrol('Style','radiobutton',...
    'String','nrem2','UserData', 2,...
    'Units', 'normalized', 'Position',[0.1 7/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(4) = uicontrol('Style','radiobutton',...
    'String','nrem3','UserData', 3,...
    'Units', 'normalized', 'Position',[0.1 5/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(5) = uicontrol('Style','radiobutton',...
    'String','rem', 'UserData', 5,...
    'Units', 'normalized', 'Position',[0.1 3/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(6) = uicontrol('Style','radiobutton',...
    'String','artifact','UserData', 6,...
    'Units', 'normalized', 'Position',[0.1 1/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');

set(handles.bg_Scoring,'SelectedObject',[]);  % No selection
set(handles.rb, 'BackgroundColor', 'w', 'FontName', 'Century Gothic','FontSize', 10);

% create stage bar
handles.StageBar = uicontrol(...
    'Parent', handles.fig,...    
    'Style',    'text',...    
    'String',   '1: Unscored',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.05 0.935 0.85 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);

% create hyponogram
handles.axHypno = axes(...
    'Parent', handles.fig,...
    'Position', [0.05 0.050 0.85 0.20],...
    'YLim',     [0 6.5],...
    'YDir',     'reverse',...
    'YTickLabel', {'wake', 'nrem1', 'nrem2', 'nrem3', '', 'rem', 'artifact'},...
    'NextPlot', 'add',...
    'FontName', 'Century Gothic',...
    'FontSize', 8);

% scale
handles.et_Scale = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'edit',...    
    'BackgroundColor', 'w',...
    'String',   '200',...
    'value',    200,...
    'Units',    'normalized',...
    'Position', [0.9 0.08+0.245 0.05 0.035],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);

% Set Callbacks
% `````````````
% set hypnogram click
set(handles.axHypno,...
    'ButtonDownFcn', {@bd_hypnoEpochSelect});

% % set(handles.lbCh,...
%     'Callback', {@updateLabel});

set(handles.et_Scale,...
    'Callback', {@updateScale});

set(handles.bg_Scoring,...
    'SelectionChangeFcn', {@updateStage});

set(handles.fig,...
    'KeyPressFcn', {@cb_KeyPressed,});

% Make Figure Visible and Maximise
% ````````````````````````````````
set(handles.fig, 'Visible', 'on');
drawnow; pause(0.001)
jFrame = get(handle(handles.fig),'JavaFrame');
jFrame.setMaximized(true);   % to maximize the figure

guidata(handles.fig, handles) 


% Menu Functions
% ``````````````
function menu_LoadEEG(hObject, ~)

handles = guidata(hObject);

% load dialog box with file type
[dataFile, dataPath] = uigetfile('*.set', 'Please Select Sleep Data');

% just return if no datafile was actually selected
if isequal(dataFile, 0)
    set(handles.StatusBar, 'String', 'Information: No file selected'); drawnow;
    return;
end

% Load the Files
% ``````````````
set(handles.StatusBar, 'String', 'Busy: Loading EEG (May take some time)...'); drawnow;

% load the struct to the workspace
load([dataPath, dataFile], '-mat');
if ~exist('EEG', 'var')
    set(handles.StatusBar, 'String', 'Warning: No EEG structure found in file'); drawnow;
    return;
end

% memory map the actual data...
tmp = memmapfile(EEG.data,...
                'Format', {'single', [EEG.nbchan EEG.pnts EEG.trials], 'eegData'});
eegData = tmp.Data.eegData;
% eegData = mmo(EEG.data, [EEG.nbchan EEG.pnts EEG.trials], false);
% EEG = pop_loadset([dataPath, dataFile]);

set(handles.fig, 'Name', ['Sleep Scoring: ', dataFile]);

% Check for Previous Scoring
% ``````````````````````````
if isfield(EEG, 'swa_scoring')
    EEG.swa_scoring.display_channels = 8;
    % if there is a previously scoring file
    % set the epochlength
%     set(handles.et_EpochLength, 'String', num2str(EEG.swa_scoring.epochLength));  
    sEpoch  = EEG.swa_scoring.epochLength*EEG.srate;
    nEpochs = floor(size(eegData,2)/sEpoch);

    % check whether the scoring file matches the length
    if length(EEG.swa_scoring.stages) ~= EEG.pnts
        fprintf(1, 'previous scoring file a different size as the data, start new scoring session \n');
        % pre-allocate the variables
        % each sample is assigned a stage (255 is default unscored)
        EEG.swa_scoring.stages      = uint8(ones(1,EEG.pnts)*255);
        EEG.swa_scoring.arousals    = logical(zeros(1,EEG.pnts)*255);
        % only every epoch is assigned a name
        EEG.swa_scoring.stageNames  = cell(1, nEpochs);
        EEG.swa_scoring.stageNames(:) = {'Unscored'};
    end
    % check for startTime
    if ~isfield(EEG.swa_scoring, 'startTime')
        EEG.swa_scoring.startTime = 0;
    end
    
else
    EEG.swa_scoring.display_channels = 8;
    % get the default setting for the epoch length from the figure
    EEG.swa_scoring.epochLength = 30;
    % calculate samples per epoch
    sEpoch  = EEG.swa_scoring.epochLength*EEG.srate; % samples per epoch 
    % calculate number of epochs in the entire series
    nEpochs = floor(size(eegData,2)/sEpoch);
    
    % pre-allocate the variables
    % each sample is assigned a stage (255 is default unscored)
    EEG.swa_scoring.stages      = uint8(ones(1,EEG.pnts)*255);
    EEG.swa_scoring.arousals    = logical(zeros(1,EEG.pnts)*255);    
    % only every epoch is assigned a name
    EEG.swa_scoring.stageNames  = cell(1,nEpochs);
    EEG.swa_scoring.stageNames(:) = {'Unscored'};

    EEG.swa_scoring.startTime = 0;
    
    % assign montage defaults
    EEG.swa_scoring.montage.labels = cell(8,1);
    EEG.swa_scoring.montage.labels(:) = {'undefined'};
    EEG.swa_scoring.montage.channels = [1:8; ones(1,8)*size(eegData,1)]';
    EEG.swa_scoring.montage.filterSettings = [ones(1,8)*0.5; ones(1,8)*30]';
end
% ``````````````

% save the sEpoch to the EEG structure
EEG.swa_scoring.sEpoch = sEpoch;

% enable the menu items
set(handles.menu.Export, 'Enable', 'on');
set(handles.menu.Statistics, 'Enable', 'on');
set(handles.menu.Montage, 'Enable', 'on');

% reset the status bar
set(handles.StatusBar, 'String', 'Idle')

% update the handles structure
guidata(handles.fig, handles)
% use setappdata for data storage to avoid passing it around in handles when not necessary
setappdata(handles.fig, 'EEG', EEG);
setappdata(handles.fig, 'eegData', eegData);

% draw the initial eeg
fcn_initial_plot(handles.fig)

set(handles.StatusBar, 'String', 'EEG Loaded'); drawnow;


function menu_SaveEEG(hObject, ~)
handles = guidata(hObject); % Get handles

% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% Ask where to put file...
[saveFile, savePath] = uiputfile('*.set');

% since the data has not changed we can just save the EEG part, not the data
save(fullfile(savePath, saveFile), 'EEG', '-mat');

set(handles.StatusBar, 'String', 'Data Saved')


function menu_Export(hObject, ~, stage)
handles = guidata(hObject); % Get handles

% get the eegData structure out of the figure
EEG = getappdata(handles.fig, 'EEG');
eegData = getappdata(handles.fig, 'eegData');

% Find the matching stage and remove arousal samples
keepSamples = false(1,size(EEG.swa_scoring.stages,2));
keepSamples(EEG.swa_scoring.stages == stage) = true;
keepSamples(EEG.swa_scoring.arousals) = false;

if sum(keepSamples) == 0
    set(handles.StatusBar, 'String', ['Cannot Export: No epochs found for stage ', num2str(stage)])
    return;
end

% copy the data to a new structure
Data.N2  = double(eegData(:, keepSamples));    

% get the necessary info from the EEG
if isempty(EEG.chanlocs)
    Info.Electrodes = EEG.urchanlocs;
else
    Info.Electrodes = EEG.chanlocs;
end
Info.sRate      = EEG.srate;

% calculate the time of each sample
time = (1:size(EEG.swa_scoring.stages,2))/EEG.srate;
Info.time       = time(keepSamples);

[saveName,savePath] = uiputfile('*.mat');
if ~isempty(saveName)
    set(handles.StatusBar, 'String', 'Busy: Exporting Data')
    save([savePath, saveName], 'Data', 'Info', '-mat', '-v7.3')
    set(handles.StatusBar, 'String', 'Idle')
end


function fcn_initial_plot(object)
% initial plot of the eeg data and hypnogram

% get the handles
handles = guidata(object);

% get the eegData structure out of the figure
EEG = getappdata(handles.fig, 'EEG');
eegData = getappdata(handles.fig, 'eegData');

% select the plotting data
range       = 1:EEG.swa_scoring.epochLength * EEG.srate;
channels    = 1:EEG.swa_scoring.display_channels;

% re-reference the data
data = eegData(EEG.swa_scoring.montage.channels(channels,1), range)...
     - eegData(EEG.swa_scoring.montage.channels(channels,2), range);

% filter the data
% ~~~~~~~~~~~~~~~
% loop each channel for their individual settings
for i = 1:8
    [EEG.filter.b(i,:), EEG.filter.a(i,:)] = ...
        butter(2,[EEG.swa_scoring.montage.filterSettings(i,1)/(EEG.srate/2),...
                  EEG.swa_scoring.montage.filterSettings(i,2)/(EEG.srate/2)]);
    
    % transpose data twice          
    data(i,:) = single(filtfilt(EEG.filter.b(i,:), EEG.filter.a(i,:),...
        double(data(i,:)'))'); 

end

% plot the data
% ~~~~~~~~~~~~~
% define accurate spacing
scale = get(handles.et_Scale, 'value')*-1;
toAdd = [1:8]'*scale;
toAdd = repmat(toAdd, [1, length(range)]);

% space out the data for the single plot
data = data+toAdd;

set([handles.channel_axes, handles.label_axes],...
    'yLim', [scale 0]*(EEG.swa_scoring.display_channels+1));

% in the case of replotting delete the old handles
if isfield(handles, 'plot_channels')
    delete(handles.channel_plots);
    delete(handles.labels);
end

% calculate the time in seconds
time = range/EEG.srate;
set(handles.channel_axes,  'xlim', [time(1), time(end)]);

% plot the data
handles.channel_plots = line(time, data,...
                        'color', [0.1, 0.1, 0.1],...
                        'parent', handles.channel_axes);
                  
% TODO: plot the arousals

% plot the labels in their own boxes
handles.labels = zeros(length(EEG.swa_scoring.montage.channels(channels)), 1);
for chn = 1:length(EEG.swa_scoring.montage.labels)
    handles.labels(chn) = text(...
        0.5, toAdd(chn,1)+scale/5, EEG.swa_scoring.montage.labels{chn},...
        'parent', handles.label_axes,...
        'fontsize',   10,...
        'fontweight', 'bold',...
        'color',      [0.1 0.1 0.1],...
        'backgroundcolor', [0.9, 0.9, 0.9],...
        'horizontalAlignment', 'center');
end
                    
 % set the current epoch
set(handles.cEpoch, 'Value', 1);

% Set Hypnogram
% `````````````
time = [1:EEG.pnts]/EEG.srate/60/60;

% set the x-limit to the number of stages
set(handles.axHypno,...
    'XLim', [0 time(end)]);
% plot the epoch indicator line
handles.ln_hypno = line([0, 0], [0, 6.5], 'color', [0.5, 0.5, 0.5], 'parent', handles.axHypno);

% plot the stages    
handles.plHypno = plot(time, EEG.swa_scoring.stages,...
    'LineWidth', 2,...
    'Color',    'k');

% set the new parameters
guidata(handles.fig, handles);
setappdata(handles.fig, 'EEG', EEG);


% Update Functions
% ````````````````
function updateAxes(handles)
% get the eegData structure out of the figure
EEG = getappdata(handles.fig, 'EEG');
eegData = getappdata(handles.fig, 'eegData');

% data section
sEpoch  = EEG.swa_scoring.sEpoch;
cEpoch  = get(handles.cEpoch, 'value');
range   = (cEpoch*sEpoch-(sEpoch-1)):(cEpoch*sEpoch);

% rereference the data
data = eegData(EEG.swa_scoring.montage.channels(:,1),range)...
     - eegData(EEG.swa_scoring.montage.channels(:,2),range);
          
% define accurate spacing
scale = get(handles.et_Scale, 'value')*-1;
toAdd = [1:8]'*scale;
toAdd = repmat(toAdd, [1, length(range)]);

 % loop for each individual channels settings
% plot the new data
for n = 1:8
    data(n,:) = single(filtfilt(EEG.filter.b(n,:), EEG.filter.a(n,:),...
        double(data(n,:)'))'); %transpose data twice
    set(handles.channel_plots(n), 'yData', data(n,:) + toAdd(n, :));
end

% plot the events
% event = data(3, :);
% event(:, ~EEG.swa_scoring.arousals(range)) = nan;
% set(handles.current_events, 'yData', event);

set(handles.StatusBar, 'string',...
   'idle'); drawnow;

function fcn_epochChange(hObject, ~, figurehandle)
% get the handles from the guidata
handles = guidata(figurehandle);

% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

cEpoch = get(handles.cEpoch, 'value');
if cEpoch < 1
    set(handles.StatusBar, 'String', 'This is the first epoch')
    set(handles.cEpoch, 'value', 1);
elseif cEpoch > length(EEG.swa_scoring.stageNames)
    set(handles.StatusBar, 'String', 'No further epochs')
    set(handles.cEpoch, 'value', length(EEG.swa_scoring.stageNames));
end
cEpoch = get(handles.cEpoch, 'value');

% update the hypnogram indicator line
x = cEpoch * EEG.swa_scoring.epochLength/60/60;
set(handles.ln_hypno, 'Xdata', [x, x]);

% set the stage name to the current stage
% calculate the current time
current_time = datestr(...
    (EEG.swa_scoring.startTime+cEpoch*EEG.swa_scoring.epochLength-30)/(60*60*24),...
    'HH:MM:SS');
set(handles.StageBar, 'String',...
    [num2str(cEpoch), ' | ', current_time, ' | ', EEG.swa_scoring.stageNames{cEpoch}]);

% update the GUI handles (*updates just fine)
guidata(handles.fig, handles)
setappdata(handles.fig, 'EEG', EEG);

% update all the axes
updateAxes(handles);

function updateScale(hObject, ~)
handles = guidata(hObject); % Get handles

% Get the new scale value
ylimits = str2double(get(handles.et_Scale, 'String'));

% Update all the axis to the new scale limits
set(handles.channel_axes,...
    'YLim', [-ylimits, ylimits]);

function updateStage(hObject, ~)
% get the updated handles from the GUI
handles = guidata(hObject);

% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% current epoch range
sEpoch  = EEG.swa_scoring.epochLength*EEG.srate; % samples per epoch
cEpoch  = get(handles.cEpoch, 'value');
range   = (cEpoch*sEpoch-(sEpoch-1)):(cEpoch*sEpoch);

% set the current sleep stage value and name
EEG.swa_scoring.stages(range) = get(get(handles.bg_Scoring, 'SelectedObject'), 'UserData');
EEG.swa_scoring.stageNames{cEpoch} = get(get(handles.bg_Scoring, 'SelectedObject'), 'String');

% reset the scoring box
set(handles.bg_Scoring,'SelectedObject',[]);  % No selection

% change the scores value
set(handles.plHypno, 'Ydata', EEG.swa_scoring.stages);

% Update the handles in the GUI
guidata(handles.fig, handles);
setappdata(handles.fig, 'EEG', EEG);

% go to the next epoch
set(handles.cEpoch, 'value', cEpoch+1);
fcn_epochChange(hObject, [], handles.fig);

function updateEpochLength(hObject, ~)
% get handles
handles = guidata(hObject); 

% get the eegData structure out of the figure
EEG = getappdata(handles.fig, 'EEG');
eegData = getappdata(handles.fig, 'eegData');

% check for minimum (5s) and maximum (120s) and give warning...
if EEG.swa_scoring.epochLength > 240
    set(handles.StatusBar, 'String', 'No more than 240s Epochs')
    EEG.swa_scoring.epochLength = 240;
    return;
elseif EEG.swa_scoring.epochLength < 5
    set(handles.StatusBar, 'String', 'No less than 5s Epochs')
    EEG.swa_scoring.epochLength = 5;  
    return;
end

% calculate the number of samples per epoch
sEpoch  = EEG.swa_scoring.epochLength * EEG.srate;
% calculate the total number of epochs in the time series
nEpochs = floor(size(eegData,2)/sEpoch);

% set limit to the axes
% set(handles.axHypno,...
%     'XLim', [1 nEpochs]);
set(handles.channel_axes,...
    'XLim', [1, sEpoch]);

% re-calculate the stage names from the value (e.g. 0 = wake)
EEG.swa_scoring.stageNames = cell(1, nEpochs);
count = 0;
for i = 1:sEpoch:nEpochs*sEpoch
    count = count+1;
    switch EEG.swa_scoring.stages(i)
        case 0
            EEG.swa_scoring.stageNames(count) = {'wake'};
        case 1
            EEG.swa_scoring.stageNames(count) = {'nrem1'};
        case 2
            EEG.swa_scoring.stageNames(count) = {'nrem2'};
        case 3
            EEG.swa_scoring.stageNames(count) = {'nrem3'};
        case 5
            EEG.swa_scoring.stageNames(count) = {'rem'};
        case 6
            EEG.swa_scoring.stageNames(count) = {'artifact'};
        otherwise
            EEG.swa_scoring.stageNames(count) = {'unscored'};
    end
end

set(handles.StatusBar, 'String', 'Idle')

% set the xdata and ydata to equal lengths
for i = 1:8
    set(handles.channel_plots(i), 'Xdata', 1:sEpoch, 'Ydata', 1:sEpoch);
end
set(handles.current_events, 'Xdata', 1:sEpoch, 'Ydata', 1:sEpoch);

% update the hypnogram
set(handles.plHypno, 'Ydata', EEG.swa_scoring.stages);

% save the sEpoch to the EEG structure
EEG.swa_scoring.sEpoch = sEpoch;

% update the GUI handles
guidata(handles.fig, handles) 
setappdata(handles.fig, 'EEG', EEG);

% update all the axes
updateAxes(handles);


function cb_KeyPressed(hObject, eventdata)
% get the updated handles structure (*not updated properly)
handles = guidata(hObject);

% get the EG structure out of the figure
EEG = getappdata(handles.fig, 'EEG');

% movement keys
switch eventdata.Key
    case 'rightarrow'
        % move to the next epoch
        set(handles.cEpoch, 'Value', get(handles.cEpoch, 'Value') + 1);
        fcn_epochChange(hObject, [], handles.fig)
    case 'leftarrow'
        % move to the previous epoch
        set(handles.cEpoch, 'Value', get(handles.cEpoch, 'Value') - 1);
        fcn_epochChange(hObject, [], handles.fig)
        
    case 'uparrow'
        scale = get(handles.et_Scale, 'value');
        if scale <= 20
            value = scale / 2;
        else
            value = scale - 20;
        end
        
        set(handles.et_Scale, 'string', num2str(value));
        set(handles.et_Scale, 'value',  value);
        
        set(handles.channel_axes, 'yLim',...
            [value * -1, 0] * (EEG.swa_scoring.display_channels + 1))
        updateAxes(handles)
        
    case 'downarrow'
        scale = get(handles.et_Scale, 'value');
        if scale <= 20
            value = scale * 2;
        else
            value = scale + 20;
        end
        
        set(handles.et_Scale, 'string', num2str(value));
        set(handles.et_Scale, 'value',  value);
        
        set(handles.channel_axes, 'yLim',...
            [value * -1, 0] * (EEG.swa_scoring.display_channels + 1))
        updateAxes(handles)
        
end

% sleep staging
switch eventdata.Character
    case '0'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(1));
        updateStage(hObject, eventdata);
    case '1'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(2));
        updateStage(hObject, eventdata);
    case '2'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(3));
        updateStage(hObject, eventdata);
    case '3'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(4));
        updateStage(hObject, eventdata);
    case '5'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(5));
        updateStage(hObject, eventdata);
    case '6'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(6));
        updateStage(hObject, eventdata);
end

guidata(handles.fig, handles)

function checkFilter(figureHandle, ~)
% get the updated handles structure
handles = guidata(figureHandle);

% User feedback since this often takes some time
set(handles.StatusBar, 'string',...
    'Checking filter parameters'); drawnow;

% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% loop each channel for their individual settings
for i = 1:8
    [EEG.filter.b(i,:), EEG.filter.a(i,:)] = ...
        butter(2,[EEG.swa_scoring.montage.filterSettings(i,1)/(EEG.srate/2),...
                  EEG.swa_scoring.montage.filterSettings(i,2)/(EEG.srate/2)]);
end
    
% save EEG struct back into the figure
setappdata(handles.fig, 'EEG', EEG);

% update the axes with the new filters
updateAxes(handles)

function bd_hypnoEpochSelect(hObject, ~)
% function when the user clicks in the hypnogram

% get the handles
handles = guidata(hObject);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

current_point = get(handles.axHypno, 'CurrentPoint');

cEpoch = floor(current_point(1)*60*60*EEG.srate/EEG.swa_scoring.sEpoch);

% set the current epoch
set(handles.cEpoch, 'value', cEpoch);

% Update the handles in the GUI
guidata(handles.fig, handles)

% update the figure
fcn_epochChange(hObject, [], handles.fig);

function fcn_options(hObject, ~, type)
% get the handles
handles = guidata(hObject);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

switch type
    case 'EpochLength'
     
        answer = inputdlg('epoch length (s)',...
            '', 1, {num2str(EEG.swa_scoring.epochLength)});

        % if different from previous
        if ~isempty(answer)
            newLength = str2double(answer{1});
            if newLength ~= EEG.swa_scoring.epochLength
                EEG.swa_scoring.epochLength = newLength;
                % update the eeg structure before call
                setappdata(handles.fig, 'EEG', EEG);
                updateEpochLength(hObject, []);
            end
        end
        
    case 'StartTime'
        
        answer = inputdlg('epoch length (s)',...
            '', 1, {'hh:mm:ss'});
        
        if ~isempty(answer)
            % calculate time in seconds from input
            EEG.swa_scoring.startTime = round(86400*mod(datenum(answer{1}),1 ));
            % update the eeg structure before call
            setappdata(handles.fig, 'EEG', EEG);
            fcn_epochChange(hObject, [], handles.fig);
        end
        
end




% Code for selecting and marking events
% ````````````````````````````````````
function fcn_select_events(~, ~, hObject, event)

H = guidata(hObject); % Get handles

% get the userData if there was some already (otherwise returns empty)
userData = getappdata(H.channel_axes(3), 'x_range');

% if there was no userData, then pre-allocate the userData
if isempty(userData)
  userData.range = []; % this is a Nx4 matrix with the selection range
  userData.box   = []; % this is a Nx1 vector with the line handle
end

% determine whether the user is currently making a selection
selecting = numel(userData.range)>0 && any(isnan(userData.range(end,:)));

% get the current point
p = get(H.channel_axes(3), 'CurrentPoint');
p = p(1,1:2);

xLim = get(H.channel_axes(3), 'xlim');
yLim = get(H.channel_axes(3), 'ylim');

% limit cursor coordinates to axes...
if p(1)<xLim(1), p(1)=xLim(1); end;
if p(1)>xLim(2), p(1)=xLim(2); end;
if p(2)<yLim(1), p(2)=yLim(1); end;
if p(2)>yLim(2), p(2)=yLim(2); end;

switch lower(event)
  
  case lower('ButtonDown')        
      if ~isempty(userData.range)
          if any(p(1)>=userData.range(:,1) & p(1)<=userData.range(:,2))
              % the user has clicked in one of the existing selections
              
              fcn_mark_event(H.Figure, userData, get(gcf,'selectiontype'));
              
              % refresh the axes
              updateAxes(H);
              
%               % after box has been clicked delete the box
%               delete(userData.box(ishandle(userData.box)));
%               userData.range = [];
%               userData.box   = [];
          end
      end
      
      % set the figure's windowbuttonmotionfunction
      set(H.Figure, 'WindowButtonMotionFcn', {@fcn_select_events, hObject, 'Motion'});
      % set the figure's windowbuttonupfunction
      set(H.Figure, 'WindowButtonUpFcn',     {@fcn_select_events, hObject, 'ButtonUp'});
      
      % add a new selection range
      userData.range(end+1,1:4) = nan;
      userData.range(end,1) = p(1);
      userData.range(end,3) = p(2);
      
      % add a new selection box
      xData = [nan nan nan nan nan];
      yData = [nan nan nan nan nan];
      userData.box(end+1) = line(xData, yData, 'parent', H.channel_axes(3));
      
  case lower('Motion')
      
    if selecting
      % update the selection box
        x1 = userData.range(end,1);
        x2 = p(1);
        
        % we are only ever interested in the horizontal range
        y1 = yLim(1);
        y2 = yLim(2);
      
      xData = [x1 x2 x2 x1 x1];
      yData = [y1 y1 y2 y2 y1];
      set(userData.box(end), 'xData', xData);
      set(userData.box(end), 'yData', yData);
      set(userData.box(end), 'Color', [0 0 0]);
      set(userData.box(end), 'EraseMode', 'xor');
      set(userData.box(end), 'LineStyle', '--');
      set(userData.box(end), 'LineWidth', 3);
      set(userData.box(end), 'Visible', 'on');
      
    end  
    
  case lower('ButtonUp')

      if selecting
          % select the other corner of the box
          userData.range(end,2) = p(1);
          userData.range(end,4) = p(2);
      end
      
      % if just a single click (point) then delete all the boxes present
      if ~isempty(userData.range) && ~diff(userData.range(end,1:2)) && ~diff(userData.range(end,3:4))
          % start with a new selection
          delete(userData.box(ishandle(userData.box)));
          userData.range = [];
          userData.box   = [];
      end
      
      if ~isempty(userData.range)
          % ensure that the selection is sane
          if diff(userData.range(end,1:2))<0
              userData.range(end,1:2) = userData.range(end,[2 1]);
          end
          if diff(userData.range(end,3:4))<0
              userData.range(end,3:4) = userData.range(end,[4 3]);
          end
          % only select along the x-axis
          userData.range(end,3:4) = [-inf inf];
      end
      
      % set the figure callbacks to empty to avoid unnecessary calls when
      % not in specific plot
        % set the figure's windowbuttonmotionfunction
      set(H.Figure, 'WindowButtonMotionFcn', []);
        % set the figure's windowbuttonupfunction
      set(H.Figure, 'WindowButtonUpFcn',     []);
    
end % switch event

% put the selection back in the figure
setappdata(H.channel_axes(3), 'x_range', userData);

function fcn_mark_event(figurehandle, userData, type)

% get the figure handles and data
handles = guidata(figurehandle);
EEG     = getappdata(handles.fig, 'EEG');

cEpoch  = get(handles.cEpoch, 'value');
sEpoch  = EEG.swa_scoring.epochLength*EEG.srate; % samples per epoch

for row = 1:size(userData.range, 1)
    range   = (cEpoch*sEpoch-(sEpoch-1))+floor(userData.range(row, 1)):(cEpoch*sEpoch-(sEpoch-1))+ceil(userData.range(row, 2));
    if strcmp(type, 'normal')
        EEG.swa_scoring.arousals(range) = true;
    else
        EEG.swa_scoring.arousals(range) = false;
    end
end

guidata(handles.fig, handles);
setappdata(handles.fig, 'EEG', EEG);

% Montage Options
% ```````````````
function updateMontage(~, ~, figurehandle)

% create the figure
H.Figure = figure(...
    'Name',         'Montage Settings',...
    'NumberTitle',  'off',...
    'Color',        'w',...
    'MenuBar',      'none',...
    'Units',        'normalized',...
    'Outerposition',[0.2 0.2 0.2 0.4]);

% create label boxes
defaults = {'LOC', 'ROC', 'Fz', 'C3', 'C4', 'O1', 'O2', 'EMG'};
for i = 1:8
    H.lbCh(i) = uicontrol(...
        'Parent',        H.Figure,...
        'Style',         'edit',...
        'BackgroundColor', 'w',...
        'Units',        'normalized',...
        'Position',     [0.1 (9-i)*0.1+0.025 0.125 0.04],...
        'String',       defaults{i},...
        'FontName',     'Century Gothic',...
        'FontSize',     8);
end

% create popup menus and axes
for i = 1:8
	H.pmCh(i) = uicontrol(...
        'Parent',   H.Figure,...  
        'Style',    'popupmenu',...  
        'BackgroundColor', 'w',...
        'Units',    'normalized',...
        'Position', [0.3 (9-i)*0.1+0.025 0.125 0.04],...
        'String',   ['Channel ', num2str(i)],...
        'UserData',  i,...
        'FontName', 'Century Gothic',...
        'FontSize', 8);
	H.pmRe(i) = uicontrol(...
        'Parent',   H.Figure,...  
        'Style',    'popupmenu',...  
        'BackgroundColor', 'w',...
        'Units',    'normalized',...
        'Position', [0.45 (9-i)*0.1+0.025 0.125 0.04],...
        'String',   ['Channel ', num2str(i)],...
        'UserData',  i,...
        'FontName', 'Century Gothic',...
        'FontSize', 8);
end

% create filter boxes
for i = 1:8
    H.lbHP(i) = uicontrol(...
        'Parent',        H.Figure,...
        'Style',         'edit',...
        'BackgroundColor', 'w',...
        'Units',        'normalized',...
        'Position',     [0.65 (9-i)*0.1+0.025 0.125 0.04],...
        'String',       '0.5',...
        'UserData',     0.5,...
        'FontName',     'Century Gothic',...
        'FontSize',     8);
    H.lbLP(i) = uicontrol(...
        'Parent',        H.Figure,...
        'Style',         'edit',...
        'BackgroundColor', 'w',...
        'Units',        'normalized',...
        'Position',     [0.8 (9-i)*0.1+0.025 0.125 0.04],...
        'String',       '30',...
        'UserData',     30,...
        'FontName',     'Century Gothic',...
        'FontSize',     8);    
end

% menu options
H.menu.Open = uimenu(H.Figure, 'Label', 'Open');
H.menu.Save = uimenu(H.Figure, 'Label', 'Apply');
H.menu.Plot = uimenu(H.Figure, 'Label', 'Plot');

setMontageData(H, figurehandle)

function setMontageData(H, figureHandle)
% get the figure handles and data
handles = guidata(figureHandle);
EEG     = getappdata(handles.fig, 'EEG');

% set the channel options in the pop-menu
try
    set([H.pmCh; H.pmRe], 'String', {EEG.urchanlocs.labels}')
catch
    set([H.pmCh; H.pmRe], 'String', {EEG.chanlocs.labels}')
end

% check if the input already has these files and change them
if isfield(EEG.swa_scoring, 'montage')
    % set the labels
    for i = 1:8
        set(H.lbCh(i), 'string', EEG.swa_scoring.montage.labels{i});
        set(H.pmCh(i), 'Value',  EEG.swa_scoring.montage.channels(i,1));
        set(H.pmRe(i), 'Value',  EEG.swa_scoring.montage.channels(i,2));
        set(H.lbHP(i), 'string', num2str(EEG.swa_scoring.montage.filterSettings(i,1)));
        set(H.lbLP(i), 'string', num2str(EEG.swa_scoring.montage.filterSettings(i,2)));
    end
else
    
    
end

% set the callbacks for the menu
set(H.menu.Open,  'Callback', {@openMontage, H, figureHandle});
set(H.menu.Save,  'Callback', {@saveMontage, H, figureHandle});
set(H.menu.Plot,  'Callback', {@plotMontage, H, figureHandle});

function openMontage(~, ~, H, figureHandle)
handles = guidata(figureHandle); % Get handles

% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

[dataFile, dataPath] = uigetfile('*.set', 'Please Select Scored File with Montage');

if isequal(dataFile, 0)
    set(handles.StatusBar, 'String', 'Information: No file selected'); drawnow;
    return;
end

% Load the Files
set(handles.StatusBar, 'String', 'Busy: Loading Montage Data'); drawnow;
nEEG = load([dataPath, dataFile], '-mat'); nEEG = nEEG.EEG;
set(handles.StatusBar, 'String', 'Idle'); drawnow;
try
    EEG.swa_scoring.montage = nEEG.swa_scoring.montage;
catch
    set(handles.StatusBar, 'String', 'Information: No montage found in file'); drawnow;  
end

clear nEEG

guidata(handles.fig,handles)
setappdata(handles.fig, 'EEG', EEG);

setMontageData(H, figureHandle)

% saving the Montage
function saveMontage(~, ~, H, figureHandle)
% get the data
handles = guidata(figureHandle);
EEG     = getappdata(figureHandle, 'EEG');

% save the selected montage into the EEG structure
EEG.swa_scoring.montage.labels = get(H.lbCh, 'String');
EEG.swa_scoring.montage.channels = cell2mat([get(H.pmCh, 'Value'), get(H.pmRe, 'Value')]);
EEG.swa_scoring.montage.filterSettings = [str2double(get(H.lbHP, 'String')), str2double(get(H.lbLP, 'String'))];

% update all the labels (even if they didn't change)
for i = 1:8
    set(handles.lbCh(i), 'string', EEG.swa_scoring.montage.labels{i})
end

% set the data
guidata(handles.fig, handles)
setappdata(figureHandle, 'EEG', EEG);

% check the filter settings (calls updateAxes itself)
checkFilter(handles.fig)

% plot empty channel set
function plotMontage(~, ~, ~, figureHandle)
EEG     = getappdata(figureHandle, 'EEG');

if ~isempty(EEG.chanlocs)
    locs = EEG.chanlocs;
else
    locs = EEG.urchanlocs;
end
   
H = swa_Topoplot(...
    nan(40, 40), locs                                       ,...
    'NewFigure',        1                                   ,...
    'NumContours',      10                                  ,...
    'PlotContour',      1                                   ,...
    'PlotChannels',     1                                   ,...
    'PlotStreams',      0                                   );


% Close request
% `````````````
function fcn_close_request(~, ~)
% User-defined close request function to display a question dialog box
selection = questdlg('Are you sure?',...
    '',...
    'Yes','No','Yes');
switch selection,
    case 'Yes'
        delete(gcf)
    case 'No'
        return
end
