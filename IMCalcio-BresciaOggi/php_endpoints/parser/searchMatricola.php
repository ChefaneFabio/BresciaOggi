<?php

/**
 * 	Ottiene le squadre delle società associate ad una lista di matricole, separate da virgola.
 *	Input: searchMatricola.php?matricole=30770,24520
 *  Output: {"teams":[{"teamID":"5546","teamName":"Milan Spa Sq.B","societyName":"Milan SPA A.C.","societyID":"6994","matricola":"30770"},{"teamID":"5422","teamName":"Milan","societyName":"Milan SPA A.C.","societyID":"6994","matricola":"30770"},{"teamID":"14213","teamName":"Juventus Spa Sq.C","societyName":"Juventus SPA F.C.","societyID":"13784","matricola":"24520"},{"teamID":"14240","teamName":"Juventus Spa Sq.B","societyName":"Juventus SPA F.C.","societyID":"13784","matricola":"24520"},{"teamID":"10763","teamName":"Juventus","societyName":"Juventus SPA F.C.","societyID":"13784","matricola":"24520"},{"teamID":"14234","teamName":"Juventus Spa Sq.D","societyName":"Juventus SPA F.C.","societyID":"13784","matricola":"24520"}]}
 */

$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

$matricole = explode(",", $_GET["matricole"]);

$query = "SELECT ss.matricola AS matricola, ts.id AS team_id, COALESCE(ts.name, ss.team_default_name) AS team_name, ss.id AS society_id, ss.nome_societa AS society_name
FROM teams_squadre ts JOIN society_society ss ON ts.society_id = ss.id WHERE ";

for ($i = 0; $i < count($matricole); $i++)
{
    $query = $query . "ss.matricola = " . pg_escape_literal($conn, $matricole[$i]);
    if ($i < count($matricole) - 1)
        $query = $query . " OR ";
    else
        $query = $query . ";";
}

$result = pg_query($conn, $query);

$ret = [];

while ($row = pg_fetch_assoc($result)) {
    $ret[] = [
        "teamID" => $row["team_id"],
        "teamName" => $row["team_name"],
        "societyName" => $row["society_name"],
        "societyID" => $row["society_id"],
        "matricola" => $row["matricola"]
    ];
}

echo json_encode(["teams" => $ret]);
header("Content-type: application/json; charset=utf-8");

pg_free_result($result);