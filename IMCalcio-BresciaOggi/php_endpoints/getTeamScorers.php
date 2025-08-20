<?php

/**
 * Ottiene i marcatori di una squadra a partire dal campionato, dal girone e dalla stagione
 * Esempio
 * Input: /getTeamScorers.php?season=2023-2024&group=UNICO&teamID=5422&champID=21509
 * Output: {"players":[{"playerID":"1393831","firstName":"Christian","lastName":"Pulisic","goals":"5","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393830","firstName":"Olivier","lastName":"Giroud","goals":"4","autogoals":"0","penalties":"3","shirtNumber":null},{"playerID":"1393829","firstName":"Rafael","lastName":"Leao","goals":"3","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393824","firstName":"Fikayo","lastName":"Tomori","goals":"2","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393841","firstName":"Noah","lastName":"Okafor","goals":"2","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393828","firstName":"Ruben","lastName":"Loftus-Cheek","goals":"1","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393823","firstName":"Theo","lastName":"Hernandez","goals":"1","autogoals":"0","penalties":"1","shirtNumber":null},{"playerID":"1394517","firstName":"Luka","lastName":"Jovic","goals":"1","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393826","firstName":"Tijjani","lastName":"Reijnders","goals":"1","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393838","firstName":"Pierre","lastName":"Kalulu","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393839","firstName":"Simon","lastName":"Kjaer","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393840","firstName":"Antonio","lastName":"Mirante","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393842","firstName":"Tommaso","lastName":"Pobega","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393843","firstName":"Luka","lastName":"Romero","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393844","firstName":"Marco","lastName":"Sportiello","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393845","firstName":"Kevin","lastName":"Zeroli","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393846","firstName":"Ismael","lastName":"Bennacer","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393847","firstName":"Yunus","lastName":"Musah","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1394326","firstName":"Marco","lastName":"Pellegrino","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1394544","firstName":"Lapo","lastName":"Nava","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1394706","firstName":"Andrea","lastName":"Bartoccioni","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1394707","firstName":"Alejandro","lastName":"Jimenez","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1394708","firstName":"Chaka","lastName":"Traore","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1394732","firstName":"Jan-Carlo","lastName":"Simic","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393822","firstName":"Mike","lastName":"Maignan","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1394774","firstName":"Francesco","lastName":"Camarda","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393825","firstName":"Davide","lastName":"Calabria","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393827","firstName":"Rade","lastName":"Krunic","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393832","firstName":"Malick","lastName":"Thiaw","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393833","firstName":"Yacine","lastName":"Adli","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393834","firstName":"Davide","lastName":"Bartesaghi","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393835","firstName":"Samuel","lastName":"Chukwueze","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393836","firstName":"Lorenzo","lastName":"Colombo","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null},{"playerID":"1393837","firstName":"Alessandro","lastName":"Florenzi","goals":"0","autogoals":"0","penalties":"0","shirtNumber":null}]}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$teamID = pg_escape_literal($conn, $_GET["teamID"]);
$champID = pg_escape_literal($conn, $_GET["champID"]);
$group = pg_escape_literal($conn, $_GET["group"]);
$season = pg_escape_literal($conn, $_GET["season"]);

$query = "WITH PlayerInfo AS (
    SELECT pp.id AS PlayerID, pp.first_name AS FirstName, pp.last_name AS LastName, pa.number AS ShirtNumber
    FROM players_associaplayer pa
             JOIN players_player pp ON pa.player_id = pp.id
    WHERE pa.team_id = $teamID AND pa.season_id = (SELECT id FROM gare_season WHERE name = $season)
      AND pa.campionato_id = $champID
),
GareSelected AS (
    SELECT g.id AS id
         FROM gare_gare g
                  JOIN gare_season s ON g.season_id = s.id
                  JOIN gare_listgirone gi ON g.girone_id = gi.id
         WHERE g.campionato_id = $champID
           AND s.name = $season
           AND gi.girone_value = $group
           AND (g.result IS NOT NULL OR g.result_abnormal_id IS NOT NULL)
),
GoalStats AS (
     SELECT gl.player_id AS PlayerID,
            SUM(CASE WHEN gl.team_fav_id = $teamID THEN 1 ELSE 0 END) AS Goals,
            SUM(CASE WHEN gl.team_fav_id = $teamID THEN 0 ELSE 1 END) AS AutoGoals
     FROM gare_goal gl
     WHERE gl.game_id IN (SELECT id FROM GareSelected)
       AND gl.player_id IS NOT NULL
     GROUP BY gl.player_id
),
 PenaltiesStats AS (
         SELECT gp.player_id AS PlayerID,
                COUNT(gp.goal) AS Penalties
         FROM gare_penalty gp
         WHERE gp.game_id IN (SELECT id FROM GareSelected)
            AND gp.player_id IS NOT NULL
         GROUP BY gp.player_id
     )
SELECT pi.PlayerID AS ID, pi.FirstName, pi.LastName, COALESCE(gs.Goals, 0) AS Goals,
       COALESCE(gs.AutoGoals, 0) AS AutoGoals, COALESCE(ps.Penalties, 0) AS Penalties, pi.ShirtNumber
FROM PlayerInfo pi
         LEFT JOIN GoalStats gs ON pi.PlayerID = gs.PlayerID
         LEFT JOIN PenaltiesStats ps ON pi.PlayerID = ps.playerID ORDER BY Goals DESC";

$result = pg_query($conn, $query);

$players = [];
while ($row = pg_fetch_assoc($result)) {
    $player = [
        "playerID" => $row["id"],
        "firstName" => $row["firstname"],
        "lastName" => $row["lastname"],
        "goals" => $row["goals"],
        "autogoals" => $row["autogoals"],
        "penalties" => $row["penalties"],
        "shirtNumber" => $row["shirtnumber"]
        //TODO ASSISTS
    ];
    $players[] = $player;
}

$ret = ["players" => $players];

$json = json_encode($ret);
header("Content-length: " . strlen($json));
echo $json;
pg_free_result($result);