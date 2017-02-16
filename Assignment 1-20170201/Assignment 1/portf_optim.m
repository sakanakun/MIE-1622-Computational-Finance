clc;
clear all;
format long

addpath('C:\Program Files\IBM\ILOG\CPLEX_Studio1262\cplex\matlab\x64_win64');
% Input files
input_file_returns = 'Returns.csv';
input_file_prices  = 'Daily_closing_prices.csv';

% Read expected returns
if(exist(input_file_returns,'file'))
  fprintf('\nReading returns datafile - %s\n', input_file_returns)
  fid1 = fopen(input_file_returns);
     % Read instrument tickers
     hheader  = textscan(fid1, '%s', 1, 'delimiter', '\n');
     headers = textscan(char(hheader{:}), '%q', 'delimiter', '\t');
     tickers = headers{1}(2:end);
     % Read time periods
     vheader = textscan(fid1, '%q %*[^\n]');
     periods = vheader{1}(1:end);
  fclose(fid1);
  data_returns = dlmread(input_file_returns, '\t', 1, 1);
else
  error('Returns datafile does not exist')
end

% Read daily prices
if(exist(input_file_prices,'file'))
  fprintf('\nReading daily prices datafile - %s\n', input_file_prices)
  fid2 = fopen(input_file_prices);
     % Read dates
     vheader = textscan(fid2, '%q %*[^\n]');
     dates = vheader{1}(2:end);
  fclose(fid2);
  data_prices = dlmread(input_file_prices, '\t', 1, 1);
else
  error('Daily prices datafile does not exist')
end

% Initial positions in the portfolio
init_positions = [5000 1000 2000 0 0 0 0 2000 3000 6500 0 0 0 0 0 0 1000 0 0 0]';

% Initial value of the portfolio
init_value = data_prices(1,:) * init_positions;
fprintf('\nInitial portfolio value = $ %10.2f\n\n', init_value);

% Initial portfolio weights
w_init = (data_prices(1,:) .* init_positions')' / init_value;

% Number of periods, assets, trading days
N_periods = length(periods);
N = length(tickers);
N_days = length(dates);

% Convert dates into array [year month day]
format_date = 'mm/dd/yyyy';
dates_array = datevec(dates, format_date);
dates_array = dates_array(:,1:3);

% Number of strategies
strategy_functions = {'strat_buy_and_hold' 'strat_equally_weighted' 'strat_min_variance' 'strat_max_Sharpe'};
strategy_names     = {'Buy and Hold' 'Equally Weighted Portfolio' 'Mininum Variance Portfolio' 'Maximum Sharpe Ratio Portfolio'};
N_strat = 4; % comment this in your code
%N_strat = length(strategy_functions); % uncomment this in your code
fh_array = cellfun(@str2func, strategy_functions, 'UniformOutput', false);

for (period = 1:N_periods)
   % Compute current year and month, first and last day of the period
   if(dates_array(1,1)==5)
       cur_year  = 5 + floor(period/7);
   else
       cur_year  = 2005 + floor(period/7);
   end
   cur_month = 2*rem(period-1,6) + 1;
   day_ind_start = find(dates_array(:,1)==cur_year & dates_array(:,2)==cur_month, 1, 'first');
   day_ind_end = find(dates_array(:,1)==cur_year & dates_array(:,2)==(cur_month+1), 1, 'last');
   fprintf('\nPeriod %d: start date %s, end date %s\n', period, char(dates(day_ind_start)), char(dates(day_ind_end)));

   % Compute expected return and covariance matrix for period 1
   if(period==1)
       mu = data_returns(period,:)';
       Q  = dlmread(['covariance_' char(periods(period)) '.csv'], '\t', 'A1..T20');
   end

   % Prices for the current day
   cur_prices = data_prices(day_ind_start,:);

   % Execute portfolio selection strategies
   for(strategy = 1:N_strat)

      % Get current portfolio positions
      if(period==1)
         curr_positions = init_positions;
         curr_cash = 0;
         portf_value{strategy} = zeros(N_days,1);
      else
         curr_positions = x{strategy,period-1};
         curr_cash = cash{strategy,period-1};
      end

      % Compute strategy
     
      [x{strategy,period} cash{strategy,period}] = fh_array{strategy}(curr_positions, curr_cash, mu, Q, cur_prices);
      %Weight Allocations
      stocks = x{strategy,period} .* cur_prices';
      %display(stocks);
      cur_portf_value = sum(stocks);
      %get the optimal weight for each stock at each reblance period
      w_optimal{strategy, period} = stocks/cur_portf_value;
      
      % Check that we can buy new portfolio subject to transaction costs

%           %If  cash < 0, sell each stock by 1 at a time according to the
%           weight allocation to get cash to fill the balance, the
%           validation procedure is computed in each strategy 


      %%%%%%%%%%% Insert your code here %%%%%%%%%%%%

      % Compute portfolio value
      portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period};

      fprintf('   Strategy "%s", value begin = $ %10.2f, value end = $ %10.2f\n', char(strategy_names{strategy}), portf_value{strategy}(day_ind_start), portf_value{strategy}(day_ind_end));

   end
      
   % Compute expected returns and covariances for the next period
   cur_returns = data_prices(day_ind_start+1:day_ind_end,:) ./ data_prices(day_ind_start:day_ind_end-1,:) - 1;
   mu = mean(cur_returns)';
   Q = cov(cur_returns);
   
