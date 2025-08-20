<?php

/**
 * Ottiene i dettagli di una partita
 * Esempio
 * Input: /getMatch.php?id=3394116
 * Output: {"ID":"3394116","Name1":"Genoa","Name2":"Fiorentina","Score1":"1","Score2":"4","ID1":"11974","ID2":"3858","Timestamp":"2023-08-19 00:00:00+02","Postponed":null}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$matchID = pg_escape_literal($conn, $_GET["id"]); //Es 2022-2023

$query = "SELECT g.id, g.num_giornata_id AS Day, COALESCE(ss1.team_default_name, ts1.name) AS Name1,
       COALESCE(ss2.team_default_name, ts2.name) AS Name2,
       g.result_team_1 AS Score1, g.result_team_2 AS Score2, g.date AS Timestamp,
       g.squadra_1_id AS ID1, g.squadra_2_id AS ID2, ab.result AS Abnormal,
       g.postponed_to AS Postponed
FROM gare_gare g LEFT JOIN gare_resultabnormal ab ON g.result_abnormal_id = ab.id
     JOIN teams_squadre ts1 ON g.squadra_1_id = ts1.id
     JOIN teams_squadre ts2 ON g.squadra_2_id = ts2.id
     JOIN society_society ss1 ON ts1.society_id = ss1.id
     JOIN society_society ss2 ON ts2.society_id = ss2.id
WHERE g.id = $matchID;";

$result = pg_query($conn, $query);

$ret = [];

while ($row = pg_fetch_assoc($result)) {
    $ret = [
        "ID" => $row["id"],
        "Name1" => $row["name1"],
        "Name2" => $row["name2"],
        "Score1" => $row["score1"],
        "Score2" => $row["score2"],
        "ID1" => $row["id1"],
        "ID2" => $row["id2"],
        "Timestamp" => $row["timestamp"],
        "Postponed" => $row["postponed"]
    ];

    if (isset($row["abnormal"]))
        $ret["Abnormal"] = $row["abnormal"];
}

$json = json_encode($ret);

header("Content-length: " . strlen($json));

// Output the JSON.
echo $json;
pg_free_result($result);
