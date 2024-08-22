create definer = root@localhost view tickers.view_alert_volatilities as
select `alerts`.`Symbol`                                                     AS `Symbol`,
       `alerts`.`StageDays`                                                  AS `StageDays`,
       `alerts`.`SharesFloat`                                                AS `SharesFloat`,
       `alerts`.`PreClose`                                                   AS `PreClose`,
       `alerts`.`Open`                                                       AS `Open`,
       `alerts`.`High`                                                       AS `High`,
       `alerts`.`Low`                                                        AS `Low`,
       `alerts`.`Close`                                                      AS `Close`,
       `alerts`.`PreVolume`                                                  AS `PreVolume`,
       `alerts`.`Volume`                                                     AS `Volume`,
       `alerts`.`VolatilityPct`                                              AS `VolatilityPct`,
       `alerts`.`HighOfDay`                                                  AS `HighOfDay`,
       `alerts`.`CurrentClose`                                               AS `CurrentClose`,
       `alerts`.`9ema`                                                       AS `9ema`,
       `alerts`.`CurrentClose9emaDiff`                                       AS `CurrentClose9emaDiff`,
       `alerts`.`20ema`                                                      AS `20ema`,
       `alerts`.`CurrentClose20emaDiff`                                      AS `CurrentClose20emaDiff`,
       `alerts`.`300ema`                                                     AS `300ema`,
       `alerts`.`CurrentClose300emaDiff`                                     AS `CurrentClose300emaDiff`,
       `alerts`.`LastNewHighOfDay_time`                                      AS `LastNewHighOfDay_time`,
       cast((`alerts`.`Volume` - `alerts`.`Pre1MinVolume`) as signed)        AS `Pre1MinVolume`,
       cast((`alerts`.`Pre1MinVolume` - `alerts`.`Pre2MinVolume`) as signed) AS `Pre2MinVolume`,
       cast((`alerts`.`Pre2MinVolume` - `alerts`.`Pre3MinVolume`) as signed) AS `Pre3MinVolume`,
       cast((`alerts`.`Pre3MinVolume` - `alerts`.`Pre4MinVolume`) as signed) AS `Pre4MinVolume`,
       cast((`alerts`.`Pre4MinVolume` - `alerts`.`Pre5MinVolume`) as signed) AS `Pre5MinVolume`,
       1                                                                     AS `Fit`
