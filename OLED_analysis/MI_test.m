% Calculated MI for continuous changing intensity stimulation , by Rona
clear all
close all


path='F:\�ڪ����ݵw��\Retina exp\exp data\Spatial stimuli\20210331';
cd(path)
load('0727_OUsmooth_Bright_RL_G4.5_5min_Q100_6.5mW_0Hz_retransfer.mat')
load('merge_0727_OUsmooth_Bright_UL_G4.5_5min_Q100_6.5mW_4Hz.mat')

all_file = dir('*.mat') ; % change the type of the files which you want to select, subdir or dir.
n_file = length(all_file);
SamplingRate=20000;
cc=hsv(n_file);

        rr =[9,17,25,33,41,49,...
          2,10,18,26,34,42,50,58,...
          3,11,19,27,35,43,51,59,...
          4,12,20,28,36,44,52,60,...
          5,13,21,29,37,45,53,61,...
          6,14,22,30,38,46,54,62,...
          7,15,23,31,39,47,55,63,...
            16,24,32,40,48,56];
roi = [1:60];
mkdir MIandSTA


bin=16.6667;  BinningInterval = bin*10^-3; 
backward=ceil(1000/bin); forward=ceil(1000/bin);
%%  TimeStamps  %%%%%%%%%%%%%%%%%%%
if length(TimeStamps)==1
    TimeStamps(2)=TimeStamps(1)+200;
end

%% a_data as isi  %   a_data2=(a_data-32768)*0.1042;
% [b,a] = butter(2,50/20000,'low'); % set butter filter
% a_data2 = filter(b,a,a_data(1,:));
% isi = a_data2(TimeStamps(1)*20000:TimeStamps(length(TimeStamps))*20000);% figure;plot(isi);
%% Spike process
% =================================================================
Spikes=Spikes(1,:);
% ==================================================================


BinningTime = [TimeStamps(1) : BinningInterval : TimeStamps(end)];
BinningSpike = zeros(60,length(BinningTime));
for i = 1:60
    if length(Spikes{i})<100
        Spikes{i}=[];
    end
    [n,xout] = hist(Spikes{i},BinningTime);
    BinningSpike(i,:) = n;
end
% [n,out] = hist(TimeStamps,BinningTime);
% Stimuli = n;
BinningSpike(:,1) = 0;BinningSpike(:,end) = 0;% figure;plot(BinningTime,sum(BinningSpike),BinningTime,10*Stimuli,'o')
%     figure;imagesc(BinningTime,[1:60],BinningSpike)

%% state of light intensity %%% 
isi2=[];
states=8;
X=bin_pos;
nX = sort(X);
abin = length(nX)/states;
intervals = [nX(1:abin:end) inf]; 
temp=0;
for jj = 1:length(X)
    temp=temp+1;
    isi2(temp) = find(X(jj)<intervals,1)-1; % stimulus for every 50ms
    inten(temp)= X(jj);
end
%% Mutual Information
MI = cell(1,60); % create an array to save the MI data
xcor = cell(1,60); % create an array to save the cross correlation data
infor=[];co=[];
figure(1);
set(gcf, 'InvertHardCopy', 'off');
set(gcf,'units','normalized','outerposition',[0 0 1 1])
for nn= 1:length(roi)
    n=roi(nn);
    Neurons = BinningSpike(n,:); 
%         Neurons = sum(BinningSpike(:,:));
     %% shuffle
%         r=randperm(length(Neurons));
%         for j=1:length(r)            
%             sNeurons(j)=Neurons(r(j));
%         end
%         Neurons=sNeurons;

dat=[];informationp=[];temp=backward+2;
for i=1:backward+1 %past(t<0)
    temp=temp-1;
    if length(Neurons)==length(isi2)
        x = Neurons((i-1)+forward+1:length(Neurons)-backward+(i-1))';
    else
        x = Neurons((i-1)+forward+1:length(Neurons)-backward+(i-1)-1)';
    end    
    y=isi2(forward+1:length(isi2)-backward)';
    dat=[x,y];
    [N,C]=hist3(dat,[max(Neurons)+1,8]); %20:dividing firing rate  6:# of stim
    px=sum(N,1)/sum(sum(N)); % x:stim
    py=sum(N,2)/sum(sum(N)); % y:word
    pxy=N/sum(sum(N));
    temp2=[];
    for j=1:length(px)
        for k=1:length(py)
          temp2(k,j)=pxy(k,j)*log( pxy(k,j)/ (py(k)*px(j)) )/log(2);
        end
    end

    informationp(temp)=nansum(temp2(:));
    c=corrcoef(x,y);
    corrp(temp)=c(2,1);
