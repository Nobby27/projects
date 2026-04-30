--#############################################################
-- VIEW UNNEST der Purchased_games mit zugejointen Gamepreisen 
--#############################################################
 
-- Für die Plattformen Playstation
DROP VIEW IF EXISTS playstation_purchased_games_prices ;
 
CREATE OR REPLACE VIEW playstation_purchased_games_prices AS
SELECT DISTINCT
    ppg.playerid,
    g.game_id,
    pp.eur AS euro_price,
	pp.usd AS dollar_price
FROM 
    playstation.purchased_games ppg
-- Entpacke das Array in einzelne Zeilen
JOIN LATERAL UNNEST(ppg.library) AS g(game_id) ON TRUE
-- Join mit der Preistabelle
JOIN 
	playstation.prices pp ON g.game_id = pp.gameid
ORDER BY
	playerid
;
 
-- Validierung:
SELECT * FROM playstation_purchased_games_prices;
 
---------------------------------------------------
-- Für Steam 
---------------------------------------------------
 
SELECT * FROM steam.purchased_games;
 
SELECT 
	stp.player_id, 
	UNNEST(library) AS game_ids
FROM 
	steam.purchased_games stp
;
 
 
CREATE OR REPLACE VIEW steam_purchased_games_prices AS
SELECT DISTINCT
    stp.player_id,
    g.game_id,
    stpr.eur AS euro_price,
	stpr.usd AS dollar_price
FROM 
    steam.purchased_games stp
JOIN LATERAL UNNEST
	(stp.library) AS g(game_id) ON TRUE
JOIN 
	steam.prices stpr ON g.game_id = stpr.game_id
ORDER BY
	player_id
;
 
 
-- Validierung:
SELECT * FROM steam_purchased_games_prices;
 
 
---------------------------------------------------------------
-- Für XBox
---------------------------------------------------------------
 
 
SELECT * FROM xbox.purchased_games;
 
SELECT 
	xbp.playerid, 
	UNNEST(library) AS game_ids
FROM 
	xbox.purchased_games xbp
;
 
 
CREATE OR REPLACE VIEW xbox_purchased_games_prices AS
SELECT DISTINCT
    xbp.playerid,
    g.game_id,
    xbpr.eur AS euro_price,
	xbpr.usd AS dollar_price
FROM 
    xbox.purchased_games xbp
JOIN LATERAL UNNEST
	(xbp.library) AS g(game_id) ON TRUE
JOIN 
	xbox.prices xbpr ON g.game_id = xbpr.gameid
ORDER BY
	playerid
;
 
-- Validierung:
SELECT * FROM xbox_purchased_games_prices;



--#################################################################################
-- TOP 5 DER PLAYSTATION SPIELE
--#################################################################################

DROP VIEW IF EXISTS top5_purchased_games_playstation;
-----------------------------------------------------------------------------------
CREATE OR REPLACE VIEW top5_purchased_games_playstation AS
WITH unnest_playstation_purch AS 
    (
    SELECT
        playerid,
        UNNEST(library) AS gamesid
    FROM
        playstation.purchased_games
    GROUP BY 
        playerid
    )
SELECT
    COUNT(playerid) AS purch_count,
    gamesid,
    plg.title
FROM
    unnest_playstation_purch upp
JOIN
    playstation.games plg ON upp.gamesid = plg.gameid
GROUP BY
    gamesid, plg.title
ORDER BY
    purch_count DESC
LIMIT
    5
;

SELECT * FROM top5_purchased_games_playstation;
 


--#################################################################################
-- 5. Welche Spiele oder Titel werden am häufigsten über alle Plattformen gespielt?
--#################################################################################
DROP VIEW IF EXISTS top5_purchased_games_playstation;
 
 
CREATE OR REPLACE VIEW top5_purchased_games_playstation AS
WITH unnest_playstation_purch AS 
	(
	SELECT
		playerid,
		UNNEST(library) AS gamesid
	FROM
		playstation.purchased_games
	GROUP BY 
		playerid
	)
SELECT
	COUNT(playerid) AS purch_count,
	gamesid,
	plg.title
FROM
	unnest_playstation_purch upp
JOIN
	playstation.games plg ON upp.gamesid = plg.gameid
GROUP BY
	gamesid, plg.title
