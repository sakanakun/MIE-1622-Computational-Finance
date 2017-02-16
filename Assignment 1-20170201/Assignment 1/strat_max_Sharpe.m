function  [x_optimal cash_optimal] = strat_max_Sharpe(x_init, cash_init, mu, Q, cur_prices)
% number of stocks 
n =20;
%contraints
lb = zeros(n+1,1);
ub = inf*ones(n+1,1);
risk_free_rate = 0.001*ones(n,1);
mu = mu-risk_free_rate;
A = ones(1,n);
b=1;
%compute Sharpe Ratio
cplex2 = Cplex('max_SharpeRatio');
cplex2.Model.sense = 'minimize';
cplex2.addCols(zeros(n+1,1),[],lb,ub);
cplex2.addRows(b,[mu',0],b); % eq
cplex2.addRows(0,[A,-1],0);%ineq
cplex2.addRows(0,[zeros(1, n), 1], inf);
cplex2.Model.Q = 2*[Q, zeros(n,1);zeros(1,n+1)];
cplex2.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex2.Param.barrier.crossover.Cur = 1; % enable crossover
cplex2.DisplayFunc = []; % disable output to screen
cplex2.solve();

%Current porforlio value
cur_value = x_init'*cur_prices'+cash_init;

% Display minimum variance portfolio
w_maxSharpe = cplex2.Solution.x(1:length(cplex2.Solution.x)-1)/cplex2.Solution.x(length(cplex2.Solution.x));
var_maxSharpe = w_maxSharpe' * Q * w_maxSharpe;
ret_maxSharpe = mu' * w_maxSharpe;
%round the shares of stocks to the closest smaller integer
x_optimal = floor((cur_value.*w_maxSharpe)./cur_prices');
trans_cost = (x_optimal'*cur_prices'-cur_value)*0.005;
cash_optimal =(cur_value- x_optimal'*cur_prices'-trans_cost);


     if cash_optimal <0
         %display(abs(cash_optimal));
         while cash_optimal <0
             %sell one share of each stock for cash, make sure the stock
             %has more than one shares initially
             for i = 1:20
                x_optimal(i) = x_optimal(i) - 1;
                cash_optimal = cash_optimal+(1-0.005)*sum(cur_prices);
                display(cash_optimal);
                if x_optimal(i) <=0
                 x_optimal(i) = x_optimal(i)+1;
                 % If the share of the stock <= 0, we add one share
                 % back
                  cash_optimal = cash_optimal-cur_prices(i);
                  %display(cash_optimal);
                end
             end
         end
     end
     
     

%fprintf ('Maximum Sharpe Ratio portfolio:\n');
% fprintf ('Solution status = %s\n', cplex2.Solution.statusstring);
% fprintf ('Solution value = %f\n', cplex2.Solution.objval);
% fprintf ('Return = %f\n', sqrt(ret_maxSharpe));
% fprintf ('Standard deviation = %f\n\n', sqrt(var_maxSharpe));