end

% Plot results (refer to lecture 3 and 4)
% figure(1);
%%%%%%%%%%% Insert your code here %%%%%%%%%%%%
figure(1);
%Chart for The daily value of portfolio for each trading strategy
for(strategy = 1:4)
    plot(portf_value{strategy});
    axis([0 600 0.8*10^6 2.4*10^6]);
    title('Daily Value of Portfolio 2005');
    xlabel('Trading Days');
    ylabel('Daily Value (in Millions)');
    legend('Buy and Hold', 'Equally Weighted Portfolio', 'Mininum Variance Portfolio' ,'Maximum Sharpe Ratio Portfolio');
    hold on;
end

%Charts for Portfolio Allocations

periods = 12;
num_of_stocks = 20;
y = zeros(4, num_of_stocks, periods);
% get the data set for daily optimal weights for each strategy at each
% reblance period
for i = 1:4
    for j =1:12
        for k =1:20
            y(i,k,j) = w_optimal{i,j}(k);
        end
    end
end

   figure();
  %Chart for min variance portforlio allocation 
  for strategy = 3:4
    for k = 1:num_of_stocks
        w_plot  = zeros(1,12);
              for period = 1:12       
            w_plot(period) = y(strategy,k,period);
              end
        subplot(2,1,1)
        plot(w_plot);
         axis([0 12 -0.1 1.0]);
    title('Min Variance -Dynamic Portfolio Allocations Portfolio 2005&2006');
    xlabel('Rebalance Period');
    ylabel('Portforlio Weight');
    %legend('MSFT', 'F','CRAY', 'GOOG',	'HPQ','YHOO',	'JAVA',	'DELL',	'AAPL',	'IBM','LNVGY','CSCO',	'BAC',	'INTC',	'AMD','SNE',	'NVDA', 'AMZN', 'CREAF','EK');
    hold on;
    
    end
    
    
%Chart for max_sharpe portforlio allocation
    for k = 1:num_of_stocks
        w_plot  = zeros(1,12);
        for period = 1:12
            w_plot(period) = y(4,k,period);
            %display(w_plot);
           
        end
        subplot(2,1,2)
        plot(w_plot);
         axis([0 12 -0.1 1.0]);
    title('Max Sharpe -Dynamic Portfolio Allocations Portfolio 2005&2006');
    xlabel('Rebalance Period');
    ylabel('Portforlio Weight');
    legend('MSFT', 'F',	'CRAY', 'GOOG',	'HPQ','YHOO','JAVA','DELL',	'AAPL',	'IBM','LNVGY','CSCO',	'BAC',	'INTC',	'AMD','SNE',	'NVDA', 'AMZN', 'CREAF','EK');
    hold on;
    
    end
  end
