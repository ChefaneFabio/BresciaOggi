<?php

/**
 * Endpoint to send a feedback to the server
 * feedback:
 * CREATE TABLE imcalcio.public.feedback(id SERIAL PRIMARY KEY, ip_address VARCHAR(32), ts TIMESTAMP NOT NULL,
 * mail VARCHAR(64) NOT NULL, message_type INTEGER NOT NULL, message TEXT NOT NULL);
 *
 * Richiesta tipo /sendFeedback.php
 * Dati POST: type = Problema / Suggerimento
 *            mail = mail del mittente
 *            message = contenuto del messaggio
 *
 * L'IP viene salvato per evitare spam: inserire la riga nella tabella solo se lo stesso IP non ha inviato un messaggio recentemente (es 1 minuto)
 */

$conn = pg_connect("host=localhost port=5432 dbname=imcalcio user=postgres password=admin");

$extendedMessageType = pg_escape_literal($conn, $_POST["type"]); //Problema / Suggerimento
$mail = pg_escape_literal($conn, $_POST["mail"]);
$message = pg_escape_literal($conn, $_POST["message"]);

const INTERVAL_MINUTES = 1;

function get_client_ip() {
    $ipaddress = '';
    if (getenv('HTTP_CLIENT_IP'))
        $ipaddress = getenv('HTTP_CLIENT_IP');
    else if(getenv('HTTP_X_FORWARDED_FOR'))
        $ipaddress = getenv('HTTP_X_FORWARDED_FOR');
    else if(getenv('HTTP_X_FORWARDED'))
        $ipaddress = getenv('HTTP_X_FORWARDED');
    else if(getenv('HTTP_FORWARDED_FOR'))
        $ipaddress = getenv('HTTP_FORWARDED_FOR');
    else if(getenv('HTTP_FORWARDED'))
        $ipaddress = getenv('HTTP_FORWARDED');
    else if(getenv('REMOTE_ADDR'))
        $ipaddress = getenv('REMOTE_ADDR');
    else
        $ipaddress = 'UNKNOWN';
    return $ipaddress;
}

$ip = pg_escape_literal($conn, get_client_ip());

$getLastPairQuery = "SELECT COUNT(*) AS count FROM feedback
    WHERE ip_address = $ip AND ts > CURRENT_TIMESTAMP - INTERVAL '" . INTERVAL_MINUTES . " minutes';";
$result = pg_query($conn, $getLastPairQuery);


while ($row = pg_fetch_assoc($result)) {
    if ($row["count"] > 0)
    {
        echo '{"status": "error", "error": "TOO_MANY_MESSAGES"}';
        return;
    }
}

pg_free_result($result);

if (strtolower($extendedMessageType) == "problema")
    $enumMessageType = 0;
else
    $enumMessageType = 1;

$enumMessageType = pg_escape_literal($conn, $enumMessageType);

$sendQuery = "INSERT INTO feedback (ip_address, ts, mail, message_type, message) VALUES ($ip, NOW(), $mail, $enumMessageType, $message)";
$result = pg_query($conn, $sendQuery);

echo '{"status": "success", "error": ""}';

header("Content-type: application/json; charset=utf-8");