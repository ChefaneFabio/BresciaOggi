<?php

/**
 * Ottiene informazioni sul comitato, campionato e champs a partire dal nome del campionato e dal girone.
 * getChampInfo.php?name=ECCELLENZA&group=A&season=2023-2024
 * {"champs":[{"groupID":"34065","champsID":"18709","campionatoName":"Eccellenza","campionatoID":"22192","committeeID":"9","committeeName":"Friuli-Venezia Giulia LND","seasonID":"24"},{"groupID":"33934","champsID":"18721","campionatoName":"Eccellenza","campionatoID":"22061","committeeID":"12","committeeName":"Lombardia LND","seasonID":"24"},{"groupID":"33984","champsID":"18758","campionatoName":"Eccellenza","campionatoID":"22111","committeeID":"21","committeeName":"Veneto LND","seasonID":"24"},{"groupID":"33968","champsID":"18704","campionatoName":"Eccellenza","campionatoID":"22095","committeeID":"8","committeeName":"Emilia Romagna LND","seasonID":"24"},{"groupID":"34016","champsID":"18734","campionatoName":"Eccellenza","campionatoID":"22143","committeeID":"15","committeeName":"Piemonte LND","seasonID":"24"}]}
 */
$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

if (isset($_GET["champID"]))
    $champID = pg_escape_literal($conn, $_GET["champID"]);
else {
    $champName = pg_escape_literal($conn, strtolower($_GET["name"]));
    $groupName = pg_escape_literal($conn, strtolower($_GET["group"]));
    $season = pg_escape_literal($conn, $_GET["season"]);
}

$query = "SELECT cc.id AS champs_id, glc.id AS campionato_id, glc.campionato_name AS campionato_name, glg.id AS girone_id,
       glco.id AS comitato_id, glco.comitato_name AS comitato_name, cc.season_id AS season_id, glg.girone_value AS group_name
    FROM champs_champ cc JOIN public.gare_listcampionati glc ON cc.campionato_id = glc.id 
                         JOIN gare_listgirone glg ON cc.girone_id = glg.id
                         JOIN gare_listcomitati glco ON  glc.comitato_id = glco.id ";

if (!isset($champID))
{
    $query = $query . "WHERE cc.season_id = (SELECT id FROM gare_season WHERE name = $season)
    AND glc.id = glg.campionato_id AND LOWER(glc.campionato_name) = $champName AND LOWER(glg.girone_value) = $groupName";
}
else
{
    $query = $query . "WHERE cc.id = $champID";
}

$result = pg_query($conn, $query);

$ret = [];

while ($row = pg_fetch_assoc($result)) {
    $ret[] = [
        "groupID" => $row["girone_id"],
        "champsID" => $row["champs_id"],
        "campionatoName" => $row["campionato_name"],
        "campionatoID" => $row["campionato_id"],
        "committeeID" => $row["comitato_id"],
        "committeeName" => $row["comitato_name"],
        "groupName" => $row["group_name"],
        "seasonID" => $row["season_id"]
    ];
}

echo json_encode(["champs" => $ret]);
header("Content-type: application/json; charset=utf-8");

pg_free_result($result);