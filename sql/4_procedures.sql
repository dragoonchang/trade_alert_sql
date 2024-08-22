create
    definer = root@localhost procedure tickers.call_update_ticker_stats(OUT total_day_row_count bigint, OUT total_minute_row_count bigint)
BEGIN
    -- 宣告變數
    DECLARE tmp_ticker_id INT;
    DECLARE tmp_day_first_date DATE;
    DECLARE tmp_day_last_date DATE;
    DECLARE tmp_day_row_count BIGINT;
    DECLARE done INT DEFAULT FALSE;

    -- 宣告游標，從視圖中獲取當前 ticker_id 的數據
    DECLARE cursor_tickers CURSOR FOR
        SELECT ticker_id, day_first_date, day_last_date, day_row_count
        FROM view_history_days_max_min_date_stats
        ORDER BY ticker_id
        ;

    -- 當游標沒有找到結果時，設置 done = 1
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- 初始化變數
    SET total_day_row_count = 0;
    SET total_minute_row_count = 0;

    -- 打開游標
    OPEN cursor_tickers;

    cursor_loop: LOOP
        -- 從游標中獲取數據
        FETCH cursor_tickers INTO tmp_ticker_id, tmp_day_first_date, tmp_day_last_date, tmp_day_row_count;

        -- 如果沒有更多的數據，退出循環
        IF done THEN
            LEAVE cursor_loop;
        END IF;

        -- 將查詢結果插入 temp_vars 表
        INSERT INTO temp_vars (`key`, `value`)
        VALUES ('call_update_ticker_stats_select', CONCAT(tmp_ticker_id, '--', tmp_day_row_count))
        ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

        -- 如果查詢結果有效，插入或更新 ticker_stats 表
        IF tmp_day_first_date IS NOT NULL AND tmp_day_last_date IS NOT NULL AND tmp_day_row_count > 0 THEN
            INSERT INTO temp_vars (`key`, `value`)
            VALUES ('call_update_ticker_stats_insert', CONCAT(tmp_ticker_id, '--', tmp_day_first_date, '--', tmp_day_last_date, '--', tmp_day_row_count))
            ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

            INSERT INTO ticker_stats (ticker_id, day_first_date, day_last_date, day_row_count, day_date_modified)
            VALUES (tmp_ticker_id, tmp_day_first_date, tmp_day_last_date, tmp_day_row_count, NOW())
            ON DUPLICATE KEY UPDATE
                day_first_date = VALUES(day_first_date),
                day_last_date = VALUES(day_last_date),
                day_row_count = VALUES(day_row_count),
                day_date_modified = VALUES(day_date_modified);

            -- 使用 ROW_COUNT() 獲取影響行數，更新總計數器
            IF ROW_COUNT() > 0 THEN
                SET total_day_row_count = total_day_row_count + 1;
            END IF;

            -- 提交事務
            COMMIT;
        END IF;
    END LOOP cursor_loop;

    -- 關閉游標
    CLOSE cursor_tickers;

END;

create
    definer = root@localhost procedure tickers.get_est_max_row_size(IN schema_name varchar(100))
main:
BEGIN
    SELECT col_sizes.TABLE_SCHEMA, col_sizes.TABLE_NAME, SUM(col_sizes.col_size) AS EST_MAX_ROW_SIZE
FROM (
    SELECT
        cols.TABLE_SCHEMA,
        cols.TABLE_NAME,
        cols.COLUMN_NAME,
        CASE cols.DATA_TYPE
            WHEN 'tinyint' THEN 1
            WHEN 'smallint' THEN 2
            WHEN 'mediumint' THEN 3
            WHEN 'int' THEN 4
            WHEN 'bigint' THEN 8
            WHEN 'float' THEN IF(cols.NUMERIC_PRECISION > 24, 8, 4)
            WHEN 'double' THEN 8
            WHEN 'decimal' THEN ((cols.NUMERIC_PRECISION - cols.NUMERIC_SCALE) DIV 9)*4  + (cols.NUMERIC_SCALE DIV 9)*4 + CEIL(MOD(cols.NUMERIC_PRECISION - cols.NUMERIC_SCALE,9)/2) + CEIL(MOD(cols.NUMERIC_SCALE,9)/2)
            WHEN 'bit' THEN (cols.NUMERIC_PRECISION + 7) DIV 8
            WHEN 'year' THEN 1
            WHEN 'date' THEN 3
            WHEN 'time' THEN 3 + CEIL(cols.DATETIME_PRECISION /2)
            WHEN 'datetime' THEN 5 + CEIL(cols.DATETIME_PRECISION /2)
            WHEN 'timestamp' THEN 4 + CEIL(cols.DATETIME_PRECISION /2)
            WHEN 'char' THEN cols.CHARACTER_OCTET_LENGTH
            WHEN 'binary' THEN cols.CHARACTER_OCTET_LENGTH
            WHEN 'varchar' THEN IF(cols.CHARACTER_OCTET_LENGTH > 255, 2, 1) + cols.CHARACTER_OCTET_LENGTH
            WHEN 'varbinary' THEN IF(cols.CHARACTER_OCTET_LENGTH > 255, 2, 1) + cols.CHARACTER_OCTET_LENGTH
            WHEN 'tinyblob' THEN 9
            WHEN 'tinytext' THEN 9
            WHEN 'blob' THEN 10
            WHEN 'text' THEN 10
            WHEN 'mediumblob' THEN 11
            WHEN 'mediumtext' THEN 11
            WHEN 'longblob' THEN 12
            WHEN 'longtext' THEN 12
            WHEN 'enum' THEN 2
            WHEN 'set' THEN 8
            ELSE 0
        END AS col_size
    FROM INFORMATION_SCHEMA.COLUMNS cols
    WHERE cols.TABLE_SCHEMA = schema_name
) AS col_sizes
GROUP BY col_sizes.TABLE_SCHEMA, col_sizes.TABLE_NAME;

END;

create
    definer = root@localhost procedure tickers.reset_ticker_id(IN in_moving_from_ticker_id int unsigned,
                                                               IN in_moving_to_ticker_id int unsigned, OUT count int)