%         informationp(temp) = ImExtrapolation_function(dat,8);
end  

dat=[];informationf=[];temp=0;sdat=[];
for i=1:forward
    temp=temp+1;
    if length(Neurons)==length(isi2)
        x =Neurons(forward+1-i:length(Neurons)-backward-i)';
    else
        x = Neurons(forward+1-i:length(Neurons)-backward-i-1)';
    end     
    y = isi2(forward+1:length(isi2)-backward)';
    dat=[x,y];
    [N,C]=hist3(dat,[max(Neurons)+1,8]); %20:dividing firing rate  6:# of stim
    px=sum(N,1)/sum(sum(N)); % x:stim
    py=sum(N,2)/sum(sum(N)); % y:word
    pxy=N/sum(sum(N));
    temp2=[];
    for j=1:length(px)
        for k=1:length(py)
            temp2(k,j)=pxy(k,j)*log( pxy(k,j)/ (py(k)*px(j)) )/log(2);
        end
    end

    informationf(temp)=nansum(temp2(:)); 
%      
    c=corrcoef(x,y);
    corrf(temp)=c(2,1);
%             informationf(temp) = ImExtrapolation_function(dat,8);
end

information=[informationp informationf]/BinningInterval;
corr=[corrp corrf];
%     fr(z)=mean(Neurons)/BinningInterval; %firing rate(Hz)
[pks(nn),plocs(nn)]=max(information);
t=[-backward*bin:bin:forward*bin];  


subplot(8,8,rr(n));hold on
spikenumber=length(Spikes{n});
if spikenumber==0
else

%         yyaxis left
    plot(t,information,'LineWidth',1,'LineStyle','-');%,'color',cc(z,:)
%         yyaxis right
%         plot(t,corr,'LineWidth',2,'LineStyle','-')
%         refline([0 0])
    xlim([-1000 1000])

%         figure(2);hold on
%         plot(t,information,'LineWidth',2,'LineStyle','-');%,'color',cc(z,:)
%         ylabel('mutual information (bits/s)')
%         xlabel('time shift (s)')
%         xlim([-1000 1000])
%         plot([0 0], ylim, '-r')
%         ax = gca;
%         ax.XGrid = 'off';
%         ax.YGrid = 'on';
end

% ==================
MI{nn} = information;
xcor{nn} = corr;

end
% TimeShift=t;
% save([path,'\MIandSTA\',filename(1:end-4),'_MI.mat'],'MI','TimeShift')
% 
% BinningTime = [TimeStamps(1) : 0.6 : TimeStamps(end)];
% BinningSpike = zeros(60,length(BinningTime));
% for i = 1:60
%     [n,xout] = hist(Spikes{i},BinningTime);
%     BinningSpike(i,:) = n;
% end
% BinningSpike(:,1) = 0;BinningSpike(:,end) = 0
% 
% SpikeSum=sum(BinningSpike,1);
% t_isi=0:1/20000:(length(isi)-1)/20000;
% figure;subplot(2,1,1)
% plot(BinningTime-TimeStamps(1),BinningSpike(35,:));
% subplot(2,1,2)
% plot(t_isi,isi)
% samexaxis('abc','xmt','on','ytac','join','yld',1);

%% single plot
% figure
% yyaxis left
% plot(t,information,'LineWidth',2,'LineStyle','-');%,'color',cc(z,:)
% ylabel('mutual information (bits/s)')
% yyaxis right
% plot(t,corr,'LineWidth',2,'LineStyle','-')
% ylabel('cross correlation')
% xlabel('time shift (s)')
% refline([0 0])
% xlim([-3000 3000])

%%

% isi3=isi2-mean(isi2);
% ttt=(1:length(isi3))*0.01;
% figure;
% yyaxis left;plot(ttt,isi3,'linewidth',2);hold on;
% ylabel('intensity of eight states subtract mean value')
% 
% yyaxis right;plot(ttt,Neurons,'linewidth',2);
% xlabel('time')
% ylabel('retina response')
% 

