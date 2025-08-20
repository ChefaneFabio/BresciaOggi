<?php

/**
 * Ottiene la classifica in casa, la classifica in trasferta e la forma di un campionato.
 * Esempio in getScoreboard.txt
 */
header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$season = pg_escape_literal($conn, $_GET["season"]); //Es 2022-2023
$championshipID = pg_escape_literal($conn, $_GET["championshipID"]); //Es Eccellenza
$groupID = pg_escape_literal($conn, $_GET["groupID"]); //Es 'A'

$out = [];

//ES es teamList:[{"id": 28341, "name": "Germania"},{"id": 32771, "name": "Ungheria"},{"id":26001,"name": "Svizzera"},{"id":"Scozia"}]
$teamList = "SELECT DISTINCT ts.id AS team_id, COALESCE(ga.team_name, ss.team_default_name, ts.name) AS team_name, ga.situation AS situation
FROM gare_associacampionato ga JOIN teams_squadre ts ON ga.team_id = ts.id
    JOIN society_society ss ON ts.society_id = ss.id
WHERE campionato_id = $championshipID AND ga.girone_id = $groupID AND ga.season_id = (SELECT gs.id FROM gare_season gs WHERE gs.name = $season)";

$resultTeamList = pg_query($conn, $teamList);
$jsonTeamList = [];
while ($row = pg_fetch_assoc($resultTeamList))
{
	$jsonTeamList[] = [
		"id" => $row["team_id"],
		"name" => $row["team_name"],
		"situation" => $row["situation"]
	];
}

$out["team_list"] = $jsonTeamList;

$lastGroupPhaseDayQuery = "SELECT cc.lastGroupPhaseDay, MAX(g.num_giornata_id) AS maxDay
FROM champs_champ cc, gare_gare g
WHERE cc.campionato_id = $championshipID AND cc.girone_id = $groupID AND cc.season_id = (SELECT gs.id FROM gare_season gs WHERE gs.name = $season)
AND g.campionato_id = $championshipID AND g.girone_id = $groupID AND g.season_id = cc.season_id
GROUP BY cc.lastGroupPhaseDay";

$resultLastGroupPhaseDay = pg_query($conn, $lastGroupPhaseDayQuery); //For championships that has "Fase a gironi" and "Fase a eliminazione", consider only the matches of the first phase.
$lastGroupPhaseDay = null;
$maxDay = null;
while ($row = pg_fetch_assoc($resultLastGroupPhaseDay))
{
	if (array_key_exists("lastgroupphaseday", $row))
		$lastGroupPhaseDay = $row["lastgroupphaseday"];
	if (array_key_exists("maxday", $row))
		$maxDay = $row["maxday"];
}

$out["last_group_phase_day"] = $lastGroupPhaseDay;
$out["max_day"] = $maxDay;

if ($lastGroupPhaseDay == null)
	$lastGroupPhaseDay = 10000;

$query1 = "WITH Matches AS (
SELECT DISTINCT g.id AS ID, COALESCE(ga1.team_name, soc1.team_default_name, ts1.name) AS Name1, COALESCE(ga2.team_name, soc2.team_default_name, ts2.name) AS Name2,
                    g.result_team_1 AS Score1, g.result_team_2 AS Score2, g.result_abnormal_id AS AbnormalResult,
                    g.squadra_1_id AS ID1, g.squadra_2_id AS ID2, g.penalita_team_1 AS Penalty1, g.penalita_team_2 AS Penalty2
    FROM gare_gare g, gare_season s, teams_squadre ts1, teams_squadre ts2,
         society_society soc1, society_society soc2, gare_associacampionato ga1, gare_associacampionato ga2
    WHERE g.campionato_id = $championshipID AND g.season_id = s.id AND g.girone_id = $groupID
AND ts1.id = g.squadra_1_id AND ts2.id = g.squadra_2_id AND (g.result IS NOT NULL OR g.result_abnormal_id IS NOT NULL)
      AND ts1.society_id = soc1.id AND ts2.society_id = soc2.id
