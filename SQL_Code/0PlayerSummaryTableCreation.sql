CREATE TABLE laliga.player_summary_stats_24_25 AS
SELECT
    g.rk,
    g.player,
    g.nation,
    g.pos,
    g.squad,
    g.age,
    g.born,
    g.mp,
    g.starts,
    g.minutes,
    g.ninety_s,
    -- General Stats
    g.gls,
    g.ast,
    g.g_plus_a,
    g.g_minus_pk,
    g.pk,
    g.pkatt,
    g.crdy,
    g.crdr,
    g.xg,
    g.npxg,
    g.xag,
    g.npxg_plus_xag,
    -- Shooting Stats
    s.sh,
    s.sot,
    s.sot_pct_,
    s.sh_per_90,
    s.sot_per_90,
    s.g_per_sh,
    s.g_per_sot,
    s.dist,
    s.fk,
    s.pkatt AS pk_att,
    -- Passing Stats
    p.cmp AS pass_cmp,
    p.att AS pass_att,
    p.cmp_pct_,
    p.totdist,
    p.prgdist,
    p.short_cmp,
    p.short_att,
    p.short_cmp_pct_,
    p.med_cmp,
    p.med_att,
    p.med_cmp_pct_,
    p.long_cmp,
    p.long_att,
    p.long_cmp_pct_,
    -- Possession Stats
    ps.touches,
    ps.prgc AS prg_carries,
    ps.prgr AS prg_recovers,
    ps.carries,
    ps.totdist AS poss_totdist,
    ps.prgdist AS poss_prgdist,
    ps.take_on_att,
    ps.succ AS take_on_succ,
    ps.succ_pct_ AS take_on_succ_pct,
    -- Defense Stats
    d.tkl,
    d.int AS interceptions,
    d.blocks,
    d.clr,
    d.err,
    -- Shot Creation
    sc.sca,
    sc.sca90,
    sc.gca,
    sc.gca90
FROM laliga.general_stats_24_25 AS g
LEFT JOIN laliga.shooting_stats_24_25 AS s
    ON g.player = s.player AND g.squad = s.squad
LEFT JOIN laliga.passing_stats_24_25 AS p
    ON g.player = p.player AND g.squad = p.squad
LEFT JOIN laliga.possesion_stats_24_25 AS ps
    ON g.player = ps.player AND g.squad = ps.squad
LEFT JOIN laliga.defense_stats_24_25 AS d
    ON g.player = d.player AND g.squad = d.squad
LEFT JOIN  laliga.shotcreation_stats_24_25 AS sc
	ON g.player = sc.player AND g.squad = sc.squad;

-- Checking Data
SELECT COUNT(*) FROM laliga.player_summary_stats_24_25;

-- Peek at the first few rows
SELECT * FROM laliga.player_summary_stats_24_25 LIMIT 10;

-- Check for duplicates (same player + squad)
SELECT player, squad, COUNT(*) 
FROM laliga.player_summary_stats_24_25
GROUP BY player, squad
HAVING COUNT(*) > 1;

-- Creating new  important stats
ALTER TABLE laliga.player_summary_stats_24_25
ADD COLUMN goals_per_90 NUMERIC,
ADD COLUMN assists_per_90 NUMERIC;

UPDATE laliga.player_summary_stats_24_25
SET goals_per_90 = CASE WHEN ninety_s > 0 THEN gls / ninety_s ELSE 0 END,
    assists_per_90 = CASE WHEN ninety_s > 0 THEN ast / ninety_s ELSE 0 END;

--Checkin to make sure the data is fine
SELECT player, squad, gls, ast, ninety_s, goals_per_90, assists_per_90
FROM laliga.player_summary_stats_24_25
ORDER BY goals_per_90 DESC
LIMIT 10;

SELECT player, minutes
FROM laliga.player_summary_stats_24_25 pss 
WHERE minutes > 1000
ORDER BY minutes DESC;

--Creating new column that only shows players first position
ALTER TABLE laliga.player_summary_stats_24_25
ADD COLUMN main_position TEXT;


UPDATE laliga.player_summary_stats_24_25
SET main_position = 
  CASE 
    WHEN SPLIT_PART(pos, ',', 1) LIKE '%FW%' THEN 'FW'
    WHEN SPLIT_PART(pos, ',', 1) LIKE '%MF%' THEN 'MF'
    WHEN SPLIT_PART(pos, ',', 1) LIKE '%DF%' THEN 'DF'
    WHEN SPLIT_PART(pos, ',', 1) LIKE '%GK%' THEN 'GK'
    ELSE 'Other'
  END;

SELECT rk, player, main_position, minutes
FROM laliga.player_summary_stats_24_25 pss
ORDER BY rk;