main:
BEGIN
    DECLARE temp_count INT UNSIGNED; -- Temporary variable to store the count of target ticker_id in related tables

    -- Exception handler: Rollback transaction and record failure information in temp_vars table on exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET count = 0;
        ROLLBACK;
        INSERT INTO temp_vars (`key`, `value`) VALUES (in_moving_to_ticker_id, CONCAT('FAIL-', in_moving_from_ticker_id));
    END;

    START TRANSACTION; -- Start the transaction

    SET count = 0; -- Initialize the output parameter count

    -- Check if the target ticker_id exists in any related tables
    SET temp_count = (
        SELECT COUNT(*)
        FROM (
            SELECT ticker_id FROM api_results             WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM high_gainers            WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM history_day_gaps        WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM history_day_stats       WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM labeling_minute_days    WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM miss_history_minutes    WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM predict_minutes         WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM ticker_stats            WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM unsplit_history_days    WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM unsplit_history_minutes WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM volatilities            WHERE ticker_id = in_moving_to_ticker_id UNION ALL
            SELECT ticker_id FROM volatilities_backup     WHERE ticker_id = in_moving_to_ticker_id
        ) AS tmp
    );

    -- If the target ticker_id exists in any related tables, exit the procedure
    IF temp_count > 0 THEN
        LEAVE main;
    END IF;

    -- Update ticker_id in all related tables
    UPDATE api_results              SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE high_gainers             SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE history_day_gaps         SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE history_day_stats        SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE labeling_minute_days     SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE miss_history_minutes     SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE predict_minutes          SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE ticker_stats             SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE unsplit_history_days     SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE unsplit_history_minutes  SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE volatilities             SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE volatilities_backup      SET ticker_id = in_moving_to_ticker_id WHERE ticker_id = in_moving_from_ticker_id;
    UPDATE history_daily_events     SET max_volume_ticker_id = in_moving_to_ticker_id WHERE max_volume_ticker_id = in_moving_from_ticker_id;

    -- Update id in the tickers table
    UPDATE tickers                  SET id = in_moving_to_ticker_id WHERE id = in_moving_from_ticker_id;

    -- Record success information in the temp_vars table
    INSERT INTO temp_vars (`key`, `value`) VALUES (in_moving_to_ticker_id, CONCAT('SUCC-', in_moving_from_ticker_id));

    -- Reset AUTO_INCREMENT to the value of the original ticker_id
    SET @sql = CONCAT('ALTER TABLE tickers AUTO_INCREMENT = ', in_moving_from_ticker_id);
    PREPARE st FROM @sql;
    EXECUTE st;
    DEALLOCATE PREPARE st;

    COMMIT; -- Commit the transaction
    SET count = 1; -- Set the output parameter count to indicate success
END;

create
    definer = root@localhost procedure tickers.reset_ticker_ids(OUT row_count bigint, OUT row_executed bigint)
BEGIN
    DECLARE temp_moving_from_ticker_id INT UNSIGNED; -- Original ticker_id
    DECLARE temp_moving_to_ticker_id INT UNSIGNED;   -- New ticker_id
    DECLARE temp_gap_starts_at INT UNSIGNED;         -- Gap start position
    DECLARE temp_gap_ends_at INT UNSIGNED;           -- Gap end position
    DECLARE temp_tmp_row BIGINT;                     -- Temporary variable for storing affected rows in a single operation
    DECLARE temp_total_rows BIGINT;                  -- Total rows in the table
    DECLARE done INT DEFAULT FALSE;                  -- Cursor loop control variable
    DECLARE max_id INT UNSIGNED;                     -- Current maximum ticker_id

    -- Cursor declaration to find gaps between ticker_ids
    DECLARE cursorMinutes CURSOR FOR
        SELECT (t1.id + 1) AS gap_starts_at,
               (SELECT MIN(t3.id) - 1 FROM tickers t3 WHERE t3.id > t1.id) AS gap_ends_at
          FROM tickers t1
         WHERE NOT EXISTS(SELECT t2.id FROM tickers t2 WHERE t2.id = t1.id + 1)
      ORDER BY gap_starts_at;

    -- Handler for cursor end
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Get the current maximum ticker_id
    SELECT MAX(id) INTO max_id FROM tickers;

    -- Reset AUTO_INCREMENT to the current maximum value + 1
    SET @sql = CONCAT('ALTER TABLE tickers AUTO_INCREMENT = ', max_id + 1);
    PREPARE st FROM @sql;
    EXECUTE st;
    DEALLOCATE PREPARE st;

    -- Get the total rows in the table
    SELECT COUNT(*) INTO temp_total_rows FROM tickers;

    -- Initialize output parameters
    SET row_count = 0;
    SET row_executed = 0;

    -- Open the cursor
    OPEN cursorMinutes;
    cursor_loop:
    LOOP
        -- Fetch gap start and end positions from the cursor
        FETCH cursorMinutes INTO temp_gap_starts_at, temp_gap_ends_at;

        -- If cursor is done, exit the loop
        IF done THEN
            LEAVE cursor_loop;
        END IF;

        -- If gap end position is NULL, exit the loop
        IF temp_gap_ends_at IS NULL THEN
            LEAVE cursor_loop;
        END IF;

        -- Increase gap count
        SET row_count = row_count + 1;

        -- Set new ticker_id
        SET temp_moving_to_ticker_id = temp_gap_starts_at;

        -- Loop within the gap range to update ticker_id
        WHILE temp_moving_to_ticker_id <= temp_gap_ends_at AND temp_moving_to_ticker_id <= temp_total_rows DO
            -- Get the current maximum ticker_id as the source ticker_id
            SELECT MAX(id) INTO temp_moving_from_ticker_id FROM tickers;

            -- Call the reset_ticker_id procedure to update ticker_id
            CALL reset_ticker_id(temp_moving_from_ticker_id, temp_moving_to_ticker_id, temp_tmp_row);

            -- Increment target ticker_id
            SET temp_moving_to_ticker_id = temp_moving_to_ticker_id + 1;

            -- Accumulate the number of affected rows
            SET row_executed = row_executed + temp_tmp_row;
        END WHILE;
    END LOOP cursor_loop;

    -- Close the cursor
    CLOSE cursorMinutes;

END;

create
    definer = root@localhost procedure tickers.unsplit_call_update_history_day_stats_day_range(IN in_start_date date, IN in_end_date date, OUT count bigint)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE ticker_done INT DEFAULT FALSE;
    -- 临时变量
    DECLARE in_ticker_id INT;

    DECLARE cur_ticker CURSOR FOR
        SELECT id FROM tickers ORDER BY ID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET ticker_done = TRUE;

    SET count = 0;

    -- 打开外层游标
    OPEN cur_ticker;

    -- 遍历所有 ticker_id
    ticker_loop: LOOP
        FETCH cur_ticker INTO in_ticker_id;

        IF ticker_done THEN
            LEAVE ticker_loop;
        END IF;

        -- 内层处理过程
        CALL unsplit_update_history_day_stats_day_range(in_ticker_id, in_start_date, in_end_date, @count1);
        SET count = count + @count1;
    END LOOP;

    -- 关闭外层游标
    CLOSE cur_ticker;

    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_call_update_history_days_ema(OUT total_count bigint)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE ticker_id INT;
    DECLARE count BIGINT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT id AS ticker_id FROM tickers ORDER BY id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET total_count = 0;

    -- Open the cursor
    OPEN cur;

    -- Loop through the cursor
    read_loop: LOOP
        FETCH cur INTO ticker_id;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Call the procedure for each ticker_id
        CALL unsplit_update_history_days_ema_by_ticker(ticker_id, count);

        -- Accumulate the total count
        SET total_count = total_count + count;
    END LOOP;

    -- Close the cursor
    CLOSE cur;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_call_update_history_minutes_partial_ema(IN in_start_date datetime, OUT total_count bigint)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE ticker_id INT;
    DECLARE count BIGINT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT id AS ticker_id FROM tickers ORDER BY id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET total_count = 0;

    -- Open the cursor
    OPEN cur;

    -- Loop through the cursor
    read_loop: LOOP
        FETCH cur INTO ticker_id;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Call the procedure for each ticker_id
        CALL unsplit_update_history_minutes_partial_ema_by_ticker(ticker_id, in_start_date, count);

        -- Accumulate the total count
        SET total_count = total_count + count;
    END LOOP;

    -- Close the cursor
    CLOSE cur;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@`192.168.31.101` procedure tickers.unsplit_call_update_history_minutes_technical_indicators(IN in_start_ticker_id bigint, OUT count bigint)
