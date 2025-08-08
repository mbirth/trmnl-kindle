<?php

$image_uri = '/trmnl';
$image_files = ["output1-8bit.png", "output2-8bit.png"];
$interval = 30;

// dump headers (contains e.g. display size)
$input_headers = getallheaders();
file_put_contents("headers.txt", print_r($input_headers, true));

// log battery capacity over time
if (array_key_exists("battery-voltage", $input_headers)) {
    $batt = $input_headers["battery-voltage"];
    file_put_contents("battery-log.csv", date("Y-m-d H:i:s") . "," . $batt . PHP_EOL, FILE_APPEND);
}

$stamp = time();
$num_options = count($image_files);
$image_idx = intdiv($stamp % ($num_options * $interval), $interval);
$image = $image_files[$image_idx];

header("Content-Type: application/json");
header("Cache-Control: no-store, no-cache, must-revalidate");

echo json_encode([
    "image_url" => 'http' . (array_key_exists('HTTPS', $_SERVER)?'s':'') . '://' . $_SERVER['SERVER_NAME'] . ':' . $_SERVER['SERVER_PORT'] . $image_uri . '/' . $image,
    "refresh_rate" => $interval
], JSON_UNESCAPED_SLASHES);
