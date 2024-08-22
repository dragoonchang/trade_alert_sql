create
    definer = root@localhost function tickers.ema_by_steps(close float, previous_ema float, steps int) returns float
    deterministic
BEGIN
  DECLARE weight FLOAT;
  DECLARE smoothing FLOAT;
  DECLARE ema FLOAT;
  SET smoothing = 2.0;
  SET weight = smoothing / (1 + steps);
  SET ema = ((close-previous_ema) * weight) + previous_ema;
  RETURN ema;
END;

create
    definer = root@localhost function tickers.ema_by_weight(close float, previous_ema float, weight float) returns float
    deterministic
BEGIN
  DECLARE ema FLOAT;
  SET ema = ((close-previous_ema) * weight) + previous_ema;
  RETURN ema;
END;

create
    definer = root@localhost function tickers.ema_weight(steps int) returns float deterministic
BEGIN
  DECLARE weight FLOAT;
  DECLARE smoothing FLOAT;
  SET smoothing = 2.0;
  SET weight = smoothing / (1 + steps);
  RETURN weight;
END;

create
    definer = root@localhost function tickers.get_history_minute_pre_date(p_ticker_id int, p_date date) returns date
    deterministic
BEGIN
    DECLARE p_pre_date date;
    SELECT date INTO p_pre_date
          FROM tickers.unsplit_history_minutes
         WHERE ticker_id = p_ticker_id
           AND date < p_date
      ORDER BY date desc
         LIMIT 1;
    RETURN p_pre_date;
END;

create
    definer = root@localhost function tickers.unsplit_history_minutes_previous_date(in_ticker_id int, in_date date) returns date
    deterministic
BEGIN
    DECLARE temp_date date;
    SELECT date INTO temp_date
          FROM unsplit_history_minutes
         WHERE ticker_id = in_ticker_id
           AND date < in_date
      ORDER BY date desc
         LIMIT 1;
    RETURN temp_date;
END;

create
    definer = root@localhost function tickers.unsplit_with_minute_ema(in_ticker_id int) returns tinyint(1)
    reads sql data
BEGIN
    DECLARE p_ema_exist BOOL DEFAULT FALSE;

    -- Check if the ticker already has EMA information in tickers table
    SELECT with_minute_ema INTO p_ema_exist
    FROM tickers
    WHERE id = in_ticker_id;

    -- If EMA information already exists, return it
    IF p_ema_exist > 0 THEN
        RETURN p_ema_exist;
    END IF;

    -- Check if there is any EMA information in unsplit_history_minutes table
    SELECT EXISTS (
        SELECT 1
        FROM unsplit_history_minutes
        WHERE ticker_id = in_ticker_id
          AND `300ema` IS NOT NULL
        LIMIT 1
    ) INTO p_ema_exist;

    -- If EMA information exists, update the tickers table
    IF p_ema_exist > 0 THEN
        UPDATE tickers
        SET with_minute_ema = 1
        WHERE id = in_ticker_id;
    END IF;

    -- Return the result
    RETURN p_ema_exist;
END;

create
    definer = root@localhost function tickers.with_ema(in_ticker_id int) returns tinyint(1) reads sql data
BEGIN
    DECLARE p_ema_exist BOOL DEFAULT FALSE;

    SELECT with_minute_ema INTO p_ema_exist
      FROM tickers
     WHERE id = in_ticker_id;

    IF p_ema_exist > 0 THEN
        return p_ema_exist;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM tickers.unsplit_history_minutes
        WHERE ticker_id = in_ticker_id
          AND 300ema IS NOT NULL
        LIMIT 1
    ) INTO p_ema_exist;

    IF p_ema_exist > 0 THEN
        UPDATE tickers
           SET with_minute_ema = 1
         WHERE id = in_ticker_id;
    END IF;

    RETURN p_ema_exist;
END;

