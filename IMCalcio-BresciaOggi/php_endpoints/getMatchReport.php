<?php

/**
 * Ottiene la cronaca di una partita + cronaca minuto per minuto
 * Esempio
 * Input: /getMatchReport.php?matchID=3324943
 * Output: {"reports":"{\"1668412683\": \"Partita con ribaltamenti di fronte quella disputata questa mattina al Bernabeu\", \"1668412701\": \"Tuttavia lo spazio di gioco \u00e8 stato....\"},
 * "minuteEvents":[{"minute":"1","set":"1","content":"Test"},{"minute":"1","set":"1","content":"Prova"}]"}
 *
 *
 **/

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$matchID = pg_escape_literal($conn, $_GET["matchID"]);

$query1 = "SELECT bc.meta::json->'comments' AS \"comments\" FROM bdcalcio_comment bc
WHERE bc.object = 'formation' AND bc.object_pk = $matchID";

$result1 = pg_query($conn, $query1);

$ret = [];

while ($row = pg_fetch_assoc($result1)) {
    $ret["reports"] = $row["comments"];
}

if (!isset($ret["reports"]))
    $ret["reports"] = "{}";

$ret["minute_events"] = [];

$query2 = "SELECT * FROM gare_report WHERE game_id = $matchID ORDER BY set ASC, minute ASC";
$result2 = pg_query($conn, $query2);
while ($row = pg_fetch_assoc($result2)) {
    $ret["minute_events"][] = [
        "minute" => $row["minute"],
        "set" => $row["set"],
        "content" => $row["content"]
    ];
}

//Build the JSON
$json = json_encode($ret);
header("Content-length: " . strlen($json));
echo $json;

pg_free_result($result1);