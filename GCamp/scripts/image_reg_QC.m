% image registration QC function

%% Inputs
base_path = 'j:\GCamp Mice\Working\G30\alternation\11_11_2014\Working';
% LAPTOP'C:\Users\Nat\Documents\BU\Imaging\Working\GCamp Mice\G30\alternation\11_11_2014\Working';

load(fullfile(base_path,'Reg_NeuronIDs.mat'));
load(fullfile(base_path,'ProcOut.mat'),'NeuronImage');
sesh(1).Neurons = NeuronImage;
sesh(1).AllNeuronMask = create_AllICmask(sesh(1).Neurons);
sesh(1).AllNeuronMask_reg = sesh(1).AllNeuronMask;

for k = 2:3
    % Load neuron images for each session
    load(fullfile(Reg_NeuronIDs(k-1).reg_path,'ProcOut.mat'),'NeuronImage');
    sesh(k).Neurons = NeuronImage;
    % Create all Neuronmask for each session
    sesh(k).AllNeuronMask = create_AllICmask(sesh(k).Neurons);
    % Get session reg info for each session
    [m d s] = get_name_date_session(Reg_NeuronIDs(k-1).reg_path);
    load(fullfile(base_path,['RegistrationInfo-' m '-' d '-session' s '.mat']));
    reg_info_multi(k).reg_info = RegistrationInfoX;
    
    % Register AllNeuronMask to base session
    if k ~= 1
       sesh(k).AllNeuronMask_reg = imwarp(sesh(k).AllNeuronMask,reg_info_multi(k).reg_info.tform,'OutputView',...
            reg_info_multi(k).reg_info.base_ref,'InterpolationMethod','nearest');
    elseif k == 1
        sesh(k).AllNeuronMask_reg = sesh(k).AllNeuronMask;
    end
    
end

%% Calculate some quantities for QC

for j = 1:length(Reg_NeuronIDs(1).neuron_id)
    % Plot closeup of each cell being registered with immediately adjacent
    % cells from each session also in the view
    for k = 1:3
        if k == 1
            neuron_index{j,k} = j;
        elseif k == 2 || k == 3
            neuron_index{j,k} = Reg_NeuronIDs(k-1).neuron_id{j};
        end
        
    end
end

% Find all cells that map to the first session on the first day
neuron_map_binary = cellfun(@(a) ~isempty(a) && ~isnan(a), neuron_index);
% Find all the cells that map to the same neuron on the second day
same_cell_binary = cellfun(@(a) ~isempty(a) && isnan(a), neuron_index);

both_sessions = neuron_map_binary(:,2) & neuron_map_binary(:,3);
either_session = neuron_map_binary(:,2) | neuron_map_binary(:,3);

%% Plot stuff

offset = 30;  % Number of pixels around each neuron you want to view

figure(50)
for j = 1:length(Reg_NeuronIDs(1).neuron_id)
    for k = 1:3
        
        % get neuron masks for plotting
        if isempty(neuron_index{j,k}) || isnan(neuron_index{j,k})
            neuron_mask_plot{k} = zeros(size(sesh(k).Neurons{1}));
        else
            neuron_mask_plot{k} = sesh(k).Neurons{neuron_index{j,k}};
        end
        
        % Register sessions to base
        if k ~= 1
            reg_neuron(k).plot = imwarp(neuron_mask_plot{k},reg_info_multi(k).reg_info.tform,'OutputView',...
                reg_info_multi(k).reg_info.base_ref,'InterpolationMethod','nearest');
        elseif k == 1
            reg_neuron(k).plot = neuron_mask_plot{k};
        end
        
        stats = regionprops(reg_neuron(k).plot,'centroid');
        subplot(2,2,k)
        imagesc(reg_neuron(k).plot + sesh(k).AllNeuronMask_reg);
        colormap jet; colorbar
        if ~isempty(stats)
            xlim([stats.Centroid(1)-offset stats.Centroid(1)+offset])
            ylim([stats.Centroid(2)-offset stats.Centroid(2)+offset])
        end
        title(['Session ' num2str(k) ' neuron #' num2str(neuron_index{j,k})]);
    end
    
    % Plot all cells overlaid on one another
    subplot(2,2,4);
    stats = regionprops(neuron_mask_plot{1},'centroid');
    imagesc(neuron_mask_plot{1} + 2*reg_neuron(2).plot + 3*reg_neuron(3).plot);
    colormap jet; colorbar
    xlim([stats.Centroid(1)-offset stats.Centroid(1)+offset])
    ylim([stats.Centroid(2)-offset stats.Centroid(2)+offset])
    title('All Sessions');
    
    waitforbuttonpress
    
    
