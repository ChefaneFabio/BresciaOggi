<?php

/**
 * Cerca squadre in base al nome (anche incompleto) e alla stagione
 * Esempio
 * Input: /searchTeams.php?team=Juventus&season=2023-2024
 * {"0":{"teamID":"14240","teamName":"Juventus","championship":"Serie A","championshipID":"21509","locality":"Torino","groupID":"33363","group":"UNICO","season":"24","societyID":"13784"},"1":{"teamID":"1060","teamName":"Alma Fano","championship":"Serie D","championshipID":"3863","locality":"Fano","groupID":"33822","group":"F","season":"24","societyID":"9484"},"2":{"teamID":"10173","teamName":"Juventus Domo","championship":"Promozione","championshipID":"970","locality":"Domodossola","groupID":"3220","group":"A","season":"24","societyID":"15109"},"3":{"teamID":"10763","teamName":"Juventus Next Gen","championship":"Serie C","championshipID":"18854","locality":"Torino","groupID":"33832","group":"B","season":"24","societyID":"13784"},"4":{"teamID":"23959","teamName":"Juventus A. Conte","championship":"Seconda Categoria","championshipID":"21929","locality":"Melilli","groupID":"33786","group":"B","season":"24","societyID":"24854"},"5":{"teamID":"1060","teamName":"Alma Juventus Fano","championship":"Serie Impossible","championshipID":"21956","locality":"Fano","groupID":"33827","group":"Impossible","season":"24","societyID":"9484"},"6":{"teamID":"9434","teamName":"Juventus Club Parma","championship":"Prima Categoria","championshipID":"870","locality":"Parma","groupID":"2938","group":"B","season":"24","societyID":"8977"},"7":{"teamID":"33286","teamName":"Juventus Club Parma","championship":"Under 15","championshipID":"21945","locality":"Parma","groupID":"33805","group":"A","season":"24","societyID":"33352"},"8":{"teamID":"4647","teamName":"Juventus Gemonio F.C.","championship":"Serie Inventata","championshipID":"21958","locality":"Casciago","groupID":"33831","group":"Inventata anche questa","season":"24","societyID":"14819"},"9":{"teamID":"11659","teamName":"Almajuventus Fano1906 Srl","championship":"Serie J","championshipID":"21957","locality":"Fano","groupID":"33828","group":"J","season":"24","societyID":"9485"}}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$team = pg_escape_literal($conn, "%" . $_GET["team"] . "%"); //Es Mil
$season = pg_escape_literal($conn, $_GET["season"]); //Es 2022-2023

$query = "SELECT DISTINCT gac.team_id AS TeamID, COALESCE(gac.team_name, sq.name) AS TeamName, ch.id AS ChampionshipID, ch.campionato_name AS Championship,
                soc.localita AS Localita, gir.id AS GironeID, gir.girone_value AS Girone, length(COALESCE(gac.team_name, sq.name)), gac.season_id AS season,
                soc.id AS SocietyID
FROM gare_associacampionato gac, teams_squadre sq, gare_listcampionati ch, gare_listgirone gir, society_society soc, gare_season sea
WHERE sq.id = gac.team_id AND gac.girone_id = gir.id AND gac.society_id = soc.id AND gac.season_id = sea.id
AND ch.id = gac.campionato_id AND sea.name LIKE $season
AND soc.provincia_id = (SELECT id FROM society_province WHERE provincia = 'Brescia')
AND LOWER(sq.name) LIKE LOWER($team) ORDER BY length(COALESCE(gac.team_name, sq.name))
LIMIT 100;";

$result = pg_query($conn, $query);

$i = 0;
$ret = "{";
while ($row = pg_fetch_assoc($result)) {

    if ($i > 0)
        $ret = $ret . ",";

    $ret = $ret . "\"$i\"" . ":" . json_encode([
        "teamID" => $row["teamid"],
        "teamName" => $row["teamname"],
        "championship" => $row["championship"],
        "championshipID" => $row["championshipid"],
        "locality" => $row["localita"],
        "groupID" => $row["gironeid"],
        "group" => $row["girone"],
        "season" => $row["season"],
        "societyID" => $row["societyid"],
    ]);
    $i = $i + 1;
}
$ret = $ret . "}";
header("Content-length: " . strlen($ret));

echo $ret;
pg_free_result($result);