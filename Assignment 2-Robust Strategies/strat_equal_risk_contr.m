function  [x_optimal cash_optimal] = strat_equal_risk_contr(x_init, cash_init, mu, Q_skip, cur_prices)

global Q A_ineq A_eq
%% Add PATH to CPLEX and other solvers
n = length(x_init);

% Equality constraints
A_eq = ones(1,n);
b_eq = 1;

% Inequality constraints
A_ineq = [];
b_ineql = [];
b_inequ = [];

cur_value = cur_prices*x_init + cash_init;
% Define initial portfolio ("equally weighted" or "1/n portfolio")
w0 = repmat(1.0/n, n, 1);

options.lb = zeros(1,n);       % lower bounds on variables
options.lu = ones (1,n);       % upper bounds on variables
options.cl = [b_eq' b_ineql']; % lower bounds on constraints
options.cu = [b_eq' b_inequ']; % upper bounds on constraints

% Set the IPOPT options
options.ipopt.jac_c_constant        = 'yes';
options.ipopt.hessian_approximation = 'limited-memory';
options.ipopt.mu_strategy           = 'adaptive';
options.ipopt.tol                   = 1e-10;


% The callback functions
funcs.objective         = @computeObjERC;
funcs.constraints       = @computeConstraints;
funcs.gradient          = @computeGradERC;
funcs.jacobian          = @computeJacobian;
funcs.jacobianstructure = @computeJacobian;
options.ipopt.print_level = 0;
% !!!! Function "computeGradERC" is just the placeholder
% !!!! You need to compute the gradient yourself
  
%% Run IPOPT
[wsol info] = ipopt(w0',funcs,options);

% Make solution a column vector
if(size(wsol,1)==1)
    w_erc = wsol';
else
    w_erc = wsol;
end

% Compute return, variance and risk contribution for the ERC portfolio
ret_ERC = dot(mu, w_erc);
var_ERC = w_erc'*Q*w_erc;
 RC_ERC = (w_erc .* ( Q*w_erc )) / sqrt(w_erc'*Q*w_erc);
%round the shares of stocks to the closest smaller integer
x_optimal = floor((w_erc*cur_value)./cur_prices');
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
                trans_cost = abs(x_optimal'*cur_prices'-cur_value)*0.005;
                cash_optimal = (cur_value-(x_optimal'*cur_prices'+trans_cost));
                  end 

end