AND ga1.campionato_id = g.campionato_id AND ga2.campionato_id = g.campionato_id AND ga1.team_id = ts1.id AND ga2.team_id = ts2.id
AND ga1.season_id = g.season_id AND ga2.season_id = g.season_id
AND g.num_giornata_id::int <= $lastGroupPhaseDay
AND s.name = $season
AND ga1.situation = 'reg' AND ga2.situation = 'reg'
),
MatchResults AS (
SELECT ID1, ID2, Name1, Name2,
           (CASE
               WHEN AbnormalResult IS NULL AND (Score1 > Score2 OR Score2 IS NULL) THEN 1
               WHEN AbnormalResult IS NOT NULL THEN abnormal.v1
               ELSE 0
           END) AS HouseWins,
           (CASE
                WHEN AbnormalResult IS NULL AND (Score2 > Score1 OR Score1 IS NULL) THEN 1
                WHEN AbnormalResult IS NOT NULL THEN abnormal.s1
                ELSE 0
           END) AS HouseLoses,
           (CASE
                WHEN AbnormalResult IS NULL AND Score1 = Score2 THEN 1
                WHEN AbnormalResult IS NOT NULL THEN abnormal.p1
                ELSE 0
           END) AS HouseDraws,
           (CASE
                WHEN AbnormalResult IS NULL THEN Score1
                ELSE abnormal.gf1
           END) AS HouseGoalsFor,
           (CASE
                WHEN AbnormalResult IS NULL THEN Score2
                ELSE abnormal.gf2
           END) AS HouseGoalsAgainst,
           (CASE
                WHEN AbnormalResult IS NULL THEN Penalty1
                ELSE abnormal.pu1
		   END) AS HousePenalty,
           (CASE
                WHEN AbnormalResult IS NULL AND (Score2 > Score1 OR Score1 IS NULL) THEN 1
                WHEN AbnormalResult IS NOT NULL THEN abnormal.v2
                ELSE 0
		   END) AS TransferWins,
           (CASE
                   WHEN AbnormalResult IS NULL AND (Score1 > Score2 OR Score2 IS NULL) THEN 1
                   WHEN AbnormalResult IS NOT NULL THEN abnormal.s2
                   ELSE 0
		   END) AS TransferLoses,
           (CASE
                   WHEN AbnormalResult IS NULL AND Score1 = Score2 THEN 1
                   WHEN AbnormalResult IS NOT NULL THEN abnormal.p2
                   ELSE 0
		   END) AS TransferDraws,
           (CASE
                   WHEN AbnormalResult IS NULL THEN Score2
                   ELSE abnormal.gf2
		   END) AS TransferGoalsFor,
           (CASE
                   WHEN AbnormalResult IS NULL THEN Score1
                   ELSE abnormal.gf1
		   END) AS TransferGoalsAgainst,
           (CASE
                   WHEN AbnormalResult IS NULL THEN Penalty2
                   ELSE abnormal.pu2
		   END) AS TransferPenalty
    FROM (Matches LEFT JOIN gare_resultabnormal AS abnormal ON abnormal.id = AbnormalResult)
),
GroupPenalties AS (
	SELECT ga.team_id AS id, COALESCE(ga.penalita, 0) AS penalty
FROM gare_associacampionato ga
WHERE ga.campionato_id = $championshipID AND ga.girone_id = $groupID AND ga.season_id = (SELECT id FROM gare_season WHERE name = $season)
),
HouseView AS (
SELECT ID1 AS id, Name1 AS Name, COUNT(*) AS GamesPlayed,
           SUM(HouseWins) AS Victories,
           SUM(HouseLoses) AS Losses,
           SUM(HouseDraws) AS Draws,
           SUM(HouseGoalsFor) AS GoalsFor,
           SUM(HouseGoalsAgainst) AS GoalsAgainst,
           SUM(HousePenalty) AS Penalty 
    FROM MatchResults
    GROUP BY ID1, Name1
),
TransferView AS (
SELECT ID2 AS id, Name2 AS Name, COUNT(*) AS GamesPlayed,
           SUM(TransferWins) AS Victories,
           SUM(TransferLoses) AS Losses,
           SUM(TransferDraws) AS Draws,
           SUM(TransferGoalsFor) AS GoalsFor,
           SUM(TransferGoalsAgainst) AS GoalsAgainst,
           SUM(TransferPenalty) AS Penalty
    FROM MatchResults
    GROUP BY ID2, Name2
),
TotalView AS (
SELECT id, Name, SUM(GamesPlayed) AS GamesPlayed, SUM(Losses) AS Losses, SUM(Victories) AS Victories, SUM(Draws) AS Draws,
           SUM(GoalsAgainst) AS GoalsAgainst, SUM(GoalsFor) AS GoalsFor, SUM(Penalty) AS Penalty
    FROM ((SELECT * FROM HouseView) UNION ALL (SELECT * FROM TransferView)) AS \"HouseUnionTransfer\"
    GROUP BY id, Name
),
HouseQueryPoints AS (
SELECT hv.id, Name, (Victories * 3 + Draws - (hv.Penalty + gp.penalty)) AS Points, GamesPlayed, Losses, Victories, Draws,
           GoalsAgainst, GoalsFor, (GoalsFor - GoalsAgainst) AS GoalDifference, hv.Penalty + gp.penalty AS Penalty
    FROM HouseView hv JOIN GroupPenalties gp ON hv.id = gp.id
    ORDER BY Points DESC
),
TransferQueryPoints AS (
SELECT tv.id, Name, (Victories * 3 + Draws - (tv.Penalty + gp.penalty)) AS Points, GamesPlayed, Losses, Victories, Draws,
           GoalsAgainst, GoalsFor, (GoalsFor - GoalsAgainst) AS GoalDifference, tv.Penalty + gp.penalty AS Penalty
    FROM TransferView tv JOIN GroupPenalties gp ON tv.id = gp.id
    ORDER BY Points DESC
),
TotalQueryPoints AS (
SELECT tv.id, Name, (Victories * 3 + Draws - (tv.Penalty + gp.penalty)) AS Points, GamesPlayed, Losses, Victories, Draws,
        GoalsAgainst, GoalsFor, (GoalsFor - GoalsAgainst) AS GoalDifference, tv.Penalty + gp.penalty AS Penalty
    FROM TotalView tv JOIN GroupPenalties gp ON tv.id = gp.id
    ORDER BY Points DESC
),
SingleDirectConfrontations AS ( --Team1, Team2, GoalDifference
SELECT ID1 AS teamID, ID2 AS opponentID,
	COUNT(*) FILTER (WHERE HouseWins = 1) * 3 + COUNT(*) FILTER (WHERE HouseDraws = 1) AS Points,
	SUM(HouseGoalsFor - HouseGoalsAgainst) AS GoalDifference
	FROM MatchResults
	GROUP BY teamID, opponentID
	UNION ALL
	SELECT ID2 AS teamID, ID1 AS opponentID,
		COUNT(*) FILTER (WHERE TransferWins = 1) * 3 + COUNT(*) FILTER (WHERE TransferDraws = 1) AS Points,
		SUM(TransferGoalsFor - TransferGoalsAgainst) AS GoalDifference
	FROM MatchResults
	GROUP BY opponentID, teamID
),
DirectConfrontations AS (
	 SELECT teamID, opponentID, SUM(Points) AS Points, SUM(GoalDifference) AS GoalDifference, COUNT(*) AS GamesPlayed, (SELECT tq.Points FROM TotalQueryPoints tq WHERE tq.id = teamID) AS totalTeamPoints, (SELECT tq.Points FROM TotalQueryPoints tq WHERE tq.id = opponentID) AS totalOpponentPoints
	 FROM SingleDirectConfrontations
	 WHERE (SELECT tq.Points FROM TotalQueryPoints tq WHERE tq.id = teamID) = (SELECT tq.Points FROM TotalQueryPoints tq WHERE tq.id = opponentID) --Keep only the ones where the two team points are equal
	 GROUP BY teamID, opponentID
),
SamePointsCount AS ( --# of teams that have the same points
	 SELECT tq.Points AS points, COUNT(*) AS count
	 FROM TotalQueryPoints tq
	 GROUP BY tq.Points
),
DirectConfrontationsFiltered AS ( --Direct confrontations of teams that have played every game.
	 SELECT dc.*
	 FROM DirectConfrontations dc
	 WHERE dc.totalTeamPoints IN ( --Of the teams that have points so that the games that have been played with the ones that have the same points are N(N - 1). E.g. if 3 teams have the same points -> 6 games must have been played
		 SELECT dc2.totalTeamPoints
		 FROM DirectConfrontations dc2
		 GROUP BY dc2.totalTeamPoints
		 HAVING SUM(dc2.GamesPlayed) = (SELECT count FROM SamePointsCount WHERE points = dc2.totalTeamPoints) * ((SELECT count FROM SamePointsCount WHERE points = dc2.totalTeamPoints) - 1) * 2
	 )
),
TotalFinalStats AS (
	 SELECT tq1.*
	 FROM TotalQueryPoints tq1 FULL OUTER JOIN DirectConfrontationsFiltered dc ON tq1.id = dc.teamID
							   FULL OUTER JOIN TotalQueryPoints tq2 ON tq2.id = dc.opponentID
	 WHERE tq1.id IS NOT NULL
	 GROUP BY tq1.id, tq1.Name, tq1.Points, tq1.GamesPlayed, tq1.Losses, tq1.Victories, tq1.Draws, tq1.GoalsAgainst, tq1.GoalsFor, tq1.GoalDifference, tq1.Penalty
	 ORDER BY tq1.Points DESC, --Points
			  SUM(dc.Points) FILTER (WHERE tq1.Points = tq2.Points) DESC, --Points on direct matches
			  SUM(dc.GoalDifference) FILTER (WHERE tq1.Points = tq2.Points) DESC, --Goal difference in direct matches
			  tq1.GoalDifference DESC, --Goal difference in championship
			  tq1.GoalsFor DESC --Total number of goals
)
SELECT 'House' as ScoreboardType, id, Name, Points, GamesPlayed, Losses, Victories, Draws, GoalsAgainst, GoalsFor, GoalDifference, Penalty
FROM HouseQueryPoints
UNION ALL
SELECT 'Transfer' AS ScoreboardType, id, Name, Points, GamesPlayed, Losses, Victories, Draws, GoalsAgainst, GoalsFor, GoalDifference, Penalty
FROM TransferQueryPoints
UNION ALL
SELECT 'Total' AS ScoreboardType, id, Name, Points, GamesPlayed, Losses, Victories, Draws, GoalsAgainst, GoalsFor, GoalDifference, Penalty
FROM TotalFinalStats";

