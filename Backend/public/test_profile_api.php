<?php
$userId = 8;
$url = "http://10.241.250.3/thesisflutter/Backend/public/api_profile.php";

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "X-USER-ID: $userId",
    "Accept: application/json"
]);

$response = curl_exec($ch);
curl_close($ch);

echo $response;
