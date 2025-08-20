<?php

/**
 * Cerca i campionati a partire dal nome (anche incompleto) e la stagione
 * Esempio
 * Input: /searchChampionships.php?champ=Serie%20D&season=2023-2024
 * Output: {"0":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"16043","groupName":"A","city":"Roma","category":"Nazionale"},"1":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"33819","groupName":"D","city":"Roma","category":"Nazionale"},"2":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"33820","groupName":"B","city":"Roma","category":"Nazionale"},"3":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"33821","groupName":"E","city":"Roma","category":"Nazionale"},"4":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"33822","groupName":"F","city":"Roma","category":"Nazionale"},"5":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"33823","groupName":"I","city":"Roma","category":"Nazionale"},"6":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"33826","groupName":"H","city":"Roma","category":"Nazionale"},"7":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"33829","groupName":"C","city":"Roma","category":"Nazionale"},"8":{"champID":"3863","champName":"Serie D","committee":"Lega Nazionale Dilettanti","groupID":"33830","groupName":"G","city":"Roma","category":"Nazionale"}}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$champ = pg_escape_literal($conn, "%" . $_GET["champ"] . "%"); //Es Mil
$season = pg_escape_literal($conn, $_GET["season"]); //Es 2022-2023

$query = "SELECT DISTINCT glc.id AS champID, glc.campionato_name AS champName, gco.id AS committee_id, gco.comitato_name AS committee, gco.area AS area,
    glg.id AS groupID, glg.girone_value AS groupName, gco.city AS city, length(glc.campionato_name) AS length
    FROM gare_listcampionati glc JOIN gare_associacampionato gac ON glc.id = gac.campionato_id
      JOIN gare_listgirone glg ON gac.girone_id = glg.id
      JOIN gare_listcomitati gco ON glc.comitato_id = gco.id
WHERE LOWER(glc.campionato_name) LIKE LOWER($champ) AND gco.area IS NOT NULL
AND gac.season_id = (SELECT id FROM gare_season WHERE name = $season)
AND EXISTS (
    SELECT 1 FROM gare_associacampionato gac2
    JOIN teams_squadre ts ON gac2.team_id = ts.id
    JOIN society_society ss ON ts.society_id = ss.id
    WHERE gac2.campionato_id = glc.id
    AND gac2.girone_id = glg.id
    AND gac2.season_id = (SELECT id FROM gare_season WHERE name = $season)
    AND ss.provincia_id = (SELECT id FROM society_province WHERE provincia = 'Brescia')
)
ORDER BY length(glc.campionato_name) LIMIT 100;";

$result = pg_query($conn, $query);

$areaMap = [
  "m" => "Estero", //Mondiale
  "c" => "Estero", //Continentale
  "e" => "Estero",
  "l" => "Provinciale", //Locale
  "n" => "Nazionale",
  "r" => "Regionale",
  "p" => "Provinciale"
];

$i = 0;
$ret = "{";
while ($row = pg_fetch_assoc($result)) {

    if ($i > 0)
        $ret = $ret . ",";

    $ret = $ret . "\"$i\"" . ":" . json_encode([
        "champID" => $row["champid"],
        "champName" => $row["champname"],
        "committeeName" => $row["committee"],
        "committeeID" => $row["committee_id"],
        "groupID" => $row["groupid"],
        "groupName" => $row["groupname"],
        "city" => $row["city"],
        "category" => $areaMap[$row["area"]]
    ]);
    $i = $i + 1;
}
$ret = $ret . "}";
header("Content-length: " . strlen($ret));

echo $ret;
pg_free_result($result);