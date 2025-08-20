<?php

/**
 * Ottiene info sulle partite live in questo momento.
 * Esempio
 * Input: /getLiveMatches.php
 * Output: {"liveMatches":[{"ID":"3394120","day":"1","Name1":"Lecce","Name2":"Lazio","ID1":"12486","ID2":"7147","Score1":"2","Score2":"1","Timestamp":"2024-01-30 16:50:00+01","Postponed":null,"ChampionshipName":"Serie A","ChampionshipID":"21509","CommitteeName":"Lega Nazionale Professionisti","CommitteeID":"30","GroupID":"33363","GroupName":"UNICO","NumDays":"38","AbnormalResult":null}]}
 */

header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$query = "
SELECT DISTINCT
    gg.id AS MatchID, gg.num_giornata_id AS Day,
    COALESCE(ss1.team_default_name, ts1.name) AS Name1, COALESCE(ss2.team_default_name, ts2.name) AS Name2,
    gg.result_team_1 AS Score1, gg.result_team_2 AS Score2, gg.date AS Timestamp, gg.postponed_to AS Postponed,
    gg.squadra_1_id AS ID1, gg.squadra_2_id AS ID2,
    glc.campionato_name AS CampionatoName, glc.id AS CampionatoID,
    gco.comitato_name AS ComitatoName, gco.id AS ComitatoID,
    glg.id AS GironeID, glg.girone_value AS GironeName,
    ab.result AS Abnormal,
    max_day.MaxDay
FROM
    gare_gare gg
        JOIN teams_squadre ts1 ON gg.squadra_1_id = ts1.id
        JOIN teams_squadre ts2 ON gg.squadra_2_id = ts2.id
        JOIN society_society ss1 ON ts1.society_id = ss1.id
        JOIN society_society ss2 ON ts2.society_id = ss2.id
        LEFT JOIN gare_resultabnormal ab ON gg.result_abnormal_id = ab.id
        JOIN gare_listcampionati glc ON gg.campionato_id = glc.id
        JOIN gare_listcomitati gco ON glc.comitato_id = gco.id
        JOIN champs_champ cc ON glc.id = cc.campionato_id
        JOIN gare_listgirone glg ON cc.girone_id = glg.id
        JOIN (SELECT g.campionato_id, MAX(CASE 
            WHEN trim(num_giornata_id) ~ '^\d+$' THEN CAST(num_giornata_id AS INTEGER) 
            ELSE NULL 
            END) AS MaxDay
              FROM gare_gare g 
              GROUP BY g.campionato_id) max_day ON max_day.campionato_id = cc.campionato_id
WHERE
    CURRENT_TIMESTAMP >= COALESCE(gg.postponed_to, gg.date) - interval '10 minutes'
    AND CURRENT_TIMESTAMP <= COALESCE(gg.postponed_to, gg.date) + (glc.match_duration + 10) * interval '1 minute';";

$ret = [];

$result = pg_query($conn, $query);

while ($row = pg_fetch_assoc($result)) {
    $ret[] = [
        "ID" => $row["matchid"],
        "day" => $row["day"],
        "Name1" => $row["name1"],
        "Name2" => $row["name2"],
        "ID1" => $row["id1"],
        "ID2" => $row["id2"],
        "Score1" => $row["score1"],
        "Score2" => $row["score2"],
        "Timestamp" => $row["timestamp"],
        "Postponed" => $row["postponed"],
        "ChampionshipName" => $row["campionatoname"],
        "ChampionshipID" => $row["campionatoid"],
        "CommitteeName" => $row["comitatoname"],
        "CommitteeID" => $row["comitatoid"],
        "GroupID" => $row["gironeid"],
        "GroupName" => $row["gironename"],
        "NumDays" => $row["maxday"],
        "AbnormalResult" => $row["abnormal"],
    ];
}

$json = json_encode(["liveMatches" => $ret]);
header("Content-length: " . strlen($json));

// Output the JSON.
echo $json;
pg_free_result($result);