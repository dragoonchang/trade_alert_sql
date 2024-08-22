create table tickers.api_results
(
    id                             bigint unsigned auto_increment
        primary key,
    date_modified                  datetime   default CURRENT_TIMESTAMP        not null on update CURRENT_TIMESTAMP,
    completed                      tinyint(1) default 0                        null,
    ticker_id                      int unsigned                                null,
    symbol                         varchar(10)                                 not null,
    vendor                         enum ('polygon', 'yahoo')                   not null,
    api_type                       enum ('stock', 'news', 'ticker_details_v3') not null,
    search_for_date                date                                        null,
    primary_exchange               varchar(255)                                null,
    ticker_type                    varchar(255)                                null,
    active                         tinyint(1)                                  null,
    list_date                      date                                        null,
    delisted_date                  date                                        null,
    public_float                   bigint unsigned                             null,
    share_class_shares_outstanding bigint unsigned                             null,
    weighted_shares_outstanding    bigint unsigned                             null,
    results                        text                                        not null
);

create index api_results_all_index
    on tickers.api_results (id, ticker_id, symbol, vendor, api_type, search_for_date, completed, date_modified);

create index api_results_bulk_idx
    on tickers.api_results (id, ticker_id, symbol, search_for_date, api_type, vendor);

create table tickers.days
(
    id                 int unsigned auto_increment
        primary key,
    date               date              not null,
    weekday            tinyint unsigned  null,
    first_day_of_month tinyint unsigned  null,
    last_day_of_month  tinyint unsigned  null,
    first_day_of_year  tinyint unsigned  null,
    last_day_of_year   tinyint unsigned  null,
    week_of_month      tinyint unsigned  null,
    week_of_year       tinyint unsigned  null,
    days_of_year       smallint unsigned null,
    leap_year          tinyint unsigned  null,
    constraint days_date_unique
        unique (date)
);

create index idx_week_of_year
    on tickers.days (id, date, week_of_year);

create table tickers.high_gainers
(
    ticker_id                           int unsigned   not null,
    symbol                              varchar(100)   not null,
    date                                date           not null,
    stage_days                          int            null,
    stage_final                         tinyint        null,
    share_class_shares_outstanding_in_m decimal(24, 4) null,
    weighted_shares_outstanding_in_m    decimal(24, 4) null,
    pre_close                           float          null,
    pm_gain_pct                         double         null,
    pm_high_minute                      varchar(5)     null,
    pm_volume                           decimal(24, 4) null,
    mh_open                             float          null,
    mh_high                             float          null,
    mh_low                              float          null,
    mh_close                            float          null,
    mh_gain_pct                         double         null,
    am_gain_pct                         double         null,
    am_high_minute                      varchar(5)     null,
    am_volume_m                         decimal(24, 4) null,
    mh_volume_m                         decimal(24, 4) null,
    mh_volume_value_m                   double         null,
    `5_range_from_low`                  float          null,
    `10_range_from_low`                 float          null,
    `20_range_from_low`                 float          null,
    `5_range_from_high`                 float          null,
    `10_range_from_high`                float          null,
    `20_range_from_high`                float          null,
    primary key (ticker_id, date)
);

create index high_gainers_ticker_id_date_symbol_index
    on tickers.high_gainers (ticker_id, date, symbol);

create table tickers.history_daily_events
(
    id                   bigint auto_increment
        primary key,
    date                 date null,
    max_volume_ticker_id int  null,
    constraint history_daily_events_date_uindex
        unique (date)
);

create table tickers.history_day_gaps
(
    id         bigint unsigned auto_increment
        primary key,
    ticker_id  int unsigned not null,
    start_date date         not null,
    end_date   date         not null,
    datediff   int unsigned null,
    constraint history_day_gaps_pk_2
        unique (ticker_id, start_date)
);

create table tickers.history_day_stats
(
    ticker_id                      int unsigned                              not null,
    date                           date                                      not null,
    date_modified                  datetime        default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    share_class_shares_outstanding bigint unsigned                           null,
    weighted_shares_outstanding    bigint unsigned                           null,
    `5_range_from_low`             float                                     null,
    `10_range_from_low`            float                                     null,
    `20_range_from_low`            float                                     null,
    `5_range_from_high`            float                                     null,
    `10_range_from_high`           float                                     null,
    `20_range_from_high`           float                                     null,
    premarket_high_minute          smallint unsigned                         null,
    premarket_high                 float                                     null,
    premarket_low_minute           smallint unsigned                         null,
    premarket_low                  float                                     null,
    premarket_ratio                float                                     null,
    premarket_open                 float                                     null,
    premarket_close                float                                     null,
    premarket_volume               bigint unsigned default '0'               null,
    market_hour_high_minute        smallint unsigned                         null,
    market_hour_low_minute         smallint unsigned                         null,
    after_10_30_low                float                                     null,
    after_10_30_low_minute         smallint unsigned                         null,
    aftermarket_high_minute        smallint unsigned                         null,
    aftermarket_high               float                                     null,
    aftermarket_low_minute         smallint unsigned                         null,
    aftermarket_low                float                                     null,
    aftermarket_ratio              float                                     null,
    aftermarket_open               float                                     null,
    aftermarket_close              float                                     null,
    aftermarket_volume             bigint unsigned default '0'               null,
    primary key (ticker_id, date)
);

