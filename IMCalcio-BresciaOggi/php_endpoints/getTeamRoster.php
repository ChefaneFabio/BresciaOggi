<?php

/**
 * Ottiene la rosa di una squadra dato il campionato, il girone e la stagione
 * Esempio
 * Input: /getTeamRoster.php?season=2023-2024&group=UNICO&teamID=5422&champID=21509
 * Output: {"players":[{"playerID":"1393822","firstName":"Mike","lastName":"Maignan","age":null,"height":null,"role":null,"monitions":"1","evictions":"1","shirtNumber":null},{"playerID":"1393823","firstName":"Theo","lastName":"Hernandez","age":null,"height":null,"role":null,"monitions":"6","evictions":"0","shirtNumber":null},{"playerID":"1393824","firstName":"Fikayo","lastName":"Tomori","age":null,"height":null,"role":null,"monitions":"3","evictions":"1","shirtNumber":null},{"playerID":"1393825","firstName":"Davide","lastName":"Calabria","age":"27 years 1 mon 24 days","height":"177","role":"d","monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393826","firstName":"Tijjani","lastName":"Reijnders","age":null,"height":null,"role":null,"monitions":"1","evictions":"0","shirtNumber":null},{"playerID":"1393827","firstName":"Rade","lastName":"Krunic","age":null,"height":null,"role":null,"monitions":"3","evictions":"0","shirtNumber":null},{"playerID":"1393828","firstName":"Ruben","lastName":"Loftus-Cheek","age":null,"height":null,"role":null,"monitions":"2","evictions":"0","shirtNumber":null},{"playerID":"1393829","firstName":"Rafael","lastName":"Leao","age":null,"height":null,"role":null,"monitions":"1","evictions":"0","shirtNumber":null},{"playerID":"1393830","firstName":"Olivier","lastName":"Giroud","age":null,"height":null,"role":null,"monitions":"1","evictions":"1","shirtNumber":null},{"playerID":"1393831","firstName":"Christian","lastName":"Pulisic","age":null,"height":null,"role":null,"monitions":"1","evictions":"0","shirtNumber":null},{"playerID":"1393832","firstName":"Malick","lastName":"Thiaw","age":null,"height":null,"role":null,"monitions":"2","evictions":"1","shirtNumber":null},{"playerID":"1393833","firstName":"Yacine","lastName":"Adli","age":null,"height":null,"role":null,"monitions":"1","evictions":"0","shirtNumber":null},{"playerID":"1393834","firstName":"Davide","lastName":"Bartesaghi","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393835","firstName":"Samuel","lastName":"Chukwueze","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393836","firstName":"Lorenzo","lastName":"Colombo","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393837","firstName":"Alessandro","lastName":"Florenzi","age":null,"height":null,"role":null,"monitions":"3","evictions":"0","shirtNumber":null},{"playerID":"1393838","firstName":"Pierre","lastName":"Kalulu","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393839","firstName":"Simon","lastName":"Kjaer","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393840","firstName":"Antonio","lastName":"Mirante","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393841","firstName":"Noah","lastName":"Okafor","age":null,"height":null,"role":null,"monitions":"1","evictions":"0","shirtNumber":null},{"playerID":"1393842","firstName":"Tommaso","lastName":"Pobega","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393843","firstName":"Luka","lastName":"Romero","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393844","firstName":"Marco","lastName":"Sportiello","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393845","firstName":"Kevin","lastName":"Zeroli","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393846","firstName":"Ismael","lastName":"Bennacer","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1393847","firstName":"Yunus","lastName":"Musah","age":null,"height":null,"role":null,"monitions":"3","evictions":"0","shirtNumber":null},{"playerID":"1394326","firstName":"Marco","lastName":"Pellegrino","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1394517","firstName":"Luka","lastName":"Jovic","age":null,"height":null,"role":null,"monitions":"1","evictions":"0","shirtNumber":null},{"playerID":"1394544","firstName":"Lapo","lastName":"Nava","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1394706","firstName":"Andrea","lastName":"Bartoccioni","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1394707","firstName":"Alejandro","lastName":"Jimenez","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1394708","firstName":"Chaka","lastName":"Traore","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1394732","firstName":"Jan-Carlo","lastName":"Simic","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null},{"playerID":"1394774","firstName":"Francesco","lastName":"Camarda","age":null,"height":null,"role":null,"monitions":"0","evictions":"0","shirtNumber":null}],"coaches":[{"id":"304","firstName":"Stefano","lastName":"Pioli"}],"managers":[{"id":"249128","firstName":"Nome","lastName":"Cognome"}]}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$teamID = pg_escape_literal($conn, $_GET["teamID"]);
$champID = pg_escape_literal($conn, $_GET["champID"]);
$group = pg_escape_literal($conn, $_GET["group"]);
$season = pg_escape_literal($conn, $_GET["season"]);


$query = "WITH PlayerInfo AS (SELECT pp.id AS PlayerID, pp.first_name AS FirstName, pp.last_name AS LastName, pa.number AS ShirtNumber,
        AGE(CURRENT_DATE, pp.birthday) AS Age, pp.height AS Height, pp.role AS Role
        FROM players_associaplayer pa JOIN players_player pp ON pa.player_id = pp.id 
        WHERE pa.team_id = $teamID AND (SELECT id FROM gare_season WHERE name = $season) = pa.season_id
AND pa.campionato_id = $champID),
Stats AS (SELECT fo.player_id AS PlayerID, 
            SUM(CASE WHEN fo.meta::json->'results'->>'amm' IS NOT NULL THEN 1 ELSE 0 END) AS Monitions, 
            SUM(CASE WHEN (fo.tempo_espulsione IS NOT NULL AND fo.tempo_espulsione > 0) THEN 1 ELSE 0 END) AS Evictions
    FROM gare_gare g, gare_season s, gare_listgirone gi, gare_formation fo
    WHERE g.season_id = s.id AND g.girone_id = gi.id AND (g.result IS NOT NULL OR g.result_abnormal_id IS NOT NULL)
    AND fo.game_id = g.id AND g.campionato_id = $champID
    AND s.name = $season AND gi.girone_value = $group AND fo.team_id = $teamID
    GROUP BY fo.player_id)
SELECT Stats.PlayerID AS ID, * FROM PlayerInfo JOIN Stats ON Stats.PlayerID = PlayerInfo.PlayerID";

$result = pg_query($conn, $query);

$players = [];
while ($row = pg_fetch_assoc($result)) {
    $player = [
        "playerID" => $row["id"],
        "firstName" => $row["firstname"],
        "lastName" => $row["lastname"],
        "age" => $row["age"],
        "height" => $row["height"],
        "role" => $row["role"],
        "monitions" => $row["monitions"],
        "evictions" => $row["evictions"],
        "shirtNumber" => $row["shirtnumber"],
    ];
    $players[] = $player;
}


$query2 = "SELECT pc.id AS id, pc.last_name AS LastName, pc.first_name AS FirstName
FROM players_associacoach pa JOIN players_coach pc ON pa.coach_id = pc.id
WHERE pa.campionato_id = $champID AND pa.team_id = $teamID AND pa.season_id = (SELECT id FROM gare_season WHERE name = $season)";
$result2 = pg_query($conn, $query2);

$query3 = "SELECT pf.id AS id, pf.last_name AS LastName, pf.first_name AS FirstName
FROM players_associadirigente pa JOIN players_footballmanager pf ON pa.football_manager_id = pf.id
WHERE pa.champ_id = $champID AND pa.team_id = $teamID AND pa.season_id = (SELECT id FROM gare_season WHERE name = $season)";
$result3 = pg_query($conn, $query3);

$coaches = [];
while ($row = pg_fetch_assoc($result2)) {
    $coach = [
        "id" => $row["id"],
        "firstName" => $row["firstname"],
        "lastName" => $row["lastname"],
    ];
    $coaches[] = $coach;
}

$managers = [];
while ($row = pg_fetch_assoc($result3)) {
    $manager = [
        "id" => $row["id"],
        "firstName" => $row["firstname"],
        "lastName" => $row["lastname"],
    ];
    $managers[] = $manager;
}

$ret = ["players" => $players, "coaches" => $coaches, "managers" => $managers];

$json = json_encode($ret);
header("Content-length: " . strlen($json));
echo $json;
pg_free_result($result);