ALTER TABLE laliga.player_summary_stats_24_25
ADD COLUMN prog_passes int,
ADD COLUMN prog_passes_per_90 numeric;

UPDATE laliga.player_summary_stats_24_25 AS m
SET prog_passes = p.prgp,
    prog_passes_per_90 = CASE
        WHEN m.ninety_s > 0 THEN p.prgp / m.ninety_s
        ELSE 0
    END
FROM laliga.passing_stats_24_25 p
WHERE m.player = p.player AND m.squad = p.squad;


ALTER TABLE laliga.player_summary_stats_24_25 
ADD COLUMN take_on_att_per_90 float;


UPDATE laliga.player_summary_stats_24_25
SET take_on_att_per_90 = take_on_att /ninety_s
WHERE ninety_s > 0;

SELECT *,
	CASE
		WHEN RANK() OVER (ORDER BY take_on_att_per_90 DESC) <= 5 THEN player
		WHEN RANK() OVER (ORDER BY take_on_succ_pct DESC) <= 5 THEN player
	END AS elite_dribblers_label
FROM laliga.player_summary_stats_24_25
WHERE minutes > 1000 AND  main_position != 'GK' AND take_on_att > 30;

CREATE OR REPLACE VIEW player_ranks_view AS
SELECT *,
	RANK() OVER (ORDER BY take_on_att_per_90 DESC) as take_on_att_rank_all,
    RANK() OVER (ORDER BY take_on_succ_pct DESC) as take_on_succ_rank_all,
    CASE 
        WHEN RANK() OVER (ORDER BY take_on_att_per_90 DESC) <= 5 
             OR RANK() OVER (ORDER BY take_on_succ_pct DESC) <= 5 
        THEN player 
        ELSE NULL 
    END as elite_dribblers_label
FROM player_summary_stats_24_25
WHERE minutes >= 1000 
  AND main_position != 'GK' 
  AND take_on_att > 35;

SELECT *
FROM laliga.player_ranks_view prv
ORDER BY elite_dribblers_label ASC;


SELECT 
    COUNT(DISTINCT 
        CASE WHEN take_on_att_rank_all <= 5 THEN player END
    ) as top_attempt_players,
    COUNT(DISTINCT 
        CASE WHEN take_on_succ_rank_all <= 5 THEN player END
    ) as top_success_players,
    COUNT(DISTINCT 
        CASE WHEN take_on_att_rank_all <= 5 AND take_on_succ_rank_all <= 5 THEN player END
    ) as top_in_both
FROM player_ranks_view;


-- Take on succ per 90 ranking top 10
ALTER TABLE laliga.player_summary_stats_24_25 
ADD COLUMN take_on_succ_per_90 float;

UPDATE laliga.player_summary_stats_24_25
SET take_on_succ_per_90 = take_on_succ  /ninety_s
WHERE ninety_s > 0;

CREATE OR REPLACE VIEW player_ranked_view AS
SELECT *,
	RANK() OVER (ORDER BY take_on_succ_per_90 DESC) as take_on_succ_rank,
    RANK() OVER (ORDER BY take_on_succ_pct DESC) as take_on_succ_pct_rank,
    CASE 
        WHEN RANK() OVER (ORDER BY take_on_succ_per_90 DESC) <= 5 
             OR RANK() OVER (ORDER BY take_on_succ_pct DESC) <= 5 
        THEN player 
        ELSE NULL 
    END as elite_dribblers_label
FROM player_summary_stats_24_25
WHERE minutes >= 1000 
  AND main_position != 'GK' 
  AND take_on_att > 35;

SELECT *
FROM player_ranked_view
ORDER BY elite_dribblers_label ASC;

SELECT *
FROM player_ranked_view
ORDER BY take_on_succ_pct_rank , take_on_succ_rank   ASC;

CREATE VIEW player_actions_ranked_view AS
SELECT *,
	RANK() OVER (ORDER BY gca90 DESC) AS gca_per_90_rank,
	RANK() OVER (ORDER BY sca90 DESC) AS sca_per_90_rank,
	CASE 
		WHEN RANK() OVER (ORDER BY gca90 DESC) <= 5
			OR RANK() OVER (ORDER BY sca90 DESC) <=5
		THEN player
		ELSE NULL
	END AS elite_creators_label
FROM laliga.player_summary_stats_24_25
WHERE minutes >= 1000
	AND main_position != 'GK'
	AND sca >= 35;

SELECT *
FROM player_actions_ranked_view
ORDER BY gca_per_90_rank, sca_per_90_rank;

SELECT *
FROM player_actions_ranked_view
ORDER BY elite_creators_label;

ALTER TABLE laliga.player_summary_stats_24_25 
ADD COLUMN prg_carries_per_90 float;

