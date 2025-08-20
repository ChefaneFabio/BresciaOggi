<?php

/**
 * Cerca giocatori in base al nome (anche incompleto, può essere nome, cognome, nome cognome, cognome nome...) e alla stagione
 * Esempio
 * Input: http://127.0.0.1:8000/searchPlayers.php?name=Calabria&season=2023-2024
 * Output: {"0":{"playerID":"1393825","matricola":null,"firstName":"Davide","lastName":"Calabria","teamID":"5422","teamName":"Milan Spa","champID":"21509","champName":"Serie A"}}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$name = trim($_GET["name"]); //Es Mario Rossi
$season = pg_escape_literal($conn, $_GET["season"]); //Es 2023-2024

$parts = explode(" ", $name);

// Create SQL conditions for each part
$conditions = [];
foreach ($parts as $part)
{
    $part = pg_escape_literal($conn, "%" . trim(strtolower($part)) . "%");
    if (!empty($part))
        $conditions[] = "(LOWER(pp.first_name) LIKE $part OR LOWER(pp.last_name) LIKE $part)";
}

$completeCondition = implode(" AND ", $conditions); //Concat

$query = "SELECT pp.id AS playerID, pp.matricola AS Matricola, pp.first_name AS FirstName, pp.last_name AS LastName,
       tt.name AS TeamName, tt.id AS TeamID, pt.campionato_id AS ChampID, glc.campionato_name AS ChampName
FROM players_player pp JOIN players_associaplayer pt ON pp.id = pt.player_id
                       JOIN teams_squadre tt ON pt.team_id = tt.id
                       JOIN gare_listcampionati glc ON pt.campionato_id = glc.id
WHERE pt.campionato_id IS NOT NULL AND $completeCondition
AND pt.season_id = (SELECT id FROM gare_season gs WHERE gs.name = $season)
AND (SELECT ss.provincia_id FROM society_society ss WHERE ss.id = tt.society_id) = (SELECT id FROM society_province WHERE provincia = 'Brescia')
ORDER BY length(CONCAT(pp.first_name,pp.last_name)) ASC, pt.campionato_id DESC LIMIT 100;";

$result = pg_query($conn, $query);

$i = 0;
$ret = "{";
while ($row = pg_fetch_assoc($result)) {

    if ($i > 0)
        $ret = $ret . ",";

    $ret = $ret . "\"$i\"" . ":" . json_encode([
        "playerID" => $row["playerid"],
        "matricola" => $row["matricola"],
        "firstName" => $row["firstname"],
        "lastName" => $row["lastname"],
        "teamID" => $row["teamid"],
        "teamName" => $row["teamname"],
        "champID" => $row["champid"],
        "champName" => $row["champname"],
    ]);
    $i = $i + 1;
}
$ret = $ret . "}";
header("Content-length: " . strlen($ret));

echo $ret;
pg_free_result($result);