$out["house"] = [];
$out["transfer"] = [];
$out["total"] = [];

$result1 = pg_query($conn, $query1);

while ($row = pg_fetch_assoc($result1))
{
	$scoreboardRow = [
		"id" =>	$row["id"],
		"name" => $row["name"],
		"points" => $row["points"],
		"gamesPlayed" => $row["gamesplayed"],
		"losses" => $row["losses"],
		"draws" => $row["draws"],
		"victories" => $row["victories"],
		"goalsAgainst" => $row["goalsagainst"],
		"goalsFor" => $row["goalsfor"],
		"goalDifference" => $row["goaldifference"],
		"penalty" => $row["penalty"],
	];
	if ($row["scoreboardtype"] == "House")
		$out["house"][] = $scoreboardRow;
	else if ($row["scoreboardtype"] == "Transfer")
		$out["transfer"][] = $scoreboardRow;
	else
		$out["total"][] = $scoreboardRow;
}

//Query2, team shape
$query2 = "WITH GareSelected AS (
SELECT g.id AS ID, ts1.name AS Name1, ts2.name AS Name2, g.num_giornata_id AS day,
           g.result_team_1 AS Score1, g.result_team_2 AS Score2, g.result_abnormal_id AS AbnormalResult,
           g.squadra_1_id AS ID1, g.squadra_2_id AS ID2, g.penalita_team_1 AS Penalty1, g.penalita_team_2 AS Penalty2, g.result
    FROM gare_gare g, gare_season s, teams_squadre ts1, teams_squadre ts2, gare_associacampionato ga1, gare_associacampionato ga2
    WHERE g.campionato_id = $championshipID AND g.season_id = s.id AND g.girone_id = $groupID
