<?php

/**
 * Ottiene la formazione di una partita, gli allenatori, i goal di una partita e gli arbitri
 * Esempio in getFormation.txt
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$matchID = pg_escape_literal($conn, $_GET["matchID"]);

$query1 = "SELECT c1.id AS \"Coach1\", c1.last_name AS \"LastName1\", c1.first_name AS \"FirstName1\", 
       c2.id AS \"Coach2\", c2.last_name AS \"LastName2\", c2.first_name AS \"FirstName2\",
       m1.scheme AS \"Modulo1\", m2.scheme AS \"Modulo2\"
FROM gare_gare g LEFT JOIN players_coach c1 ON g.coach_1_id = c1.id
                LEFT JOIN players_coach c2 ON g.coach_2_id = c2.id
                LEFT JOIN gare_gamescheme m1 ON m1.id = g.team_1_schema_id
                LEFT JOIN gare_gamescheme m2 ON m2.id = g.team_2_schema_id
WHERE g.id = $matchID";

$query3 = "SELECT DISTINCT gf.*, pp.last_name AS \"LastName\", pp.first_name AS \"FirstName\"
,gf2.min_exit AS \"MinutoEntrata\", gf2.tempo_uscita AS \"TempoEntrata\", gf.meta::json->'results'->>'amm' AS \"MonitionStatus\"
FROM gare_formation gf LEFT JOIN gare_formation gf2 ON (gf2.replacer_id = gf.player_id AND gf2.game_id = gf.game_id), players_player pp
WHERE gf.game_id = $matchID AND gf.player_id = pp.id;";

$query4 = "SELECT gg.player_id AS \"PlayerID\", gg.minute AS \"Minute\",
       gg.tempo AS \"Set\", gg.team_fav_id AS \"TeamFavID\", 'Goal' AS \"Type\"
FROM gare_goal gg
WHERE gg.game_id = $matchID
UNION 
SELECT gp.player_id AS \"PlayerID\", gp.min AS \"Minute\",
       gp.time AS \"Set\", gp.team_fav_id AS \"TeamFavID\", 'Penalty' AS \"Type\"
FROM gare_penalty gp
WHERE gp.game_id = $matchID;";

//Arbitri
$query5 = "SELECT
    g.referee_id AS \"ID1\",
    CONCAT(r1.last_name, ' ', r1.first_name) AS \"Name1\",
    g.referee_id AS \"ID2\",
    CONCAT(r2.last_name, ' ', r2.first_name) AS \"Name2\",
    g.referee_id AS \"ID3\",
    CONCAT(r3.last_name, ' ', r3.first_name) AS \"Name3\",
    g.referee_id AS \"ID4\",
    CONCAT(r4.last_name, ' ', r4.first_name) AS \"Name4\",
    g.referee_id AS \"ID5\",
    CONCAT(r5.last_name, ' ', r5.first_name) AS \"Name5\"
FROM
    gare_gare g
LEFT JOIN players_referee r1 ON g.referee_id = r1.id
LEFT JOIN players_referee r2 ON g.referee_id = r2.id
LEFT JOIN players_referee r3 ON g.referee_id = r3.id
LEFT JOIN players_referee r4 ON g.referee_id = r4.id
LEFT JOIN players_referee r5 ON g.referee_id = r5.id
WHERE
    g.id = $matchID;"; //TODO MODIFICARE QUANDO AGGIUNGONO GLI ALTRI ARBITRI

$result1 = pg_query($conn, $query1);
$result3 = pg_query($conn, $query3);
$result4 = pg_query($conn, $query4);
$result5 = pg_query($conn, $query5);

$ret = [];

while ($row = pg_fetch_assoc($result1)) {
    $ret["Coach1"] = $row["Coach1"];
    $ret["LastName1"] = $row["LastName1"];
    $ret["FirstName1"] = $row["FirstName1"];
    $ret["Coach2"] = $row["Coach2"];
    $ret["LastName2"] = $row["LastName2"];
    $ret["FirstName2"] = $row["FirstName2"];
    $ret["Modulo1"] = $row["Modulo1"];
    $ret["Modulo2"] = $row["Modulo2"];
}

$ret["formations"] = [];
while ($row = pg_fetch_assoc($result3)) {
    $ret["formations"][] = [
        "FirstName" => $row["FirstName"],
        "LastName" => $row["LastName"],
        "playerID" => $row["player_id"],
        "number" => $row["number"],
        "entranceMinute" => $row["MinutoEntrata"],
        "entranceSet" => $row["TempoEntrata"],
        "exitMinute" => $row["min_exit"],
        "exitSet" => $row["tempo_uscita"],
        "minutesPlayed" => $row["minutes_played"],
        "substitutedWithID" => $row["replacer_id"],
        "substitutedNumber" => $row["replacer_number"],
        "monitionMinute" => $row["min_ammonizione"],
        "monitionSet" => $row["tempo_ammonizione"],
        "evictionMinute" => $row["min_espulsione"],
        "evictionSet" => $row["tempo_espulsione"],
        "monitionReason" => $row["motivo_ammonizione"],
        "substitutionReason" => $row["motivo_sostituzione"],
        "evictionReason" => $row["motivo_espulsione"],
        "teamID" => $row["team_id"],
        "monitionX" => $row["MonitionStatus"]
    ];
}

//p.player_id AS \"PlayerID\", gp.min AS \"Minute\",
//       gp.time AS \"Set\", gp.team_fav_id AS \"TeamFavID\", 'Penalty' AS \"Type\"
$ret["goals"] = [];
while ($row = pg_fetch_assoc($result4))
{
    $ret["goals"][] = [
      "PlayerID" => $row["PlayerID"],
      "Minute" => $row["Minute"],
      "Set" => $row["Set"],
      "TeamFavID" => $row["TeamFavID"],
      "Type" => $row["Type"]
    ];
}

while ($row = pg_fetch_assoc($result5))
{
    $ret["referees"] = [
      "ID1" => $row["ID1"],
      "ID2" => $row["ID2"],
      "ID3" => $row["ID3"],
      "ID4" => $row["ID4"],
      "ID5" => $row["ID5"],
      "Name1" => $row["Name1"],
      "Name2" => $row["Name2"],
      "Name3" => $row["Name3"],
      "Name4" => $row["Name4"],
      "Name5" => $row["Name5"]
    ];
}

//Build the JSON
$json = json_encode($ret);
header("Content-length: " . strlen($json));
echo $json;

pg_free_result($result1);
pg_free_result($result3);
pg_free_result($result4);
pg_free_result($result5);