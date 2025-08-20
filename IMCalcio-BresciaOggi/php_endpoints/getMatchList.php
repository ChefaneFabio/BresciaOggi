<?php

/**
 * Ottiene la lista di partite di un certo campionato
 * Esempio in getMatchList.txt
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$season = pg_escape_literal($conn, $_GET["season"]); //Es 2022-2023
$championshipID = pg_escape_literal($conn, $_GET["championship_id"]); //Es Eccellenza
$groupID = pg_escape_literal($conn, $_GET["group_id"]); //Es 'A'

if (isset($_GET["team"])) {
    $team = pg_escape_literal($conn, $_GET["team"]);
}

$query = "SELECT DISTINCT g.id AS \"ID\", g.num_giornata_id AS \"Day\", COALESCE(ga1.team_name, ts1.name, ss1.team_default_name) AS \"Name1\",
       COALESCE(ga2.team_name, ts2.name, ss2.team_default_name) AS \"Name2\",
       g.result_team_1 AS \"Score1\", g.result_team_2 AS \"Score2\", g.date AS \"Timestamp\",
       g.squadra_1_id AS \"ID1\", g.squadra_2_id AS \"ID2\", ab.result AS \"Abnormal\",
       g.postponed_to AS \"Postponed\", CAST (g.num_giornata_id AS INT)
FROM gare_gare g LEFT JOIN gare_resultabnormal ab ON g.result_abnormal_id = ab.id, gare_season s,
     teams_squadre ts1, teams_squadre ts2, society_society ss1, society_society ss2, 
     gare_associacampionato ga1, gare_associacampionato ga2
WHERE g.campionato_id = $championshipID AND g.season_id = s.id 
AND ts1.id = g.squadra_1_id AND ts2.id = g.squadra_2_id
AND ts1.society_id = ss1.id AND ts2.society_id = ss2.id
AND ga1.campionato_id = g.campionato_id AND ga2.campionato_id = g.campionato_id
AND ga1.team_id = g.squadra_1_id AND ga2.team_id = g.squadra_2_id
AND ga1.season_id = s.id AND ga2.season_id = s.id
AND s.name = $season AND g.girone_id = $groupID";

if (isset($team)) { //Filter by team
    $query = $query . "\nAND (g.squadra_1_id = $team OR g.squadra_2_id = $team)";
}

$query = $query . "\nORDER BY CAST (g.num_giornata_id AS INT), g.date;";

$result = pg_query($conn, $query);

$maxDayQuery = "SELECT MAX(g.num_giornata_id::INTEGER) AS MaxDay FROM gare_gare g, gare_listcampionati ca, gare_season s
             WHERE g.girone_id = $groupID AND g.season_id = s.id AND g.campionato_id = $championshipID
             AND s.name = $season";

$maxDayResult = pg_query($conn, $maxDayQuery);

while ($row = pg_fetch_assoc($maxDayResult)) {
    $maxDay = $row["maxday"];
}

$matchList = [];

//Build map
if (!isset($team)) { //Grouped matches: {"matches":[{"day":"1","matches":[{...}]}]};
    $groupedMatches = [];
    while ($row = pg_fetch_assoc($result)) {
        $day = $row["Day"];

        $match = [
            "ID" => $row["ID"],
            "Name1" => $row["Name1"],
            "Name2" => $row["Name2"],
            "Score1" => $row["Score1"],
            "Score2" => $row["Score2"],
            "ID1" => $row["ID1"],
            "ID2" => $row["ID2"],
            "Timestamp" => $row["Timestamp"],
            "Postponed" => $row["Postponed"]
        ];

        if (isset($row["Abnormal"])) {
            $match["Abnormal"] = $row["Abnormal"];
        }

        if (!isset($groupedMatches[$day])) {
            $groupedMatches[$day] = ["day" => $day, "matches" => []];
        }

        $groupedMatches[$day]["matches"][] = $match; //Append match
    }

    //Build the json
    $resultArray = ["numDays" => $maxDay, "matches" => array_values($groupedMatches)];
}
else //All matches in the same array
{
    while ($row = pg_fetch_assoc($result)) {
        $match = [
            "ID" => $row["ID"],
            "day" => $row["Day"],
            "Name1" => $row["Name1"],
            "Name2" => $row["Name2"],
            "Score1" => $row["Score1"],
            "Score2" => $row["Score2"],
            "ID1" => $row["ID1"],
            "ID2" => $row["ID2"],
            "Timestamp" => $row["Timestamp"],
        ];
        $matchList[] = $match;
    }

    $resultArray = ["numDays" => $maxDay, "matches" => $matchList];
}

$json = json_encode($resultArray);
header("Content-length: " . strlen($json));

// Output the JSON.
echo $json;
pg_free_result($result);