end

%% More Error Checking! in conjunction with image_register_simple - this 
% looks at all the cells in the 1st session that are assigned to the same
% cell in the 2nd session
same_index = find(sum(Reg_NeuronIDs(1).same_neuron,2));
same_neuron = Reg_NeuronIDs(1).same_neuron;

figure(60);
for j = 1:same_index
    neuron2plot = find(same_neuron(:,same_index(j)));
%     imagesc(day(2).NeuronImage_reg{same_index(j)});
%     hold on;
    
    temp_plot = zeros(size(sesh(1).Neurons{1}));
    for k = 1:length(neuron2plot);
        temp_plot = temp_plot + (k+1)*bwperim(sesh(1).Neurons{neuron2plot(k)});
    end;
    
%     imagesc(day(2).NeuronImage_reg{same_index(j)} + temp_plot)
    imagesc(temp_plot);
    waitforbuttonpress;
end

%% QC for multi_image_reg

folder{1} = 'j:\GCamp Mice\Working\G30\alternation\11_11_2014\Working';
folder{2} = 'j:\GCamp Mice\Working\G30\alternation\11_12_2014\Working';
folder{3} = 'j:\GCamp Mice\Working\G30\alternation\11_13_2014\Working\take2';

reg_file{2} = 'RegistrationInfo-G30-11_12_2014-session1.mat';
reg_file{3} = 'RegistrationInfo-G30-11_13_2014-session1.mat';

for k = 1:3
    load(fullfile(folder{k},'ProcOut.mat'),'NeuronImage');
    session(k).neurons = NeuronImage;
    if k > 1
        load(fullfile(folder{1},reg_file{k}));
        session(k).reginfo = RegistrationInfoX;
    end
end

figure(560)
for j = 1208:1220
   for k = 1:3
      if isempty(all_map{j,k}) || isnan(all_map{j,k}) || all_map{j,k} > size(session(k).neurons,2)
          mask{k} = zeros(size(session(1).neurons{1}));
      else
          if k == 1
              mask{k} = session(k).neurons{j};
          elseif k > 1
              temp = session(k).neurons{all_map{j,k}};
              mask{k} = imwarp(temp, session(k).reginfo.tform,'OutputView',...
                session(k).reginfo.base_ref,'InterpolationMethod','nearest');
          end
      end
   end
   
   imagesc(mask{1} + 2*mask{2} + 3*mask{3});
   colormap jet
   colorbar
   
   waitforbuttonpress
end

%% More stuff

currdir = cd;
ChangeDirectory(Reg_NeuronIDs(1).mouse,Reg_NeuronIDs(1).base_date, ...
    Reg_NeuronIDs(1).base_session);
load('ProcOut.mat','NeuronImage');
cd(currdir)
sesh(1).NeuronImage = NeuronImage;
base_mds.Animal = Reg_NeuronIDs(1).mouse;
base_mds.Date = Reg_NeuronIDs(1).base_date;
base_mds.Session = Reg_NeuronIDs(1).base_session;
% Register Neurons from Future sessions to previous ones
for j = 1:length(Reg_NeuronIDs)
    reg_mds.Animal = Reg_NeuronIDs(j).mouse;
    reg_mds.Date = Reg_NeuronIDs(j).reg_date;
    reg_mds.Session = Reg_NeuronIDs(j).reg_session;
    
   sesh(j+1).NeuronImage = get_regNeuronImage( base_mds, reg_mds );
   if j == 1
       all_session_map = Reg_NeuronIDs(1).all_session_map;
   end
    
