<?php

/**
 * Cerca allenatori in base al nome (anche incompleto)
 * Esempio
 * Input: /searchCoaches.php?name=Allegri
 * Output: {"0":{"id":"239","firstName":"Massimiliano","lastName":"Allegri","championship":"Serie A","committee":"Lega Nazionale Professionisti","team":"Juventus Spa Sq.B","birthday":null,"season":"2023-2024"}}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$name = $_GET["name"]; //Like Mario Rossi or Rossi Mario or Rossi or Mario
function buildQuery($conn, $input) {
    $parts = explode(' ', $input);
    $whereClauses = [];

    foreach ($parts as $part) {
        $part = pg_escape_literal($conn, "%" . trim($part) . "%");
        $part = strtolower($part);
        if (!empty($part))  //For each part of the name, check both first_name and last_name
            $whereClauses[] = "(LOWER(pc.first_name) LIKE $part OR LOWER(pc.last_name) LIKE $part)";
    }

    $query = "SELECT DISTINCT pc.id AS coachID, pc.first_name, pc.last_name, gca.campionato_name, gco.comitato_name, ts.id AS team_id, COALESCE(gac.team_name, ts.name) AS team_name, pc.birthday, gs.name AS season, length(CONCAT(pc.first_name,pc.last_name)), gs.id AS seasonID
            FROM players_coach pc
            JOIN players_associacoach pa ON pc.id = pa.coach_id
            JOIN gare_listcampionati gca ON pa.campionato_id = gca.id
            JOIN gare_listcomitati gco ON gca.comitato_id = gco.id
            JOIN teams_squadre ts ON pa.team_id = ts.id
            JOIN gare_season gs ON pa.season_id = gs.id
            JOIN gare_associacampionato gac ON gca.id = gac.campionato_id AND gac.season_id = gs.id AND gac.team_id = ts.id
            WHERE " . implode(" OR ", $whereClauses) . " 
            AND gs.id >= ALL (
                SELECT pa.season_id
                FROM players_coach pc2 
                JOIN players_associacoach pa ON pc2.id = pa.coach_id                
                WHERE pc2.id = pc.id
            ) 
            AND (SELECT ss.provincia_id FROM society_society ss WHERE ss.id = ts.society_id) = (SELECT id FROM society_province WHERE provincia = 'Brescia')
            ORDER BY gs.id DESC, length(CONCAT(pc.first_name,pc.last_name))
            LIMIT 100";

    return $query;
}

$query = buildQuery($conn, $name);
$result = pg_query($conn, $query);

$i = 0;
$ret = "{";
while ($row = pg_fetch_assoc($result)) {

    if ($i > 0)
        $ret = $ret . ",";

    $ret = $ret . "\"$i\"" . ":" . json_encode([
        "id" => $row["coachid"],
        "firstName" => $row["first_name"],
        "lastName" => $row["last_name"],
        "championship" => $row["campionato_name"],
        "committee" => $row["comitato_name"],
        "teamID" => $row["team_id"],
        "teamName" => $row["team_name"],
        "birthday" => $row["birthday"],
        "season" => $row["season"],
    ]);
    $i = $i + 1;
}
$ret = $ret . "}";
header("Content-length: " . strlen($ret));

echo $ret;
pg_free_result($result);