BEGIN
    -- Variables to control cursor loop and store ticker_id
    DECLARE ticker_done INT DEFAULT FALSE;
    DECLARE in_ticker_id INT;

    -- Cursor to iterate over ticker IDs starting from in_start_ticker_id
    DECLARE cur_ticker CURSOR FOR
        SELECT id FROM tickers WHERE id >= in_start_ticker_id ORDER BY id;

    -- Handler for cursor end condition
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET ticker_done = TRUE;

    -- Initialize count
    SET count = 0;

    -- Open the cursor
    OPEN cur_ticker;

    -- Loop through all ticker_ids
    ticker_loop: LOOP
        -- Fetch the next ticker_id into in_ticker_id
        FETCH cur_ticker INTO in_ticker_id;

        -- Update the temp_vars table with the current ticker_id
        UPDATE temp_vars SET value = in_ticker_id WHERE `key` = 'last_unsplit_history_minutes_technical_indicators_ticker_id' LIMIT 1;
        COMMIT;

        -- Exit loop if end of cursor is reached
        IF ticker_done THEN
            LEAVE ticker_loop;
        END IF;

        -- Call the procedure to update technical indicators for the current ticker_id
        CALL unsplit_update_history_minutes_technical_indicators_by_ticker(in_ticker_id, @count1);

        -- Accumulate the count of updated records
        SET count = count + @count1;
    END LOOP;

    -- Close the cursor
    CLOSE cur_ticker;

    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_day_stats_day_range(IN in_ticker_id int unsigned,
                                                                                          IN in_start_date date,
                                                                                          IN in_end_date date,
                                                                                          OUT count bigint)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    -- Declare temporary variables
    DECLARE temp_ticker_id INT;
    DECLARE temp_date DATE;

    -- Declare the cursor to read the required data
    DECLARE cur CURSOR FOR
        SELECT ticker_id, `date`
        FROM unsplit_history_days
        WHERE (`ticker_id` >= COALESCE(in_ticker_id, 0))
          AND (`date` >= COALESCE(in_start_date, '1900-01-01'))
          AND (`date` <= COALESCE(in_end_date, '9999-12-31'))
        ORDER BY `ticker_id`, `date`;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET count = 0;

    -- Open the cursor
    OPEN cur;

    -- Loop through the cursor
    read_loop: LOOP
        FETCH cur INTO temp_ticker_id, temp_date;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Calculate rolling window statistics
        UPDATE history_day_stats
        SET
            `5_range_from_low` = (SELECT ROUND(MAX(high * cumulative_reverse_split_ratio) / MIN(low * cumulative_reverse_split_ratio), 4)
                                  FROM (SELECT high, low, cumulative_reverse_split_ratio
                                        FROM unsplit_history_days
                                        WHERE `ticker_id` = temp_ticker_id AND `date` <= temp_date
                                        ORDER BY `date` DESC LIMIT 5) AS subquery),
            `10_range_from_low` = (SELECT ROUND(MAX(high * cumulative_reverse_split_ratio) / MIN(low * cumulative_reverse_split_ratio), 4)
                                   FROM (SELECT high, low, cumulative_reverse_split_ratio
                                         FROM unsplit_history_days
                                         WHERE `ticker_id` = temp_ticker_id AND `date` <= temp_date
                                         ORDER BY `date` DESC LIMIT 10) AS subquery),
            `20_range_from_low` = (SELECT ROUND(MAX(high * cumulative_reverse_split_ratio) / MIN(low * cumulative_reverse_split_ratio), 4)
                                   FROM (SELECT high, low, cumulative_reverse_split_ratio
                                         FROM unsplit_history_days
                                         WHERE `ticker_id` = temp_ticker_id AND `date` <= temp_date
                                         ORDER BY `date` DESC LIMIT 20) AS subquery),
            `5_range_from_high` = (SELECT ROUND(MIN(low * cumulative_reverse_split_ratio) / MAX(high * cumulative_reverse_split_ratio), 4)
                                   FROM (SELECT high, low, cumulative_reverse_split_ratio
                                         FROM unsplit_history_days
                                         WHERE `ticker_id` = temp_ticker_id AND `date` <= temp_date
                                         ORDER BY `date` DESC LIMIT 5) AS subquery),
            `10_range_from_high` = (SELECT ROUND(MIN(low * cumulative_reverse_split_ratio) / MAX(high * cumulative_reverse_split_ratio), 4)
                                    FROM (SELECT high, low, cumulative_reverse_split_ratio
                                          FROM unsplit_history_days
                                          WHERE `ticker_id` = temp_ticker_id AND `date` <= temp_date
                                          ORDER BY `date` DESC LIMIT 10) AS subquery),
            `20_range_from_high` = (SELECT ROUND(MIN(low * cumulative_reverse_split_ratio) / MAX(high * cumulative_reverse_split_ratio), 4)
                                    FROM (SELECT high, low, cumulative_reverse_split_ratio
                                          FROM unsplit_history_days
                                          WHERE `ticker_id` = temp_ticker_id AND `date` <= temp_date
                                          ORDER BY `date` DESC LIMIT 20) AS subquery)
        WHERE `ticker_id` = temp_ticker_id AND `date` = temp_date;

        SET count = count + ROW_COUNT();

    END LOOP;

    -- Close the cursor
    CLOSE cur;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_days_ema_by_ticker(IN in_ticker_id int, OUT count bigint)
BEGIN
    -- Update the unsplit_history_days table to calculate the EMAs for the specified ticker
    UPDATE unsplit_history_days
    SET
        9ema = ta_ema(close * cumulative_reverse_split_ratio, 9) / cumulative_reverse_split_ratio,
        20ema = ta_ema(close * cumulative_reverse_split_ratio, 20) / cumulative_reverse_split_ratio,
        300ema = ta_ema(close * cumulative_reverse_split_ratio, 300) / cumulative_reverse_split_ratio
    WHERE ticker_id = in_ticker_id
    ORDER BY date;

    -- Get the number of affected rows
    SELECT ROW_COUNT() INTO count;

    -- Update the temp_vars table with the last updated ticker_id
    UPDATE temp_vars
    SET value = in_ticker_id
    WHERE `key` = 'last_update_day_ema_ticker_id'
    LIMIT 1;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@`192.168.31.101` procedure tickers.unsplit_update_history_days_previous_date(IN in_start_date date, IN in_ticker_id int unsigned)