ORDER BY
	purch_count DESC
LIMIT
	5
;

SELECT * FROM top5_purchased_games_playstation;



--#################################################################################
-- TOP 5 DER STEAM SPIELE
--#################################################################################
 
DROP VIEW IF EXISTS top5_purchased_games_steam;
-----------------------------------------------------------------------------------
CREATE OR REPLACE VIEW top5_purchased_games_steam AS
WITH unnest_steam_purch AS 
	(
	SELECT
		player_id,
		UNNEST(library) AS gamesid
	FROM
		steam.purchased_games
	GROUP BY 
		player_id
	)
SELECT
	COUNT(player_id) AS purch_count,
	gamesid,
	stg.title
FROM
	unnest_steam_purch usp
JOIN
	steam.games stg ON usp.gamesid = stg.game_id
GROUP BY
	gamesid, stg.title
ORDER BY
	purch_count DESC
LIMIT
	5
;
 
SELECT * FROM top5_purchased_games_steam;
 
 
--#################################################################################
-- TOP 5 DER XBOX SPIELE
--#################################################################################
 
DROP VIEW IF EXISTS top5_purchased_games_xbox;
-----------------------------------------------------------------------------------
CREATE OR REPLACE VIEW top5_purchased_games_xbox AS
WITH unnest_xbox_purch AS 
	(
	SELECT
		playerid,
		UNNEST(library) AS gamesid
	FROM
		xbox.purchased_games
	GROUP BY 
		playerid
	)
SELECT
	COUNT(playerid) AS purch_count,
	gamesid,
	xbg.title
FROM
	unnest_xbox_purch uxp
JOIN
	xbox.games xbg ON uxp.gamesid = xbg.gameid
GROUP BY
	gamesid, xbg.title
ORDER BY
	purch_count DESC
LIMIT
	5
;
 
SELECT * FROM top5_purchased_games_xbox;


--#####################################################################################################
-- TOP 5 OVERALL RANKING PLATTFORMEN ZUSAMMEN
--#####################################################################################################
CREATE OR REPLACE VIEW top5_overall_ranking AS
SELECT
    *,
    CASE
        WHEN gamesid IN (tpx.gamesid) THEN 'XBOX'
    END platform
FROM
    top5_purchased_games_xbox tpx
UNION
    SELECT
        *,
        CASE
            WHEN gamesid IN (tps.gamesid) THEN 'STEAM'
        END platform
    FROM
        top5_purchased_games_steam tps
UNION
    SELECT
        *,
        CASE
            WHEN gamesid IN (tpp.gamesid) THEN 'PLAYSTATION'
        END platform
    FROM
        top5_purchased_games_playstation tpp
ORDER BY
    purch_count DESC
LIMIT 5
;

-- Validieren
SELECT * FROM top5_overall_ranking;


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


WITH game_prices AS 
	(
		SELECT 
			game_id,
			MAX(euro_price) AS euro_price,
			MAX(dollar_price) AS dollar_price
		FROM
			playstation_purchased_games_prices
		GROUP BY game_id
	)
SELECT 
	eu.eu_gameid,
	eu.eu_title,
	eu.euro_price,
	dol.dol_gameid,
	dol.dol_title,
	dol.dollar_price
FROM
	(SELECT 
		gp.game_id AS eu_gameid,
		pg.title AS eu_title,
		euro_price,
		ROW_NUMBER() OVER (ORDER BY euro_price DESC) AS rn 
	 FROM 
	 	game_prices gp
	 JOIN
	 	playstation.games pg ON gp.game_id = pg.gameid
	 WHERE 
	 	euro_price IS NOT NULL 
	 LIMIT 10) eu 
JOIN
	(SELECT 
		gp.game_id AS dol_gameid,
		pg.title AS dol_title,
		dollar_price, 
		ROW_NUMBER() OVER (ORDER BY dollar_price DESC) AS rn
	 FROM 
	 	game_prices gp
	 JOIN
	 	playstation.games pg ON gp.game_id = pg.gameid
	 WHERE 
	 	dollar_price IS NOT NULL 
	 LIMIT 10) dol
	USING (rn)
;

















Hier einmal die TOP5 Games by Revenue (Einnahmen)
--###################################
-- TOP 5 GAMES BY REVENUE
--###################################
 