AND ts1.id = g.squadra_1_id AND ts2.id = g.squadra_2_id AND g.result IS NOT NULL
AND ga1.campionato_id = g.campionato_id AND ga2.campionato_id = g.campionato_id AND ga1.team_id = ts1.id AND ga2.team_id = ts2.id
AND ga1.season_id = g.season_id AND ga2.season_id = g.season_id
AND ga1.situation = 'reg' AND ga2.situation = 'reg'
AND s.name = $season
),
    MatchStatusesHouse AS (
SELECT
        g.ID1 AS TeamID,
        g.Name1 AS Name,
        CASE
            WHEN AbnormalResult IS NULL AND (Score1 > Score2 OR Score2 IS NULL) THEN 'V' 
            WHEN AbnormalResult IS NULL AND Score2 > Score1 THEN 'P'
            WHEN AbnormalResult IS NOT NULL AND abnormal.v1 = 1 THEN 'V'
            WHEN AbnormalResult IS NOT NULL AND abnormal.v2 = 1 THEN 'P'
            ELSE 'N'   
        END AS Status,
        g.day AS day
    FROM GareSelected g LEFT JOIN gare_resultabnormal AS abnormal ON abnormal.id = AbnormalResult
    ORDER BY day::INTEGER ASC),
    MatchStatusesTransfer AS (
SELECT
        g.ID2 AS TeamID,
        g.Name2 AS Name,
        CASE
            WHEN AbnormalResult IS NULL AND (Score2 > Score1 OR Score1 IS NULL) THEN 'V' 
            WHEN AbnormalResult IS NULL AND Score1 > Score2 THEN 'P'
            WHEN AbnormalResult IS NOT NULL AND abnormal.v2 = 1 THEN 'V'
            WHEN AbnormalResult IS NOT NULL AND abnormal.v1 = 1 THEN 'P'
            ELSE 'N'    
        END AS Status,
        g.day AS day
    FROM GareSelected g LEFT JOIN gare_resultabnormal AS abnormal ON abnormal.id = AbnormalResult
    ORDER BY day::INTEGER ASC),
    MatchStatuses AS (
    SELECT * FROM (
        SELECT TeamID, Name, Status, day FROM MatchStatusesHouse AS TB1
        UNION ALL
        SELECT TeamID, Name, Status, day FROM MatchStatusesTransfer) AS TB2
    ORDER BY (day::INTEGER) ASC
    ),
    TotalMatches AS (
SELECT ms.TeamID, ms.Name, array_to_string(ARRAY_AGG(ms.Status), '') AS TotalStatuses
         FROM MatchStatuses ms
         GROUP BY ms.TeamID, ms.Name
    ),
    HouseMatches AS (
SELECT msh.TeamID, msh.Name, array_to_string(ARRAY_AGG(msh.Status), '') AS HouseStatuses
         FROM MatchStatusesHouse msh
         GROUP BY msh.TeamID, msh.Name
    ),
    TransferMatches AS (
SELECT mst.TeamID, mst.Name, array_to_string(ARRAY_AGG(mst.Status), '') AS TransferStatuses
    FROM MatchStatusesTransfer mst
    GROUP BY mst.TeamID, mst.Name
    )
SELECT ttm.TeamID AS id, ttm.Name AS name, COALESCE(ttm.TotalStatuses, '') AS TotalStatuses, COALESCE(hm.HouseStatuses, '') AS HouseStatuses, COALESCE(tsm.TransferStatuses, '') AS TransferStatuses
FROM TotalMatches ttm FULL OUTER JOIN HouseMatches hm ON ttm.TeamID = hm.TeamID
    FULL OUTER JOIN TransferMatches tsm ON ttm.TeamID = tsm.TeamID;";

$result2 = pg_query($conn, $query2);

$shapes = [];
while ($row = pg_fetch_assoc($result2)) {
    $shapes[] = [
        "id" => $row["id"],
        "TotalStatuses" => $row["totalstatuses"],
        "HouseStatuses" => $row["housestatuses"],
        "TransferStatuses" => $row["transferstatuses"],
    ];
}

$out["shapes"] = $shapes;

$json = json_encode($out);
header("Content-length: " . strlen($json));
echo $json;

pg_free_result($result1);
pg_free_result($result2);