BEGIN
    -- Variable to control the cursor loop
    DECLARE done INT DEFAULT 0;

    -- Variables to store the current and previous ticker_id and date
    DECLARE curr_ticker_id INT UNSIGNED;
    DECLARE curr_date DATE;
    DECLARE prev_ticker_id INT UNSIGNED DEFAULT NULL;
    DECLARE prev_date DATE;

    -- Cursor to select ticker_id and date from unsplit_history_days based on the input parameters
    DECLARE cur CURSOR FOR
    SELECT ticker_id, date
    FROM tickers.unsplit_history_days
    WHERE (in_start_date IS NULL OR date >= in_start_date)
      AND (in_ticker_id IS NULL OR ticker_id >= in_ticker_id)
    ORDER BY ticker_id, date;

    -- Handler to set done to 1 when the cursor reaches the end
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Initialize prev_date to NULL
    SET prev_date = NULL;

    -- Open the cursor
    OPEN cur;

    -- Loop through the rows fetched by the cursor
    read_loop: LOOP
        -- Fetch the next row into curr_ticker_id and curr_date
        FETCH cur INTO curr_ticker_id, curr_date;

        -- Exit the loop if no more rows are found
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- If the previous ticker_id is the same as the current one, update the previous_date
        IF prev_ticker_id IS NOT NULL AND prev_ticker_id = curr_ticker_id THEN
            UPDATE tickers.unsplit_history_days
            SET
                previous_date = prev_date,
                date_modified = CURRENT_TIMESTAMP
            WHERE
                ticker_id = curr_ticker_id
                AND date = curr_date;
        ELSEIF prev_ticker_id IS NOT NULL THEN
            -- If the ticker_id changes, update the temp_vars table and commit the transaction
            UPDATE temp_vars
            SET value = prev_ticker_id
            WHERE `key` = 'unsplit_update_history_days_previous_date'
            LIMIT 1;
            COMMIT;
        END IF;

        -- Update the previous ticker_id and date with the current values
        SET prev_ticker_id = curr_ticker_id;
        SET prev_date = curr_date;
    END LOOP;

    -- Close the cursor
    CLOSE cur;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_days_stats(IN in_start_date date, IN in_end_date date, OUT count bigint)
BEGIN
    -- Variables to hold the previous row's values
    DECLARE prev_ticker_id INT DEFAULT NULL;
    DECLARE prev_date DATE DEFAULT NULL;
    DECLARE prev_consecutive_trend_days INT DEFAULT NULL;
    DECLARE prev_trend_reversal INT DEFAULT NULL;
    DECLARE prev_close FLOAT DEFAULT NULL;
    DECLARE prev_cumulative_reverse_split_ratio FLOAT DEFAULT 1;

    -- Variables to hold the current row's values
    DECLARE curr_ticker_id INT;
    DECLARE curr_date DATE;
    DECLARE curr_open FLOAT;
    DECLARE curr_high FLOAT;
    DECLARE curr_low FLOAT;
    DECLARE curr_close FLOAT;
    DECLARE curr_cumulative_reverse_split_ratio FLOAT DEFAULT 1;
    DECLARE curr_price_change_ratio FLOAT;
    DECLARE curr_market_session_change_ratio FLOAT;
    DECLARE curr_consecutive_trend_days INT;
    DECLARE curr_trend_reversal INT;

    DECLARE date_diff INT;

    DECLARE done INT DEFAULT FALSE;

    -- Cursor to iterate through the rows in the specified date range
    DECLARE cursor_days CURSOR FOR
        SELECT ticker_id, date, open, close, high, low, cumulative_reverse_split_ratio, consecutive_trend_days, trend_reversal
        FROM unsplit_history_days
        WHERE date >= in_start_date AND date <= in_end_date
        ORDER BY ticker_id, date;

    -- Handler for the end of the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SET count = 0;
    OPEN cursor_days;

    cursor_loop:
    LOOP
        -- Fetch the current row from the cursor
        FETCH cursor_days INTO curr_ticker_id, curr_date, curr_open, curr_close, curr_high, curr_low, curr_cumulative_reverse_split_ratio, curr_consecutive_trend_days, curr_trend_reversal;

        IF done THEN
            LEAVE cursor_loop;
        END IF;

        -- If it's the first row of a ticker, save the current row's values and continue to the next row
        IF prev_ticker_id IS NULL OR prev_ticker_id <> curr_ticker_id THEN
            SET prev_ticker_id = curr_ticker_id;
            SET prev_date = curr_date;
            SET prev_close = curr_close * curr_cumulative_reverse_split_ratio;
            SET prev_cumulative_reverse_split_ratio = curr_cumulative_reverse_split_ratio;
            SET prev_consecutive_trend_days = curr_consecutive_trend_days;
            SET prev_trend_reversal = curr_trend_reversal;
            ITERATE cursor_loop;
        END IF;

        -- Check if the gap between the current and previous dates is too large
        SET date_diff = DATEDIFF(curr_date, prev_date);
        IF date_diff >= 7 THEN
            -- Log the gap
            INSERT IGNORE INTO history_day_gaps (ticker_id, start_date, end_date, datediff)
            VALUES (curr_ticker_id, prev_date, curr_date, date_diff);

            -- Reset the previous values
            SET prev_date = NULL;
            SET prev_close = NULL;
            SET curr_consecutive_trend_days = 0;
            SET curr_trend_reversal = 0;
            SET curr_price_change_ratio = 0;
            SET curr_market_session_change_ratio = ROUND((curr_high - curr_open) / curr_open, 4);

            -- Update the current row with the reset values
            UPDATE unsplit_history_days
            SET previous_date = prev_date,
                consecutive_trend_days = curr_consecutive_trend_days,
                trend_reversal = curr_trend_reversal,
                price_change_ratio = curr_price_change_ratio,
                market_session_change_ratio = curr_market_session_change_ratio,
                date_modified = CURRENT_TIMESTAMP
            WHERE ticker_id = curr_ticker_id AND date = curr_date;

            -- Update the temporary variable table to track the progress
            INSERT INTO temp_vars (`key`, `value`) VALUES (CONCAT('unsplit_update_history_days_stats-ignore', '--', curr_ticker_id), curr_date)
            ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

            ITERATE cursor_loop;
        END IF;

        -- Skip rows with zero or null close values
        IF curr_close <= 0 OR curr_close IS NULL THEN
            SET prev_ticker_id = curr_ticker_id;
            SET prev_date = curr_date;
            SET prev_close = curr_close * curr_cumulative_reverse_split_ratio;
            SET prev_cumulative_reverse_split_ratio = curr_cumulative_reverse_split_ratio;
            SET prev_consecutive_trend_days = curr_consecutive_trend_days;
            SET prev_trend_reversal = curr_trend_reversal;
            ITERATE cursor_loop;
        END IF;

        -- Skip rows where the previous close value is zero or null
        IF prev_close <= 0 OR prev_close IS NULL THEN
            SET prev_ticker_id = curr_ticker_id;
            SET prev_date = curr_date;
            SET prev_close = curr_close * curr_cumulative_reverse_split_ratio;
            SET prev_cumulative_reverse_split_ratio = curr_cumulative_reverse_split_ratio;
            SET prev_consecutive_trend_days = curr_consecutive_trend_days;
            SET prev_trend_reversal = curr_trend_reversal;
            ITERATE cursor_loop;
        END IF;

        -- Calculate the price change ratio and market session change ratio
        SET curr_price_change_ratio = ROUND((curr_close * curr_cumulative_reverse_split_ratio - prev_close) / prev_close, 4);
        SET curr_market_session_change_ratio = ROUND((curr_high - curr_open) / curr_open, 4);

        -- Determine the trend based on the price change ratio
        IF ABS(curr_price_change_ratio) <= 0.01 THEN
            SET prev_trend_reversal = 0;
            SET curr_trend_reversal = 0;
            SET curr_consecutive_trend_days = prev_consecutive_trend_days;
        ELSEIF curr_price_change_ratio > 0.01 THEN
            IF prev_consecutive_trend_days >= 0 THEN
                SET prev_trend_reversal = 0;
                SET curr_trend_reversal = 0;
                SET curr_consecutive_trend_days = prev_consecutive_trend_days + 1;
            ELSE
                SET prev_trend_reversal = 1;
                SET curr_trend_reversal = 0;
                SET curr_consecutive_trend_days = 1;
            END IF;
        ELSEIF curr_price_change_ratio < -0.01 THEN
            IF prev_consecutive_trend_days <= 0 THEN
                SET prev_trend_reversal = 0;
                SET curr_trend_reversal = 0;
                SET curr_consecutive_trend_days = prev_consecutive_trend_days - 1;
            ELSE
                SET prev_trend_reversal = 1;
                SET curr_trend_reversal = 0;
                SET curr_consecutive_trend_days = -1;
            END IF;
        END IF;

        -- Update the current row with the calculated values
        UPDATE unsplit_history_days
        SET previous_date = prev_date,
            consecutive_trend_days = curr_consecutive_trend_days,
            trend_reversal = curr_trend_reversal,
            price_change_ratio = curr_price_change_ratio,
            market_session_change_ratio = curr_market_session_change_ratio,
            date_modified = CURRENT_TIMESTAMP
        WHERE ticker_id = curr_ticker_id AND date = curr_date;

        -- Update the previous row's trend_reversal value
        UPDATE unsplit_history_days
        SET trend_reversal = prev_trend_reversal
        WHERE ticker_id = prev_ticker_id AND date = prev_date;

        -- Update the previous row's values with the current row's values
        SET prev_ticker_id = curr_ticker_id;
        SET prev_date = curr_date;
        SET prev_close = curr_close * curr_cumulative_reverse_split_ratio;
        SET prev_cumulative_reverse_split_ratio = curr_cumulative_reverse_split_ratio;
        SET prev_consecutive_trend_days = curr_consecutive_trend_days;
        SET prev_trend_reversal = curr_trend_reversal;

        -- Increment the count of updated rows
        SET count = count + ROW_COUNT();
    END LOOP cursor_loop;

    CLOSE cursor_days;
    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_days_vwap_by_ticker(IN in_ticker_id int, IN in_start_date date, OUT count bigint)
