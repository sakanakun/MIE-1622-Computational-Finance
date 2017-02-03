function  [x_optimal cash_optimal] = strat_equally_weighted(x_init, cash_init, mu, Q, cur_prices)
   x_optimal = x_init;
   cash_optimal = cash_init;
   % Initial portfolio weights
    w_init = (data_prices(1,:) .* init_positions')' / init_value;

    % Number of periods, assets, trading days
    N_periods = length(periods);
    N = length(tickers);
    N_days = length(dates);


end