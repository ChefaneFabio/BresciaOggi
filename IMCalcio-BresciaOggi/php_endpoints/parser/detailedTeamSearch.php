<?php
/**
 * Ricerca dettagliata di un team. Restitiusce diversi risultati con la similarità della ricerca.
 * NOTA: Usa l'estensione Trigram di PostGres che va abilitata con CREATE EXTENSION IF NOT EXISTS pg_trgm;
 * http://127.0.0.1:8000/parser/detailedTeamSearch.php?currentSeason=2023-2024&teamName=FORTE%20DEI%20MARMI%202015
 * {"teams":[{"teamID":"22284","societyID":"23360","societyName":"Forte dei Marmi","teamName":"Forte dei Marmi","similarity":"1.1609977756768401","exact":"0"},{"teamID":"3619","societyID":"6163","societyName":"Forte Dei Marmi 2015","teamName":"Forte Dei Marmi 2015","similarity":"1.8","exact":"-1"},{"teamID":"3942","societyID":"6163","societyName":"Forte Dei Marmi 2015","teamName":"Forte Dei Marmi 2015 Sq.B","similarity":"1.4871301508514136","exact":"-1"},{"teamID":"22284","societyID":"23360","societyName":"Forte dei Marmi","teamName":"Forte dei Marmi","similarity":"1.0448979981091562","exact":"-1"},{"teamID":"22284","societyID":"23360","societyName":"Forte dei Marmi","teamName":"Forte dei Marmi","similarity":"1.0448979981091562","exact":"-1"},{"teamID":"25904","societyID":"26726","societyName":"Forte dei  Marmi","teamName":"Forte dei  Marmi","similarity":"1.0448979981091562","exact":"-1"},{"teamID":"25904","societyID":"26726","societyName":"Forte dei  Marmi","teamName":"Forte dei  Marmi","similarity":"1.0448979981091562","exact":"-1"},{"teamID":"25904","societyID":"26726","societyName":"Forte dei  Marmi","teamName":"Forte dei  Marmi","similarity":"1.0448979981091562","exact":"-1"}]}
 */
$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

$season = pg_escape_literal($conn, strtolower($_GET["currentSeason"]));
$rawTeamName = strtolower($_GET["teamName"]);


$teamNameLike = pg_escape_literal($conn, "%" . $rawTeamName . "%");

//Cerca societa' in stagione precedente
$query1 = "SELECT DISTINCT gac.team_id, ts.society_id, ss.nome_societa AS society_name, COALESCE(ss.team_default_name, gac.team_name) AS team_name
    FROM gare_associacampionato gac JOIN teams_squadre ts ON gac.team_id = ts.id
         JOIN society_society ss ON ts.society_id = ss.id,
    gare_season gs
    WHERE gs.name = $season AND gac.season_id = gs.id-1 
      AND LOWER(ss.nome_societa) LIKE $teamNameLike LIMIT 1;";

$ret = [];

$result1 = pg_query($conn, $query1);

while ($row = pg_fetch_assoc($result1)) {
    $ret[] = [
        "teamID" => $row["team_id"],
        "societyID" => $row["society_id"],
        "societyName" => $row["society_name"],
        "teamName" => $row["team_name"],
        "similarity" => 10,
        "exact" => "1"
    ];
}


//Cerca squadre simili in stagione precedente, togliendo parole come calcio
$rawTeamNameFiltered = str_replace("calcio ", "", $rawTeamName);
$rawTeamNameFiltered = str_replace("a.s.d.", "", $rawTeamNameFiltered);
$rawTeamNameFiltered = str_replace("s.s.d.", "", $rawTeamNameFiltered);
$rawTeamNameFiltered = str_replace("s.r.l.", "", $rawTeamNameFiltered);
$rawTeamNameFiltered = str_replace("u.s.", "", $rawTeamNameFiltered);
$rawTeamNameFiltered = str_replace("a.s.", "", $rawTeamNameFiltered);
$rawTeamNameFiltered = str_replace("a.c.", "", $rawTeamNameFiltered);
$rawTeamNameFiltered = str_replace("f.c.", "", $rawTeamNameFiltered);
$rawTeamNameFiltered = str_replace("u.s.d.", "", $rawTeamNameFiltered);

$teamNameFiltered = pg_escape_literal($conn, $rawTeamNameFiltered);
$query2 = "SELECT DISTINCT gac.team_id, ts.society_id, ss.nome_societa AS society_name, 
                (similarity($teamNameFiltered, LOWER(COALESCE(ts.name, ss.team_default_name)))^2 + similarity($teamNameFiltered, LOWER(ss.nome_societa))^2) AS similarity, COALESCE(ts.name, ss.team_default_name) AS team_name
    FROM gare_associacampionato gac JOIN teams_squadre ts ON gac.team_id = ts.id
         JOIN society_society ss ON ts.society_id = ss.id,
    gare_season gs
      WHERE gs.name = $season AND gac.season_id = gs.id-1
      AND (similarity($teamNameFiltered, LOWER(COALESCE(ts.name, ss.team_default_name)))^2 + similarity($teamNameFiltered, LOWER(ss.nome_societa))^2) > 0.19
      ORDER BY (similarity($teamNameFiltered, LOWER(COALESCE(ts.name, ss.team_default_name)))^2 + similarity($teamNameFiltered, LOWER(ss.nome_societa))^2) DESC LIMIT 10;";

$result2 = pg_query($conn, $query2);

while ($row = pg_fetch_assoc($result2)) {
    $ret[] = [
        "teamID" => $row["team_id"],
        "societyID" => $row["society_id"],
        "societyName" => $row["society_name"],
        "teamName" => $row["team_name"],
        "similarity" => $row["similarity"],
        "exact" => "0"
    ];
}
//Cerca società simili come prima ma senza stagione
$query3 = "WITH rank AS (SELECT DISTINCT ts.id AS team_id, ts.society_id, ss.nome_societa AS society_name, 
                (similarity($teamNameFiltered, LOWER(COALESCE(ts.name, ss.team_default_name)))^2 + similarity($teamNameFiltered, LOWER(ss.nome_societa))^2)*.9 AS similarity, COALESCE(ts.name, ss.team_default_name) AS team_name,
                ROW_NUMBER() OVER (
                    PARTITION BY ss.id
                    ORDER BY gac.season_id DESC
                ) AS rn
    		FROM gare_associacampionato gac RIGHT JOIN teams_squadre ts ON gac.team_id = ts.id
         	JOIN society_society ss ON ts.society_id = ss.id
    		WHERE (similarity($teamNameFiltered, LOWER(COALESCE(ts.name, ss.team_default_name)))^2 + similarity($teamNameFiltered, LOWER(ss.nome_societa))^2)*.9 > 0.25
      		ORDER BY (similarity($teamNameFiltered, LOWER(COALESCE(ts.name, ss.team_default_name)))^2 + similarity($teamNameFiltered, LOWER(ss.nome_societa))^2)*.9 DESC LIMIT 10)
      SELECT team_id, society_id, society_name, similarity, team_name
      FROM rank WHERE rn <= 3;";

$result3 = pg_query($conn, $query3);

while ($row = pg_fetch_assoc($result3)) {
    $ret[] = [
        "teamID" => $row["team_id"],
        "societyID" => $row["society_id"],
        "societyName" => $row["society_name"],
        "teamName" => $row["team_name"],
        "similarity" => $row["similarity"],
        "exact" => "-1"
    ];
}

echo json_encode(["teams" => $ret]);
header("Content-type: application/json; charset=utf-8");

pg_free_result($result1);
pg_free_result($result2);
pg_free_result($result3);