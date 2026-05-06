<?php
/**
 * PBN API Gateway
 * Forwards requests from the public site to the backend API.
 */

// Configuration
$BACKEND_URL = "https://api.primebusiness.network/api/v1";
$path = $_GET['path'] ?? 'industry-categories';

// Build the destination URL with query string if params exist
$params = $_GET;
unset($params['path']);
$queryString = http_build_query($params);
$url = "$BACKEND_URL/$path" . ($queryString ? "?$queryString" : ""); 

$ch = curl_init($url);

// Basic cURL settings
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 20);

// Forwarding headers
// Note: We don't need the 'Host' override since we're calling the domain directly
$headers = [
    'Content-Type: application/json',
    'Accept: application/json'
];

// If the client sent an Authorization header, forward it (for logged-in members)
if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
    $headers[] = 'Authorization: ' . $_SERVER['HTTP_AUTHORIZATION'];
}

curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

// Handle POST submissions (like Applications, Leads, RFPs)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents('php://input'));
}
// Handle PATCH requests (like status updates)
else if ($_SERVER['REQUEST_METHOD'] === 'PATCH') {
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
    curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents('php://input'));
}
// Handle DELETE requests
else if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
}

// Execute the request
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

// Handle connection errors
if (curl_errno($ch)) {
    http_response_code(502);
    header('Content-Type: application/json');
    echo json_encode([
        "status" => "error",
        "message" => "Gateway Connection Error: " . curl_error($ch)
    ]);
    exit;
}

curl_close($ch);

// Set the response status and headers
http_response_code($httpCode);
header('Content-Type: application/json');

// Clean up response: if backend returned a non-JSON error, wrap it
if ($httpCode >= 400 && (empty($response) || strpos($response, '{') !== 0)) {
    echo json_encode([
        "status" => "error",
        "message" => "Backend returned error $httpCode",
        "details" => strip_tags($response)
    ]);
} else {
    echo $response;
}
