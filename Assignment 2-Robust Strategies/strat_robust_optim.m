function  [x_optimal cash_optimal] = strat_robust_optim(x_init, cash_init, mu, Q, cur_prices)

% number of stocks
n = 20;
%% Initial portfolio ("equally weighted" or "1/n")
w_0 = (1/n)*ones(n,1); %initially equal weight 
ret_init = dot(mu, w_0); % 1/n portfolio return
var_init = w_0' * Q * w_0; % 1/n portfolio variance
% Bounds on variables
lb_rMV = zeros(n,1); ub_rMV = inf*ones(n,1);
% Target portfolio return estimation error
var_matr = diag(diag(Q));
rob_init = w_0' * var_matr * w_0; % r.est.err. of 1/n portf
rob_bnd = rob_init; % target return estimation error
% Compute minimum variance portfolio (MVP)
%contraints

A = ones(1,n);
b=1;

%% Compute mean-variance portfolio
cplex3 = Cplex('min_Variance_comp');
cplex3.addCols(zeros(n,1),[],lb_rMV ,ub_rMV);
cplex3.addRows(b,A,b);
cplex3.Model.Q = 2*Q;
cplex3.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex3.Param.barrier.crossover.Cur = 1; % enable crossover
cplex3.DisplayFunc = []; % disable output to screen
cplex3.solve();
%Current porforlio value 
cur_value = x_init'*cur_prices'+cash_init;
w_minVar = cplex3.Solution.x;
% Display minimum variance portfolio
ret_minVar = mu' * w_minVar;
% Target portfolio return = return of MVP
Portf_Retn = ret_minVar;
%% Formulate and solve robust mean-variance problem
f_rMV = zeros(n,1); % objective function
% Constraints
A_rMV = sparse([ mu'; ones(1,n)]);
lhs_rMV = [Portf_Retn; 1]; rhs_rMV = [inf; 1];
% Create CPLEX model
cplex_rMV = Cplex('Robust_MV');
cplex_rMV.addCols(f_rMV, [], lb_rMV, ub_rMV);
cplex_rMV.addRows(lhs_rMV, A_rMV, rhs_rMV);
% Add quadratic objective
cplex_rMV.Model.Q = 2*Q;
% Add quadratic constraint on return estimation error (robustness constraint)
cplex_rMV.addQCs(zeros(size(f_rMV)), var_matr, 'L', rob_bnd, {'qc_robust'});
% Solve
cplex_rMV.solve();

%%
w_robust = cplex_rMV.Solution.x;
ret_robust = mu' * w_robust;
%round the shares of stocks to the closest smaller integer
x_optimal = floor((cur_value.*w_robust)./cur_prices');
trans_cost = abs(x_optimal'*cur_prices'-cur_value)*0.005;
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
                     trans_cost =  abs(cur_value-x_optimal'*cur_prices')*0.005;
                    cash_optimal = (cur_value-(x_optimal'*cur_prices'+trans_cost));
                  end 

end