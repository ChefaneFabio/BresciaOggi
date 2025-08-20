<?php

/**
 * Ottiene le statistiche di un team dato il campionato, la stagione e il girone
 * Esempio
 * Input: /getTeamStats.php?teamID=5422&champ=Serie%20A&group=UNICO&season=2023-2024
 * Output: {"id":"5422","points":"29","gamesPlayed":"14","losses":"3","victories":"9","draws":"2","goalsAgainst":"15","goalsFor":"24","goalDifference":"9","penalty":"0","position":"4","goalsPenalty":"3","meanAge":"27.15","monitions":"30","evictions":"4"}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$teamID = pg_escape_literal($conn, $_GET["teamID"]);
$champ = pg_escape_literal($conn, $_GET["champ"]);
$group = pg_escape_literal($conn, $_GET["group"]);
$season = pg_escape_literal($conn, $_GET["season"]);

$query = "WITH GareSelected AS (
SELECT g.id AS ID, soc1.team_default_name AS Name1, soc2.team_default_name AS Name2,
           g.result_team_1 AS Score1, g.result_team_2 AS Score2, g.result_abnormal_id AS AbnormalResult,
           g.squadra_1_id AS ID1, g.squadra_2_id AS ID2, g.penalita_team_1 AS Penalty1, g.penalita_team_2 AS Penalty2, g.campionato_id AS ChampID
    FROM gare_gare g, gare_listcampionati ca, gare_season s, gare_listgirone gi, teams_squadre ts1,
         teams_squadre ts2, society_society soc1, society_society soc2
    WHERE g.campionato_id = ca.id AND g.season_id = s.id AND g.girone_id = gi.id
AND ts1.id = g.squadra_1_id AND ts2.id = g.squadra_2_id AND (g.result IS NOT NULL OR g.result_abnormal_id IS NOT NULL)
      AND ts1.society_id = soc1.id AND ts2.society_id = soc2.id
AND ca.campionato_name = $champ
AND s.name = $season AND gi.girone_value = $group
),
    HouseView AS (
SELECT ID1 AS id, Name1 AS Name, COUNT(*) AS GamesPlayed,
           SUM(CASE
                   WHEN AbnormalResult IS NULL AND (Score1 > Score2 OR Score2 IS NULL) THEN 1
                   WHEN AbnormalResult IS NOT NULL THEN abnormal.v1
                   ELSE 0
               END) AS Victories,
           SUM(CASE
                   WHEN AbnormalResult IS NULL AND (Score2 > Score1 OR Score1 IS NULL) THEN 1
                   WHEN AbnormalResult IS NOT NULL THEN abnormal.s1
                   ELSE 0
               END) AS Losses,
           SUM(CASE
                   WHEN AbnormalResult IS NULL AND Score1 = Score2 THEN 1
                   WHEN AbnormalResult IS NOT NULL THEN abnormal.p1
                   ELSE 0
               END) AS Draws,
           SUM(CASE
                   WHEN AbnormalResult IS NULL THEN Score1
                   ELSE abnormal.gf1
               END) AS GoalsFor,
           SUM(CASE
                   WHEN AbnormalResult IS NULL THEN Score2
                   ELSE abnormal.gf2
               END) AS GoalsAgainst,
           SUM(CASE
                   WHEN AbnormalResult IS NULL THEN Penalty1
                   ELSE abnormal.pu1
               END) AS Penalty
    FROM (GareSelected LEFT JOIN gare_resultabnormal AS abnormal ON abnormal.id = AbnormalResult)
    GROUP BY ID1, Name1
),
    TransferView AS (
SELECT ID2 AS id, Name2 AS Name, COUNT(*) AS GamesPlayed,
           SUM(CASE
                   WHEN AbnormalResult IS NULL AND (Score2 > Score1 OR Score1 IS NULL) THEN 1
                   WHEN AbnormalResult IS NOT NULL THEN abnormal.v2
                   ELSE 0
               END) AS Victories,
           SUM(CASE
                   WHEN AbnormalResult IS NULL AND (Score1 > Score2 OR Score2 IS NULL) THEN 1
                   WHEN AbnormalResult IS NOT NULL THEN abnormal.s2
                   ELSE 0
               END) AS Losses,
           SUM(CASE
                   WHEN AbnormalResult IS NULL AND Score1 = Score2 THEN 1
                   WHEN AbnormalResult IS NOT NULL THEN abnormal.p2
                   ELSE 0
               END) AS Draws,
           SUM(CASE
                   WHEN AbnormalResult IS NULL THEN Score2
                   ELSE abnormal.gf2
               END) AS GoalsFor,
           SUM(CASE
                   WHEN AbnormalResult IS NULL THEN Score1
                   ELSE abnormal.gf1
               END) AS GoalsAgainst,
           SUM(CASE
                   WHEN AbnormalResult IS NULL THEN Penalty2
                   ELSE abnormal.pu2
               END) AS Penalty
    FROM (GareSelected LEFT JOIN gare_resultabnormal AS abnormal ON abnormal.id = AbnormalResult)
    GROUP BY ID2, Name2
),
    TotalView AS (
SELECT id, Name, SUM(GamesPlayed) AS GamesPlayed, SUM(Losses) AS Losses, SUM(Victories) AS Victories, SUM(Draws) AS Draws,
               SUM(GoalsAgainst) AS GoalsAgainst, SUM(GoalsFor) AS GoalsFor, SUM(Penalty) AS Penalty
        FROM (SELECT * FROM HouseView UNION SELECT * FROM TransferView) AS TotalSet
        GROUP BY id, Name
),
    PenaltyGoals AS (
SELECT COUNT(DISTINCT p.game_id) AS goals_penalty
          FROM gare_penalty p JOIN GareSelected g ON p.game_id = g.ID
          WHERE p.team_fav_id = $teamID
),
    MeanAge AS (
SELECT ROUND(EXTRACT(epoch FROM AVG(AGE(CURRENT_DATE, pp.birthday))) / (365.25 * 24 * 60 * 60), 2) AS MeanAge
        FROM players_associaplayer pa JOIN players_player pp ON pa.player_id = pp.id
        WHERE pa.team_id = $teamID AND (SELECT id FROM gare_season WHERE name = $season) = pa.season_id
AND pa.campionato_id = (SELECT DISTINCT ChampID FROM GareSelected) AND pp.birthday IS NOT NULL
),
    Flags AS (
SELECT COUNT(CASE WHEN gf.meta::json->'results'->>'amm' IS NOT NULL THEN 1 END) AS Monitions,
           COUNT(CASE WHEN gf.tempo_espulsione IS NOT NULL AND gf.tempo_espulsione > 0 THEN 1 END) AS Evictions
    FROM gare_formation gf, GareSelected gs
    WHERE gf.game_id = gs.ID AND gf.team_id = 5422
),
    TotalInfos AS (
SELECT TotalView.id AS id, Name, (Victories * 3 + Draws - Penalty) AS Points, GamesPlayed, Losses, Victories, Draws,
               GoalsAgainst, GoalsFor, (GoalsFor - GoalsAgainst) AS GoalDifference, Penalty,
               1 + ROW_NUMBER() OVER (ORDER BY (Victories * 3 + Draws - Penalty) DESC, (GoalsFor - GoalsAgainst) DESC, GoalsFor DESC) AS Position,
               PenaltyGoals.goals_penalty AS GoalsPenalty, MeanAge, Monitions, Evictions
        FROM TotalView, PenaltyGoals, MeanAge, Flags
        ORDER BY Points DESC
)
    SELECT * FROM TotalInfos WHERE id = $teamID;";

$result = pg_query($conn, $query);
$ret = [];
while ($row = pg_fetch_assoc($result)) {
    $ret["id"] = $row["id"];
    $ret["points"] = $row["points"];
    $ret["gamesPlayed"] = $row["gamesplayed"];
    $ret["losses"] = $row["losses"];
    $ret["victories"] = $row["victories"];
    $ret["draws"] = $row["draws"];
    $ret["goalsAgainst"] = $row["goalsagainst"];
    $ret["goalsFor"] = $row["goalsfor"];
    $ret["goalDifference"] = $row["goaldifference"];
    $ret["penalty"] = $row["penalty"];
    $ret["position"] = $row["position"];
    $ret["goalsPenalty"] = $row["goalspenalty"];
    $ret["meanAge"] = $row["meanage"];
    $ret["monitions"] = $row["monitions"];
    $ret["evictions"] = $row["evictions"];
}

$json = json_encode($ret);
header("Content-length: " . strlen($json));

echo $json;
pg_free_result($result);