-- Überblick:
SELECT * FROM playstation_purchased_games_prices;
SELECT * FROM steam_purchased_games_prices;
SELECT * FROM xbox_purchased_games_prices;

SELECT * FROM top5_games_revenue_playstation;
SELECT * FROM top5_games_revenue_steam;
SELECT * FROM top5_games_revenue_xbox;
 
--###############
-- PLAYSTATION
--###############
DROP MATERIALIZED VIEW top5_games_revenue_playstation;
 
CREATE MATERIALIZED VIEW top5_games_revenue_playstation AS
WITH games_count AS
	(
		SELECT
			game_id,
			COUNT(*) AS quantity,
			MAX(euro_price) AS euro_price,
        	MAX(dollar_price) AS dollar_price
		FROM
			playstation_purchased_games_prices ppgp
		GROUP BY
			game_id
	) 
SELECT
	gc.game_id,
	pg.title,
	pg.genres,
	gc.euro_price,
	gc.dollar_price,
	gc.quantity,
	gc.quantity * gc.euro_price AS euro_total_per_game,
	gc.quantity * gc.dollar_price AS dollar_total_per_game
FROM
	games_count gc
JOIN
	playstation.games pg ON gc.game_id = pg.gameid
WHERE
	euro_price IS NOT NULL AND dollar_price IS NOT NULL
ORDER BY
	euro_total_per_game DESC
LIMIT
	5
;
 
-- Validieren
 
SELECT * FROM top5_games_revenue_playstation;
 
-----------------------------------------------------------------------------------------------------
--###############
-- STEAM
--###############
DROP MATERIALIZED VIEW top5_games_revenue_steam;
 
CREATE MATERIALIZED VIEW top5_games_revenue_steam AS
WITH games_count AS
	(
		SELECT
			game_id,
			COUNT(*) AS quantity,
			MAX(euro_price) AS euro_price,
        	MAX(dollar_price) AS dollar_price
		FROM
			steam_purchased_games_prices 
		GROUP BY
			game_id
	) 
SELECT
	gc.game_id,
	sg.title,
	sg.genres,
	gc.euro_price,
	gc.dollar_price,
	gc.quantity,
	gc.quantity * gc.euro_price AS euro_total_per_game,
	gc.quantity * gc.dollar_price AS dollar_total_per_game
FROM
	games_count gc
JOIN
	steam.games sg ON gc.game_id = sg.game_id
WHERE
	euro_price IS NOT NULL AND dollar_price IS NOT NULL
ORDER BY
	euro_total_per_game DESC
LIMIT
	5
;
 
-- Validieren
 
SELECT * FROM top5_games_revenue_steam;
 
-----------------------------------------------------------------------------------------------------
--###############
-- XBOX
--###############
DROP MATERIALIZED VIEW top5_games_revenue_xbox;
 
CREATE MATERIALIZED VIEW top5_games_revenue_xbox AS
WITH games_count AS
	(
		SELECT
			game_id,
			COUNT(*) AS quantity,
			MAX(euro_price) AS euro_price,
        	MAX(dollar_price) AS dollar_price
		FROM
			xbox_purchased_games_prices 
		GROUP BY
			game_id
	) 
SELECT
	gc.game_id,
	xg.title,
	xg.genres,
	gc.euro_price,
	gc.dollar_price,
	gc.quantity,
	gc.quantity * gc.euro_price AS euro_total_per_game,
	gc.quantity * gc.dollar_price AS dollar_total_per_game
FROM
	games_count gc
JOIN
	xbox.games xg ON gc.game_id = xg.gameid
WHERE
	euro_price IS NOT NULL AND dollar_price IS NOT NULL
ORDER BY
	euro_total_per_game DESC
LIMIT
	5
;
 
-- Validieren
 
SELECT * FROM top5_games_revenue_xbox;












--########################################################
-- TOP 10 TEUERSTEN SPIELE PRO PLATTFORM IN EURO UND DOLLAR
--########################################################
 
--###############
-- PLAYSTATION
--###############
CREATE MATERIALIZED VIEW top10_priciest_games_playstation AS
WITH game_prices AS 
	(
		SELECT 
			game_id,
			MAX(euro_price) AS euro_price,
			MAX(dollar_price) AS dollar_price
		FROM
			playstation_purchased_games_prices
		GROUP BY game_id
	)
