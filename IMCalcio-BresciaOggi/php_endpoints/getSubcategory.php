<?php

/**
 * Ottiene le sottocategorie (comitati) a partire da stagione e categoria
 * Esempio
 * Input: /getSubcategory.php?season=2023-2024&category=Nazionale
 * Output: {"subcategories" : [
 *      {id: 32, name: "Lega Nazionale Dilettanti"},{id: 30, name: "Lega Nazionale Professionisti","Lega Pro"}
 * ]}
 */

$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

$season = pg_escape_literal($conn, $_GET["season"]); //Es 2022-2023
$category = pg_escape_literal($conn, $_GET["category"]); //Es Regionale

$area = "'" . strtolower(substr($category, 1,1)) . "'"; //Le aree sono p, r, n, c, ...

$query = "SELECT DISTINCT lc.id, lc.comitato_name FROM gare_listcomitati lc
    WHERE lc.area = $area AND lc.comitato_name <> 'Calcio Estero' --It does not make sense to have 'Calcio Estero' since is a Category
    AND (EXISTS (
        SELECT * FROM champs_champ cc, gare_season s
        WHERE s.name = $season AND s.id = cc.season_id AND cc.comitato_id = lc.id
    ) OR EXISTS (
        SELECT 1 FROM gare_associacampionato gac
        JOIN gare_listcampionati glc ON gac.campionato_id = glc.id
        JOIN teams_squadre ts ON gac.team_id = ts.id
        JOIN society_society ss ON ts.society_id = ss.id
        WHERE glc.comitato_id = lc.id
        AND gac.season_id = (SELECT id FROM gare_season WHERE name = $season)
        AND ss.provincia_id = (SELECT id FROM society_province WHERE provincia = 'Brescia')
    ));";

$result = pg_query($conn, $query);

$ret = [];
while ($row = pg_fetch_assoc($result)) {
   $ret[] = [
       "id" => $row["id"],
       "name" => $row["comitato_name"]
   ];
}

$json = json_encode(["subcategories" => $ret]);

echo $json;

header("Content-type: application/json; charset=utf-8");

pg_free_result($result);