BEGIN
    DECLARE total_volume FLOAT;
    DECLARE total_vwap FLOAT;
    DECLARE loop_date DATE;
    DECLARE current_typical_price FLOAT;
    DECLARE current_volume FLOAT;
    DECLARE current_ratio FLOAT;
    DECLARE temp_vwap FLOAT;
    DECLARE done INT DEFAULT FALSE;

    -- Cursor declaration
    DECLARE cur CURSOR FOR
        SELECT date, (high + low + close) / 3 * cumulative_reverse_split_ratio AS typical_price,
               volume / cumulative_reverse_split_ratio AS volume,
               cumulative_reverse_split_ratio
        FROM unsplit_history_days
        WHERE ticker_id = in_ticker_id AND date >= COALESCE(in_start_date, '1900-01-01')
        ORDER BY date;

    -- Handler for cursor end
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Initialize variables
    SET total_volume = 0;
    SET total_vwap = 0;
    SET count = 0;

    -- Initialize initial data
    SELECT IFNULL(SUM(volume / cumulative_reverse_split_ratio), 0) INTO total_volume
    FROM unsplit_history_days
    WHERE ticker_id = in_ticker_id AND date < COALESCE(in_start_date, '1900-01-01');

    SELECT IFNULL(SUM((high + low + close) / 3 * cumulative_reverse_split_ratio * volume / cumulative_reverse_split_ratio), 0) INTO total_vwap
    FROM unsplit_history_days
    WHERE ticker_id = in_ticker_id AND date < COALESCE(in_start_date, '1900-01-01');

    -- Open cursor
    OPEN cur;

    -- Loop through the cursor
    read_loop: LOOP
        FETCH cur INTO loop_date, current_typical_price, current_volume, current_ratio;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Calculate VWAP
        SET total_volume = total_volume + current_volume;
        SET total_vwap = total_vwap + (current_typical_price * current_volume);
        IF total_volume > 0 THEN
            SET temp_vwap = total_vwap / total_volume / current_ratio;
        ELSE
            SET temp_vwap = 0; -- Or set to 0 or other appropriate value
        END IF;

        -- Update VWAP in the table
        UPDATE unsplit_history_days
        SET vwap = temp_vwap
        WHERE ticker_id = in_ticker_id
          AND date = loop_date;

        SET count = count + ROW_COUNT();
    END LOOP;

    -- Close cursor
    CLOSE cur;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_minutes_after_10_30_low(IN in_start_date date,
                                                                                              IN in_end_date date,
                                                                                              OUT insert_count bigint,
                                                                                              OUT update_count bigint)
BEGIN
    -- Declare variables for storing row data and calculations
    DECLARE temp_ticker_id INT;
    DECLARE temp_date DATE;
    DECLARE temp_low FLOAT;
    DECLARE temp_minute INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE last_ticker_id INT DEFAULT NULL;
    DECLARE last_date DATE DEFAULT NULL;

    -- Cursor to fetch relevant data from unsplit_history_minutes within the specified date range
    DECLARE cursor_minutes CURSOR FOR
        SELECT
            low_minutes.ticker_id,
            low_minutes.`date`,
            low_minutes.low,
            uhm.minute
        FROM (
            SELECT
                uhm.ticker_id,
                uhm.`date`,
                MIN(uhm.low) AS low
            FROM
                unsplit_history_minutes uhm
            WHERE
                uhm.minute >= 630
                AND uhm.`date` >= in_start_date
                AND uhm.`date` <= in_end_date
            GROUP BY
                uhm.ticker_id, uhm.`date`
            ORDER BY
                uhm.ticker_id, uhm.`date`
        ) AS low_minutes
        JOIN unsplit_history_minutes uhm ON
            low_minutes.ticker_id = uhm.ticker_id
            AND low_minutes.`date` = uhm.`date`
            AND low_minutes.low = uhm.low
        ORDER BY
            low_minutes.ticker_id, low_minutes.`date`, uhm.minute ASC;

    -- Handler for the end of the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Initialize counters
    SET insert_count = 0;
    SET update_count = 0;

    -- Open the cursor
    OPEN cursor_minutes;

    -- Loop through the rows fetched by the cursor
    cursor_loop: LOOP
        FETCH cursor_minutes INTO temp_ticker_id, temp_date, temp_low, temp_minute;

        -- If no more data, exit the loop
        IF done THEN
            LEAVE cursor_loop;
        END IF;

        -- Only update the first record for each ticker on each date
        IF last_ticker_id IS NULL OR last_ticker_id != temp_ticker_id OR last_date != temp_date THEN
            -- Insert data or update on key conflict
            INSERT INTO history_day_stats (
                ticker_id, `date`, after_10_30_low, after_10_30_low_minute
            ) VALUES (
                temp_ticker_id, temp_date, temp_low, temp_minute
            )
            ON DUPLICATE KEY UPDATE
                after_10_30_low = VALUES(after_10_30_low),
                after_10_30_low_minute = VALUES(after_10_30_low_minute);

            -- Use ROW_COUNT() to get the number of affected rows
            IF ROW_COUNT() = 1 THEN
                -- Indicates a row was inserted
                SET insert_count = insert_count + 1;
            ELSEIF ROW_COUNT() = 2 THEN
                -- Indicates a row was updated
                SET update_count = update_count + 1;
            END IF;

            -- Update last_ticker_id and last_date
            SET last_ticker_id = temp_ticker_id;
            SET last_date = temp_date;
        END IF;
    END LOOP cursor_loop;

    -- Close the cursor
    CLOSE cursor_minutes;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_minutes_aftermarket_stats(IN in_start_date date, IN in_end_date date, OUT total_count bigint)