from (select `tickers`.`view_volatilities`.`symbol`                                                                   AS `Symbol`,
             `tickers`.`view_volatilities`.`StageDays`                                                                AS `StageDays`,
             `tickers`.`view_volatilities`.`SharesFloat`                                                              AS `SharesFloat`,
             `tickers`.`view_volatilities`.`PreClose`                                                                 AS `PreClose`,
             `tickers`.`view_volatilities`.`Open`                                                                     AS `Open`,
             `tickers`.`view_volatilities`.`High`                                                                     AS `High`,
             `tickers`.`view_volatilities`.`Low`                                                                      AS `Low`,
             `tickers`.`view_volatilities`.`Close`                                                                    AS `Close`,
             `tickers`.`view_volatilities`.`PreVolume`                                                                AS `PreVolume`,
             `tickers`.`view_volatilities`.`Volume`                                                                   AS `Volume`,
             `tickers`.`view_volatilities`.`VolatilityPct`                                                            AS `VolatilityPct`,
             `tickers`.`view_volatilities`.`HighOfDay`                                                                AS `HighOfDay`,
             `tickers`.`view_volatilities`.`CurrentClose`                                                             AS `CurrentClose`,
             `tickers`.`view_volatilities`.`9ema`                                                                     AS `9ema`,
             `tickers`.`view_volatilities`.`CurrentClose9emaDiff`                                                     AS `CurrentClose9emaDiff`,
             `tickers`.`view_volatilities`.`20ema`                                                                    AS `20ema`,
             `tickers`.`view_volatilities`.`CurrentClose20emaDiff`                                                    AS `CurrentClose20emaDiff`,
             `tickers`.`view_volatilities`.`300ema`                                                                   AS `300ema`,
             `tickers`.`view_volatilities`.`CurrentClose300emaDiff`                                                   AS `CurrentClose300emaDiff`,
             `tickers`.`view_volatilities`.`LastNewHighOfDay_time`                                                    AS `LastNewHighOfDay_time`,
             cast((`tickers`.`view_volatilities`.`Volume` -
                   `tickers`.`view_volatilities`.`Pre1MinVolume`) as signed)                                          AS `Pre1MinVolume`,
             cast((`tickers`.`view_volatilities`.`Pre1MinVolume` -
                   `tickers`.`view_volatilities`.`Pre2MinVolume`) as signed)                                          AS `Pre2MinVolume`,
             cast((`tickers`.`view_volatilities`.`Pre2MinVolume` -
                   `tickers`.`view_volatilities`.`Pre3MinVolume`) as signed)                                          AS `Pre3MinVolume`,
             cast((`tickers`.`view_volatilities`.`Pre3MinVolume` -
                   `tickers`.`view_volatilities`.`Pre4MinVolume`) as signed)                                          AS `Pre4MinVolume`,
             cast((`tickers`.`view_volatilities`.`Pre4MinVolume` -
                   `tickers`.`view_volatilities`.`Pre5MinVolume`) as signed)                                          AS `Pre5MinVolume`,
             1                                                                                                        AS `Fit`,
             `tickers`.`view_volatilities`.`LastNewHighOfDay`                                                         AS `LastNewHighOfDay`,
             1                                                                                                        AS `Priority`
      from `tickers`.`view_volatilities`
      where ((`tickers`.`view_volatilities`.`Date` = '2022-11-15') and
             (`tickers`.`view_volatilities`.`VolatilityPct` > 0.05) and
             (`tickers`.`view_volatilities`.`CurrentClose9emaDiff` < 0.01) and
             (`tickers`.`view_volatilities`.`CurrentClose20emaDiff` > -(0.01)) and
             (`tickers`.`view_volatilities`.`Close` >= 0.5) and
             ((`tickers`.`view_volatilities`.`CurrentVolume` - `tickers`.`view_volatilities`.`Pre1MinVolume`) >
              10000) and
             ((`tickers`.`view_volatilities`.`Pre1MinVolume` - `tickers`.`view_volatilities`.`Pre2MinVolume`) >
              8000) and
             ((`tickers`.`view_volatilities`.`Pre2MinVolume` - `tickers`.`view_volatilities`.`Pre3MinVolume`) >
              6000) and (`tickers`.`view_volatilities`.`StageDays` < 0) and
             (`tickers`.`view_volatilities`.`SharesFloat` < 120))
      union
      (select `tickers`.`view_volatilities`.`symbol`                          AS `Symbol`,
              `tickers`.`view_volatilities`.`StageDays`                       AS `StageDays`,
              `tickers`.`view_volatilities`.`SharesFloat`                     AS `SharesFloat`,
              `tickers`.`view_volatilities`.`PreClose`                        AS `PreClose`,
              `tickers`.`view_volatilities`.`Open`                            AS `Open`,
              `tickers`.`view_volatilities`.`High`                            AS `High`,
              `tickers`.`view_volatilities`.`Low`                             AS `Low`,
              `tickers`.`view_volatilities`.`Close`                           AS `Close`,
              `tickers`.`view_volatilities`.`PreVolume`                       AS `PreVolume`,
              `tickers`.`view_volatilities`.`Volume`                          AS `Volume`,
              `tickers`.`view_volatilities`.`VolatilityPct`                   AS `VolatilityPct`,
              `tickers`.`view_volatilities`.`HighOfDay`                       AS `HighOfDay`,
              `tickers`.`view_volatilities`.`CurrentClose`                    AS `CurrentClose`,
              `tickers`.`view_volatilities`.`9ema`                            AS `9ema`,
              `tickers`.`view_volatilities`.`CurrentClose9emaDiff`            AS `CurrentClose9emaDiff`,
              `tickers`.`view_volatilities`.`20ema`                           AS `20ema`,
              `tickers`.`view_volatilities`.`CurrentClose20emaDiff`           AS `CurrentClose20emaDiff`,
              `tickers`.`view_volatilities`.`300ema`                          AS `300ema`,
              `tickers`.`view_volatilities`.`CurrentClose300emaDiff`          AS `CurrentClose300emaDiff`,
              `tickers`.`view_volatilities`.`LastNewHighOfDay_time`           AS `LastNewHighOfDay_time`,
              cast((`tickers`.`view_volatilities`.`Volume` -
                    `tickers`.`view_volatilities`.`Pre1MinVolume`) as signed) AS `Pre1MinVolume`,
              cast((`tickers`.`view_volatilities`.`Pre1MinVolume` -
                    `tickers`.`view_volatilities`.`Pre2MinVolume`) as signed) AS `Pre2MinVolume`,
              cast((`tickers`.`view_volatilities`.`Pre2MinVolume` -
                    `tickers`.`view_volatilities`.`Pre3MinVolume`) as signed) AS `Pre3MinVolume`,
              cast((`tickers`.`view_volatilities`.`Pre3MinVolume` -
                    `tickers`.`view_volatilities`.`Pre4MinVolume`) as signed) AS `Pre4MinVolume`,
              cast((`tickers`.`view_volatilities`.`Pre4MinVolume` -
                    `tickers`.`view_volatilities`.`Pre5MinVolume`) as signed) AS `Pre5MinVolume`,
              1                                                               AS `Fit`,
              `tickers`.`view_volatilities`.`LastNewHighOfDay`                AS `LastNewHighOfDay`,
              2                                                               AS `Priority`
       from `tickers`.`view_volatilities`
       where ((`tickers`.`view_volatilities`.`Date` = '2022-11-15') and
              (`tickers`.`view_volatilities`.`VolatilityPct` > 0.05) and
              (`tickers`.`view_volatilities`.`CurrentClose9emaDiff` < 0.01) and
              (`tickers`.`view_volatilities`.`CurrentClose20emaDiff` > -(0.01)) and
              (`tickers`.`view_volatilities`.`Close` >= 0.5) and
              ((`tickers`.`view_volatilities`.`CurrentVolume` - `tickers`.`view_volatilities`.`Pre1MinVolume`) >
               10000) and
              ((`tickers`.`view_volatilities`.`Pre1MinVolume` - `tickers`.`view_volatilities`.`Pre2MinVolume`) >
               8000) and
              ((`tickers`.`view_volatilities`.`Pre2MinVolume` - `tickers`.`view_volatilities`.`Pre3MinVolume`) >
               6000) and ((`tickers`.`view_volatilities`.`StageDays` >= 0) or
                          (`tickers`.`view_volatilities`.`SharesFloat` >= 120) or
                          (`tickers`.`view_volatilities`.`SharesFloat` is null)))
       order by `tickers`.`view_volatilities`.`LastNewHighOfDay` desc
       limit 50)) `alerts`
order by `alerts`.`Priority`, `alerts`.`LastNewHighOfDay` desc;

create definer = root@localhost view tickers.view_history_daily_events as
select `tickers`.`history_daily_events`.`id`                   AS `id`,
       `tickers`.`history_daily_events`.`date`                 AS `date`,
       `tickers`.`history_daily_events`.`max_volume_ticker_id` AS `max_volume_ticker_id`,
       `tickers`.`tickers`.`symbol`                            AS `max_volume_symbol`
from (`tickers`.`history_daily_events` join `tickers`.`tickers`)
where ((`tickers`.`history_daily_events`.`max_volume_ticker_id` = `tickers`.`tickers`.`id`) and
       (`tickers`.`tickers`.`deleted` = 0));

create definer = root@localhost view tickers.view_history_day_gaps as
select `gaps`.`id`                  AS `id`,
       `tickers`.`tickers`.`symbol` AS `symbol`,
       `gaps`.`ticker_id`           AS `ticker_id`,
       `gaps`.`start_date`          AS `start_date`,
       `gaps`.`end_date`            AS `end_date`,
       `gaps`.`datediff`            AS `datediff`
from (`tickers`.`history_day_gaps` `gaps` join `tickers`.`tickers`)
where ((`gaps`.`ticker_id` = `tickers`.`tickers`.`id`) and (`tickers`.`tickers`.`deleted` = 0));

create definer = root@`192.168.31.101` view tickers.view_labeling_days as
select `tickers`.`labeling_days`.`id`                            AS `id`,
       `tickers`.`tickers`.`id`                                  AS `ticker_id`,
       `tickers`.`labeling_days`.`strategy_type`                 AS `strategy_type`,
       `tickers`.`labeling_days`.`symbol`                        AS `symbol`,
       `tickers`.`labeling_days`.`start`                         AS `start`,
       from_unixtime((`tickers`.`labeling_days`.`start` / 1000)) AS `start_date`,
       `tickers`.`labeling_days`.`end`                           AS `end`,
       from_unixtime((`tickers`.`labeling_days`.`end` / 1000))   AS `end_date`,
       `tickers`.`labeling_days`.`date_modified`                 AS `date_modified`