SELECT 
	eu.eu_gameid,
	eu.eu_title,
	eu.euro_price,
	dol.dol_gameid,
	dol.dol_title,
	dol.dollar_price
FROM
	(SELECT 
		gp.game_id AS eu_gameid,
		pg.title AS eu_title,
		euro_price,
		ROW_NUMBER() OVER (ORDER BY euro_price DESC) AS rn 
	 FROM 
	 	game_prices gp
	 JOIN
	 	playstation.games pg ON gp.game_id = pg.gameid
	 WHERE 
	 	euro_price IS NOT NULL 
	 LIMIT 10) eu 
JOIN
	(SELECT 
		gp.game_id AS dol_gameid,
		pg.title AS dol_title,
		dollar_price, 
		ROW_NUMBER() OVER (ORDER BY dollar_price DESC) AS rn
	 FROM 
	 	game_prices gp
	 JOIN
	 	playstation.games pg ON gp.game_id = pg.gameid
	 WHERE 
	 	dollar_price IS NOT NULL 
	 LIMIT 10) dol
	USING (rn)
;
 
-- Validieren
SELECT * FROM top10_priciest_games_playstation;
 
 
--###########
-- STEAM
--###########
CREATE MATERIALIZED VIEW top10_priciest_games_steam AS
WITH game_prices AS 
	(
		SELECT 
			game_id,
			MAX(euro_price) AS euro_price,
			MAX(dollar_price) AS dollar_price
		FROM
			steam_purchased_games_prices
		GROUP BY game_id
	)
SELECT 
	eu.eu_gameid,
	eu.eu_title,
	eu.euro_price,
	dol.dol_gameid,
	dol.dol_title,
	dol.dollar_price
FROM
	(SELECT 
		gp.game_id AS eu_gameid,
		sg.title AS eu_title,
		euro_price,
		ROW_NUMBER() OVER (ORDER BY euro_price DESC) AS rn 
	 FROM 
	 	game_prices gp
	 JOIN
	 	steam.games sg ON gp.game_id = sg.game_id
	 WHERE 
	 	euro_price IS NOT NULL 
	 LIMIT 10) eu 
JOIN
	(SELECT 
		gp.game_id AS dol_gameid,
		sg.title AS dol_title,
		dollar_price, 
		ROW_NUMBER() OVER (ORDER BY dollar_price DESC) AS rn
	 FROM 
	 	game_prices gp
	 JOIN
	 	steam.games sg ON gp.game_id = sg.game_id
	 WHERE 
	 	dollar_price IS NOT NULL 
	 LIMIT 10) dol
	USING (rn)
;
 
-- Validieren
 
SELECT * FROM top10_priciest_games_steam;
 
--###########
-- XBOX
--###########
CREATE MATERIALIZED VIEW top10_priciest_games_xbox AS
WITH game_prices AS 
	(
		SELECT 
			game_id,
			MAX(euro_price) AS euro_price,
			MAX(dollar_price) AS dollar_price
		FROM
			xbox_purchased_games_prices
		GROUP BY game_id
	)
SELECT 
	eu.eu_gameid,
	eu.eu_title,
	eu.euro_price,
	dol.dol_gameid,
	dol.dol_title,
	dol.dollar_price
FROM
	(SELECT 
		gp.game_id AS eu_gameid,
		xg.title AS eu_title,
		euro_price,
		ROW_NUMBER() OVER (ORDER BY euro_price DESC) AS rn 
	 FROM 
	 	game_prices gp
	 JOIN
	 	xbox.games xg ON gp.game_id = xg.gameid
	 WHERE 
	 	euro_price IS NOT NULL 
	 LIMIT 10) eu 
JOIN
	(SELECT 
		gp.game_id AS dol_gameid,
		xg.title AS dol_title,
		dollar_price, 
		ROW_NUMBER() OVER (ORDER BY dollar_price DESC) AS rn
	 FROM 
	 	game_prices gp
	 JOIN
	 	xbox.games xg ON gp.game_id = xg.gameid
	 WHERE 
	 	dollar_price IS NOT NULL 
	 LIMIT 10) dol
	USING (rn)
;
 
-- Validieren
 
SELECT * FROM top10_priciest_games_xbox;












