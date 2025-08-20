<?php

/**
 * Prende l'username di Django, l'id del match e l'immagine e la salva.
 * Deve restituire un json con {"status": "success"} se il caricamento è riuscito.
 * Questo endpoint viene usato dagli utenti autenticati, quindi con cookies session_id e csrftoken.
 */
header("Content-type: application/json; charset=utf-8");

$conn = pg_connect("host=127.0.0.1 port=5432 dbname=imcalcio user=postgres password=admin");

$username = $_POST["username"];
$match_id = $_POST["match_id"];
$img_data = $_POST["img"];

//TODO SALVARE CHI HA CARICATO L'IMMAGINE IN UNA TABELLA + SALVARE L'IMMAGINE COME id.jpg

file_put_contents("immagine.jpg", $img_data);

echo json_encode(["status" => "success"]);