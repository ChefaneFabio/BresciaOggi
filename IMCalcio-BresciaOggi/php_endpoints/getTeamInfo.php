<?php

/**
 * Ottiene le informazioni di una squadra (e della societò), e le squadre associate alla società.
 * Esempio
 * Input: /getTeamInfo.php?teamID=5422&season=2023-2024
 * Output: {"matricola":"30770","societyName":"Milan Spa","teamDefaultName":"Milan","societyPrefix":"A.C.","year":"1899","committee":"Lombardia","address":"A.C. Milan S.P.A.","addressStreet":"Via Aldo Rossi,   8","locality":"Milano","province":"Milano","cap":"20149","stadiumName":"","stadiumAddress":"","stadiumLocality":"","stadiumProvince":"Altri","stadiumCAP":"0","telephone":"0282696921","email":"manola.pasini@acmilan.it","website":"www.acmilan.com","president":"Galliani Adriano","presidentTelephone":null,"secretaryTelephone":null,"color1":null,"color2":"Rosso-Nero","color3":"Rosso-Nero","societyTeams":[{"teamID":"5422","teamName":"Milan","champID":"21509","champName":"Serie A","groupID":"33363","groupName":"UNICO"}]}
 */
header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$teamID = pg_escape_literal($conn, $_GET["teamID"]);
$season = pg_escape_literal($conn, $_GET["season"]);

$query = "SELECT soc.matricola AS matricola, soc.nome_societa AS nome_societa, soc.team_default_name AS team_default_name,
       soc.sigla_societa AS sigla_societa, soc.anno AS anno, gl.comitato_name AS comitato_name, soc.indirizzo_sede AS indirizzo_sede,
       soc.indirizzo_sede_via AS indirizzo_sede_via, soc.localita AS localita, prov.provincia AS provincia,
       soc.cap AS cap, soc.nome_impianto AS nome_impianto, soc.indirizzo_impianto AS indirizzo_impianto, soc.loc_impianto AS loc_impianto,
       prov_imp.provincia AS provincia_impianto, soc.cap_impianto AS cap_impianto,
       soc.recap_telefonico AS recap_telefonico, soc.email AS email, soc.www AS www, soc.presidente AS presidente,
       soc.presidente_telefono AS presidente_telefono, soc.segretario_telefono AS segretario_telefono,
       soc.color_1 AS color_1, soc.color_2 AS color_2, soc.color_3 AS color_3
FROM (society_society soc LEFT JOIN public.gare_listcomitati gl on soc.comitato_regionale_id = gl.id)
    LEFT JOIN society_province prov ON soc.provincia_id = prov.id
    LEFT JOIN society_province prov_imp ON soc.prov_impianto_id = prov_imp.id
WHERE soc.id = (
    SELECT society_id FROM teams_squadre WHERE id = $teamID
);";

$result = pg_query($conn, $query);

$ret = [];
while ($row = pg_fetch_assoc($result)) {
    $ret["matricola"] = $row["matricola"];
    $ret["societyName"] = $row["nome_societa"];
    $ret["teamDefaultName"] = $row["team_default_name"];
    $ret["societyPrefix"] = $row["sigla_societa"];
    $ret["year"] = $row["anno"];
    $ret["committee"] = $row["comitato_name"];
    $ret["address"] = $row["indirizzo_sede"];
    $ret["addressStreet"] = $row["indirizzo_sede_via"];
    $ret["locality"] = $row["localita"];
    $ret["province"] = $row["provincia"];
    $ret["cap"] = $row["cap"];
    $ret["stadiumName"] = $row["nome_impianto"];
    $ret["stadiumAddress"] = $row["indirizzo_impianto"];
    $ret["stadiumLocality"] = $row["loc_impianto"];
    $ret["stadiumProvince"] = $row["provincia_impianto"];
    $ret["stadiumCAP"] = $row["cap_impianto"];
    $ret["telephone"] = $row["recap_telefonico"];
    $ret["email"] = $row["email"];
    $ret["website"] = $row["www"];
    $ret["president"] = $row["presidente"];
    $ret["presidentTelephone"] = $row["presidente_telefono"];
    $ret["secretaryTelephone"] = $row["segretario_telefono"];
    $ret["color1"] = $row["color_1"];
    $ret["color2"] = $row["color_2"];
    $ret["color3"] = $row["color_3"];
}

$query2 = "SELECT DISTINCT ga.team_id, ga.team_name, gl.id AS champ_id, gl.campionato_name, glg.id AS girone_id, glg.girone_value
FROM gare_associacampionato ga JOIN gare_listcampionati gl ON ga.campionato_id = gl.id
    JOIN gare_listgirone glg ON ga.girone_id = glg.id
WHERE ga.society_id = (SELECT society_id FROM teams_squadre WHERE id = $teamID) 
  AND ga.season_id = (SELECT id FROM gare_season WHERE name = $season); 
";

$societyTeams = [];
$result2 = pg_query($conn, $query2);
while ($row = pg_fetch_assoc($result2)) {
    $societyTeams[] = [
        "teamID" => $row["team_id"],
        "teamName" => $row["team_name"],
        "champID" => $row["champ_id"],
        "champName" => $row["campionato_name"],
        "groupID" => $row["girone_id"],
        "groupName" => $row["girone_value"],
    ];
}

$ret["societyTeams"] = $societyTeams;

$json = json_encode($ret);
header("Content-length: " . strlen($json));

echo $json;
pg_free_result($result);

//Società: 109+51, Codice: 346+84, Denominazione: 448+134, Località: 686+89, Indirizzo: 927+55, Telefono: 1167, Seleziona: 1329 + 60