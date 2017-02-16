
function  [x_optimal cash_optimal] = strat_min_variance(x_init, cash_init, mu, Q, cur_prices)

% number of stocks 
n =20;
%contraints
lb = zeros(n,1);
ub = inf*ones(n,1);
A = ones(1,n);
b=1;

%compute mean-variance
cplex1 = Cplex('min_Variance');
cplex1.addCols(zeros(n,1),[],lb,ub);
cplex1.addRows(b,A,b);
cplex1.Model.Q = 2*Q;
cplex1.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex1.Param.barrier.crossover.Cur = 1; % enable crossover
cplex1.DisplayFunc = []; % disable output to screen
cplex1.solve();
%Current porforlio value
cur_value = x_init'*cur_prices'+cash_init;

% Display minimum variance portfolio
w_minVar = cplex1.Solution.x;
var_minVar = w_minVar' * Q * w_minVar;
ret_minVar = mu' * w_minVar;
%round the shares of stocks to the closest smaller integer
x_optimal = floor((cur_value.*w_minVar)./cur_prices');
x_balance = abs(x_optimal - x_init);
trans_cost = ((x_balance)'*cur_prices')*0.005;
%fprintf ('Minimum variance portfolio:\n');

%check cash account > 0 
 cash_optimal = (cur_value-x_optimal'*cur_prices'-trans_cost);

     if cash_optimal <0
         while cash_optimal <0
             %sell one share of each stock for cash, make sure the stock
             %has more than one shares initially
             for i = 1:20
                x_optimal(i) = x_optimal(i) - 1;
                cash_optimal = cash_optimal+(1-0.005)*sum(cur_prices);
                %display(cash_optimal);
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
% fprintf ('Solution status = %s\n', cplex1.Solution.statusstring);
% fprintf ('Solution value = %f\n', cplex1.Solution.objval);
% fprintf ('Return = %f\n', sqrt(ret_minVar));
% fprintf ('Standard deviation = %f\n\n', sqrt(var_minVar));


  
end