<?php

/**
 * Ottiene le informazioni di un giocatore, con le statistiche dato l'ID, la stagione e il campionato
 * Esempio
 * Input: /getPlayerInfo.php?id=1393825&champID=21509&season=2023-2024
 * Output: [{"firstName":"Davide","lastName":"Calabria","sex":null,"birthday":null,"age":null,"city":"Mariano Comense","attendancesHolder":"21","attendancesReserve":"4","totalAttendancesHolder":"21","totalAttendancesReserve":"4","weight":"75","height":"177","role":"d","goals":"0","totalGoals":"0","groupID":"33363","groupName":"UNICO","shirtNumber":"-","feet":"-","monitions":"3","evictions":"1","minutes":"1389","totalMonitions":"3","totalEvictions":"1","totalMinutes":"1389"}]
 */

//Modificato il valore 11 con match_holders di gare_listcampionati + aggiunte le statistiche totali

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$playerID = pg_escape_literal($conn, $_GET["id"]); //Player ID
$champID = pg_escape_literal($conn, $_GET["champID"]); //Championship ID
$season = pg_escape_literal($conn, $_GET["season"]); //2023-2024

$query = "WITH Group_ AS (
    SELECT glg.id AS id, glg.girone_value AS name, COALESCE(glc.match_holders,11) AS holders
    FROM gare_listgirone glg JOIN gare_associacampionato ga ON glg.id = ga.girone_id
        JOIN players_associaplayer pa ON pa.team_id = ga.team_id JOIN gare_listcampionati glc ON glc.id = $champID
    WHERE pa.player_id = $playerID AND ga.season_id = (SELECT id FROM gare_season WHERE name = $season)
    AND ga.campionato_id = $champID
),
Goals AS (
    SELECT COUNT(*) AS goals
FROM gare_goal gg
         JOIN gare_gare ga ON gg.game_id = ga.id
         JOIN gare_season gs ON ga.season_id = gs.id
         JOIN players_associaplayer pa ON gg.player_id = pa.player_id, Group_
WHERE gg.player_id = $playerID AND ga.campionato_id = $champID AND ga.girone_id = Group_.id
  AND gs.name = $season
  AND pa.team_id = gg.team_fav_id
),
TotalGoals AS (
    SELECT COUNT(*) AS goals
FROM gare_goal gg
         JOIN gare_gare ga ON gg.game_id = ga.id
         JOIN gare_season gs ON ga.season_id = gs.id
         JOIN players_associaplayer pa ON gg.player_id = pa.player_id
WHERE gg.player_id = $playerID
  AND pa.team_id = gg.team_fav_id
),
Penalties AS (
    SELECT COUNT(*) AS penalties
FROM gare_penalty gp
         JOIN gare_gare ga ON gp.game_id = ga.id
         JOIN gare_season gs ON ga.season_id = gs.id
         JOIN players_associaplayer pa ON gp.player_id = pa.player_id, Group_
WHERE gp.player_id = $playerID AND ga.campionato_id = $champID AND ga.girone_id = Group_.id
  AND gs.name = $season
),
TotalPenalties AS (
    SELECT COUNT(*) AS penalties
FROM gare_penalty gp
         JOIN gare_gare ga ON gp.game_id = ga.id
         JOIN gare_season gs ON ga.season_id = gs.id
         JOIN players_associaplayer pa ON gp.player_id = pa.player_id
WHERE gp.player_id = $playerID
),
AttendancesHolder AS (
    SELECT COUNT(*) AS attendances
    FROM gare_gare gg JOIN gare_formation gf ON gg.id = gf.game_id, Group_
    WHERE gf.player_id = $playerID AND gf.number <= Group_.holders --TITOLARE
    AND gg.campionato_id = $champID AND gg.girone_id = Group_.id
    AND season_id = (SELECT id FROM gare_season WHERE name = $season)
),
TotalAttendancesHolder AS (
    SELECT COUNT(*) AS attendances
    FROM gare_gare gg JOIN gare_formation gf ON gg.id = gf.game_id JOIN gare_listgirone glg ON gg.girone_id = glg.id
        JOIN gare_listcampionati glc ON gg.campionato_id = glc.id
    WHERE gf.player_id = $playerID AND gf.number <= COALESCE(glc.match_holders,11) --TITOLARE
),
AttendancesReserve AS (
    SELECT COUNT(*) AS attendances
    FROM gare_gare gg JOIN gare_formation gf ON gg.id = gf.game_id, Group_
    WHERE gf.player_id = $playerID AND gf.number > Group_.holders --RISERVA
    AND gg.campionato_id = $champID AND gg.girone_id = Group_.id
    AND season_id = (SELECT id FROM gare_season WHERE name = $season)
),
TotalAttendancesReserve AS (
    SELECT COUNT(*) AS attendances
    FROM gare_gare gg JOIN gare_formation gf ON gg.id = gf.game_id JOIN gare_listgirone glg ON gg.girone_id = glg.id
        JOIN gare_listcampionati glc ON gg.campionato_id = glc.id
    WHERE gf.player_id = $playerID AND gf.number > COALESCE(glc.match_holders,11) --RISERVA
),
MatchDuration AS (
    SELECT COALESCE(gl.match_duration, 90) AS duration FROM gare_listcampionati gl WHERE gl.id = $champID
),
Stats AS (
    SELECT SUM(CASE WHEN fo.meta::json->'results'->>'amm' IS NOT NULL THEN 1 ELSE 0 END) AS Monitions, 
          SUM(CASE WHEN (fo.tempo_espulsione IS NOT NULL AND fo.tempo_espulsione > 0) THEN 1 ELSE 0 END) AS Evictions,
          SUM(CASE
            WHEN (fo.number <= Group_.holders AND (fo.min_exit IS NULL AND fo.min_espulsione IS NULL)) THEN d.duration
            WHEN (fo.number <= Group_.holders AND (fo.min_exit IS NOT NULL OR fo.min_espulsione IS NOT NULL)) THEN COALESCE(fo.min_exit, fo.min_espulsione)
            WHEN (fo.number > Group_.holders AND fo.min_enter IS NULL) THEN 0
            WHEN (fo.number > Group_.holders AND fo.min_enter IS NOT NULL AND (fo.min_exit IS NULL AND fo.min_espulsione IS NULL)) THEN d.duration - fo.min_enter
            ELSE fo.min_exit - COALESCE(fo.min_exit, fo.min_espulsione) 
            END) AS Minutes
    FROM gare_gare g, gare_formation fo, Group_, MatchDuration d
    WHERE g.girone_id = Group_.id AND (g.result IS NOT NULL OR g.result_abnormal_id IS NOT NULL)
    AND fo.game_id = g.id AND g.campionato_id = $champID
    AND g.season_id = (SELECT id FROM gare_season WHERE name = $season) AND fo.player_id = $playerID),