BEGIN
    -- Declare variables for storing row data and calculations
    DECLARE temp_ticker_id INT;
    DECLARE temp_date DATE;
    DECLARE temp_aftermarket_high FLOAT;
    DECLARE temp_aftermarket_high_minute INT;
    DECLARE temp_aftermarket_low FLOAT;
    DECLARE temp_aftermarket_low_minute INT;
    DECLARE temp_aftermarket_open FLOAT;
    DECLARE temp_aftermarket_open_minute INT;
    DECLARE temp_aftermarket_close FLOAT;
    DECLARE temp_aftermarket_close_minute INT;
    DECLARE temp_aftermarket_ratio FLOAT;
    DECLARE temp_aftermarket_volume BIGINT;
    DECLARE temp_minute_count INT;
    DECLARE temp_open FLOAT;
    DECLARE temp_close FLOAT;
    DECLARE done INT DEFAULT FALSE;

    -- Cursor to fetch relevant data from unsplit_history_minutes and unsplit_history_days within the specified date range
    DECLARE cursor_minutes CURSOR FOR
        SELECT
            uhm.ticker_id,
            uhm.`date`,
            curr_day.open,
            curr_day.close,
            ROUND(MAX(uhm.high) / curr_day.close, 4) AS ratio,
            SUM(uhm.volume) AS volume,
            COUNT(uhm.minute) AS minute_count
        FROM
            unsplit_history_minutes uhm
        JOIN
            unsplit_history_days curr_day
            ON uhm.ticker_id = curr_day.ticker_id
            AND uhm.`date` = curr_day.`date`
        WHERE
            uhm.minute >= 960
            AND uhm.`date` >= in_start_date
            AND uhm.`date` <= in_end_date
        GROUP BY
            uhm.ticker_id,
            uhm.`date`
        ORDER BY
            uhm.ticker_id,
            uhm.`date`;

    -- Handler for the end of the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Initialize the count of updated rows
    SET total_count = 0;

    -- Open the cursor
    OPEN cursor_minutes;

    -- Loop through the rows fetched by the cursor
    cursor_loop: LOOP
        FETCH cursor_minutes INTO temp_ticker_id, temp_date, temp_open, temp_close, temp_aftermarket_ratio, temp_aftermarket_volume, temp_minute_count;

        IF done THEN
            LEAVE cursor_loop;
        END IF;

        -- Fetch the highest aftermarket price and corresponding minute
        SELECT uhm.high, uhm.minute
        INTO temp_aftermarket_high, temp_aftermarket_high_minute
        FROM unsplit_history_minutes uhm
        WHERE uhm.ticker_id = temp_ticker_id
          AND uhm.`date` = temp_date
          AND uhm.minute >= 960
        ORDER BY uhm.high DESC
        LIMIT 1;

        -- Fetch the lowest aftermarket price and corresponding minute after the highest minute
        SELECT uhm.low, uhm.minute
        INTO temp_aftermarket_low, temp_aftermarket_low_minute
        FROM unsplit_history_minutes uhm
        WHERE uhm.ticker_id = temp_ticker_id
          AND uhm.`date` = temp_date
          AND uhm.minute >= 960
          AND uhm.minute >= temp_aftermarket_high_minute
        ORDER BY uhm.low ASC
        LIMIT 1;

        -- Fetch the first aftermarket open price and corresponding minute
        SELECT uhm.open, uhm.minute
        INTO temp_aftermarket_open, temp_aftermarket_open_minute
        FROM unsplit_history_minutes uhm
        WHERE uhm.ticker_id = temp_ticker_id
          AND uhm.`date` = temp_date
          AND uhm.minute >= 960
        ORDER BY uhm.minute ASC
        LIMIT 1;

        -- Fetch the last aftermarket close price and corresponding minute
        SELECT uhm.close, uhm.minute
        INTO temp_aftermarket_close, temp_aftermarket_close_minute
        FROM unsplit_history_minutes uhm
        WHERE uhm.ticker_id = temp_ticker_id
          AND uhm.`date` = temp_date
          AND uhm.minute >= 960
        ORDER BY uhm.minute DESC
        LIMIT 1;

        -- Insert or update the premarket statistics in the history_day_stats table
        INSERT INTO history_day_stats (
            ticker_id,
            `date`,
            aftermarket_high_minute,
            aftermarket_high,
            aftermarket_low_minute,
            aftermarket_low,
            aftermarket_ratio,
            aftermarket_open,
            aftermarket_close,
            aftermarket_volume
        ) VALUES (
            temp_ticker_id,
            temp_date,
            temp_aftermarket_high_minute,
            temp_aftermarket_high,
            temp_aftermarket_low_minute,
            temp_aftermarket_low,
            temp_aftermarket_ratio,
            temp_aftermarket_open,
            temp_aftermarket_close,
            temp_aftermarket_volume
        ) ON DUPLICATE KEY UPDATE
            aftermarket_high_minute = VALUES(aftermarket_high_minute),
            aftermarket_high = VALUES(aftermarket_high),
            aftermarket_low_minute = VALUES(aftermarket_low_minute),
            aftermarket_low = VALUES(aftermarket_low),
            aftermarket_ratio = VALUES(aftermarket_ratio),
            aftermarket_open = VALUES(aftermarket_open),
            aftermarket_close = VALUES(aftermarket_close),
            aftermarket_volume = VALUES(aftermarket_volume);

        -- Increment the count of updated rows
        SET total_count = total_count + ROW_COUNT();

        -- Insert or update the progress in the temp_vars table
        INSERT INTO temp_vars (`key`, `value`) VALUES ('unsplit_update_history_minutes_aftermarket_stats', CONCAT(temp_date, '--', temp_ticker_id, '--', total_count))
        ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
    END LOOP;

    -- Close the cursor
    CLOSE cursor_minutes;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_minutes_ema_by_ticker(IN in_ticker_id int, OUT count bigint)
