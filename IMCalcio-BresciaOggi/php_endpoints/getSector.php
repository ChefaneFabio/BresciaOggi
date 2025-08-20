<?php

/**
 * Ottiene un comitato a partire da stagione, regione, categoria
 * Esempio
 * Input: /getSector.php?season=2023-2024&region=Lombardia&category=Regionale
 * Output: {"sectorNames" : ["Lombardia"]}
 */

$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

$season = pg_escape_literal($conn, $_GET["season"]); //Es 2022-2023
$region = pg_escape_literal($conn, $_GET["region"]); //Es Lombardia
$category = pg_escape_literal($conn, $_GET["category"]); //Es Regionale

$area = "'" . strtolower(substr($category, 1,1)) . "'"; //Le aree sono p, r, n, c, ...

$query = "SELECT DISTINCT lc.id, lc.comitato_name FROM gare_listcomitati lc, champs_champ cc, gare_season s, society_regione r
    WHERE cc.comitato_id = lc.id AND cc.season_id = s.id AND r.id = lc.region_id
    AND lc.area = $area AND s.name LIKE $season
    AND (r.name = $region OR EXISTS (
        SELECT 1 FROM gare_associacampionato gac
        JOIN gare_listcampionati glc ON gac.campionato_id = glc.id
        JOIN teams_squadre ts ON gac.team_id = ts.id
        JOIN society_society ss ON ts.society_id = ss.id
        WHERE glc.comitato_id = lc.id
        AND gac.season_id = s.id
        AND ss.provincia_id = (SELECT id FROM society_province WHERE provincia = 'Brescia')
    ));";

$result = pg_query($conn, $query);

$ret = [];
while ($row = pg_fetch_assoc($result)) {
    $ret[] = [
        "comitatoID" => $row["id"],
        "comitatoName" => $row["comitato_name"]
    ];
}

$json = json_encode(["sectorNames" => $ret]);

header("Content-type: application/json; charset=utf-8");

echo $json;

pg_free_result($result);