create index history_day_stats_full_index
    on tickers.history_day_stats (ticker_id asc, date desc, aftermarket_ratio asc, premarket_ratio asc,
                                  `20_range_from_low` asc, `20_range_from_high` asc, share_class_shares_outstanding asc,
                                  weighted_shares_outstanding asc);

create table tickers.labeling_days
(
    id            bigint auto_increment
        primary key,
    strategy_type enum ('long_buy', 'long_tp', 'long_sl', 'short_sell', 'short_tp', 'short_sl', 'fgd') default 'long_buy'        null,
    symbol        varchar(100)                                                                                                   not null,
    start         bigint unsigned                                                                                                not null,
    end           bigint unsigned                                                                                                not null,
    date_modified datetime                                                                             default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP
);

create index labeling_days_full_index
    on tickers.labeling_days (strategy_type, symbol, start, end);

create table tickers.labeling_minute_days
(
    id            bigint auto_increment
        primary key,
    ticker_id     int                                                            not null,
    strategy_type enum ('fgd_buy', 'fgd_tp', 'fgd_sl') default 'fgd_buy'         not null,
    date          date                                                           not null,
    date_created  datetime                             default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint labeling_minute_days_pk
        unique (ticker_id, strategy_type, date)
);

create table tickers.labeling_minutes
(
    id            bigint auto_increment
        primary key,
    strategy_type enum ('fgd_buy', 'fgd_tp', 'fgd_sl') default 'fgd_buy'         null,
    symbol        varchar(100)                                                   not null,
    date          date                                                           not null,
    start         bigint unsigned                                                not null,
    end           bigint unsigned                                                not null,
    date_modified datetime                             default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP
);

create index labeling_minutes_full_index
    on tickers.labeling_minutes (strategy_type, symbol, date, start, end);

create table tickers.miss_history_minutes
(
    id        bigint auto_increment
        primary key,
    ticker_id int unsigned not null,
    date      date         not null
);

create index miss_history_minutes_index
    on tickers.miss_history_minutes (ticker_id, date);

create table tickers.polygon_minutes
(
    sym varchar(10) charset utf8mb4 not null comment 'The ticker symbol for the given stock.',
    s   datetime                    not null comment 'The timestamp of the starting tick for this aggregate window in Unix Milliseconds.',
    v   int unsigned                not null comment 'The tick volume.',
    av  int unsigned                not null comment 'Today''s accumulated volume.',
    op  float                       null comment 'Today''s official opening price.',
    vw  float                       null comment 'The tick''s volume weighted average price.',
    o   float                       null comment 'The opening tick price for this aggregate window.',
    c   float                       null comment 'The closing tick price for this aggregate window.',
    h   float                       null comment 'The highest tick price for this aggregate window.',
    l   float                       null comment 'The lowest tick price for this aggregate window.',
    a   float                       null comment 'Today''s volume weighted average price.',
    z   int unsigned                null comment 'The average trade size for this aggregate window.'
)
    charset = ascii;

create index idx_sym_s
    on tickers.polygon_minutes (sym asc, s desc);

create index s
    on tickers.polygon_minutes (s desc);

create table tickers.polygon_seconds
(
    sym varchar(10) charset utf8mb4 not null comment 'The ticker symbol for the given stock.',
    s   datetime                    not null comment 'The timestamp of the starting tick for this aggregate window in Unix Milliseconds.',
    v   int unsigned                not null comment 'The tick volume.',
    av  int unsigned                not null comment 'Today''s accumulated volume.',
    op  float                       null comment 'Today''s official opening price.',
    vw  float                       null comment 'The tick''s volume weighted average price.',
    o   float                       null comment 'The opening tick price for this aggregate window.',
    c   float                       null comment 'The closing tick price for this aggregate window.',
    h   float                       null comment 'The highest tick price for this aggregate window.',
    l   float                       null comment 'The lowest tick price for this aggregate window.',
    a   float                       null comment 'Today''s volume weighted average price.',
    z   int unsigned                null comment 'The average trade size for this aggregate window.'
)
    charset = ascii;

create index s
    on tickers.polygon_seconds (s desc);

create index s_sym
    on tickers.polygon_seconds (s desc, sym asc);

