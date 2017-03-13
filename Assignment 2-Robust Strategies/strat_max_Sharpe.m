function  [x_optimal cash_optimal] = strat_max_Sharpe(x_init, cash_init, mu, Q, cur_prices)
% number of stocks 
n =20;
%contraints
lb = zeros(n+1,1);
ub = inf*ones(n+1,1);
% risk free rate is choosen as 4.22/250%
risk_free_rate = (4.22/(250*100))*ones(n,1);
mu = mu-risk_free_rate;
A1 = [-1*eye(20),0.001*ones(n,1)]; %coefficient matrix for -ay+lk <=0
A2 = [-1*eye(20),ones(n,1)];% coefficient matrix for ay-uk<=0
b=1;
% Constraints
lhs = [-inf*ones(n,1); zeros(n,1)]; %lower bound for inequality constraints
rhs = [zeros(n,1); inf*ones(n,1)]; %upper bound for inequality constraints

%compute Sharpe Ratio
cplex2 = Cplex('max_SharpeRatio');
cplex2.Model.sense = 'minimize';
cplex2.addCols(zeros(n+1,1),[],lb,ub);
cplex2.addRows(b,[mu',0],b); % equality constraint
cplex2.addRows(lhs,[A1;A2],rhs);%inequality constraint
cplex2.addRows(0,[zeros(1, n), 1], inf);
cplex2.Model.Q = 2*[Q, zeros(n,1);zeros(1,n+1)];
cplex2.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex2.Param.barrier.crossover.Cur = 1; % enable crossover
cplex2.DisplayFunc = []; % disable output to screen
cplex2.solve();


%Current porforlio value
cur_value = x_init'*cur_prices'+cash_init;

%% Display minimum variance portfolio
%weighti = yi/k, where k = sum(yi)
%w_maxSharpe = cplex2.Solution.x(1:length(cplex2.Solution.x)-1)/sum(cplex2.Solution.x(1:length(cplex2.Solution.x)-1));

    if(isfield(cplex2.Solution, 'x'))
        w_maxSharpe =cplex2.Solution.x(1:length(cplex2.Solution.x)-1)/sum(cplex2.Solution.x(1:length(cplex2.Solution.x)-1));
    else
        w_maxSharpe = (1/n)*ones(n,1);
    end  

var_maxSharpe = w_maxSharpe' * Q * w_maxSharpe;
ret_maxSharpe = mu' * w_maxSharpe;
%round the shares of stocks to the closest smaller integer
x_optimal = floor((cur_value.*w_maxSharpe)./cur_prices');
trans_cost = abs(cur_value-x_optimal'*cur_prices')*0.005;
cash_optimal =(cur_value- x_optimal'*cur_prices'-trans_cost);

%% Transaction cost compjutation and Cash Account Validation
   %display(abs(cash_optimal));
    while cash_optimal <0
             %sell one share of each stock for cash, if after rebalancing, 
             %one particular stock shares remain unchanged, do nothing 
             %about that stock 
             %need to make sure the stock has more than one shares initially
             for i = 1:20
                if x_optimal == x_init(i) 
                    x_optimal(i)=x_optimal(i);
                    %fprintf('Remain unchanged %d \n',x_optimal(i));
                else
                    x_optimal(i) = x_optimal(i)-1;
                    %while x_optimal(i)>x_init(i), reduce one share in
                    %x_optimal means buy one less share, extra cash
                    %accumulated in cash account
                    
                    %while x_optimal(i)<x_init(i), reduce one share in
                    %x_optimal means sell one more share
                     if x_optimal(i) <=0
                       x_optimal(i) = x_optimal(i)+1;
                       %if shares of stock i already = 0, add one share
                       %back 
                     end
             

               end
                
             end
            trans_cost = abs(x_optimal'*cur_prices'-cur_value)*0.005;
                cash_optimal = (cur_value-(x_optimal'*cur_prices'+trans_cost)); 
    end
    [M I] = min(cur_prices); %get index and value for the stock with lowest price
                  while cash_optimal >= min(cur_prices)*(1+0.005)
                      %while the cash balance is larger than lowest stock
                      %price plus transaction cost, we buy one more stock
                      
                      x_optimal(I) = x_optimal(I) +1;
                      %recompute the cash balance and transaction cost
                     trans_cost = abs(cur_value-x_optimal'*cur_prices')*0.005;
                    cash_optimal = (cur_value-(x_optimal'*cur_prices'+trans_cost));
                  end 

     end
     
     



