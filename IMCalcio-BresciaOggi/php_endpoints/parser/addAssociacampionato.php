<?php

$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

$champsID = pg_escape_literal($conn, $_GET["champsID"]);
$teamID = pg_escape_literal($conn, $_POST["team_pk"]);
$season = pg_escape_literal($conn, $_GET["season"]);

//TODO csrfmiddlewaretoken

$query = "
WITH Champ AS (
    SELECT campionato_id, girone_id FROM champs_champ WHERE id = $champsID
),
teamNumber AS (
    SELECT MAX(ga.team_number) AS tn
    FROM gare_associacampionato ga, Champ ch
    WHERE ga.season_id = (SELECT id FROM gare_season WHERE name = $season)
    AND ga.campionato_id = ch.campionato_id AND ga.girone_id = ch.girone_id
)
INSERT INTO gare_associacampionato (created, modified, active, team_number, team_name, situation, penalita, penalita_tot, campionato_id, society_id, team_id, meta, girone_id, season_id, hour, withdrawn)
 SELECT NOW(), NOW(), true, teamNumber.tn, (SELECT name FROM teams_squadre WHERE id = $teamID), 'reg', 0, 0, Champ.campionato_id, (SELECT society_id FROM teams_squadre WHERE id = $teamID), $teamID,
 '[]', Champ.girone_id, (SELECT id FROM gare_season WHERE name = $season), '10:00:00', false
 FROM teamNumber, Champ;";

$result = pg_query($conn, $query);

echo "OK";
header("Content-type: application/json; charset=utf-8");

pg_free_result($result);