<?php

/**
 * Utilizzato per aggiungere un record alla tabella gare_report (cronaca minuto per minuto)
 * NOTA: E' da assumere che il client abbia i cookies sessionid e csrftoken.
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$matchID = pg_escape_literal($conn, $_POST["matchID"]);
$minute = pg_escape_literal($conn, $_POST["minute"]);
$set = pg_escape_literal($conn, $_POST["set"]);
$content = pg_escape_literal($conn, $_POST["content"]);

$query = "INSERT INTO gare_report (game_id, minute, set, content) VALUES ($matchID, $minute, $set, $content);";

$res = pg_query($conn, $query);

echo "{\"status\":\"success\"}";