BEGIN
    -- Update the unsplit_history_minutes table to calculate the EMAs for the specified ticker
    UPDATE unsplit_history_minutes uhm
    JOIN unsplit_history_days uhd
    ON uhm.ticker_id = uhd.ticker_id AND uhm.date = uhd.date
    SET
        -- Calculate 9ema, considering the effect of cumulative_reverse_split_ratio
        uhm.9ema = ta_ema(uhm.close * uhd.cumulative_reverse_split_ratio, 9) / uhd.cumulative_reverse_split_ratio,
        -- Calculate 20ema, considering the effect of cumulative_reverse_split_ratio
        uhm.20ema = ta_ema(uhm.close * uhd.cumulative_reverse_split_ratio, 20) / uhd.cumulative_reverse_split_ratio,
        -- Calculate 300ema, considering the effect of cumulative_reverse_split_ratio
        uhm.300ema = ta_ema(uhm.close * uhd.cumulative_reverse_split_ratio, 300) / uhd.cumulative_reverse_split_ratio
    WHERE uhm.ticker_id = in_ticker_id
    ORDER BY uhm.date, uhm.minute;

    -- Get the number of affected rows
    SELECT ROW_COUNT() INTO count;

    -- Update the temp_vars table with the last updated ticker_id
    UPDATE temp_vars
    SET value = in_ticker_id
    WHERE `key` = 'last_update_minute_ema_ticker_id'
    LIMIT 1;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@`192.168.31.101` procedure tickers.unsplit_update_history_minutes_partial_ema_by_ticker(IN in_ticker_id int, IN in_start_date datetime, OUT count bigint)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE last_9ema FLOAT;
    DECLARE last_20ema FLOAT;
    DECLARE last_300ema FLOAT;
    DECLARE last_ratio FLOAT;
    DECLARE record_date DATETIME;
    DECLARE record_min SMALLINT;
    DECLARE curr_price FLOAT;
    DECLARE next_9ema FLOAT;
    DECLARE next_20ema FLOAT;
    DECLARE next_300ema FLOAT;
    DECLARE curr_ratio FLOAT;

    DECLARE cur CURSOR FOR
        SELECT uhm.date, uhm.minute, uhm.close, uhd.cumulative_reverse_split_ratio
        FROM unsplit_history_minutes uhm
        JOIN unsplit_history_days uhd
        ON uhm.ticker_id = uhd.ticker_id AND uhm.date = uhd.date
        WHERE uhm.ticker_id = in_ticker_id AND uhm.date >= in_start_date
        ORDER BY uhm.date, uhm.minute;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET count = 0;

    -- Set the initial EMA values
    SELECT uhm.9ema * uhd.cumulative_reverse_split_ratio, uhm.20ema * uhd.cumulative_reverse_split_ratio, uhm.300ema * uhd.cumulative_reverse_split_ratio, uhd.cumulative_reverse_split_ratio INTO last_9ema, last_20ema, last_300ema, last_ratio
    FROM unsplit_history_minutes uhm
    JOIN unsplit_history_days uhd
    ON uhm.ticker_id = uhd.ticker_id AND uhm.date = uhd.date
    WHERE uhm.ticker_id = in_ticker_id AND uhm.date < in_start_date
    ORDER BY uhm.date DESC, uhm.minute DESC
    LIMIT 1;

    -- Open the cursor
    OPEN cur;

    -- Prepare the update statement
    SET @sql_update = CONCAT('UPDATE unsplit_history_minutes SET `9ema` = ?, `20ema` = ?, `300ema` = ? WHERE ticker_id = ? AND date = ? AND minute = ?');
    PREPARE stmt_update FROM @sql_update;

    -- Loop through the cursor
    read_loop: LOOP
        FETCH cur INTO record_date, record_min, curr_price, curr_ratio;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Adjust the current price using the curr_ratio
        SET curr_price = curr_price * curr_ratio;

        -- Calculate 9ema
        IF last_9ema IS NULL THEN
            SET next_9ema = curr_price;
        ELSE
            SET next_9ema = ema_by_steps(curr_price, last_9ema, 9);
        END IF;

        -- Calculate 20ema
        IF last_20ema IS NULL THEN
            SET next_20ema = curr_price;
        ELSE
            SET next_20ema = ema_by_steps(curr_price, last_20ema, 20);
        END IF;

        -- Calculate 300ema
        IF last_300ema IS NULL THEN
            SET next_300ema = curr_price;
        ELSE
            SET next_300ema = ema_by_steps(curr_price, last_300ema, 300);
        END IF;

        -- Update previous EMA values for the next loop iteration
        SET last_9ema = next_9ema;
        SET last_20ema = next_20ema;
        SET last_300ema = next_300ema;

        -- Update EMA values in the table
        SET @next_9ema = next_9ema / curr_ratio;
        SET @next_20ema = next_20ema / curr_ratio;
        SET @next_300ema = next_300ema / curr_ratio;

        SET @in_ticker_id = in_ticker_id;
        SET @record_date = record_date;
        SET @record_min = record_min;
        EXECUTE stmt_update USING @next_9ema, @next_20ema, @next_300ema, @in_ticker_id, @record_date, @record_min;

        SET count = count + ROW_COUNT();
    END LOOP;

    -- Close the cursor
    CLOSE cur;

    -- Deallocate the prepared statement
    DEALLOCATE PREPARE stmt_update;

    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_minutes_premarket_stats(IN in_start_date date, IN in_end_date date, OUT total_count bigint)