create table tickers.predict_minutes
(
    ticker_id int                                not null,
    date      date                               not null,
    minute    int                                not null,
    strategy  enum ('buy', 'sell') default 'buy' not null,
    predict   float                default 0     not null,
    `3_9`     tinyint(1)           default 0     not null,
    `3_12`    tinyint(1)           default 0     not null,
    `4_12`    tinyint(1)           default 0     not null,
    `4_16`    tinyint(1)           default 0     not null,
    `5_15`    tinyint(1)           default 0     not null,
    `5_20`    tinyint(1)           default 0     not null,
    primary key (ticker_id, date, minute, strategy)
);

create table tickers.temp_vars
(
    id    bigint auto_increment
        primary key,
    `key` varchar(100)  not null,
    value varchar(1000) not null,
    constraint temp_vars_key_uindex
        unique (`key`)
);

create table tickers.ticker_dividends
(
    symbol           varchar(100)                        not null,
    record_date      date                                not null,
    dividend_type    varchar(100)                        not null,
    frequency        int unsigned                        null,
    currency         varchar(20)                         not null,
    cash_amount      float                               not null,
    declaration_date date                                null,
    ex_dividend_date date                                null,
    pay_date         date                                null,
    date_modified    timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    primary key (symbol, record_date)
);

create table tickers.ticker_splits
(
    symbol         varchar(100)                        not null,
    execution_date date                                not null,
    split_from     float                               null,
    split_to       float                               null,
    date_modified  timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    applied        bit       default b'0'              not null,
    primary key (symbol, execution_date)
);

create table tickers.ticker_stats
(
    ticker_id         int unsigned             not null
        primary key,
    day_first_date    date                     null,
    day_last_date     date                     null,
    day_row_count     int unsigned default '0' not null,
    day_date_modified datetime                 null
);

create table tickers.tickers
(
    id                           int unsigned auto_increment
        primary key,
    deleted                      tinyint    default 0                 null,
    symbol                       varchar(100)                         not null,
    with_minute_ema              tinyint(1) default 0                 not null,
    disable_update               tinyint    default 0                 not null,
    zip                          varchar(100)                         null,
    sector                       varchar(100)                         null,
    fullTimeEmployees            varchar(100)                         null,
    longBusinessSummary          varchar(8000)                        null,
    city                         varchar(100)                         null,
    phone                        varchar(100)                         null,
    state                        varchar(100)                         null,
    country                      varchar(100)                         null,
    companyOfficers              varchar(200)                         null,
    website                      varchar(255)                         null,
    maxAge                       float                                null,
    address1                     varchar(100)                         null,
    fax                          varchar(100)                         null,
    industry                     varchar(100)                         null,
    previousClose                float                                null,
    regularMarketOpen            float                                null,
    twoHundredDayAverage         float                                null,
    trailingAnnualDividendYield  float                                null,
    payoutRatio                  float                                null,
    volume24Hr                   varchar(100)                         null,
    regularMarketDayHigh         float                                null,
    navPrice                     float                                null,
    averageDailyVolume10Day      bigint                               null,
    totalAssets                  varchar(100)                         null,
    regularMarketPreviousClose   float                                null,
    fiftyDayAverage              float                                null,
    trailingAnnualDividendRate   float                                null,
    open                         float                                null,
    toCurrency                   varchar(100)                         null,
    averageVolume10days          float                                null,
    expireDate                   bigint                               null,
    yield                        varchar(100)                         null,
    algorithm                    varchar(100)                         null,
    dividendRate                 float                                null,
    exDividendDate               bigint                               null,
    beta                         float                                null,
    circulatingSupply            varchar(100)                         null,
    startDate                    bigint                               null,
    regularMarketDayLow          float                                null,
    priceHint                    bigint                               null,
    currency                     varchar(100)                         null,
    trailingPE                   varchar(100)                         null,
    regularMarketVolume          bigint                               null,
    lastMarket                   varchar(100)                         null,
    maxSupply                    varchar(100)                         null,
    openInterest                 varchar(100)                         null,
    marketCap                    bigint                               null,
    volumeAllCurrencies          varchar(100)                         null,
    strikePrice                  varchar(100)                         null,
    averageVolume                bigint                               null,
    priceToSalesTrailing12Months varchar(100)                         null,
    dayLow                       float                                null,
    ask                          float                                null,
    ytdReturn                    varchar(100)                         null,
    askSize                      bigint                               null,
    volume                       bigint                               null,
    fiftyTwoWeekHigh             float                                null,
    forwardPE                    float                                null,
    fromCurrency                 varchar(100)                         null,
    fiveYearAvgDividendYield     float                                null,
    fiftyTwoWeekLow              float                                null,
    bid                          float                                null,
    tradeable                    varchar(100)                         null,
    dividendYield                float                                null,
    bidSize                      bigint                               null,
    dayHigh                      float                                null,
    exchange                     varchar(100)                         null,
    shortName                    varchar(100)                         null,
    longName                     varchar(200)                         null,
    exchangeTimezoneName         varchar(100)                         null,
    exchangeTimezoneShortName    varchar(100)                         null,
    isEsgPopulated               varchar(100)                         null,
    gmtOffSetMilliseconds        varchar(100)                         null,
    quoteType                    varchar(100)                         null,
    messageBoardId               varchar(100)                         null,
    market                       varchar(100)                         null,
    annualHoldingsTurnover       varchar(100)                         null,
    enterpriseToRevenue          float                                null,
    beta3Year                    varchar(100)                         null,
    profitMargins                float                                null,
    enterpriseToEbitda           float                                null,
    `52WeekChange`               float                                null,
    morningStarRiskRating        varchar(100)                         null,
    forwardEps                   float                                null,
    revenueQuarterlyGrowth       varchar(100)                         null,
    sharesOutstanding            bigint                               null,
    fundInceptionDate            bigint                               null,
    annualReportExpenseRatio     varchar(100)                         null,
    bookValue                    float                                null,
    sharesShort                  bigint                               null,
    sharesPercentSharesOut       float                                null,
    fundFamily                   varchar(100)                         null,
    lastFiscalYearEnd            bigint                               null,
    heldPercentInstitutions      float                                null,
    netIncomeToCommon            bigint                               null,
    trailingEps                  float                                null,
    lastDividendValue            varchar(100)                         null,
    SandP52WeekChange            float                                null,
    priceToBook                  float                                null,
    heldPercentInsiders          float                                null,
    nextFiscalYearEnd            bigint                               null,
    mostRecentQuarter            bigint                               null,
    shortRatio                   float                                null,
    sharesShortPreviousMonthDate bigint                               null,
    floatShares                  bigint                               null,
    enterpriseValue              bigint                               null,
    threeYearAverageReturn       varchar(100)                         null,
    lastSplitDate                bigint                               null,
    lastSplitFactor              varchar(100)                         null,
    legalType                    varchar(100)                         null,
    morningStarOverallRating     varchar(100)                         null,
    earningsQuarterlyGrowth      float                                null,
    dateShortInterest            bigint                               null,
    pegRatio                     float                                null,
    lastCapGain                  varchar(100)                         null,
    shortPercentOfFloat          float                                null,
    sharesShortPriorMonth        bigint                               null,
    category                     varchar(100)                         null,
    fiveYearAverageReturn        varchar(100)                         null,
    regularMarketPrice           float                                null,
    logo_url                     varchar(200)                         null,
    day_date_modified            datetime                             null,
    minute_date_modified         datetime                             null,
    date_modified                timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint tickers_unique
        unique (symbol)
);

