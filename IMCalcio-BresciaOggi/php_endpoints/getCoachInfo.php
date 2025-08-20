<?php

/**
 * Ottiene le informazioni e statistiche di un allenatore
 * Esempio
 * Input: /getCoachInfo.php?id=239
 * Output: {"info":{"firstName":"Massimiliano","lastName":"Allegri","birthday":null,"city":null,"age":null},"teams":[{"season":"2022-2023","societyID":"13784","societyName":"Juventus Spa","championshipID":"21509","groupID":"33363","groupName":"UNICO","championshipName":"Serie A","teamID":"10763","teamName":"Juventus","from":null,"to":null,"attendances":"38"},{"season":"2023-2024","societyID":"13784","societyName":"Juventus Spa","championshipID":"21509","groupID":"33363","groupName":"UNICO","championshipName":"Serie A","teamID":"14240","teamName":"Juventus","from":null,"to":null,"attendances":"14"}]}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$coachID = pg_escape_literal($conn, $_GET["id"]);

$queryInfo = "SELECT co.first_name, co.last_name, co.birthday, co.city, DATE_PART('year', AGE(NOW(), co.birthday)) AS years
FROM players_coach co
WHERE co.id = $coachID;";

$queryTeams = "WITH Attendances1 AS (
  SELECT g.squadra_1_id AS teamID, g.season_id AS seasonID, g.girone_id AS groupID, COUNT(*) AS attendances
      FROM gare_gare g
      WHERE g.coach_1_id = $coachID
  GROUP BY g.squadra_1_id, g.season_id, g.girone_id
),
Attendances2 AS (
    SELECT g.squadra_2_id AS teamID, g.season_id AS seasonID, g.girone_id AS groupID, COUNT(*) AS attendances
    FROM gare_gare g
    WHERE g.coach_2_id = $coachID
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
SELECT sea.name AS season, pa.society_id, so.nome_societa, pa.campionato_id, gca.campionato_name, pa.team_id, COALESCE(gac.team_name, ts.name) AS team_name,
 pa.da, pa.a, COALESCE(at.attendances, 0) AS attendances, at.groupID, gir.girone_value
FROM players_coach co JOIN players_associacoach pa on co.id = pa.coach_id
    JOIN society_society so ON pa.society_id = so.id
    JOIN teams_squadre ts ON pa.team_id = ts.id
    JOIN gare_listcampionati gca ON pa.campionato_id = gca.id
    JOIN gare_season sea ON pa.season_id = sea.id
    LEFT JOIN Attendances at ON at.teamID = pa.team_id AND at.seasonID = pa.season_id
    JOIN gare_listgirone gir ON gir.id = at.groupID
    JOIN gare_associacampionato gac ON gac.campionato_id = gca.id AND gac.team_id = ts.id
WHERE co.id = $coachID
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
        "championshipID" => $row["campionato_id"],
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