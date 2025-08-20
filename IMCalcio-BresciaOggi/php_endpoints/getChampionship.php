<?php

/** Ottiene i campionati a partire da stagione, regione, categoria e comitato
 *  Esempio:
 *  Input: getChampionship.php?season=2023-2024&region=&category=Nazionale&committee=Lega Nazionale Professionisti
 *  Output: {"championships":[
 * {"name": "Serie A", "id": "21509", "groups":[{"id":"33363","name":"UNICO"}]},
 * {"name": "Serie B", "id": "3323", "groups":[{"id":"33811","name":"Unico"}]}
 * ]}
 **/

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$season = pg_escape_literal($conn, $_GET["season"]); //Es 2022-2023

$region = pg_escape_literal($conn, $_GET["region"]); //Es Lombardia
$category = pg_escape_literal($conn, $_GET["category"]); //Es Regionale
$committeeID = pg_escape_literal($conn, $_GET["committeeID"]); //Es Lombardia SGS

$area = "'" . strtolower(substr($category, 1,1)) . "'"; //Le aree sono p, r, n, c, ...

$query = "SELECT cc.comitato_id AS ID, glc.id AS campionatoID, glc.campionato_name AS campionato, glg.girone_value AS girone, glg.id AS gironeID
FROM champs_champ cc JOIN gare_listcampionati glc ON cc.campionato_id = glc.id
    JOIN gare_listgirone glg ON cc.girone_id = glg.id
WHERE cc.season_id = (SELECT id FROM gare_season WHERE name = $season)
AND (cc.comitato_id = $committeeID OR EXISTS (
    SELECT 1 FROM gare_associacampionato gac
    JOIN teams_squadre ts ON gac.team_id = ts.id
    JOIN society_society ss ON ts.society_id = ss.id
    WHERE gac.campionato_id = glc.id
    AND gac.girone_id = glg.id
    AND gac.season_id = (SELECT id FROM gare_season WHERE name = $season)
    AND ss.provincia_id = (SELECT id FROM society_province WHERE provincia = 'Brescia')
))
ORDER BY glc.campionato_name, glg.girone_value ASC;";


$result = pg_query($conn, $query);

$championships = [];
$champIDs = [];

//Build championships map
while ($row = pg_fetch_assoc($result))
{
    $curr_champ = $row["campionato"];
    $curr_champID = $row["campionatoid"];
    $curr_group = $row["girone"];
    $curr_groupID = $row["gironeid"];
    $championships[$curr_champ][] = ["id" => $curr_groupID, "name" => $curr_group]; //Push $curr_group into the array
    $champIDs[$curr_champ] = $curr_champID;
}

echo "{\"championships\":[\n";
$first = true;
foreach ($championships as $champ => $group)
{
    if (!$first)
        echo ",\n";
    echo "{\"name\": \"$champ\", \"id\": \"$champIDs[$champ]\", \"groups\":";
    echo json_encode($group);
    echo "}";
    $first = false;
}
echo "\n]}";

header("Content-type: application/json; charset=utf-8");

pg_free_result($result);