create index tickers_id_symbol_deleted_with_minute_ema_index
    on tickers.tickers (id, symbol, deleted, with_minute_ema);

create table tickers.trade_labels
(
    id            bigint auto_increment comment 'A unique identifier for each label entry'
        primary key,
    strategy_type enum ('first_green_day', 'breakout_trading', 'follow_through_day', 'gap_and_go', 'dip_buy', 'pullback_to_support') default 'first_green_day' not null comment 'The type of trading strategy associated with the label',
    action        enum ('entry_point', 'take_profit', 'stop_loss')                                                                   default 'entry_point'     not null comment 'The type of action being labeled (e.g., entry point, take profit, stop loss)',
    symbol        varchar(10)                                                                                                                                  not null comment 'The stock symbol associated with the label',
    start         bigint unsigned                                                                                                                              not null comment 'The start time of the labeled period, typically represented as a timestamp',
    end           bigint unsigned                                                                                                                              not null comment 'The end time of the labeled period, typically represented as a timestamp',
    time_frame    enum ('daily', 'minute')                                                                                                                     not null comment 'Indicates whether the label is based on daily or minute-level data',
    created_at    datetime                                                                                                           default CURRENT_TIMESTAMP not null comment 'Records the timestamp when the entry was created',
    updated_at    datetime                                                                                                           default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment 'Automatically updates to the current timestamp whenever the entry is modified'
)
    comment 'Table to store labels for various trading strategies, tracking key actions and time frames';

create index idx_trade_labels_full
    on tickers.trade_labels (strategy_type, action, symbol, start, end, time_frame)
    comment 'Composite index to optimize queries filtering by strategy type, action, symbol, start and end times, and time frame';