BEGIN
    -- Declare variables for storing row data and calculations
    DECLARE temp_ticker_id INT;
    DECLARE temp_date DATE;
    DECLARE temp_prev_close FLOAT;
    DECLARE temp_premarket_high FLOAT;
    DECLARE temp_premarket_high_minute INT;
    DECLARE temp_premarket_low FLOAT;
    DECLARE temp_premarket_low_minute INT;
    DECLARE temp_premarket_open FLOAT;
    DECLARE temp_premarket_open_minute INT;
    DECLARE temp_premarket_close FLOAT;
    DECLARE temp_premarket_close_minute INT;
    DECLARE temp_premarket_ratio FLOAT;
    DECLARE temp_premarket_volume BIGINT;
    DECLARE temp_minute_count INT;

    -- Variable to control the cursor loop
    DECLARE done INT DEFAULT FALSE;

    -- Cursor to fetch relevant data from unsplit_history_minutes and unsplit_history_days within the specified date range
    DECLARE cursor_minutes CURSOR FOR
        SELECT uhm.ticker_id,
               uhm.`date`,
               prev_day.close / curr_day.cumulative_reverse_split_ratio * prev_day.cumulative_reverse_split_ratio AS prev_close,
               ROUND(MAX(uhm.high) / (prev_day.close / curr_day.cumulative_reverse_split_ratio * prev_day.cumulative_reverse_split_ratio), 4) AS ratio,
               SUM(uhm.volume) AS volume,
               COUNT(uhm.minute) AS minute_count
        FROM unsplit_history_minutes uhm
        JOIN unsplit_history_days curr_day ON uhm.ticker_id = curr_day.ticker_id AND uhm.`date` = curr_day.`date`
        JOIN unsplit_history_days prev_day ON curr_day.ticker_id = prev_day.ticker_id AND curr_day.previous_date = prev_day.`date`
        WHERE uhm.minute >= 240
          AND uhm.minute < 570
          AND uhm.`date` >= in_start_date
          AND uhm.`date` <= in_end_date
        GROUP BY uhm.ticker_id, uhm.`date`
        ORDER BY uhm.ticker_id, uhm.`date`;

    -- Handler for the end of the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Initialize the count of updated rows
    SET total_count = 0;

    -- Open the cursor
    OPEN cursor_minutes;

    -- Loop through the rows fetched by the cursor
    cursor_loop: LOOP
        FETCH cursor_minutes INTO temp_ticker_id, temp_date, temp_prev_close, temp_premarket_ratio, temp_premarket_volume, temp_minute_count;

        IF done THEN
            LEAVE cursor_loop;
        END IF;

        -- Fetch the highest premarket price and corresponding minute
        SELECT uhm.high, uhm.minute
        INTO temp_premarket_high, temp_premarket_high_minute
        FROM unsplit_history_minutes uhm
        WHERE uhm.ticker_id = temp_ticker_id
          AND uhm.`date` = temp_date
          AND uhm.minute >= 240
          AND uhm.minute < 570
        ORDER BY uhm.high DESC
        LIMIT 1;

        -- Fetch the lowest premarket price and corresponding minute after the highest minute
        SELECT uhm.low, uhm.minute
        INTO temp_premarket_low, temp_premarket_low_minute
        FROM unsplit_history_minutes uhm
        WHERE uhm.ticker_id = temp_ticker_id
          AND uhm.`date` = temp_date
          AND uhm.minute >= 240
          AND uhm.minute < 570
          AND uhm.minute >= temp_premarket_high_minute
        ORDER BY uhm.low
        LIMIT 1;

        -- Fetch the first premarket open price and corresponding minute
        SELECT uhm.open, uhm.minute
        INTO temp_premarket_open, temp_premarket_open_minute
        FROM unsplit_history_minutes uhm
        WHERE uhm.ticker_id = temp_ticker_id
          AND uhm.`date` = temp_date
          AND uhm.minute >= 240
          AND uhm.minute < 570
        ORDER BY uhm.minute
        LIMIT 1;

        -- Fetch the last premarket close price and corresponding minute
        SELECT uhm.close, uhm.minute
        INTO temp_premarket_close, temp_premarket_close_minute
        FROM unsplit_history_minutes uhm
        WHERE uhm.ticker_id = temp_ticker_id
          AND uhm.`date` = temp_date
          AND uhm.minute >= 240
          AND uhm.minute < 570
        ORDER BY uhm.minute DESC
        LIMIT 1;

        -- Insert or update the premarket statistics in the history_day_stats table
        INSERT INTO history_day_stats (
            ticker_id,
            `date`,
            premarket_high_minute,
            premarket_high,
            premarket_low_minute,
            premarket_low,
            premarket_ratio,
            premarket_open,
            premarket_close,
            premarket_volume
        ) VALUES (
            temp_ticker_id,
            temp_date,
            temp_premarket_high_minute,
            temp_premarket_high,
            temp_premarket_low_minute,
            temp_premarket_low,
            temp_premarket_ratio,
            temp_premarket_open,
            temp_premarket_close,
            temp_premarket_volume
        ) ON DUPLICATE KEY UPDATE
            premarket_high_minute = VALUES(premarket_high_minute),
            premarket_high = VALUES(premarket_high),
            premarket_low_minute = VALUES(premarket_low_minute),
            premarket_low = VALUES(premarket_low),
            premarket_ratio = VALUES(premarket_ratio),
            premarket_open = VALUES(premarket_open),
            premarket_close = VALUES(premarket_close),
            premarket_volume = VALUES(premarket_volume);

        -- Increment the count of updated rows
        SET total_count = total_count + ROW_COUNT();

        -- Insert or update the progress in the temp_vars table
        INSERT INTO temp_vars (`key`, `value`) VALUES ('unsplit_update_history_minutes_premarket_stats', CONCAT(temp_date, '--', temp_ticker_id, '--', total_count))
        ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
    END LOOP;

    -- Close the cursor
    CLOSE cursor_minutes;

    -- Commit the transaction
    COMMIT;
END;

create
    definer = root@localhost procedure tickers.unsplit_update_history_minutes_technical_indicators_by_ticker(IN in_ticker_id int, OUT count bigint)
BEGIN
    -- Drop temporary tables if they already exist
    DROP TEMPORARY TABLE IF EXISTS temp_adjusted_minutes;
    DROP TEMPORARY TABLE IF EXISTS temp_technical_indicators_results;

    -- Create temporary table to store adjusted data
    CREATE TEMPORARY TABLE temp_adjusted_minutes (
        ticker_id INT,
        date DATE,
        minute INT,
        adjusted_close FLOAT,
        adjusted_volume FLOAT,
        typical_price FLOAT,
        reverse_split_ratio FLOAT
    );

    -- Insert adjusted data into the temporary table
    INSERT INTO temp_adjusted_minutes
    SELECT
        uh.ticker_id,
        uh.date,
        uh.minute,
        uh.close * hd.cumulative_reverse_split_ratio AS adjusted_close,
        uh.volume / hd.cumulative_reverse_split_ratio AS adjusted_volume,
        (uh.high + uh.low + uh.close) / 3 * hd.cumulative_reverse_split_ratio AS typical_price,
        hd.cumulative_reverse_split_ratio
    FROM
        unsplit_history_minutes uh
    JOIN
        unsplit_history_days hd ON uh.ticker_id = hd.ticker_id AND uh.date = hd.date
    WHERE
        uh.ticker_id = in_ticker_id;

    -- Create temporary table to store technical indicators calculation results
    CREATE TEMPORARY TABLE temp_technical_indicators_results (
        ticker_id INT,
        date DATE,
        minute INT,
        ema_9 FLOAT,
        ema_20 FLOAT,
        ema_300 FLOAT,
        cumulative_volume FLOAT,
        cumulative_dollar_volume FLOAT,
        vwap FLOAT
    );

    -- Insert technical indicators calculation results into the temporary table
    INSERT INTO temp_technical_indicators_results
    SELECT
        tam.ticker_id,
        tam.date,
        tam.minute,
        ta_ema(tam.adjusted_close, 9) / tam.reverse_split_ratio AS ema_9,
        ta_ema(tam.adjusted_close, 20) / tam.reverse_split_ratio AS ema_20,
        ta_ema(tam.adjusted_close, 300) / tam.reverse_split_ratio AS ema_300,
        SUM(tam.adjusted_volume) OVER (PARTITION BY tam.date ORDER BY tam.minute) AS cumulative_volume,
        SUM(tam.adjusted_volume * tam.typical_price) OVER (PARTITION BY tam.date ORDER BY tam.minute) AS cumulative_dollar_volume,
        SUM(tam.adjusted_volume * tam.typical_price) OVER (PARTITION BY tam.date ORDER BY tam.minute) / SUM(tam.adjusted_volume) OVER (PARTITION BY tam.date ORDER BY tam.minute) AS vwap
    FROM
        temp_adjusted_minutes tam
    ORDER BY
        tam.date, tam.minute;

    -- Update the unsplit_history_minutes table with the calculated technical indicators
    UPDATE unsplit_history_minutes uh
    JOIN temp_technical_indicators_results ter ON uh.ticker_id = ter.ticker_id AND uh.date = ter.date AND uh.minute = ter.minute
    SET
        uh.9ema = ter.ema_9,
        uh.20ema = ter.ema_20,
        uh.300ema = ter.ema_300,
        uh.vwap = ter.vwap
    WHERE
        uh.ticker_id = in_ticker_id;

    -- Get the number of updated rows
    SELECT ROW_COUNT() INTO count;

    -- Insert or update the temp_vars table with the count of updated rows
    INSERT INTO temp_vars (`key`, `value`)
    VALUES (
        CONCAT('update_unsplit_history_minutes_technical_indicators_by_ticker', '--', in_ticker_id, '--last_ema'), count
    )
    ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

    -- Commit the transaction
    COMMIT;

    -- Drop temporary tables to clean up
    DROP TEMPORARY TABLE IF EXISTS temp_adjusted_minutes;
    DROP TEMPORARY TABLE IF EXISTS temp_technical_indicators_results;
END;

