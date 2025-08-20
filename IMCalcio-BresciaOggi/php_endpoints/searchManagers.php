<?php

/**
 * Cerca dirigenti in base al nome (anche incompleto)
 * Per l'esempio guardare searchCoaches.php in quanto il formato è lo stesso
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$name = $_GET["name"]; //Like Mario Rossi or Rossi Mario or Rossi or Mario
function buildQuery($conn, $input) {
    $parts = explode(' ', $input);
    $whereClauses = [];

    foreach ($parts as $part) {
        $part = pg_escape_literal($conn, "%" . trim($part) . "%");
        if (!empty($part))  //For each part of the name, check both first_name and last_name
            $whereClauses[] = "(LOWER(pf.first_name) LIKE $part OR LOWER(pf.last_name) LIKE $part)";
    }

    $query = "SELECT DISTINCT pf.id AS managerID, pf.first_name, pf.last_name, gca.campionato_name, gco.comitato_name, ts.id AS team_id, COALESCE(gac.team_name, ts.name) AS team_name, pf.birthday, gs.name AS season, length(CONCAT(pf.first_name,pf.last_name)), gs.id AS seasonID
            FROM players_footballmanager pf
            LEFT JOIN players_associadirigente pa ON pf.id = pa.football_manager_id
            LEFT JOIN gare_listcampionati gca ON pa.champ_id = gca.id
            JOIN gare_listcomitati gco ON gca.comitato_id = gco.id
            LEFT JOIN teams_squadre ts ON pa.team_id = ts.id
            JOIN gare_season gs ON pa.season_id = gs.id
            JOIN gare_associacampionato gac ON gca.id = gac.campionato_id AND gs.id = gac.season_id AND gac.team_id = ts.id
            WHERE pa.role_id = (SELECT id FROM players_role role WHERE role.name = 'Dirigente')
            AND " . implode(" OR ", $whereClauses) . "
            AND gs.id >= ALL (
                SELECT pa.season_id
                FROM players_footballmanager pf2 
                JOIN players_associadirigente pa ON pf2.id = pa.football_manager_id               
                WHERE pf2.id = pf.id
            )
            AND (SELECT ss.provincia_id FROM society_society ss WHERE ss.id = ts.society_id) = (SELECT id FROM society_province WHERE provincia = 'Brescia')
            ORDER BY gs.id DESC, length(CONCAT(pf.first_name,pf.last_name))
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
            "id" => $row["managerid"],
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