create table tickers.unsplit_history_days
(
    ticker_id                      int unsigned                              not null,
    date                           date                                      not null,
    open                           float                                     null,
    high                           float                                     null,
    low                            float                                     null,
    close                          float                                     null,
    trades                         int unsigned    default '0'               null,
    volume                         bigint unsigned default '0'               null,
    vwap                           float                                     null,
    `9ema`                         float                                     null,
    `20ema`                        float                                     null,
    `300ema`                       float                                     null,
    cumulative_reverse_split_ratio float unsigned  default '1'               null,
    market_session_change_ratio    float           default 1                 null,
    price_change_ratio             float           default 0                 null,
    trend_reversal                 tinyint         default 0                 null,
    consecutive_trend_days         int             default 0                 null,
    date_modified                  datetime        default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    previous_date                  date                                      null,
    primary key (ticker_id, date)
);

create index unsplit_history_days_date_index
    on tickers.unsplit_history_days (date desc);

create index unsplit_history_days_full_index
    on tickers.unsplit_history_days (ticker_id asc, date desc, high asc, low asc, close asc, volume asc,
                                     consecutive_trend_days asc, trend_reversal asc, market_session_change_ratio asc,
                                     price_change_ratio asc);

create table tickers.unsplit_history_minutes
(
    ticker_id     int unsigned                       not null,
    date          date                               not null,
    minute        smallint unsigned                  not null,
    open          float                              not null,
    high          float                              not null,
    low           float                              not null,
    close         float                              not null,
    vwap          float                              null,
    `9ema`        float                              null,
    `20ema`       float                              null,
    `300ema`      float                              null,
    trades        int unsigned                       not null,
    volume        int unsigned                       not null,
    date_modified datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    primary key (ticker_id, date, minute)
)
    partition by range columns (`date`) (
        partition p2000q1 values less than ('2000-04-01'),
        partition p2000q2 values less than ('2000-07-01'),
        partition p2000q3 values less than ('2000-10-01'),
        partition p2000q4 values less than ('2001-01-01'),
        partition p2001q1 values less than ('2001-04-01'),
        partition p2001q2 values less than ('2001-07-01'),
        partition p2001q3 values less than ('2001-10-01'),
        partition p2001q4 values less than ('2002-01-01'),
        partition p2002q1 values less than ('2002-04-01'),
        partition p2002q2 values less than ('2002-07-01'),
        partition p2002q3 values less than ('2002-10-01'),
        partition p2002q4 values less than ('2003-01-01'),
        partition p2003q1 values less than ('2003-04-01'),
        partition p2003q2 values less than ('2003-07-01'),
        partition p2003q3 values less than ('2003-10-01'),
        partition p2003q4 values less than ('2004-01-01'),
        partition p2004q1 values less than ('2004-04-01'),
        partition p2004q2 values less than ('2004-07-01'),
        partition p2004q3 values less than ('2004-10-01'),
        partition p2004q4 values less than ('2005-01-01'),
        partition p2005q1 values less than ('2005-04-01'),
        partition p2005q2 values less than ('2005-07-01'),
        partition p2005q3 values less than ('2005-10-01'),
        partition p2005q4 values less than ('2006-01-01'),
        partition p2006q1 values less than ('2006-04-01'),
        partition p2006q2 values less than ('2006-07-01'),
        partition p2006q3 values less than ('2006-10-01'),
        partition p2006q4 values less than ('2007-01-01'),
        partition p2007q1 values less than ('2007-04-01'),
        partition p2007q2 values less than ('2007-07-01'),
        partition p2007q3 values less than ('2007-10-01'),
        partition p2007q4 values less than ('2008-01-01'),
        partition p2008q1 values less than ('2008-04-01'),
        partition p2008q2 values less than ('2008-07-01'),
        partition p2008q3 values less than ('2008-10-01'),
        partition p2008q4 values less than ('2009-01-01'),
        partition p2009q1 values less than ('2009-04-01'),
        partition p2009q2 values less than ('2009-07-01'),
        partition p2009q3 values less than ('2009-10-01'),
        partition p2009q4 values less than ('2010-01-01'),
        partition p2010q1 values less than ('2010-04-01'),
        partition p2010q2 values less than ('2010-07-01'),
        partition p2010q3 values less than ('2010-10-01'),
        partition p2010q4 values less than ('2011-01-01'),
        partition p2011q1 values less than ('2011-04-01'),
        partition p2011q2 values less than ('2011-07-01'),
        partition p2011q3 values less than ('2011-10-01'),
        partition p2011q4 values less than ('2012-01-01'),
        partition p2012q1 values less than ('2012-04-01'),
        partition p2012q2 values less than ('2012-07-01'),
        partition p2012q3 values less than ('2012-10-01'),
        partition p2012q4 values less than ('2013-01-01'),
        partition p2013q1 values less than ('2013-04-01'),
        partition p2013q2 values less than ('2013-07-01'),
        partition p2013q3 values less than ('2013-10-01'),
        partition p2013q4 values less than ('2014-01-01'),
        partition p2014q1 values less than ('2014-04-01'),
        partition p2014q2 values less than ('2014-07-01'),
        partition p2014q3 values less than ('2014-10-01'),
        partition p2014q4 values less than ('2015-01-01'),
        partition p2015q1 values less than ('2015-04-01'),
        partition p2015q2 values less than ('2015-07-01'),
        partition p2015q3 values less than ('2015-10-01'),
        partition p2015q4 values less than ('2016-01-01'),
        partition p2016q1 values less than ('2016-04-01'),
        partition p2016q2 values less than ('2016-07-01'),
        partition p2016q3 values less than ('2016-10-01'),
        partition p2016q4 values less than ('2017-01-01'),
        partition p2017q1 values less than ('2017-04-01'),
        partition p2017q2 values less than ('2017-07-01'),
        partition p2017q3 values less than ('2017-10-01'),
        partition p2017q4 values less than ('2018-01-01'),
        partition p2018q1 values less than ('2018-04-01'),
        partition p2018q2 values less than ('2018-07-01'),
        partition p2018q3 values less than ('2018-10-01'),
        partition p2018q4 values less than ('2019-01-01'),
        partition p2019q1 values less than ('2019-04-01'),
        partition p2019q2 values less than ('2019-07-01'),
        partition p2019q3 values less than ('2019-10-01'),
        partition p2019q4 values less than ('2020-01-01'),
        partition p2020q1 values less than ('2020-04-01'),
        partition p2020q2 values less than ('2020-07-01'),
        partition p2020q3 values less than ('2020-10-01'),
        partition p2020q4 values less than ('2021-01-01'),
        partition p2021q1 values less than ('2021-04-01'),
        partition p2021q2 values less than ('2021-07-01'),
        partition p2021q3 values less than ('2021-10-01'),
        partition p2021q4 values less than ('2022-01-01'),
        partition p2022q1 values less than ('2022-04-01'),
        partition p2022q2 values less than ('2022-07-01'),
        partition p2022q3 values less than ('2022-10-01'),
        partition p2022q4 values less than ('2023-01-01'),
        partition p2023q1 values less than ('2023-04-01'),
        partition p2023q2 values less than ('2023-07-01'),
        partition p2023q3 values less than ('2023-10-01'),
        partition p2023q4 values less than ('2024-01-01'),
        partition p2024q1 values less than ('2024-04-01'),
        partition p2024q2 values less than ('2024-07-01'),
        partition p2024q3 values less than ('2024-10-01'),
        partition p2024q4 values less than ('2025-01-01'),
        partition p2025q1 values less than ('2025-04-01'),
        partition p2025q2 values less than ('2025-07-01'),
        partition p2025q3 values less than ('2025-10-01'),
        partition p2025q4 values less than ('2026-01-01'),
        partition p2026q1 values less than ('2026-04-01'),
        partition p2026q2 values less than ('2026-07-01'),
        partition p2026q3 values less than ('2026-10-01'),
        partition p2026q4 values less than ('2027-01-01'),
        partition p2027q1 values less than ('2027-04-01'),
        partition p2027q2 values less than ('2027-07-01'),
        partition p2027q3 values less than ('2027-10-01'),
        partition p2027q4 values less than ('2028-01-01'),
        partition p2028q1 values less than ('2028-04-01'),
        partition p2028q2 values less than ('2028-07-01'),
        partition p2028q3 values less than ('2028-10-01'),
        partition p2028q4 values less than ('2029-01-01'),
        partition p2029q1 values less than ('2029-04-01'),
        partition p2029q2 values less than ('2029-07-01'),
        partition p2029q3 values less than ('2029-10-01'),
        partition p2029q4 values less than ('2030-01-01'),
        partition p2030q1 values less than ('2030-04-01'),
        partition p2030q2 values less than ('2030-07-01'),
        partition p2030q3 values less than ('2030-10-01'),
        partition p2030q4 values less than ('2031-01-01'),
        partition p2031q1 values less than ('2031-04-01'),
        partition p2031q2 values less than ('2031-07-01'),
        partition p2031q3 values less than ('2031-10-01'),
        partition p2031q4 values less than ('2032-01-01'),
        partition p2032q1 values less than ('2032-04-01'),
        partition p2032q2 values less than ('2032-07-01'),
        partition p2032q3 values less than ('2032-10-01'),
        partition p2032q4 values less than ('2033-01-01'),
        partition p2033q1 values less than ('2033-04-01'),
        partition p2033q2 values less than ('2033-07-01'),
        partition p2033q3 values less than ('2033-10-01'),
        partition p2033q4 values less than ('2034-01-01'),
        partition p2034q1 values less than ('2034-04-01'),
        partition p2034q2 values less than ('2034-07-01'),
        partition p2034q3 values less than ('2034-10-01'),
        partition p2034q4 values less than ('2035-01-01'),
        partition p2035q1 values less than ('2035-04-01'),
        partition p2035q2 values less than ('2035-07-01'),
        partition p2035q3 values less than ('2035-10-01'),
        partition p2035q4 values less than ('2036-01-01'),
        partition p2036q1 values less than ('2036-04-01'),
        partition p2036q2 values less than ('2036-07-01'),
        partition p2036q3 values less than ('2036-10-01'),
        partition p2036q4 values less than ('2037-01-01'),
        partition p2037q1 values less than ('2037-04-01'),
        partition p2037q2 values less than ('2037-07-01'),
        partition p2037q3 values less than ('2037-10-01'),
        partition p2037q4 values less than ('2038-01-01'),
        partition p2038q1 values less than ('2038-04-01'),
        partition p2038q2 values less than ('2038-07-01'),
        partition p2038q3 values less than ('2038-10-01'),
        partition p2038q4 values less than ('2039-01-01'),
        partition p2039q1 values less than ('2039-04-01'),
        partition p2039q2 values less than ('2039-07-01'),
        partition p2039q3 values less than ('2039-10-01'),
        partition p2039q4 values less than ('2040-01-01'),
        partition pFuture values less than (MAXVALUE)
        );