TotalStats AS (
    SELECT SUM(CASE WHEN fo.meta::json->'results'->>'amm' IS NOT NULL THEN 1 ELSE 0 END) AS Monitions,
      SUM(CASE WHEN (fo.tempo_espulsione IS NOT NULL AND fo.tempo_espulsione > 0) THEN 1 ELSE 0 END) AS Evictions,
      SUM(CASE
        WHEN (fo.number <= COALESCE(glc.match_holders, 11) AND (fo.min_exit IS NULL AND fo.min_espulsione IS NULL)) THEN COALESCE(glc.match_duration, 90)
        WHEN (fo.number <= COALESCE(glc.match_holders, 11) AND (fo.min_exit IS NOT NULL OR fo.min_espulsione IS NOT NULL)) THEN COALESCE(fo.min_exit, fo.min_espulsione)
        WHEN (fo.number > COALESCE(glc.match_holders, 11) AND fo.min_enter IS NULL) THEN 0
        WHEN (fo.number > COALESCE(glc.match_holders, 11) AND fo.min_enter IS NOT NULL AND (fo.min_exit IS NULL AND fo.min_espulsione IS NULL)) THEN COALESCE(glc.match_duration, 90) - fo.min_enter
        ELSE fo.min_exit - COALESCE(fo.min_exit, fo.min_espulsione) 
        END) AS Minutes
    FROM gare_gare g JOIN gare_listcampionati glc ON g.campionato_id = glc.id,
         gare_formation fo
    WHERE (g.result IS NOT NULL OR g.result_abnormal_id IS NOT NULL)
    AND fo.game_id = g.id AND fo.player_id = $playerID)
SELECT pp.first_name, pp.last_name, pp.sex, pp.birthday, DATE_PART('YEAR', (AGE(pp.birthday))) AS age, pp.city, pp.matricola,
  pp.weight, pp.height, pp.role, sr.name AS region, g.goals + p.penalties AS goals, group_.id AS groupID, group_.name AS groupName,
  '-' AS shirtNumber, '-' AS feet, ah.attendances AS attendancesHolder, as_.attendances AS attendancesReserve, 
  Stats.Monitions, Stats.Evictions, Stats.Minutes,
   tg.goals + tp.penalties AS totalGoals, tah.attendances AS totalAttendancesHolder, tar.attendances AS totalAttendancesReserve, 
   ts.Monitions AS totalMonitions, ts.Evictions AS totalEvictions, ts.Minutes AS totalMinutes
    FROM players_player pp
        LEFT JOIN society_province sp ON pp.province_id = sp.id
        LEFT JOIN society_regione sr ON sp.region_id = sr.id,
        Goals g, Penalties p, Group_ group_, AttendancesHolder ah, AttendancesReserve as_, Stats,
         TotalGoals tg, TotalPenalties tp, TotalAttendancesHolder tah, TotalAttendancesReserve tar, TotalStats ts
    WHERE pp.id = $playerID;";

$result = pg_query($conn, $query);

$ret = [];
while ($row = pg_fetch_assoc($result)) {
    $ret = [
        "firstName" => $row["first_name"],
        "lastName" => $row["last_name"],
        "sex" => $row["sex"],
        "birthday" => $row["birthday"],
        "age" => $row["age"],
        "city" => $row["city"],
        "attendancesHolder" => $row["attendancesholder"],
        "attendancesReserve" => $row["attendancesreserve"],
		"totalAttendancesHolder" => $row["totalattendancesholder"],
		"totalAttendancesReserve" => $row["totalattendancesreserve"],
        "weight" => $row["weight"],
        "height" => $row["height"],
        "role" => $row["role"],
        "goals" => $row["goals"],
		"totalGoals" => $row["totalgoals"],
        "groupID" => $row["groupid"],
        "groupName" => $row["groupname"],
        "shirtNumber" => $row["shirtnumber"],
        "feet" => $row["feet"],
        "monitions" => $row["monitions"],
        "evictions" => $row["evictions"],
        "minutes" => $row["minutes"],
		"totalMonitions" => $row["totalmonitions"],
		"totalEvictions" => $row["totalevictions"],
		"totalMinutes" => $row["totalminutes"]
    ];
}

$json = "[" . json_encode($ret) . "]";

header("Content-length: " . strlen($json));

echo $json;
pg_free_result($result);