<?php

/**
 * Ottiene la lista di stagioni disponibili
 * Esempio
 * Input: /getSeasons.php
 * Output: {"seasons" : ["2023-2024","2022-2023","2021-2022","2020-2021","2019-2020","2018-2019","2017-2018","2016-2017","2015-2016","2014-2015","2013-2014","2012-2013","2011-2012","2010-2011","2009-2010","2008-2009","2007-2008","2006-2007","2005-2006","2004-2005","2003-2004","2002-2003","2001-2002","2000-2001"]}
 */

$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

$query = "SELECT DISTINCT id, name, year_start, year_end, name as season
        FROM gare_season
        ORDER BY name DESC;";

$result = pg_query($conn, $query);


$ret = [];

while ($row = pg_fetch_assoc($result)) {
    $ret[$row["name"]] = [
        "id" => $row["id"],
        "year_start" => $row["year_start"],
        "year_end" => $row["year_end"]
    ];
}

echo json_encode($ret);
header("Content-type: application/json; charset=utf-8");

pg_free_result($result);