create index unsplit_history_minutes_ticker_id_index
    on tickers.unsplit_history_minutes (ticker_id);

create table tickers.unsplit_polygon_seconds
(
    sym varchar(10)  not null comment 'The ticker symbol for the given stock.',
    s   timestamp    not null comment 'The Unix sec timestamp for the start of the aggregate window.',
    v   int unsigned not null comment 'The tick volume.',
    vw  float        null comment 'The tick''s volume weighted average price.',
    o   float        null comment 'The opening tick price for this aggregate window.',
    c   float        null comment 'The closing tick price for this aggregate window.',
    h   float        null comment 'The highest tick price for this aggregate window.',
    l   float        null comment 'The lowest tick price for this aggregate window.',
    n   int unsigned not null comment 'The number of transactions in the aggregate window.',
    primary key (sym, s)
)
    charset = ascii;

create index s_sym
    on tickers.unsplit_polygon_seconds (s desc, sym asc);

create index t
    on tickers.unsplit_polygon_seconds (s desc);

create table tickers.volatilities
(
    ticker_id              int unsigned                              not null,
    Symbol                 varchar(100)                              null,
    Date                   date                                      not null,
    PreClose               float           default 0                 not null,
    PreVolume              bigint          default 0                 null,
    Open                   float           default 0                 not null,
    High                   float           default 0                 not null,
    Low                    float           default 0                 not null,
    Close                  float           default 0                 not null,
    Volume                 bigint unsigned default '0'               not null,
    HighOfDay              float           default 0                 not null,
    LowOfDay               float           default 0                 not null,
    VolatilityPct          float           default 0                 not null,
    Vwap                   float           default 0                 not null,
    AboveVwapMin           int unsigned    default '0'               not null,
    BelowVwapMin           int unsigned    default '0'               not null,
    AboveVwapMins          int unsigned    default '0'               not null,
    BelowVwapMins          int unsigned    default '0'               not null,
    AboveVwapPct           float           default 0                 not null,
    BelowVwapPct           float           default 0                 not null,
    NewHighOfDayMins       int unsigned    default '0'               not null,
    NewLowOfDayMins        int unsigned    default '0'               not null,
    LastNewHighOfDay       datetime        default CURRENT_TIMESTAMP null,
    LastNewLowOfDay        datetime        default CURRENT_TIMESTAMP null,
    GapUp                  float           default 0                 not null,
    MaxGapUp               float           default 0                 not null,
    PreMarketHigh          float           default 0                 not null,
    PreMarketHighMin       int unsigned    default '0'               not null,
    AfterMarketHigh        float           default 0                 null,
    AfterMarketHighMin     int unsigned    default '0'               null,
    Pre1MinClose           float           default 0                 null,
    Pre1MinVolume          bigint unsigned default '0'               null,
    Pre1MinDate            datetime        default CURRENT_TIMESTAMP null,
    Pre2MinClose           float           default 0                 null,
    Pre2MinVolume          bigint unsigned default '0'               null,
    Pre2MinDate            datetime        default CURRENT_TIMESTAMP null,
    Pre3MinClose           float           default 0                 null,
    Pre3MinVolume          bigint unsigned default '0'               null,
    Pre3MinDate            datetime        default CURRENT_TIMESTAMP null,
    Pre4MinClose           float           default 0                 null,
    Pre4MinVolume          bigint unsigned default '0'               null,
    Pre4MinDate            datetime        default CURRENT_TIMESTAMP null,
    Pre5minClose           float           default 0                 null,
    Pre5MinVolume          bigint unsigned default '0'               null,
    Pre5MinDate            datetime        default CURRENT_TIMESTAMP null,
    `9ema`                 float           default 0                 null,
    `20ema`                float           default 0                 null,
    `300ema`               float           default 0                 null,
    CurrentOpen            float           default 0                 null,
    CurrentHigh            float           default 0                 null,
    CurrentLow             float           default 0                 null,
    CurrentClose           float           default 0                 null,
    CurrentVolume          bigint unsigned default '0'               null,
    CurrentVwap            float           default 0                 null,
    CurrentClose9emaDiff   float           default 0                 null,
    CurrentClose20emaDiff  float           default 0                 null,
    CurrentClose300emaDiff float           default 0                 null,
    StageDays              int                                       null,
    SharesFloat            float unsigned                            null,
    date_modified          datetime        default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    primary key (ticker_id, Date)
);