UPDATE laliga.player_summary_stats_24_25
SET prg_carries_per_90 = prg_carries / ninety_s
WHERE ninety_s > 0;

ALTER TABLE laliga.player_summary_stats_24_25 
ADD COLUMN prgdist_per_90 float;

UPDATE laliga.player_summary_stats_24_25
SET prgdist_per_90 = prgdist / ninety_s
WHERE ninety_s > 0;

CREATE VIEW player_carries_ranked_view AS
SELECT *,
	RANK() OVER (ORDER BY prg_carries_per_90 DESC) AS prg_carries_rank,
	RANK() OVER (ORDER BY prgdist_per_90 DESC) AS prgdist_rank,
	CASE
		WHEN RANK() OVER (ORDER BY prg_carries_per_90 DESC) <= 5
			OR RANK() OVER (ORDER BY prgdist_per_90 DESC) <= 5
		THEN player
		ELSE NULL
	END AS elite_carriers_label,
    CASE 
        WHEN carries > 0 THEN (prg_carries::FLOAT / carries) * 100
        ELSE 0 
    END as prog_carry_pct
FROM laliga.player_summary_stats_24_25
WHERE minutes >= 1000
	AND main_position != 'GK'
	AND prg_carries >= 20;

-- Use prg carries per 90 as x axis and prgdist per 90 as y axis, prog_carry_pct as size
SELECT *
FROM player_carries_ranked_view
ORDER BY elite_carriers_label;

ALTER TABLE laliga.player_summary_stats_24_25
ADD COLUMN tkl_per_90 float, ADD COLUMN int_per_90 float, ADD COLUMN tkl_plus_int_per_90 float;

UPDATE laliga.player_summary_stats_24_25
SET tkl_per_90 = tkl / ninety_s, int_per_90 = interceptions / ninety_s
WHERE ninety_s > 0;

UPDATE laliga.player_summary_stats_24_25
SET tkl_plus_int_per_90 = tkl_per_90 + int_per_90
WHERE ninety_s > 0;

ALTER TABLE laliga.player_summary_stats_24_25
ADD COLUMN err_per_90 float;

UPDATE laliga.player_summary_stats_24_25
SET err_per_90 = err / ninety_s
WHERE ninety_s > 0;

ALTER TABLE laliga.player_summary_stats_24_25
ADD COLUMN tkl_plus_int int;

UPDATE laliga.player_summary_stats_24_25
SET tkl_plus_int = tkl + interceptions;


CREATE VIEW players_defense_ranked AS
SELECT *,
	RANK() OVER (ORDER BY tkl_plus_int_per_90 DESC) AS tkl_plus_int_per_90_rank,
	RANK() OVER (ORDER BY err_per_90 DESC) AS err_per_90_rank,
	CASE
		WHEN RANK() OVER (ORDER BY tkl_plus_int_per_90 DESC) <= 10
		THEN player
		ELSE NULL
	END AS elite_defenders_label
FROM laliga.player_summary_stats_24_25
WHERE minutes >= 1000
	AND main_position != 'GK'
	AND tkl_plus_int >= 45;
	
SELECT *
FROM laliga.players_defense_ranked
ORDER BY tkl_plus_int_per_90_rank  ASC;

SELECT *
FROM laliga.players_defense_ranked
ORDER BY tkl_plus_int_per_90_rank  ASC;
	
ALTER TABLE laliga.player_summary_stats_24_25
ADD COLUMN key_passes int;

UPDATE laliga.player_summary_stats_24_25 pss
SET key_passes = p.kp
FROM passing_stats_24_25 p
WHERE pss.player = p.player 
	AND pss.squad = p.squad;

ALTER TABLE laliga.player_summary_stats_24_25
ADD COLUMN key_passes_per_90 float;

UPDATE laliga.player_summary_stats_24_25
SET key_passes_per_90 = key_passes / ninety_s
WHERE ninety_s > 0;

CREATE VIEW player_vision_ranked AS
SELECT *,
	RANK() OVER (ORDER BY key_passes_per_90 DESC) AS key_passes_per_90_rank,
	RANK() OVER (ORDER BY cmp_pct_ DESC) AS pass_cmp_pct_rank,
	CASE
		WHEN RANK() OVER (ORDER BY key_passes_per_90 DESC) <=5
			OR RANK() OVER (ORDER BY cmp_pct_ DESC) <=5
		THEN player
		ELSE NULL
	END AS elite_vision_label
FROM laliga.player_summary_stats_24_25
WHERE minutes >= 1000
	AND main_position != 'GK'
	AND pass_cmp >= 600;

SELECT *
FROM player_vision_ranked
ORDER BY elite_vision_label ASC;

SELECT *
FROM player_vision_ranked
ORDER BY key_passes_per_90_rank, pass_cmp_pct_rank  ASC;
