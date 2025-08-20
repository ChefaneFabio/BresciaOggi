<?php


/**
 Modfifica i parametri impianto di una società a partire dall'ID della squadra
 */
header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$teamID = pg_escape_literal($conn, $_GET["teamID"]);
$pitchID = pg_escape_literal($conn, $_GET["pitchID"]);
$pitchDenomination = pg_escape_literal($conn, $_GET["pitchDenomination"]);
$pitchLocality = pg_escape_literal($conn, $_GET["pitchLocality"]);
$pitchAddress = pg_escape_literal($conn, $_GET["pitchAddress"]);
$pitchTelephone = pg_escape_literal($conn, $_GET["pitchTelephone"]);

$query = "UPDATE society_society SET code_field = $pitchID, nome_impianto = $pitchDenomination, indirizzo_impianto = $pitchAddress,
									 loc_impianto = $pitchLocality, recap_telefonico = $pitchTelephone
		  WHERE id = (SELECT society_id FROM teams_squadre WHERE id = $teamID)";

$result = pg_query($conn, $query);

echo "OK";