create index idx_bulk
    on tickers.volatilities (ticker_id, Date, VolatilityPct, CurrentClose9emaDiff, CurrentClose20emaDiff,
                             CurrentClose300emaDiff, Close, LastNewHighOfDay, LastNewLowOfDay);

create table tickers.volatilities_backup
(
    ticker_id              int unsigned                              not null,
    Symbol                 varchar(100)                              null,
    Date                   date                                      not null,
    PreClose               float           default 0                 not null,
    PreVolume              bigint          default 0                 null,
    Open                   float           default 0                 not null,
    High                   float           default 0                 not null,
    Low                    float           default 0                 not null,
    Close                  float           default 0                 not null,
    Volume                 bigint unsigned default '0'               not null,
    HighOfDay              float           default 0                 not null,
    LowOfDay               float           default 0                 not null,
    VolatilityPct          float           default 0                 not null,
    Vwap                   float           default 0                 not null,
    AboveVwapMin           int unsigned    default '0'               not null,
    BelowVwapMin           int unsigned    default '0'               not null,
    AboveVwapMins          int unsigned    default '0'               not null,
    BelowVwapMins          int unsigned    default '0'               not null,
    AboveVwapPct           float           default 0                 not null,
    BelowVwapPct           float           default 0                 not null,
    NewHighOfDayMins       int unsigned    default '0'               not null,
    NewLowOfDayMins        int unsigned    default '0'               not null,
    LastNewHighOfDay       datetime        default CURRENT_TIMESTAMP null,
    LastNewLowOfDay        datetime        default CURRENT_TIMESTAMP null,
    GapUp                  float           default 0                 not null,
    MaxGapUp               float           default 0                 not null,
    PreMarketHigh          float           default 0                 not null,
    PreMarketHighMin       int unsigned    default '0'               not null,
    AfterMarketHigh        float           default 0                 null,
    AfterMarketHighMin     int unsigned    default '0'               null,
    Pre1MinClose           float           default 0                 null,
    Pre1MinVolume          bigint unsigned default '0'               null,
    Pre1MinDate            datetime        default CURRENT_TIMESTAMP null,
    Pre2MinClose           float           default 0                 null,
    Pre2MinVolume          bigint unsigned default '0'               null,
    Pre2MinDate            datetime        default CURRENT_TIMESTAMP null,
    Pre3MinClose           float           default 0                 null,
    Pre3MinVolume          bigint unsigned default '0'               null,
    Pre3MinDate            datetime        default CURRENT_TIMESTAMP null,
    Pre4MinClose           float           default 0                 null,
    Pre4MinVolume          bigint unsigned default '0'               null,
    Pre4MinDate            datetime        default CURRENT_TIMESTAMP null,
    Pre5minClose           float           default 0                 null,
    Pre5MinVolume          bigint unsigned default '0'               null,
    Pre5MinDate            datetime        default CURRENT_TIMESTAMP null,
    `9ema`                 float           default 0                 null,
    `20ema`                float           default 0                 null,
    `300ema`               float           default 0                 null,
    CurrentOpen            float           default 0                 null,
    CurrentHigh            float           default 0                 null,
    CurrentLow             float           default 0                 null,
    CurrentClose           float           default 0                 null,
    CurrentVolume          bigint unsigned default '0'               null,
    CurrentVwap            float           default 0                 null,
    CurrentClose9emaDiff   float           default 0                 null,
    CurrentClose20emaDiff  float           default 0                 null,
    CurrentClose300emaDiff float           default 0                 null,
    StageDays              int                                       null,
    SharesFloat            float unsigned                            null,
    date_modified          datetime        default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    primary key (ticker_id, Date)
);

create index idx_bulk
    on tickers.volatilities_backup (ticker_id, Date, VolatilityPct, CurrentClose9emaDiff, CurrentClose20emaDiff,
                                    CurrentClose300emaDiff, Close, LastNewHighOfDay, LastNewLowOfDay);

