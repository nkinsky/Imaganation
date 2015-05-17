function r = plot_multisesh_alt(base_path,check)
%plot_multisesh_alt(base_path)
%
%

%% Make sure you have the appropriate files. 
    try 
        load(fullfile(base_path,'MultiRegisteredCells.mat')); 
    catch
        disp('MultiRegisteredCells.mat not found! Trying to load Reg_NeuronIDs.mat...'); 
        try 
            load(fullfile(base_path,'Reg_NeuronIDs.mat')); 
            disp('Running find_multisesh_cells...'); 
            
            find_multisesh_cells(Reg_NeuronIDs,1);
            load(fullfile(base_path,'MultiRegisteredCells.mat')); 
        catch
            disp('Reg_NeuronIDs.mat not found! Preparing to run multi_image_reg...'); 
            num_sessions = input('How many sessions would you like to register your base image to? '); 
            
            base_file = fullfile(base_path, 'ICmovie_min_proj.tif'); 
            multi_image_reg(base_file,num_sessions,zeros(num_sessions)); 
            
            load(fullfile(base_path,'Reg_NeuronIDs.mat')); 
            disp('Running find_multisesh_cells...'); 
            
            find_multisesh_cells(Reg_NeuronIDs,0);
            load(fullfile(base_path,'MultiRegisteredCells.mat')); 
        end
    end
    
%% Useful parameters. 
    %Number of total sessions, including the base file. 
    num_sessions = length(Reg_NeuronIDs)+1;
    num_cells = size(cell_list,1); 

%% Extract data. 
    %Preallocate.
    session = struct; 
    disp('Extracting data...'); 
    
    %Base image stats. 
    session(1).path = Reg_NeuronIDs(1).base_path; 
    
    load(fullfile(session(1).path, 'PlaceMaps.mat'), 'TMap', 'OccMap'); 
    load(fullfile(session(1).path, 'ProcOut.mat'), 'NeuronImage'); 
        
    %Compile into struct. 
    session(1).TMap = TMap; 
    session(1).OccMap = OccMap; 
    session(1).NeuronImage = NeuronImage; 
    
    for this_sesh = 2:num_sessions
        %Get registered image path. 
        session(this_sesh).path = Reg_NeuronIDs(this_sesh-1).reg_path; 
        
        %Load place fields and neuron mask. 
        load(fullfile(session(this_sesh).path, 'PlaceMaps.mat'), 'TMap', 'OccMap');
        load(fullfile(session(this_sesh).path, 'ProcOut.mat'), 'NeuronImage'); 
      
        %Compile into struct. 
        session(this_sesh).TMap = TMap; 
        session(this_sesh).OccMap = OccMap; 
        session(this_sesh).NeuronImage = NeuronImage; 
    end
    
%% Plot.
    %Initialize. 
    r = nan(num_cells,num_sessions-1); 
    this_mask = cell(num_cells,num_sessions); 
    TMap_temp = cell(num_cells,num_sessions); 
    TMap_plot = cell(num_cells,num_sessions); 
    TMap_resized = cell(num_cells,num_sessions); 
    
    %For each neuron, get the resized TMap. 
    for this_neuron = 1:num_cells  
        %Resizing variable.
        sizing = nan(num_sessions,2);
        
        %Extract size information. 
        for this_sesh = 1:num_sessions
            %Get the size of a TMap. 
            sizing(this_sesh,[1:2]) = size(session(this_sesh).TMap{1}); 
            
            %Index for NeuronImage, TMap. 
            neuron_ind = cell_list(this_neuron,this_sesh); 
            
            %Get individual neuron masks and TMaps. 
            this_mask{this_neuron,this_sesh} = session(this_sesh).NeuronImage{neuron_ind};
            TMap_temp{this_neuron,this_sesh} = session(this_sesh).TMap{neuron_ind}; 
        end
        
        %Normalized size. 
        size_use = min(sizing,[],1); 
    end

    for this_neuron = 1:num_cells
        for this_sesh = 2:num_sessions
            %Some TMaps are full of NaNs. Exclude them from the
            %correlation. 
            if sum(isnan(TMap_temp{this_neuron,this_sesh}(:))) ~= 0 || sum(isnan(TMap_temp{this_neuron,1}(:))) ~= 0
                r(this_neuron,this_sesh-1) = nan; 
            else
                %Otherwise, resize the TMaps and do the correlation. 
                TMap_resized{this_neuron,this_sesh} = resize(TMap_temp{this_neuron,this_sesh},size_use);
                TMap_resized{this_neuron,1} = resize(TMap_temp{this_neuron,1},size_use); 
                
                %Correlate the TMap of the base image to that of the registered
                %image. 
                r(this_neuron,this_sesh-1) = corr2(TMap_resized{this_neuron,1},TMaps_resized{this_neuron,this_sesh});
            end
        end
    end
    
        
    %Check neuron masks and TMaps. 
    figure(600);
    keepgoing = 1; 
    this_neuron = 1; 
    
    if exist('check', 'var') && check == 1
    disp('Use left and right arrow keys to scroll through cells. Press Esc to exit.'); 
        while keepgoing
            sesh_sub_ind = 1;

            %Plot each session. 
            for this_sesh = 1:num_sessions
                subplot(num_sessions,3,sesh_sub_ind)
                    
                
                    imagesc(this_mask{this_neuron,this_sesh});
                    title(['Neuron #', num2str(cell_list(this_neuron,this_sesh))], 'fontsize', 12); 
                subplot(num_sessions,3,[sesh_sub_ind+1:sesh_sub_ind+2]); 
                    [~,TMap_plot{this_neuron,this_sesh}] = make_nan_TMap(session(this_sesh).OccMap, TMap_temp{this_neuron,this_sesh});
                    imagesc_nan(rot90(TMap_plot{this_neuron,this_sesh}));
                    title('TMap', 'fontsize', 12);

                sesh_sub_ind = sesh_sub_ind+3; 
            end

            figure(600);
            [~,~,key] = ginput(1); 

            %Advance or backtrack. 
            if key == 29 && this_neuron < num_cells
                this_neuron = this_neuron + 1; 
            elseif key == 28 && this_neuron ~= 1
                this_neuron = this_neuron - 1; 
            elseif key == 27
                keepgoing = 0; 
                close(figure(600)); 
            end
        end
    end          
        
end
                
%% 