from (`tickers`.`labeling_days` join `tickers`.`tickers`
      on ((`tickers`.`labeling_days`.`symbol` = `tickers`.`tickers`.`symbol`)));

create definer = root@`192.168.31.101` view tickers.view_labeling_minutes as
select `tickers`.`labeling_minutes`.`id`                                                             AS `id`,
       `tickers`.`tickers`.`id`                                                                      AS `ticker_id`,
       `tickers`.`labeling_minutes`.`strategy_type`                                                  AS `strategy_type`,
       `tickers`.`labeling_minutes`.`symbol`                                                         AS `symbol`,
       `tickers`.`labeling_minutes`.`date`                                                           AS `date`,
       `tickers`.`labeling_minutes`.`start`                                                          AS `start`,
       cast(((((`tickers`.`labeling_minutes`.`start` + 28800000) / 1000) % 86400) / 60) as unsigned) AS `start_minute`,
       `tickers`.`labeling_minutes`.`end`                                                            AS `end`,
       cast(((((`tickers`.`labeling_minutes`.`end` + 28800000) / 1000) % 86400) / 60) as unsigned)   AS `end_minute`,
       `tickers`.`labeling_minutes`.`date_modified`                                                  AS `date_modified`
from (`tickers`.`labeling_minutes` join `tickers`.`tickers`
      on ((`tickers`.`labeling_minutes`.`symbol` = `tickers`.`tickers`.`symbol`)));

