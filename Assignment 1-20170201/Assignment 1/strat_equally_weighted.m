
function  [x_optimal cash_optimal] = strat_equally_weighted(x_init, cash_init, mu, Q, cur_prices)
   cur_value = x_init'*cur_prices'+cash_init; %initial portfotlio value
   w_equal = (1/20)*ones(20,1); %equal weight 
   %round the shares of stocks to the closest smaller integer
   x_optimal= floor((cur_value.*w_equal)./cur_prices');
   x_balance = abs(x_optimal - x_init);
   trans_cost = ((x_balance)'*cur_prices')*0.005;
   %fprintf('initial transition cost is %10.2f\n', char(trans_cost));
   cash_optimal = (cur_value-(x_optimal'*cur_prices'+trans_cost));
   %display(x_optimal);


%  Check that we can buy new portfolio subject to transaction costs
%Validation Procedure:
%If  cash < 0, according to the weight allocation, we sell each stock by 1
% at a time for cash. If the shares of the stock <= 0, we skip that stock 

     if cash_optimal <0
         %display(abs(cash_optimal));
         while cash_optimal <0
             %sell one share of each stock for cash, make sure the stock
             %has more than one shares initially
             for i = 1:20
                x_optimal(i) = x_optimal(i) - 1;
                cash_optimal = cash_optimal+(1-0.005)*sum(cur_prices);
                %get cash subject to the transation cost
                %display(cash_optimal);
                if x_optimal(i) <=0
                   % If the share of the stock <= 0, we add one share
                   % back
                 x_optimal(i) = x_optimal(i)+1;
                  cash_optimal = cash_optimal-cur_prices(i);
                  %update the new cash balance
                end
             end
         
         end
 end