end
%% 
figure(100);
for i = 1:length(Reg_NeuronIDs)
    same_neuron = Reg_NeuronIDs(i).same_neuron;
    multi_neurons = find(sum(same_neuron,1) > 0);
    for j = 1: length(multi_neurons)
        temp = find(same_neuron(:,multi_neurons(j))); % Get rows of neurons that map to the same session
        for k = 1:length(temp)
            col_num(k) = find(cellfun(@(a) ~isempty(a) && ~isnan(a), all_session_map(temp(1),2:end)),1,'first')+1;
        end
        % Put in something here to id if cell is from session 1 or session 2 or
        % session n and add it in.  Also to create a name identifying it in the
        % title or savename... will need to register stuff too
        temp2 = zeros(size(sesh(1).NeuronImage{1}));
        fig_name = 'Cell ';
        for k = 1:length(temp)
            sesh_num = 1;
            neuron_num = all_session_map{temp(k),sesh_num+1};
            while isempty(neuron_num)
                sesh_num = sesh_num + 1;
                neuron_num = all_session_map{temp(k),sesh_num+1};
            end
            temp2 = temp2 + sesh(sesh_num).NeuronImage{neuron_num}*k;
            if k < length(temp)
                fig_name = [fig_name num2str(neuron_num) ' from session ' num2str(sesh_num)  ' and ' ];
            else
                fig_name = [fig_name num2str(neuron_num) ' from session ' num2str(sesh_num) ...
                     ' to ' num2str(multi_neurons(j)) ' from session ' num2str(i+1)];
            end
        end
        
        outlines = bwboundaries(sesh(i+1).NeuronImage{multi_neurons(j)});
        imagesc(temp2)
        colorbar
        hold on
        plot(outlines{1}(:,2),outlines{1}(:,1),'r');
        title(fig_name)
        hold off
%         waitforbuttonpress
        %
        export_fig(fullfile(pwd,'plots',[Reg_NeuronIDs(i).base_date ' to ' Reg_NeuronIDs(i).reg_date], ...
            fig_name),'-jpg');
    end
end

%% Check multiple mapping neurons
same_neuron_list = find(sum(same_neuron,1));
figure(200)
for j = 1:length(same_neuron_list)
    % Get boundaries of 2nd session neuron
    bounds_image = bwboundaries(day(2).NeuronImage_reg{same_neuron_list(j)});
    bounds_mean = bwboundaries(day(2).NeuronMean_reg{same_neuron_list(j)});
    same_neuron1 = find(same_neuron(:,same_neuron_list(j)));
    temp_image = zeros(size(day(1).NeuronImage_reg{1}));
    temp_mean = zeros(size(day(1).NeuronImage_reg{1}));
    for k = 1:length(same_neuron1)
       temp_image = temp_image + day(1).NeuronImage_reg{same_neuron1(k)};
       temp_mean = temp_mean + day(1).NeuronMean_reg{same_neuron1(k)};
    end
    
    bounds_plot_x = [min(bounds_mean{1}(:,2))-5 max(bounds_mean{1}(:,2))+5];
    bounds_plot_y = [min(bounds_mean{1}(:,1))-5 max(bounds_mean{1}(:,1))+5];
    
    subplot(2,2,1)
    imagesc(day(1).NeuronImage_reg{same_neuron1(1)}); colorbar
    hold on; 
    plot(bounds_image{1}(:,2),bounds_image{1}(:,1),'r');
    hold off
    xlim(bounds_plot_x); ylim(bounds_plot_y);
    title(['NeuronImage: 1st session neuron = ' num2str(same_neuron1(1)) '. 2nd session =  ' num2str(same_neuron_list(j))])
    
    subplot(2,2,2)
    imagesc(day(1).NeuronImage_reg{same_neuron1(2)}); colorbar
    hold on; 
    plot(bounds_image{1}(:,2),bounds_image{1}(:,1),'r');
    hold off
    xlim(bounds_plot_x); ylim(bounds_plot_y);
    title(['NeuronImage: 1st session neuron = ' num2str(same_neuron1(2)) '. 2nd session =  ' num2str(same_neuron_list(j))])
    
    subplot(2,2,3)
    imagesc(day(1).NeuronMean_reg{same_neuron1(1)}); colorbar
    hold on; 
    plot(bounds_mean{1}(:,2),bounds_mean{1}(:,1),'r');
    hold off
    xlim(bounds_plot_x); ylim(bounds_plot_y);
    title(['NeuronMean: 1st session neuron = ' num2str(same_neuron1(1)) '. 2nd session =  ' num2str(same_neuron_list(j))])
    
    subplot(2,2,4)
    imagesc(day(1).NeuronMean_reg{same_neuron1(2)}); colorbar
    hold on; 
    plot(bounds_mean{1}(:,2),bounds_mean{1}(:,1),'r');
    hold off
    xlim(bounds_plot_x); ylim(bounds_plot_y);
    title(['NeuronMean: 1st session neuron = ' num2str(same_neuron1(2)) '. 2nd session =  ' num2str(same_neuron_list(j))])
    
    waitforbuttonpress
end

