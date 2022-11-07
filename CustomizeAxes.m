classdef CustomizeAxes < matlab.task.LiveTask & matlab.mixin.SetGet
    properties (Access = private,Transient,Hidden)
        %% Top-level uicontrols: axes-selection and properties accordion panel
        InputAxesDropDown       matlab.ui.control.DropDown
        CodeStyleDropDown       matlab.ui.control.DropDown
        AccordionParent         matlab.ui.container.internal.Accordion

        %% General properties panel
        GeneralPanel            matlab.ui.container.internal.AccordionPanel
        BoxCheckBox             matlab.ui.control.CheckBox
        BGColorPicker           matlab.ui.control.internal.ColorPicker
        GridColorPicker         matlab.ui.control.internal.ColorPicker
        GridStyleDropDown       matlab.ui.control.DropDown

        %% Font properties panel
        FontPanel               matlab.ui.container.internal.AccordionPanel
        FontNameDropDown        matlab.ui.control.DropDown
        FontSizeSpinner         matlab.ui.control.Spinner
        FontWeightBoldCheckBox  matlab.ui.control.CheckBox
        FontAngleItalicCheckBox matlab.ui.control.CheckBox

        %% Rulers properties panel
        RulersPanel             matlab.ui.container.internal.AccordionPanel

        % X-Axis properties sub-panel
        XVisibleCheckBox        matlab.ui.control.CheckBox
        XLabel                  matlab.ui.control.EditField
        XLabel2                 matlab.ui.control.EditField
        XColorPicker            matlab.ui.control.internal.ColorPicker
        XAxisLocationDropDown   matlab.ui.control.DropDown
        XDirReverseCheckBox     matlab.ui.control.CheckBox
        XGridCheckBox           matlab.ui.control.CheckBox
        XMinorGridCheckBox      matlab.ui.control.CheckBox
        XMinorTickCheckBox      matlab.ui.control.CheckBox
        XScaleLogCheckBox       matlab.ui.control.CheckBox

        % Y-Axis properties sub-panel
        YVisibleCheckBox        matlab.ui.control.CheckBox
        YLabel                  matlab.ui.control.EditField
        YLabel2                 matlab.ui.control.EditField
        YColorPicker            matlab.ui.control.internal.ColorPicker
        YAxisLocationDropDown   matlab.ui.control.DropDown
        YDirReverseCheckBox     matlab.ui.control.CheckBox
        YGridCheckBox           matlab.ui.control.CheckBox
        YMinorGridCheckBox      matlab.ui.control.CheckBox
        YMinorTickCheckBox      matlab.ui.control.CheckBox
        YScaleLogCheckBox       matlab.ui.control.CheckBox

        % Y-Axis properties sub-panel
        ZVisibleCheckBox        matlab.ui.control.CheckBox
        ZLabel                  matlab.ui.control.EditField
        ZLabel2                 matlab.ui.control.EditField
        ZColorPicker            matlab.ui.control.internal.ColorPicker
        ZPropertiesGrid         matlab.ui.container.GridLayout
        %ZAxisLocationDropDown   matlab.ui.control.DropDown  % Axes have no ZLocation property!
        ZDirReverseCheckBox     matlab.ui.control.CheckBox
        ZGridCheckBox           matlab.ui.control.CheckBox
        ZMinorGridCheckBox      matlab.ui.control.CheckBox
        ZMinorTickCheckBox      matlab.ui.control.CheckBox
        ZScaleLogCheckBox       matlab.ui.control.CheckBox

        %% General private task properties
        % Default row height (App Designer default = 22)
        TextRowHeight double = 16;
        CtrlRowHeight double = 20;

        % Default padding between rows
        TextRowPadding double = 0;

        %% Internal properties: axes handle and variable name
        Axes
        AxesVarName
        AxesDisplayName
        AxesDeletedListener
        AxesUpdatedListener
    end

    properties
        State
        Summary
    end

    properties (SetAccess = protected)
        CodeStyle
    end

    methods (Access = private, Hidden)
        function createComponents(task)
            task.LayoutManager.RowSpacing = 5;
            task.LayoutManager.RowHeight = {'fit', 'fit'};
            task.LayoutManager.ColumnWidth = {'fit'};

            %% Axes selection panel
            %task.Axes = gca;
            inputgrid = uigridlayout(task.LayoutManager, 'Padding',0, ...
                'RowHeight',{'fit'}, 'ColumnWidth',{'fit','fit','1x','fit','fit',0});
            tooltip = 'Select the axes to customize';
            uilabel(inputgrid, 'Text','Axes:', 'Tooltip',tooltip);
            %{
            task.InputDataDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent', inputgrid);
            task.InputDataDropDown.Workspace = 'base'; %=task.Workspace;
            task.InputDataDropDown.Tooltip = tooltip;
            task.InputDataDropDown.ValueChangedFcn = @app.updateControls;
            task.InputDataDropDown.FilterVariablesFcn = @(val,var)app.isASuitableInput(val)&&~strcmp(var,'centroids');
            %}
            task.InputAxesDropDown = uidropdown(...
                'Parent',inputgrid, ...
                'ValueChangedFcn',@task.updateControls, ...
                'DropDownOpeningFcn',@task.populateWSDropdownItems, ...
                'Tooltip',tooltip);
            task.populateWSDropdownItems(task.InputAxesDropDown);
            tooltip = 'Source code style - using set() or dot notation';

            uilabel(inputgrid,'Text',''); %spacer

            hLabel = uilabel(inputgrid, 'Text','Code style:', 'Tooltip',tooltip, 'Visible','off');
            task.CodeStyleDropDown = uidropdown(...
                'Parent',inputgrid, ...
                'Items',["Dot notation", "set() notation"], ...
                'ValueChangedFcn',@task.taskControlsUpdated, ...
                'Tooltip',tooltip, ...
                'UserData',hLabel, ...
                'Visible','off');

            %% Collapsible properties panels (accordion)
            task.AccordionParent = matlab.ui.container.internal.Accordion('Parent',task.LayoutManager);
            createGeneralPanel(task);
            createFontPanel(task);
            createRulersPanel(task);
        end

        function createGeneralPanel(task)
            task.GeneralPanel = matlab.ui.container.internal.AccordionPanel('Parent',task.AccordionParent, 'Title','General', 'Collapsed',false);
            h2 = uigridlayout(task.GeneralPanel, 'RowHeight',task.CtrlRowHeight, 'ColumnWidth',repmat("fit",1,7), 'Padding',0);
            commonProps = {'Parent',h2, 'ValueChangedFcn',@task.taskControlsUpdated};

            task.BoxCheckBox = uicheckbox(commonProps{:}, 'Text','Box', 'Tooltip','Box around the axes?');

            tooltip = 'Axes background color';
            uilabel(h2, 'HorizontalAlignment','right', 'Text','Background:', 'Tooltip',tooltip);
            task.BGColorPicker   = matlab.ui.control.internal.ColorPicker(commonProps{:}, 'Tooltip',tooltip, 'Value','w');

            tooltip = 'Grid-lines color';
            uilabel(h2, 'HorizontalAlignment','right', 'Text','Grid color:', 'Tooltip',tooltip);
            task.GridColorPicker = matlab.ui.control.internal.ColorPicker(commonProps{:}, 'Tooltip',tooltip, 'Value','k');

            tooltip = 'Grid-lines style';
            uilabel(h2, 'HorizontalAlignment','right', 'Text','Grid style:', 'Tooltip',tooltip);
            gridStyles = {'Line (-)', 'Dashed (--)', 'Dotted (:)', 'Dash-dot (-.)', 'None'};
            task.GridStyleDropDown = uidropdown(commonProps{:}, 'Items',gridStyles, 'Value','None', 'Tooltip',tooltip);
            function valueStr = getGridStyleValue()
                basicStyles = regexprep(gridStyles, {'.+\(','\)'},{'',''});
                value = find(strcmpi(task.Axes.GridLineStyle,basicStyles));
                if isempty(value), value = 1; end
                valueStr = gridStyles{value};
            end
        end

        function createFontPanel(task)
            task.FontPanel = matlab.ui.container.internal.AccordionPanel('Parent',task.AccordionParent, 'Title','Font', 'Collapsed',false);
            h2 = uigridlayout(task.FontPanel, 'RowHeight',task.CtrlRowHeight, 'ColumnWidth',{'fit','fit','fit',120,'fit',60}, 'Padding',0);        
            commonProps = {'Parent',h2, 'ValueChangedFcn',@task.taskControlsUpdated};

            task.FontWeightBoldCheckBox  = uicheckbox(commonProps{:}, 'Text','Bold',   'Tooltip','Bold font?');   %, 'Value',strcmpi(task.Axes.FontWeight,'bold'));
            task.FontAngleItalicCheckBox = uicheckbox(commonProps{:}, 'Text','Italic', 'Tooltip','Italic font?'); %, 'Value',strcmpi(task.Axes.FontAngle,'italic'));

            tooltip = 'Axes font face name';
            uilabel(h2, 'HorizontalAlignment','right', 'Text','Font name:', 'Tooltip',tooltip);
            task.FontNameDropDown = uidropdown(commonProps{:}, 'Items',listfonts, 'Tooltip',tooltip); %, 'Value',task.Axes.FontName);

            tooltip = 'Axes font size';
            uilabel(h2, 'HorizontalAlignment','right', 'Text','Font size:', 'Tooltip',tooltip);
            task.FontSizeSpinner = uispinner(commonProps{:}, 'Limits',[5,inf], 'Tooltip',tooltip); %, 'Value',task.Axes.FontSize);
        end

        function createRulersPanel(task)
            task.RulersPanel = matlab.ui.container.internal.AccordionPanel('Parent',task.AccordionParent, 'Title','Rulers', 'Collapsed',false);
            h2 = uigridlayout(task.RulersPanel, 'RowHeight',{'fit'}, 'ColumnWidth',repmat("fit",1,4), 'Padding',0);

            % Labels column
            textHeight = task.TextRowHeight;
            ctrlHeight = task.CtrlRowHeight;
            rowHeights = [textHeight-[1,0], repmat(ctrlHeight,1,4), textHeight([1,1,1,1,1])];
            rowPadding = [0, task.TextRowPadding, 0, task.TextRowPadding];
            h3 = uigridlayout(h2, 'RowHeight',rowHeights, 'ColumnWidth',{'fit'}, 'Padding',rowPadding, 'RowSpacing',7);
            uilabel(h3, 'HorizontalAlignment','right', 'Text',''); %no header for the labels column
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Visible:',     'Tooltip','Display axis ruler?');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Label:',       'Tooltip','Main axis label');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','2nd label:',   'Tooltip','Secondary label');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Color:',       'Tooltip','Axis color');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Location:',    'Tooltip','Axes crossover location');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Reverse:',     'Tooltip','Reverse axis limits?');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Log scale:',   'Tooltip','Logarithmic scaling?');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Main grid:',   'Tooltip','Display main gridlines?');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Minor grid:',  'Tooltip','Display minor gridlines?');
            uilabel(h3, 'HorizontalAlignment','right', 'Text','Minor ticks:', 'Tooltip','Display minor tick marks?');

            % Controls columns
            createAxisPanel(task, h2,'X');
            createAxisPanel(task, h2,'Y');
            createAxisPanel(task, h2,'Z');
        end

        function createAxisPanel(task, h2, axis)
            textHeight = task.TextRowHeight;
            ctrlHeight = task.CtrlRowHeight;
            rowHeights = [textHeight-[1,0], repmat(ctrlHeight,1,4), textHeight([1,1,1,1,1])];
            rowPadding = [0, task.TextRowPadding, 0, task.TextRowPadding];
            callback = @task.taskControlsUpdated;
            h3 = uigridlayout(h2, 'RowHeight',rowHeights, 'ColumnWidth',{'fit'}, 'Padding',rowPadding, 'RowSpacing',7);
            commonProps = {'Parent',h3, 'ValueChangedFcn',callback};

            % Column header
            uilabel(h3, 'Text',[axis ' axis'], 'HorizontalAlignment','center', 'FontWeight','bold');

            % Property controls
            task.([axis 'VisibleCheckBox']) = newCheckbox(h3, callback, 'Display axis ruler?');
            task.([axis 'Label'])  = uieditfield(commonProps{:}, 'Tooltip','Main axis label');
            task.([axis 'Label2']) = uieditfield(commonProps{:}, 'Tooltip','Secondary label');
            task.([axis 'ColorPicker']) = matlab.ui.control.internal.ColorPicker(commonProps{:}, 'Tooltip','Axis color', 'Value','k');

            if axis ~= "Z"
                hAxes = task.Axes;
                if ~isAxes(hAxes)
                    hFig = ancestor(task.LayoutManager,'figure');
                    hAxes = hFig.CurrentAxes;
                end
                if ~isAxes(hAxes)
                    possibleValues = {'origin'};
                else
                    possibleValues = set(hAxes, [axis 'AxisLocation']);
                end
               %currentValue = lower(hAxes.([axis 'AxisLocation']));
                task.([axis 'AxisLocationDropDown']) = uidropdown(commonProps{:}, 'Items',possibleValues, 'Tooltip','Axes crossover location'); %, 'Value',currentValue
            else
                uilabel(h3, 'Text','');

                % Hide Z-axis properties panel if the axes is 2D (X-Y)
                h3.Visible = ~is2D(task.Axes);
            end

            task.([axis 'DirReverseCheckBox']) = newCheckbox(h3, callback, 'Reverse axis limits?');
            task.([axis 'ScaleLogCheckBox'])   = newCheckbox(h3, callback, 'Logarithmic scaling?');
            task.([axis 'GridCheckBox'])       = newCheckbox(h3, callback, 'Display main gridlines?');
            task.([axis 'MinorGridCheckBox'])  = newCheckbox(h3, callback, 'Display minor gridlines?');
            task.([axis 'MinorTickCheckBox'])  = newCheckbox(h3, callback, 'Display minor tick marks?');
        end

        function setControlsToDefault(~)
            % do nothing!
        end

        function updateControls(task,source,evt) %#ok<INUSD> 
            %% Bail out if the originating axes is not the currently-selected one
            if nargin > 1 && ~isequal(source, task.Axes) && ~isa(source,'matlab.ui.control.Component')
                return
            end

            %% Bail out if this methos was triggered by taskControlsUpdated()
            if any(strcmp({dbstack().name},[mfilename '.taskControlsUpdated']))
                return
            end

            %% Get the selected axes (not just if modified)
            %if isequal(source, task.InputAxesDropDown)
                hAxes = getSelectedAxes(task);
                isAxesValid = isAxes(hAxes);
                task.AccordionParent.Visible = isAxesValid;
                if ~isAxesValid
                    return
                else
                    task.populateWSDropdownItems(task.InputAxesDropDown);
                end
            %end

            %% Display the code style controls if source axes was selected
            if nargin > 1 && source == task.InputAxesDropDown
                task.CodeStyleDropDown.Visible = 'on';
                task.CodeStyleDropDown.UserData.Visible = 'on';  %hLabel
            end

            %% Call drawnow to ensure property values are consistent
            %drawnow;

            %% Update the General controls based on the axes properties:
            task.BoxCheckBox.Value     = double(hAxes.Box);
            task.BGColorPicker.Value   = getColorNoBG(task, hAxes.Color);
            task.GridColorPicker.Value = getColorNoBG(task, hAxes.GridColor);

            gridStyleNames = task.GridStyleDropDown.Items;
            gridStyles = regexprep(gridStyleNames, {'.+\(','\)'},{'',''});
            task.GridStyleDropDown.Value = gridStyleNames(strcmpi(hAxes.GridLineStyle, gridStyles));

            %% Update the Font controls based on the axes properties:
            task.FontNameDropDown.Value = hAxes.FontName;
            task.FontSizeSpinner.Value  = hAxes.FontSize;
            task.FontWeightBoldCheckBox.Value  = strcmpi(hAxes.FontWeight,'bold');
            task.FontAngleItalicCheckBox.Value = strcmpi(hAxes.FontAngle, 'italic');

            %% Update the Ruler controls based on the axes properties:
            updateAxisControls(task, 'X');
            updateAxisControls(task, 'Y');
            updateAxisControls(task, 'Z');

            %% A final drawnow for the task controls
            %drawnow

            %% Attach an event listener to the axes for auotmatic future updates
            hListener = getappdata(hAxes,[mfilename 'Listener']);
            if isempty(hListener) || ~isvalid(hListener)
                hListener = addlistener(hAxes, 'MarkedClean', @task.updateControls);
                setappdata(hAxes,[mfilename 'Listener'],hListener);
            else
                % Update the callback to ensure that the function handle uses this task, rather than a stale one
                hListener.Callback = @task.updateControls;
            end

            %% Trigger the live editor to update the generated script
            notify(task,'StateChanged');
        end

        function updateAxisControls(task, axis)
            hAxes = task.Axes;
            task.([axis 'VisibleCheckBox']).Value = double(hAxes.([axis 'Axis']).Visible);
            task.([axis 'Label']).Value  = getLabel(task, hAxes.([axis 'Label']));
            task.([axis 'Label2']).Value = getLabel(task, hAxes.([axis 'Axis']).SecondaryLabel);
            task.([axis 'ColorPicker']).Value = getColorNoBG(task, hAxes.([axis 'Color']));

            try
                task.([axis 'AxisLocationDropDown']).Items = set(hAxes,[axis 'AxisLocation']);
                task.([axis 'AxisLocationDropDown']).Value = lower(hAxes.([axis 'AxisLocation']));
            catch
                % ZAxisLocation is not a valid axes proprty!
            end

            % Hide Z-axis properties panel if the axes is 2D (X-Y)
            if string(axis)=='Z'
                task.ZLabel.Parent.Visible = ~is2D(hAxes);
            end

            task.([axis 'DirReverseCheckBox']).Value = strcmpi(hAxes.([axis 'Dir']),'reverse');
            task.([axis 'ScaleLogCheckBox']).Value   = strcmpi(hAxes.([axis 'Scale']),'log');
            task.([axis 'GridCheckBox']).Value       = double(hAxes.([axis 'Grid']));
            task.([axis 'MinorGridCheckBox']).Value  = double(hAxes.([axis 'MinorGrid']));
            task.([axis 'MinorTickCheckBox']).Value  = double(hAxes.([axis 'MinorTick']));
        end

        function [hAxes,axesVarName,axesDispName] = getSelectedAxes(task,force)
            % Use the cached task values, if still valid/relevant
            axesVarName = char(task.InputAxesDropDown.Value);
            hAxes = task.Axes;
            if (nargin > 1 && force) || ~isequal(task.AxesVarName, axesVarName) || ~isAxes(hAxes)
                % Refetch the axes (live data)
                if strcmpi(strtok(axesVarName),'Select')
                    hAxes = [];
                    axesVarName = ''; %'<not yet set>';
                    axesDispName = axesVarName;
                elseif any(char(axesVarName)==' ')
                    % We use 'gca()' to enable constructs such as 'gca().XColor'
                    % (without the (), we can only use set(), not dot notation)
                    hAxes = evalin('base','gca()');
                    axesVarName = 'gca()';
                    axesDispName = 'current';
                else
                    hAxes = evalin('base',axesVarName);
                    axesDispName = axesVarName;
                    axesVarName = ['`' axesVarName '`'];
                end

                % If the axes is valid
                if isAxes(hAxes)
                    % Update the internal task properties with the axes' data
                    task.Axes = hAxes;
                    task.AxesVarName = axesVarName;
                    task.AxesDisplayName = axesDispName;

                    % Attach listeners to update the task when axes is updated/deleted
                    task.AxesUpdatedListener = listener(hAxes,'MarkedClean',         @task.axesWasUpdated);
                    task.AxesDeletedListener = listener(hAxes,'ObjectBeingDestroyed',@task.axesWasDeleted);
                end
            else
                axesDispName = task.AxesDisplayName;
            end
        end

        function populateWSDropdownItems(task, src, ~)
            workspaceVariables = evalin('base', 'whos');
            axesVarNames = strings(0);
            for i = 1 : length(workspaceVariables)
                var = workspaceVariables(i);
                if strcmp(var.name,'ans'), continue, end  % ignore "ans": users should never use it
                try
                    a = evalin('base',var.name);
                    if isAxes(a)
                        axesVarNames(end+1) = var.name; %#ok<AGROW> 
                    end
                catch
                end
            end
            if ~isAxes(task.Axes)
                items = 'Select axes';
            else
                items = [];
            end
            src.Items = [items; 'Current axes (gca)'; axesVarNames'];
        end

        function color = getColorNoBG(~, color)
            try
                % Replace None (transparent) with white color
                if ~isnumeric(color)
                    color = strrep(lower(color),'none','w');
                end
            catch
                % color must be numeric - leave it as-is
            end
        end

        function str = getLabel(~, hLabel)
            try str = hLabel.String; catch, str = ''; end
        end

        % Callback function called when any task control is modified
        function taskControlsUpdated(task, src, ~) %#ok<INUSD>
            % Temporarily disable listener, to avoid unnecesary updateControls()
            % Note: this is not strictly necessary, because as extra precaution
            % ^^^^  we bail-out of updateControls() if triggered by this method
            try
                hListener = getappdata(task.Axes, [mfilename 'Listener']);
                hListener.Enabled = false;
                hCleanup = onCleanup(@()setfield(hListener,'Enabled',true));
            catch
            end

            % If Auto-run is on, generate and execute the code to update the axes
            if task.AutoRun
                code = generateCode(task);
                % Strip code comments since evalin() might croak otherwise
                code = regexprep(code,{['% .+?' 10],'`'},'');
                assignin('base','code',code); % for debugging only
                evalin('base', code);
                drawnow;  %let MarkedClean event fire before hListener is re-enabled
            end
        end

        % Callback function called when the displayed axes is updated
        function axesWasUpdated(task, varargin)
            task.updateControls();
        end

        % Callback function called when the displayed axes is deleted
        function axesWasDeleted(task, varargin)
            if ~isvalid(task), return, end
            task.Axes = [];
            task.AxesVarName = '';
            task.AxesDisplayName = '';
            task.AccordionParent.Visible = false;
            task.CodeStyleDropDown.Visible = false;
            task.CodeStyleDropDown.UserData.Visible = false;  %hLabel
            task.populateWSDropdownItems(task.InputAxesDropDown);
            task.InputAxesDropDown.Value = task.InputAxesDropDown.Items{1}; %='Select axes'
            drawnow
        end

        % Utility function: set the value of the specified axes property
        function str = setFieldValue(task, handleName, axisName, fieldName, value)
            valStr = getValueStr(value);
            handleName = char(handleName);                 % string => char
            fieldName = [char(axisName) char(fieldName)];  % string => char
            subFields = strsplit(fieldName,'.');
            handleName = strjoin({handleName, subFields{1:end-1}},'.');
            fieldName = subFields{end};
            useSetNotation = any(handleName=='(') || ... % Matlab croaks on gca().Color=... so we use set()
                             strncmpi(task.CodeStyle,'set',3);
            if useSetNotation
                str = ['set(' handleName ', "' fieldName '", ' valStr ')' newline];
            else
                str = [handleName '.' fieldName ' = ' valStr ';' newline];
            end
        end
    end

    methods (Access = protected)
        function setup(task)
            createComponents(task);
            setControlsToDefault(task);
            updateControls(task);
        end
    end

    methods
        function task = CustomizeAxes(varargin)
            %task@matlab.task.LiveTask(varargin{:});
            if nargin && isAxes(varargin{end})
                task.Axes = varargin{end};
                axesVarNames = task.InputAxesDropDown.Items;
                wasAxesFound = false;
                for i = length(axesVarNames) : -1 : 1
                    axesVarName = axesVarNames{i};
                    if strcmpi(strtok(axesVarName),'Select')
                        continue
                    elseif any(axesVarName==' ')  % gca
                        hAxes = gca;
                    else
                        try hAxes = evalin('base',axesVarName); catch, continue, end
                    end
                    if isequal(hAxes, task.Axes)
                        wasAxesFound = true;
                        break
                    end
                end
                if wasAxesFound
                    task.InputAxesDropDown.Value = axesVarName;
                else
                    % Ensure that we have a proper workspace var for the axes
                    assignin('base','hAxes',task.Axes);
                    %task.InputAxesDropDown.Items = unique([axesVarNames 'hAxes'],'stable');
                    task.InputAxesDropDown.Value = 'hAxes';
                end
                task.populateWSDropdownItems(task.InputAxesDropDown);
                task.CodeStyleDropDown.Visible = 'on';
                task.CodeStyleDropDown.UserData.Visible = 'on';  %hLabel
                %varargin(end) = [];
                updateControls(task);
            end
        end

        function [code,outputs] = generateCode(task)
            [hAxes, axesVarName, axesDispName] = getSelectedAxes(task); %#ok<ASGLU>
            outputs = {};

            % Set the internal code style
            task.CodeStyle = char(task.CodeStyleDropDown.Value);

            % General properties
            gridStyle = lower(regexprep(task.GridStyleDropDown.Value, {'.+\(','\)'},{'',''}));
            code = ['% Customize ' axesDispName ' axes' newline];

            % Matlab croaks on gca().Color=... so we must use a temp variable hAx
            % Enclose hAx with backticks (`hAx`) or it will be duplicated each call!
            if any(axesVarName == '(') %&& ~strncmpi(task.CodeStyle,'set',3)
                code = [code '`hAx` = ' axesVarName ';' newline newline];
                axesVarName = '`hAx`';
            end

            code = [code ...
                    '% General properties:' newline ...
                    task.setFieldValue(axesVarName, '', 'Box',           task.BoxCheckBox.Value) ...
                    task.setFieldValue(axesVarName, '', 'Color',         task.BGColorPicker.Value) ...
                    task.setFieldValue(axesVarName, '', 'GridColor',     task.GridColorPicker.Value) ...
                    task.setFieldValue(axesVarName, '', 'GridLineStyle', gridStyle)];

            % Font properties
            weight = 'normal'; if task.FontWeightBoldCheckBox.Value, weight = 'bold';   end
            angle  = 'normal'; if task.FontAngleItalicCheckBox.Value, angle = 'italic'; end
            code = [code newline ...
                    '% Font properties:' newline ...
                    task.setFieldValue(axesVarName, '', 'FontName',   task.FontNameDropDown.Value) ...
                    task.setFieldValue(axesVarName, '', 'FontSize',   task.FontSizeSpinner.Value) ...
                    task.setFieldValue(axesVarName, '', 'FontWeight', weight) ...
                    task.setFieldValue(axesVarName, '', 'FontAngle',  angle)];

            % Ruler axes properties
            code = [code getAxisUpdateCode(task,axesVarName,'X')];
            code = [code getAxisUpdateCode(task,axesVarName,'Y')];
            code = [code getAxisUpdateCode(task,axesVarName,'Z')];
        end

        function code = getAxisUpdateCode(task, axesVarName, axis)
            dir   = 'normal'; if task.([axis 'DirReverseCheckBox']).Value, dir = 'reverse'; end
            scale = 'linear'; if task.([axis 'ScaleLogCheckBox']).Value,   scale = 'log';   end
            code = [newline ...
                    '% ' axis '-axis properties:' newline ...
                    task.setFieldValue(axesVarName, axis, 'Dir',       dir) ...
                    task.setFieldValue(axesVarName, axis, 'Scale',     scale) ...
                    task.setFieldValue(axesVarName, axis, 'Grid',      getPropValue('GridCheckBox')) ...
                    task.setFieldValue(axesVarName, axis, 'MinorGrid', getPropValue('MinorGridCheckBox')) ...
                    task.setFieldValue(axesVarName, axis, 'MinorTick', getPropValue('MinorTickCheckBox')) ...
                    task.setFieldValue(axesVarName, axis, 'Color',     getPropValue('ColorPicker')) ...
                    ];
            % ZAxisLocation is not a valid axes proprty!
            if axis ~= "Z"
                value = getPropValue('AxisLocationDropDown');
                code = [code task.setFieldValue(axesVarName, axis, 'AxisLocation', value)];
            end
            if isempty(task.([axis 'Label']).Value)
                code = [code task.setFieldValue(axesVarName, axis, 'Label.Visible',"off")];
            else
                code = [code ...
                        task.setFieldValue(axesVarName, axis, 'Label.Visible',"on"') ...
                        task.setFieldValue(axesVarName, axis, 'Label.String', getPropValue('Label'))];
            end
            if isempty(task.([axis 'Label2']).Value)
                code = [code ...
                        task.setFieldValue(axesVarName, axis, 'Axis.SecondaryLabel.Visible',"off") ...
                        task.setFieldValue(axesVarName, axis, 'Axis.SecondaryLabel.String', "")];
            else
                code = [code ...
                        task.setFieldValue(axesVarName, axis, 'Axis.SecondaryLabel.Visible',"on") ...
                        task.setFieldValue(axesVarName, axis, 'Axis.SecondaryLabel.String', getPropValue('Label2'))];
            end
            code = [code task.setFieldValue(axesVarName, axis, 'Axis.Visible', getPropValue('VisibleCheckBox'))];

            function value = getPropValue(propName)
                value = task.([axis propName]).Value;
            end
        end

        function summary = get.Summary(task) % TODO
            [hAxes, axesVarName, axesDispName] = getSelectedAxes(task); %#ok<ASGLU>
            summary = ['Customize ' axesDispName ' axes' ];
        end

        function state = get.State(task) %#ok<MANU> 
            % All this task's controls are transient - no persistent state to store!
            state = [];
        end

        function set.State(task,state) %#ok<INUSD> 
            % All this task's controls are transient - no persistent state to store!
        end

        function reset(task)
            setControlsToDefault(task);
            updateControls(task);
        end
    end
end

%% Utility sub-functions

% Get a char (string) that represents a property value (used by code-generator)
function str = getValueStr(value)
    if isnumeric(value)
        % Convert number(s) to char representation, convert spaces => ','
        str = regexprep(num2str(value),'\s+',',');
        % Enclose mutiple values with '[...]'
        if numel(value) ~= 1
            str = ['[' str ']'];
        end
    elseif islogical(value)  % convert true => 'true', false => 'false'
        str = mat2str(value);
    else  % enclose string values with ".."
        str = ['"' char(value) '"'];
    end
end

% Check whether the specified handles is a valid axes
function flag = isAxes(h)
    flag = false;
    if ~isempty(h)
        %cls = string(class(h));
        try
            h.XColor;  % this will croak if h is not a valid live axes
            if ishandle(h) %cls.endsWith("axes")
                flag = true;
            end
        catch
        end
    end
end

% Create a new uicheckbox in the center of the specified uigrid column
function h = newCheckbox(hParent, callback, tooltip, varargin)
    %uicheckbox(hParent, 'Text','', 'ValueChangedFcn',callback, 'Tooltip',tooltip);
    p = uigridlayout(hParent, 'ColumnWidth',{'1x','fit','1x'}, ...
                     'RowHeight',{'fit'}, 'Padding',0,'RowSpacing',0);
    h = uicheckbox(p, 'Text','', 'ValueChangedFcn',callback, 'Tooltip',tooltip, varargin{:});
    h.Layout.Column = 2;  % center the checkbox in the middle of the panel
end
