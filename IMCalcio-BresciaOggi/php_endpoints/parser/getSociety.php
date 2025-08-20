<?php

/**
 * Ottiene nome della squadra, nome della società, ID della società a partire dall'ID della squadra.
 * getSociety.php?teamID=5422
 * {"teamName":"Milan","societyName":"Milan SPA A.C.","societyID":"6994"}
 */

$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

$teamID = pg_escape_literal($conn, $_GET["teamID"]);

$query = "SELECT COALESCE(ss.team_default_name, ts.name) AS team_name, ss.nome_societa AS society_name, ss.id AS society_id
    FROM teams_squadre ts JOIN society_society ss ON ts.society_id = ss.id
    WHERE ts.id = $teamID
    LIMIT 1";

$result = pg_query($conn, $query);

$ret = [];

while ($row = pg_fetch_assoc($result)) {
    $ret = [
        "teamName" => $row["team_name"],
        "societyName" => $row["society_name"],
        "societyID" => $row["society_id"]
    ];
}

echo json_encode($ret);
header("Content-type: application/json; charset=utf-8");

pg_free_result($result);