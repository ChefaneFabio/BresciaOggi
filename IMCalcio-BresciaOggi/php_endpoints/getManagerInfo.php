<?php

/**
 * Ottiene le informazioni e statistiche di un dirigente.
 * Per l'esempio, guardare getCoachInfo.php in quanto il formato è lo stesso di quello dell'allenatore.
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$managerID = pg_escape_literal($conn, $_GET["id"]);

$queryInfo = "SELECT pf.first_name, pf.last_name, pf.birthday, pf.city, DATE_PART('year', AGE(NOW(), pf.birthday)) AS years
FROM players_footballmanager pf
WHERE pf.id = $managerID;";

$queryTeams = "WITH Attendances1 AS (
    SELECT g.squadra_1_id AS teamID, g.season_id AS seasonID, g.girone_id AS groupID, COUNT(*) AS attendances
    FROM gare_gare g
    WHERE g.football_manager_1_id = 249128
    GROUP BY g.squadra_1_id, g.season_id, g.girone_id
),
Attendances2 AS (
     SELECT g.squadra_2_id AS teamID, g.season_id AS seasonID, g.girone_id AS groupID, COUNT(*) AS attendances
     FROM gare_gare g
     WHERE g.football_manager_2_id = 249128
     GROUP BY g.squadra_2_id, g.season_id, g.girone_id
),
Attendances AS (
    SELECT teamID, seasonID, groupID, SUM(attendances) AS attendances
    FROM (SELECT *
       FROM Attendances1 a1
       UNION ALL
       SELECT *
       FROM Attendances2 a2) AS totalAttendances
    GROUP BY teamID, seasonID, groupID
)
SELECT DISTINCT sea.name AS season, pa.society_id, so.nome_societa, pa.champ_id, gca.campionato_name, pa.team_id, COALESCE(gac.team_name, ts.name) AS team_name,
    NULL AS da, NULL AS a, COALESCE(at.attendances, 0) AS attendances, at.groupID, gir.girone_value
FROM players_footballmanager pf JOIN players_associadirigente pa ON pf.id = pa.football_manager_id
                      JOIN society_society so ON pa.society_id = so.id
                      JOIN teams_squadre ts ON pa.team_id = ts.id
                      JOIN gare_listcampionati gca ON pa.champ_id = gca.id
                      JOIN gare_season sea ON pa.season_id = sea.id
                      LEFT JOIN Attendances at ON at.teamID = pa.team_id AND at.seasonID = pa.season_id
                      JOIN gare_listgirone gir ON gir.id = at.groupID
                      JOIN gare_associacampionato gac ON gac.campionato_id = gca.id AND gac.team_id = ts.id
WHERE pf.id = $managerID
ORDER BY sea.name DESC;";

$resultInfo = pg_query($conn, $queryInfo);

$ret = [];

while ($row = pg_fetch_assoc($resultInfo)) {
    $ret["info"] = [
        "firstName" => $row["first_name"],
        "lastName" => $row["last_name"],
        "birthday" => $row["birthday"],
        "city" => $row["city"],
        "age" => $row["years"],
    ];
}

$resultTeams = pg_query($conn, $queryTeams);

$ret["teams"] = [];
while ($row = pg_fetch_assoc($resultTeams)) {
    $ret["teams"][] = [
        "season" => $row["season"],
        "societyID" => $row["society_id"],
        "societyName" => $row["nome_societa"],
        "championshipID" => $row["champ_id"],
        "groupID" => $row["groupid"],
        "groupName" => $row["girone_value"],
        "championshipName" => $row["campionato_name"],
        "teamID" => $row["team_id"],
        "teamName" => $row["team_name"],
        "from" => $row["da"],
        "to" => $row["a"],
        "attendances" => $row["attendances"],
    ];
}

$json = json_encode($ret);
header("Content-length: " . strlen($json));

echo $json;

pg_free_result($resultInfo);
pg_free_result($resultTeams);