create definer = root@localhost view tickers.view_split_history_day_stats as
select `tickers`.`tickers`.`symbol`                                                                                   AS `symbol`,
       `tickers`.`history_day_stats`.`ticker_id`                                                                      AS `ticker_id`,
       `tickers`.`history_day_stats`.`date`                                                                           AS `date`,
       ((`tickers`.`history_day_stats`.`share_class_shares_outstanding` /
         `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`) /
        1000000)                                                                                                      AS `share_class_shares_outstanding_in_m`,
       ((`tickers`.`history_day_stats`.`weighted_shares_outstanding` /
         `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`) /
        1000000)                                                                                                      AS `weighted_shares_outstanding_in_m`,
       `tickers`.`history_day_stats`.`premarket_ratio`                                                                AS `premarket_ratio`,
       `tickers`.`unsplit_history_days`.`market_session_change_ratio`                                                 AS `market_session_change_ratio`,
       `tickers`.`history_day_stats`.`aftermarket_ratio`                                                              AS `aftermarket_ratio`,
       `tickers`.`unsplit_history_days`.`consecutive_trend_days`                                                      AS `consecutive_trend_days`,
       `tickers`.`unsplit_history_days`.`trend_reversal`                                                              AS `trend_reversal`,
       ((`tickers`.`history_day_stats`.`premarket_volume` /
         `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`) /
        1000000)                                                                                                      AS `premarket_volume_in_m`,
       ((`tickers`.`unsplit_history_days`.`volume` /
         `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`) /
        1000000)                                                                                                      AS `market_hour_volume_in_m`,
       ((`tickers`.`history_day_stats`.`aftermarket_volume` /
         `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`) /
        1000000)                                                                                                      AS `aftermarket_volume_in_m`,
       round((((((`tickers`.`unsplit_history_days`.`volume` + `tickers`.`history_day_stats`.`premarket_volume`) +
                 `tickers`.`history_day_stats`.`aftermarket_volume`) /
                `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`) *
               `tickers`.`unsplit_history_days`.`close`) / 1000000),
             4)                                                                                                       AS `traded_value_in_m`,
       (`tickers`.`unsplit_history_days`.`open` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `open`,
       (`tickers`.`unsplit_history_days`.`high` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `high`,
       (`tickers`.`unsplit_history_days`.`low` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `low`,
       (`tickers`.`unsplit_history_days`.`close` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `close`,
       (`tickers`.`unsplit_history_days`.`vwap` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `vwap`,
       `tickers`.`unsplit_history_days`.`trades`                                                                      AS `trades`,
       `tickers`.`unsplit_history_days`.`price_change_ratio`                                                          AS `price_change_ratio`,
       `tickers`.`history_day_stats`.`5_range_from_low`                                                               AS `5_range_from_low`,
       `tickers`.`history_day_stats`.`10_range_from_low`                                                              AS `10_range_from_low`,
       `tickers`.`history_day_stats`.`20_range_from_low`                                                              AS `20_range_from_low`,
       `tickers`.`history_day_stats`.`5_range_from_high`                                                              AS `5_range_from_high`,
       `tickers`.`history_day_stats`.`10_range_from_high`                                                             AS `10_range_from_high`,
       `tickers`.`history_day_stats`.`20_range_from_high`                                                             AS `20_range_from_high`,
       `tickers`.`history_day_stats`.`premarket_high_minute`                                                          AS `premarket_high_minute`,
       concat(lpad(floor((`tickers`.`history_day_stats`.`premarket_high_minute` / 60)), 2, 0), ':',
              lpad((`tickers`.`history_day_stats`.`premarket_high_minute` % 60), 2,
                   0))                                                                                                AS `premarket_high_minute_display`,
       `tickers`.`history_day_stats`.`premarket_high`                                                                 AS `premarket_high`,
       `tickers`.`history_day_stats`.`premarket_low_minute`                                                           AS `premarket_low_minute`,
       concat(lpad(floor((`tickers`.`history_day_stats`.`premarket_low_minute` / 60)), 2, 0), ':',
              lpad((`tickers`.`history_day_stats`.`premarket_low_minute` % 60), 2,
                   0))                                                                                                AS `premarket_low_minute_display`,
       `tickers`.`history_day_stats`.`premarket_low`                                                                  AS `premarket_low`,
       `tickers`.`history_day_stats`.`premarket_open`                                                                 AS `premarket_open`,
       `tickers`.`history_day_stats`.`premarket_close`                                                                AS `premarket_close`,
       `tickers`.`history_day_stats`.`aftermarket_high_minute`                                                        AS `aftermarket_high_minute`,
       concat(lpad(floor((`tickers`.`history_day_stats`.`aftermarket_high_minute` / 60)), 2, 0), ':',
              lpad((`tickers`.`history_day_stats`.`aftermarket_high_minute` % 60), 2,
                   0))                                                                                                AS `aftermarket_high_minute_display`,
       `tickers`.`history_day_stats`.`aftermarket_high`                                                               AS `aftermarket_high`,
       `tickers`.`history_day_stats`.`aftermarket_low_minute`                                                         AS `aftermarket_low_minute`,
       concat(lpad(floor((`tickers`.`history_day_stats`.`aftermarket_low_minute` / 60)), 2, 0), ':',
              lpad((`tickers`.`history_day_stats`.`aftermarket_low_minute` % 60), 2,
                   0))                                                                                                AS `aftermarket_low_minute_display`,
       `tickers`.`history_day_stats`.`aftermarket_low`                                                                AS `aftermarket_low`,
       `tickers`.`history_day_stats`.`aftermarket_open`                                                               AS `aftermarket_open`,
       `tickers`.`history_day_stats`.`aftermarket_close`                                                              AS `aftermarket_close`,
       `tickers`.`history_day_stats`.`after_10_30_low`                                                                AS `after_10_30_low`,
       `tickers`.`history_day_stats`.`after_10_30_low_minute`                                                         AS `after_10_30_low_minute`,
       concat(lpad(floor((`tickers`.`history_day_stats`.`after_10_30_low_minute` / 60)), 2, 0), ':',
              lpad((`tickers`.`history_day_stats`.`after_10_30_low_minute` % 60), 2,
                   0))                                                                                                AS `after_10_30_low_minute_display`,
       `tickers`.`history_day_stats`.`market_hour_high_minute`                                                        AS `market_hour_high_minute`,
       concat(lpad(floor((`tickers`.`history_day_stats`.`market_hour_high_minute` / 60)), 2, 0), ':',
              lpad((`tickers`.`history_day_stats`.`market_hour_high_minute` % 60), 2,
                   0))                                                                                                AS `market_hour_high_minute_display`,
       `tickers`.`history_day_stats`.`market_hour_low_minute`                                                         AS `market_hour_low_minute`,
       concat(lpad(floor((`tickers`.`history_day_stats`.`market_hour_low_minute` / 60)), 2, 0), ':',
              lpad((`tickers`.`history_day_stats`.`market_hour_low_minute` % 60), 2,
                   0))                                                                                                AS `market_hour_low_minute_display`
from ((`tickers`.`unsplit_history_days` USE INDEX (`unsplit_history_days_full_index`) join `tickers`.`history_day_stats` USE INDEX (`history_day_stats_full_index`)) join `tickers`.`tickers` USE INDEX (`tickers_id_symbol_deleted_with_minute_ema_index`))
where ((`tickers`.`history_day_stats`.`ticker_id` = `tickers`.`tickers`.`id`) and
       (`tickers`.`history_day_stats`.`ticker_id` = `tickers`.`unsplit_history_days`.`ticker_id`) and
       (`tickers`.`history_day_stats`.`date` = `tickers`.`unsplit_history_days`.`date`) and
       (`tickers`.`tickers`.`deleted` = 0));

create definer = root@`192.168.31.101` view tickers.view_split_history_days as
select `tickers`.`unsplit_history_days`.`ticker_id`                                                                   AS `ticker_id`,
       `tickers`.`tickers`.`symbol`                                                                                   AS `symbol`,
       `tickers`.`unsplit_history_days`.`date`                                                                        AS `date`,
       (`tickers`.`unsplit_history_days`.`open` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `open`,
       (`tickers`.`unsplit_history_days`.`high` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `high`,
       (`tickers`.`unsplit_history_days`.`low` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `low`,
       (`tickers`.`unsplit_history_days`.`close` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `close`,
       `tickers`.`unsplit_history_days`.`trades`                                                                      AS `trades`,
       round((`tickers`.`unsplit_history_days`.`volume` /
              `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`),
             0)                                                                                                       AS `volume`,
       (`tickers`.`unsplit_history_days`.`vwap` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `vwap`,
       (`tickers`.`unsplit_history_days`.`9ema` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `9ema`,
       (`tickers`.`unsplit_history_days`.`20ema` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `20ema`,
       (`tickers`.`unsplit_history_days`.`300ema` *
        `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`)                                            AS `300ema`,
       `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio`                                              AS `cumulative_reverse_split_ratio`,
       `tickers`.`unsplit_history_days`.`market_session_change_ratio`                                                 AS `market_session_change_ratio`,
       `tickers`.`unsplit_history_days`.`price_change_ratio`                                                          AS `price_change_ratio`,
       `tickers`.`unsplit_history_days`.`trend_reversal`                                                              AS `trend_reversal`,
       `tickers`.`unsplit_history_days`.`consecutive_trend_days`                                                      AS `consecutive_trend_days`,
       `tickers`.`unsplit_history_days`.`date_modified`                                                               AS `date_modified`
from (`tickers`.`unsplit_history_days` join `tickers`.`tickers`
      on ((`tickers`.`unsplit_history_days`.`ticker_id` = `tickers`.`tickers`.`id`)));

create definer = root@localhost view tickers.view_ticker_stats as
select `tickers`.`tickers`.`symbol`                 AS `symbol`,
       `tickers`.`ticker_stats`.`ticker_id`         AS `ticker_id`,
       `tickers`.`ticker_stats`.`day_first_date`    AS `day_first_date`,
       `tickers`.`ticker_stats`.`day_last_date`     AS `day_last_date`,
       `tickers`.`ticker_stats`.`day_row_count`     AS `day_row_count`,
       `tickers`.`ticker_stats`.`day_date_modified` AS `day_date_modified`
from (`tickers`.`ticker_stats` join `tickers`.`tickers`)
where ((`tickers`.`ticker_stats`.`ticker_id` = `tickers`.`tickers`.`id`) and (`tickers`.`tickers`.`deleted` = 0));

create definer = root@localhost view tickers.view_tickers as
select `tickers`.`tickers`.`id`                           AS `id`,
       `tickers`.`tickers`.`symbol`                       AS `symbol`,
       `tickers`.`tickers`.`disable_update`               AS `disable_update`,
       `tickers`.`tickers`.`zip`                          AS `zip`,
       `tickers`.`tickers`.`sector`                       AS `sector`,
       `tickers`.`tickers`.`fullTimeEmployees`            AS `fullTimeEmployees`,
       `tickers`.`tickers`.`longBusinessSummary`          AS `longBusinessSummary`,
       `tickers`.`tickers`.`city`                         AS `city`,
       `tickers`.`tickers`.`phone`                        AS `phone`,
       `tickers`.`tickers`.`state`                        AS `state`,
       `tickers`.`tickers`.`country`                      AS `country`,
       `tickers`.`tickers`.`companyOfficers`              AS `companyOfficers`,
       `tickers`.`tickers`.`website`                      AS `website`,
       `tickers`.`tickers`.`maxAge`                       AS `maxAge`,
       `tickers`.`tickers`.`address1`                     AS `address1`,
       `tickers`.`tickers`.`fax`                          AS `fax`,
       `tickers`.`tickers`.`industry`                     AS `industry`,
       `tickers`.`tickers`.`previousClose`                AS `previousClose`,
       `tickers`.`tickers`.`regularMarketOpen`            AS `regularMarketOpen`,
       `tickers`.`tickers`.`twoHundredDayAverage`         AS `twoHundredDayAverage`,
       `tickers`.`tickers`.`trailingAnnualDividendYield`  AS `trailingAnnualDividendYield`,
       `tickers`.`tickers`.`payoutRatio`                  AS `payoutRatio`,
       `tickers`.`tickers`.`volume24Hr`                   AS `volume24Hr`,
       `tickers`.`tickers`.`regularMarketDayHigh`         AS `regularMarketDayHigh`,
       `tickers`.`tickers`.`navPrice`                     AS `navPrice`,
       `tickers`.`tickers`.`averageDailyVolume10Day`      AS `averageDailyVolume10Day`,
       `tickers`.`tickers`.`totalAssets`                  AS `totalAssets`,
       `tickers`.`tickers`.`regularMarketPreviousClose`   AS `regularMarketPreviousClose`,
       `tickers`.`tickers`.`fiftyDayAverage`              AS `fiftyDayAverage`,
       `tickers`.`tickers`.`trailingAnnualDividendRate`   AS `trailingAnnualDividendRate`,
       `tickers`.`tickers`.`open`                         AS `open`,
       `tickers`.`tickers`.`toCurrency`                   AS `toCurrency`,
       `tickers`.`tickers`.`averageVolume10days`          AS `averageVolume10days`,
       `tickers`.`tickers`.`expireDate`                   AS `expireDate`,
       `tickers`.`tickers`.`yield`                        AS `yield`,
       `tickers`.`tickers`.`algorithm`                    AS `algorithm`,
       `tickers`.`tickers`.`dividendRate`                 AS `dividendRate`,
       `tickers`.`tickers`.`exDividendDate`               AS `exDividendDate`,
       `tickers`.`tickers`.`beta`                         AS `beta`,
       `tickers`.`tickers`.`circulatingSupply`            AS `circulatingSupply`,
       `tickers`.`tickers`.`startDate`                    AS `startDate`,
       `tickers`.`tickers`.`regularMarketDayLow`          AS `regularMarketDayLow`,
       `tickers`.`tickers`.`priceHint`                    AS `priceHint`,
       `tickers`.`tickers`.`currency`                     AS `currency`,
       `tickers`.`tickers`.`trailingPE`                   AS `trailingPE`,
       `tickers`.`tickers`.`regularMarketVolume`          AS `regularMarketVolume`,
       `tickers`.`tickers`.`lastMarket`                   AS `lastMarket`,
       `tickers`.`tickers`.`maxSupply`                    AS `maxSupply`,
       `tickers`.`tickers`.`openInterest`                 AS `openInterest`,
       `tickers`.`tickers`.`marketCap`                    AS `marketCap`,
       `tickers`.`tickers`.`volumeAllCurrencies`          AS `volumeAllCurrencies`,
       `tickers`.`tickers`.`strikePrice`                  AS `strikePrice`,
       `tickers`.`tickers`.`averageVolume`                AS `averageVolume`,
       `tickers`.`tickers`.`priceToSalesTrailing12Months` AS `priceToSalesTrailing12Months`,
       `tickers`.`tickers`.`dayLow`                       AS `dayLow`,
       `tickers`.`tickers`.`ask`                          AS `ask`,
       `tickers`.`tickers`.`ytdReturn`                    AS `ytdReturn`,
       `tickers`.`tickers`.`askSize`                      AS `askSize`,
       `tickers`.`tickers`.`volume`                       AS `volume`,
       `tickers`.`tickers`.`fiftyTwoWeekHigh`             AS `fiftyTwoWeekHigh`,
       `tickers`.`tickers`.`forwardPE`                    AS `forwardPE`,
       `tickers`.`tickers`.`fromCurrency`                 AS `fromCurrency`,
       `tickers`.`tickers`.`fiveYearAvgDividendYield`     AS `fiveYearAvgDividendYield`,
       `tickers`.`tickers`.`fiftyTwoWeekLow`              AS `fiftyTwoWeekLow`,
       `tickers`.`tickers`.`bid`                          AS `bid`,
       `tickers`.`tickers`.`tradeable`                    AS `tradeable`,
       `tickers`.`tickers`.`dividendYield`                AS `dividendYield`,
       `tickers`.`tickers`.`bidSize`                      AS `bidSize`,
       `tickers`.`tickers`.`dayHigh`                      AS `dayHigh`,
       `tickers`.`tickers`.`exchange`                     AS `exchange`,
       `tickers`.`tickers`.`shortName`                    AS `shortName`,
       `tickers`.`tickers`.`longName`                     AS `longName`,
       `tickers`.`tickers`.`exchangeTimezoneName`         AS `exchangeTimezoneName`,
       `tickers`.`tickers`.`exchangeTimezoneShortName`    AS `exchangeTimezoneShortName`,
       `tickers`.`tickers`.`isEsgPopulated`               AS `isEsgPopulated`,
       `tickers`.`tickers`.`gmtOffSetMilliseconds`        AS `gmtOffSetMilliseconds`,
       `tickers`.`tickers`.`quoteType`                    AS `quoteType`,
       `tickers`.`tickers`.`messageBoardId`               AS `messageBoardId`,
       `tickers`.`tickers`.`market`                       AS `market`,
       `tickers`.`tickers`.`annualHoldingsTurnover`       AS `annualHoldingsTurnover`,
       `tickers`.`tickers`.`enterpriseToRevenue`          AS `enterpriseToRevenue`,
       `tickers`.`tickers`.`beta3Year`                    AS `beta3Year`,
       `tickers`.`tickers`.`profitMargins`                AS `profitMargins`,
       `tickers`.`tickers`.`enterpriseToEbitda`           AS `enterpriseToEbitda`,
       `tickers`.`tickers`.`52WeekChange`                 AS `52WeekChange`,
       `tickers`.`tickers`.`morningStarRiskRating`        AS `morningStarRiskRating`,
       `tickers`.`tickers`.`forwardEps`                   AS `forwardEps`,
       `tickers`.`tickers`.`revenueQuarterlyGrowth`       AS `revenueQuarterlyGrowth`,
       `tickers`.`tickers`.`sharesOutstanding`            AS `sharesOutstanding`,
       `tickers`.`tickers`.`fundInceptionDate`            AS `fundInceptionDate`,
       `tickers`.`tickers`.`annualReportExpenseRatio`     AS `annualReportExpenseRatio`,
       `tickers`.`tickers`.`bookValue`                    AS `bookValue`,
       `tickers`.`tickers`.`sharesShort`                  AS `sharesShort`,
       `tickers`.`tickers`.`sharesPercentSharesOut`       AS `sharesPercentSharesOut`,
       `tickers`.`tickers`.`fundFamily`                   AS `fundFamily`,
       `tickers`.`tickers`.`lastFiscalYearEnd`            AS `lastFiscalYearEnd`,
       `tickers`.`tickers`.`heldPercentInstitutions`      AS `heldPercentInstitutions`,
       `tickers`.`tickers`.`netIncomeToCommon`            AS `netIncomeToCommon`,
       `tickers`.`tickers`.`trailingEps`                  AS `trailingEps`,
       `tickers`.`tickers`.`lastDividendValue`            AS `lastDividendValue`,
       `tickers`.`tickers`.`SandP52WeekChange`            AS `SandP52WeekChange`,
       `tickers`.`tickers`.`priceToBook`                  AS `priceToBook`,
       `tickers`.`tickers`.`heldPercentInsiders`          AS `heldPercentInsiders`,
       `tickers`.`tickers`.`nextFiscalYearEnd`            AS `nextFiscalYearEnd`,
       `tickers`.`tickers`.`mostRecentQuarter`            AS `mostRecentQuarter`,
       `tickers`.`tickers`.`shortRatio`                   AS `shortRatio`,
       `tickers`.`tickers`.`sharesShortPreviousMonthDate` AS `sharesShortPreviousMonthDate`,
       `tickers`.`tickers`.`floatShares`                  AS `floatShares`,
       `tickers`.`tickers`.`enterpriseValue`              AS `enterpriseValue`,
       `tickers`.`tickers`.`threeYearAverageReturn`       AS `threeYearAverageReturn`,
       `tickers`.`tickers`.`lastSplitDate`                AS `lastSplitDate`,
       `tickers`.`tickers`.`lastSplitFactor`              AS `lastSplitFactor`,
       `tickers`.`tickers`.`legalType`                    AS `legalType`,
       `tickers`.`tickers`.`morningStarOverallRating`     AS `morningStarOverallRating`,
       `tickers`.`tickers`.`earningsQuarterlyGrowth`      AS `earningsQuarterlyGrowth`,
       `tickers`.`tickers`.`dateShortInterest`            AS `dateShortInterest`,
       `tickers`.`tickers`.`pegRatio`                     AS `pegRatio`,
       `tickers`.`tickers`.`lastCapGain`                  AS `lastCapGain`,
       `tickers`.`tickers`.`shortPercentOfFloat`          AS `shortPercentOfFloat`,
       `tickers`.`tickers`.`sharesShortPriorMonth`        AS `sharesShortPriorMonth`,
       `tickers`.`tickers`.`category`                     AS `category`,
       `tickers`.`tickers`.`fiveYearAverageReturn`        AS `fiveYearAverageReturn`,
       `tickers`.`tickers`.`regularMarketPrice`           AS `regularMarketPrice`,
       `tickers`.`tickers`.`logo_url`                     AS `logo_url`,
       `tickers`.`tickers`.`day_date_modified`            AS `day_date_modified`,
       `tickers`.`tickers`.`minute_date_modified`         AS `minute_date_modified`,
       `tickers`.`tickers`.`date_modified`                AS `date_modified`
from `tickers`.`tickers`
where (`tickers`.`tickers`.`deleted` = 0);

create definer = root@`192.168.31.101` view tickers.view_trade_labels as
select `tickers`.`trade_labels`.`id`                            AS `id`,
       `tickers`.`tickers`.`id`                                 AS `ticker_id`,
       `tickers`.`trade_labels`.`strategy_type`                 AS `strategy_type`,
       `tickers`.`trade_labels`.`action`                        AS `action`,
       `tickers`.`trade_labels`.`symbol`                        AS `symbol`,
       `tickers`.`trade_labels`.`start`                         AS `start`,
       from_unixtime((`tickers`.`trade_labels`.`start` / 1000)) AS `start_date`,
       `tickers`.`trade_labels`.`end`                           AS `end`,
       from_unixtime((`tickers`.`trade_labels`.`end` / 1000))   AS `end_date`,
       `tickers`.`trade_labels`.`time_frame`                    AS `time_frame`,
       `tickers`.`trade_labels`.`created_at`                    AS `created_at`,
       `tickers`.`trade_labels`.`updated_at`                    AS `updated_at`
from (`tickers`.`trade_labels` join `tickers`.`tickers`
      on ((`tickers`.`trade_labels`.`symbol` = `tickers`.`tickers`.`symbol`)));

-- comment on column tickers.view_trade_labels.id not supported: A unique identifier for each label entry

-- comment on column tickers.view_trade_labels.strategy_type not supported: The type of trading strategy associated with the label

-- comment on column tickers.view_trade_labels.action not supported: The type of action being labeled (e.g., entry point, take profit, stop loss)

-- comment on column tickers.view_trade_labels.symbol not supported: The stock symbol associated with the label

-- comment on column tickers.view_trade_labels.start not supported: The start time of the labeled period, typically represented as a timestamp

-- comment on column tickers.view_trade_labels.end not supported: The end time of the labeled period, typically represented as a timestamp

-- comment on column tickers.view_trade_labels.time_frame not supported: Indicates whether the label is based on daily or minute-level data

-- comment on column tickers.view_trade_labels.created_at not supported: Records the timestamp when the entry was created

-- comment on column tickers.view_trade_labels.updated_at not supported: Automatically updates to the current timestamp whenever the entry is modified

create definer = root@`192.168.31.101` view tickers.view_unsplit_history_days as
select `curr`.`ticker_id`                                                                               AS `ticker_id`,
       `tickers`.`tickers`.`symbol`                                                                     AS `symbol`,
       `curr`.`date`                                                                                    AS `date`,
       if((`prev`.`open` is null), NULL,
          (`prev`.`open` * `prev`.`cumulative_reverse_split_ratio`))                                    AS `previous_open`,
       if((`prev`.`close` is null), NULL,
          (`prev`.`close` * `prev`.`cumulative_reverse_split_ratio`))                                   AS `previous_close`,
       if((`prev`.`trades` is null), NULL,
          (`prev`.`trades` / `prev`.`cumulative_reverse_split_ratio`))                                  AS `previous_trades`,
       if((`prev`.`volume` is null), NULL,
          (`prev`.`volume` / `prev`.`cumulative_reverse_split_ratio`))                                  AS `previous_volume`,
       (`curr`.`open` * `curr`.`cumulative_reverse_split_ratio`)                                        AS `open`,
       (`curr`.`high` * `curr`.`cumulative_reverse_split_ratio`)                                        AS `high`,
       (`curr`.`low` * `curr`.`cumulative_reverse_split_ratio`)                                         AS `low`,
       (`curr`.`close` * `curr`.`cumulative_reverse_split_ratio`)                                       AS `close`,
       (`curr`.`trades` / `curr`.`cumulative_reverse_split_ratio`)                                      AS `trades`,
       (`curr`.`volume` / `curr`.`cumulative_reverse_split_ratio`)                                      AS `volume`,
       (`curr`.`vwap` * `curr`.`cumulative_reverse_split_ratio`)                                        AS `vwap`,
       (`curr`.`9ema` * `curr`.`cumulative_reverse_split_ratio`)                                        AS `9ema`,
       (`curr`.`20ema` * `curr`.`cumulative_reverse_split_ratio`)                                       AS `20ema`,
       (`curr`.`300ema` * `curr`.`cumulative_reverse_split_ratio`)                                      AS `300ema`,
       `curr`.`cumulative_reverse_split_ratio`                                                          AS `cumulative_reverse_split_ratio`,
       `curr`.`market_session_change_ratio`                                                             AS `market_session_change_ratio`,
       `curr`.`price_change_ratio`                                                                      AS `price_change_ratio`,
       `curr`.`trend_reversal`                                                                          AS `trend_reversal`,
       `curr`.`consecutive_trend_days`                                                                  AS `consecutive_trend_days`,
       `curr`.`date_modified`                                                                           AS `date_modified`
from ((`tickers`.`unsplit_history_days` `curr` join `tickers`.`tickers`
       on ((`curr`.`ticker_id` = `tickers`.`tickers`.`id`))) left join `tickers`.`unsplit_history_days` `prev`
      on (((`curr`.`ticker_id` = `prev`.`ticker_id`) and (`curr`.`previous_date` = `prev`.`date`))))
where (`tickers`.`tickers`.`deleted` = 0);

create definer = root@localhost view tickers.view_unsplit_history_days_max_min_date_stats as
select `tickers`.`tickers`.`id`                                           AS `ticker_id`,
       `tickers`.`tickers`.`symbol`                                       AS `symbol`,
       ifnull(min(`tickers`.`unsplit_history_days`.`date`), '2000-01-01') AS `day_first_date`,
       ifnull(max(`tickers`.`unsplit_history_days`.`date`), '2000-01-01') AS `day_last_date`,
       count(`tickers`.`unsplit_history_days`.`date`)                     AS `day_row_count`,
       `tickers`.`tickers`.`day_date_modified`                            AS `day_date_modified`
from (`tickers`.`tickers` left join `tickers`.`unsplit_history_days`
      on ((`tickers`.`tickers`.`id` = `tickers`.`unsplit_history_days`.`ticker_id`)))
where (`tickers`.`tickers`.`deleted` = 0)
group by `tickers`.`tickers`.`id`;

create definer = root@`192.168.31.101` view tickers.view_unsplit_history_minutes as
with `ratio_cte` as (select `tickers`.`unsplit_history_days`.`ticker_id`                      AS `ticker_id`,
                            `tickers`.`unsplit_history_days`.`date`                           AS `date`,
                            `tickers`.`unsplit_history_days`.`cumulative_reverse_split_ratio` AS `cumulative_reverse_split_ratio`
                     from `tickers`.`unsplit_history_days`)
select `curr`.`ticker_id`                                           AS `ticker_id`,
       `tickers`.`tickers`.`symbol`                                 AS `symbol`,
       `curr`.`date`                                                AS `date`,
       `curr`.`minute`                                              AS `minute`,
       (`curr`.`date` + interval `curr`.`minute` minute)            AS `datetime`,
       time_format(sec_to_time((`curr`.`minute` * 60)), '%H:%i')    AS `minute_display`,
       (`curr`.`open` * `ratio`.`cumulative_reverse_split_ratio`)   AS `open`,
       (`curr`.`high` * `ratio`.`cumulative_reverse_split_ratio`)   AS `high`,
       (`curr`.`low` * `ratio`.`cumulative_reverse_split_ratio`)    AS `low`,
       (`curr`.`close` * `ratio`.`cumulative_reverse_split_ratio`)  AS `close`,
       (`curr`.`trades` / `ratio`.`cumulative_reverse_split_ratio`) AS `trades`,
       (`curr`.`volume` / `ratio`.`cumulative_reverse_split_ratio`) AS `volume`,
       (`curr`.`vwap` * `ratio`.`cumulative_reverse_split_ratio`)   AS `vwap`,
       (`curr`.`9ema` * `ratio`.`cumulative_reverse_split_ratio`)   AS `9ema`,
       (`curr`.`20ema` * `ratio`.`cumulative_reverse_split_ratio`)  AS `20ema`,
       (`curr`.`300ema` * `ratio`.`cumulative_reverse_split_ratio`) AS `300ema`,
       `curr`.`date_modified`                                       AS `date_modified`
from ((`tickers`.`unsplit_history_minutes` `curr` join `tickers`.`tickers`
       on ((`curr`.`ticker_id` = `tickers`.`tickers`.`id`))) join `ratio_cte` `ratio`
      on (((`curr`.`ticker_id` = `ratio`.`ticker_id`) and (`curr`.`date` = `ratio`.`date`))))
where (`tickers`.`tickers`.`deleted` = 0);

create definer = root@localhost view tickers.view_volatilities as
select `tickers`.`volatilities`.`ticker_id`                                                        AS `ticker_id`,
       `tickers`.`volatilities`.`Symbol`                                                           AS `symbol`,
       `tickers`.`volatilities`.`Date`                                                             AS `Date`,
       if(((`tickers`.`volatilities`.`LastNewHighOfDay` is not null) and
           (`tickers`.`volatilities`.`LastNewHighOfDay` > `tickers`.`volatilities`.`LastNewLowOfDay`)),
          `tickers`.`volatilities`.`LastNewHighOfDay`, `tickers`.`volatilities`.`LastNewLowOfDay`) AS `LastHighOrLow`,
       `tickers`.`volatilities`.`VolatilityPct`                                                    AS `VolatilityPct`,
       `tickers`.`volatilities`.`PreClose`                                                         AS `PreClose`,
       `tickers`.`volatilities`.`PreVolume`                                                        AS `PreVolume`,
       `tickers`.`volatilities`.`Volume`                                                           AS `Volume`,
       `tickers`.`volatilities`.`AfterMarketHigh`                                                  AS `AfterMarketHigh`,
       `tickers`.`volatilities`.`PreMarketHigh`                                                    AS `PreMarketHigh`,
       `tickers`.`volatilities`.`GapUp`                                                            AS `GapUp`,
       `tickers`.`volatilities`.`MaxGapUp`                                                         AS `MaxGapUp`,
       `tickers`.`volatilities`.`Open`                                                             AS `Open`,
       `tickers`.`volatilities`.`High`                                                             AS `High`,
       `tickers`.`volatilities`.`Low`                                                              AS `Low`,
       `tickers`.`volatilities`.`Close`                                                            AS `Close`,
       `tickers`.`volatilities`.`HighOfDay`                                                        AS `HighOfDay`,
       `tickers`.`volatilities`.`LowOfDay`                                                         AS `LowOfDay`,
       `tickers`.`volatilities`.`Vwap`                                                             AS `Vwap`,
       `tickers`.`volatilities`.`AboveVwapMin`                                                     AS `AboveVwapMin`,
       `tickers`.`volatilities`.`BelowVwapMin`                                                     AS `BelowVwapMin`,
       `tickers`.`volatilities`.`AboveVwapPct`                                                     AS `AboveVwapPct`,
       `tickers`.`volatilities`.`BelowVwapPct`                                                     AS `BelowVwapPct`,
       `tickers`.`volatilities`.`NewHighOfDayMins`                                                 AS `NewHighOfDayMins`,
       `tickers`.`volatilities`.`NewLowOfDayMins`                                                  AS `NewLowOfDayMins`,
       `tickers`.`volatilities`.`LastNewHighOfDay`                                                 AS `LastNewHighOfDay`,
       date_format(`tickers`.`volatilities`.`LastNewHighOfDay`, '%H:%i:%s')                        AS `LastNewHighOfDay_time`,
       `tickers`.`volatilities`.`LastNewLowOfDay`                                                  AS `LastNewLowOfDay`,
       `tickers`.`volatilities`.`PreMarketHighMin`                                                 AS `PreMarketHighMin`,
       `tickers`.`volatilities`.`Pre1MinClose`                                                     AS `Pre1MinClose`,
       `tickers`.`volatilities`.`Pre1MinVolume`                                                    AS `Pre1MinVolume`,
       `tickers`.`volatilities`.`Pre1MinDate`                                                      AS `Pre1MinDate`,
       `tickers`.`volatilities`.`Pre2MinClose`                                                     AS `Pre2MinClose`,
       `tickers`.`volatilities`.`Pre2MinVolume`                                                    AS `Pre2MinVolume`,
       `tickers`.`volatilities`.`Pre2MinDate`                                                      AS `Pre2MinDate`,
       `tickers`.`volatilities`.`Pre3MinClose`                                                     AS `Pre3MinClose`,
       `tickers`.`volatilities`.`Pre3MinVolume`                                                    AS `Pre3MinVolume`,
       `tickers`.`volatilities`.`Pre3MinDate`                                                      AS `Pre3MinDate`,
       `tickers`.`volatilities`.`Pre4MinClose`                                                     AS `Pre4MinClose`,
       `tickers`.`volatilities`.`Pre4MinVolume`                                                    AS `Pre4MinVolume`,
       `tickers`.`volatilities`.`Pre4MinDate`                                                      AS `Pre4MinDate`,
       `tickers`.`volatilities`.`Pre5minClose`                                                     AS `Pre5MinClose`,
       `tickers`.`volatilities`.`Pre5MinVolume`                                                    AS `Pre5MinVolume`,
       `tickers`.`volatilities`.`Pre5MinDate`                                                      AS `Pre5MinDate`,
       `tickers`.`volatilities`.`9ema`                                                             AS `9ema`,
       `tickers`.`volatilities`.`20ema`                                                            AS `20ema`,
       `tickers`.`volatilities`.`300ema`                                                           AS `300ema`,
       `tickers`.`volatilities`.`CurrentClose`                                                     AS `CurrentClose`,
       `tickers`.`volatilities`.`CurrentClose9emaDiff`                                             AS `CurrentClose9emaDiff`,
       `tickers`.`volatilities`.`CurrentClose20emaDiff`                                            AS `CurrentClose20emaDiff`,
       `tickers`.`volatilities`.`CurrentClose300emaDiff`                                           AS `CurrentClose300emaDiff`,
       `tickers`.`volatilities`.`CurrentOpen`                                                      AS `CurrentOpen`,
       `tickers`.`volatilities`.`CurrentHigh`                                                      AS `CurrentHigh`,
       `tickers`.`volatilities`.`CurrentLow`                                                       AS `CurrentLow`,
       `tickers`.`volatilities`.`CurrentVolume`                                                    AS `CurrentVolume`,
       `tickers`.`volatilities`.`CurrentVwap`                                                      AS `CurrentVwap`,
       concat(lpad(floor((`tickers`.`volatilities`.`PreMarketHighMin` / 60)), 2, 0), ':',
              lpad((`tickers`.`volatilities`.`PreMarketHighMin` % 60), 2, 0))                      AS `PreMarketHighMinDisplay`,
       `tickers`.`volatilities`.`AfterMarketHighMin`                                               AS `AfterMarketHighMin`,
       concat(lpad(floor((`tickers`.`volatilities`.`AfterMarketHighMin` / 60)), 2, 0), ':',
              lpad((`tickers`.`volatilities`.`AfterMarketHighMin` % 60), 2, 0))                    AS `AfterMarketHighMinDisplay`,
       `tickers`.`volatilities`.`StageDays`                                                        AS `StageDays`,
       `tickers`.`volatilities`.`SharesFloat`                                                      AS `SharesFloat`,
       `tickers`.`volatilities`.`date_modified`                                                    AS `date_modified`
from `tickers`.`volatilities` USE INDEX (`idx_bulk`);

