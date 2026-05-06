<?php
/**
 * Prime Business Network — SMTP Mailer
 * Place this file in the same directory as index.html on your server.
 *
 * CONFIGURE THE SETTINGS BELOW BEFORE UPLOADING
 */

// ─────────────────────────────────────────────
//  SMTP CONFIGURATION  ← edit these values
// ─────────────────────────────────────────────
define('SMTP_HOST',     'mail.primebusiness.network'); // your mail server hostname
define('SMTP_PORT',     587);                          // 587 = TLS/STARTTLS, 465 = SSL, 25 = plain
define('SMTP_SECURE',   'tls');                        // 'tls', 'ssl', or '' for none
define('SMTP_USERNAME', 'info@primebusiness.network'); // your email login
define('SMTP_PASSWORD', '9;hyhrWOoXa{ud*?');        // your email password
define('MAIL_FROM',     'info@primebusiness.network'); // from address
define('MAIL_FROM_NAME','Prime Business Network');     // from name
define('MAIL_TO',       'info@primebusiness.network'); // where applications go
define('MAIL_TO_NAME',  'Prime Business Network');
// ─────────────────────────────────────────────

// Only allow POST requests from same origin
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: https://www.primebusiness.network');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// ── Read & sanitise input ──────────────────────────────────────────────────
$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

if (!$data) {
    // Fall back to form-encoded POST
    $data = $_POST;
}

function clean($val) {
    return htmlspecialchars(strip_tags(trim((string)$val)), ENT_QUOTES, 'UTF-8');
}

$name     = clean($data['name']     ?? '');
$business = clean($data['business'] ?? '');
$phone    = clean($data['phone']    ?? '');
$email    = clean($data['email']    ?? '');
$district = clean($data['district'] ?? '');
$category = clean($data['category'] ?? '');

// ── Validate ───────────────────────────────────────────────────────────────
$errors = [];
if (!$name)                          $errors[] = 'Name is required';
if (!$business)                      $errors[] = 'Business name is required';
if (!$phone)                         $errors[] = 'Phone number is required';
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = 'Valid email is required';
if (!$district)                      $errors[] = 'District is required';
if (!$category)                      $errors[] = 'Industry category is required';

if ($errors) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => implode(', ', $errors)]);
    exit;
}

// ── Build email content ────────────────────────────────────────────────────
$subject = "New Founding Seat Application – {$name} ({$category})";

$html_body = "
<!DOCTYPE html>
<html>
<head><meta charset='UTF-8'></head>
<body style='margin:0;padding:0;background:#f4f5f8;font-family:Arial,sans-serif;'>
  <table width='100%' cellpadding='0' cellspacing='0' style='background:#f4f5f8;padding:40px 0;'>
    <tr><td align='center'>
      <table width='560' cellpadding='0' cellspacing='0' style='background:#ffffff;border-radius:10px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.08);'>

        <!-- Header -->
        <tr>
          <td style='background:#080d24;padding:32px 40px;'>
            <p style='margin:0 0 6px;font-size:11px;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;color:#c9a84c;'>★ Founding Seat Application</p>
            <h1 style='margin:0;font-size:22px;font-weight:900;color:#ffffff;'>New Application Received</h1>
            <p style='margin:8px 0 0;font-size:13px;color:#7a85b0;'>Prime Business Network — Charter Member</p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style='padding:36px 40px;'>
            <table width='100%' cellpadding='0' cellspacing='0'>

              <tr>
                <td style='padding-bottom:20px;border-bottom:1px solid #eaedf5;'>
                  <p style='margin:0 0 4px;font-size:11px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#7a85b0;'>Full Name</p>
                  <p style='margin:0;font-size:16px;font-weight:600;color:#080d24;'>{$name}</p>
                </td>
              </tr>

              <tr>
                <td style='padding:20px 0;border-bottom:1px solid #eaedf5;'>
                  <p style='margin:0 0 4px;font-size:11px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#7a85b0;'>Business Name</p>
                  <p style='margin:0;font-size:16px;font-weight:600;color:#080d24;'>{$business}</p>
                </td>
              </tr>

              <tr>
                <td style='padding:20px 0;border-bottom:1px solid #eaedf5;'>
                  <table width='100%' cellpadding='0' cellspacing='0'>
                    <tr>
                      <td width='50%' style='padding-right:12px;'>
                        <p style='margin:0 0 4px;font-size:11px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#7a85b0;'>Contact Number</p>
                        <p style='margin:0;font-size:15px;font-weight:600;color:#080d24;'>{$phone}</p>
                      </td>
                      <td width='50%'>
                        <p style='margin:0 0 4px;font-size:11px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#7a85b0;'>Email Address</p>
                        <p style='margin:0;font-size:15px;font-weight:600;color:#080d24;'>{$email}</p>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <tr>
                <td style='padding:20px 0;border-bottom:1px solid #eaedf5;'>
                  <table width='100%' cellpadding='0' cellspacing='0'>
                    <tr>
                      <td width='50%' style='padding-right:12px;'>
                        <p style='margin:0 0 4px;font-size:11px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#7a85b0;'>District</p>
                        <p style='margin:0;font-size:15px;font-weight:600;color:#080d24;'>{$district}</p>
                      </td>
                      <td width='50%'>
                        <p style='margin:0 0 4px;font-size:11px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#7a85b0;'>Industry Category</p>
                        <p style='margin:0;font-size:15px;font-weight:600;color:#080d24;'>{$category}</p>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

            </table>

            <!-- Reply CTA -->
            <table width='100%' cellpadding='0' cellspacing='0' style='margin-top:28px;background:#f4f5f8;border-radius:8px;padding:20px 24px;'>
              <tr>
                <td>
                  <p style='margin:0 0 4px;font-size:12px;color:#7a85b0;'>Reply directly to the applicant:</p>
                  <a href='mailto:{$email}' style='font-size:15px;font-weight:700;color:#c9a84c;text-decoration:none;'>{$email}</a>
                  &nbsp;&nbsp;|&nbsp;&nbsp;
                  <a href='tel:{$phone}' style='font-size:15px;font-weight:700;color:#c9a84c;text-decoration:none;'>{$phone}</a>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style='background:#080d24;padding:20px 40px;text-align:center;'>
            <p style='margin:0;font-size:11px;color:#4a5580;'>Prime Business Network · primebusiness.network · This is an automated notification.</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
";

$text_body = "NEW FOUNDING SEAT APPLICATION\n\n"
    . "Name:     {$name}\n"
    . "Business: {$business}\n"
    . "Phone:    {$phone}\n"
    . "Email:    {$email}\n"
    . "District: {$district}\n"
    . "Category: {$category}\n\n"
    . "Reply to: {$email}";

// ── Send via SMTP ──────────────────────────────────────────────────────────
try {
    smtp_send(
        SMTP_HOST, SMTP_PORT, SMTP_SECURE,
        SMTP_USERNAME, SMTP_PASSWORD,
        MAIL_FROM, MAIL_FROM_NAME,
        MAIL_TO,   MAIL_TO_NAME,
        $subject, $html_body, $text_body,
        $email, $name   // Reply-To the applicant
    );

    echo json_encode(['success' => true, 'message' => 'Application sent successfully']);

} catch (Exception $e) {
    error_log('PBN Mailer Error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Mail error: ' . $e->getMessage()]);
}

// ── Pure-PHP SMTP function (no external libraries needed) ──────────────────
function smtp_send(
    $host, $port, $secure,
    $user, $pass,
    $from, $from_name,
    $to,   $to_name,
    $subject, $html, $text,
    $reply_to = '', $reply_to_name = ''
) {
    $context = stream_context_create();

    if ($secure === 'ssl') {
        $conn = stream_socket_client("ssl://{$host}:{$port}", $errno, $errstr, 15, STREAM_CLIENT_CONNECT, $context);
    } else {
        $conn = stream_socket_client("tcp://{$host}:{$port}", $errno, $errstr, 15, STREAM_CLIENT_CONNECT, $context);
    }

    if (!$conn) throw new Exception("Connection failed: {$errstr} ({$errno})");

    stream_set_timeout($conn, 15);

    function smtp_cmd($conn, $cmd, $expect) {
        if ($cmd) fwrite($conn, $cmd . "\r\n");
        $res = '';
        while ($line = fgets($conn, 512)) {
            $res .= $line;
            if (substr($line, 3, 1) === ' ') break;
        }
        $code = (int)substr($res, 0, 3);
        if ($code !== $expect) throw new Exception("SMTP error (expected {$expect}, got {$code}): {$res}");
        return $res;
    }

    smtp_cmd($conn, null, 220);                                    // greeting
    smtp_cmd($conn, "EHLO " . gethostname(), 250);                 // hello

    if ($secure === 'tls') {
        smtp_cmd($conn, "STARTTLS", 220);
        stream_socket_enable_crypto($conn, true, STREAM_CRYPTO_METHOD_TLS_CLIENT);
        smtp_cmd($conn, "EHLO " . gethostname(), 250);             // re-hello after TLS
    }

    smtp_cmd($conn, "AUTH LOGIN", 334);
    smtp_cmd($conn, base64_encode($user), 334);
    smtp_cmd($conn, base64_encode($pass), 235);                    // authenticated

    smtp_cmd($conn, "MAIL FROM:<{$from}>", 250);
    smtp_cmd($conn, "RCPT TO:<{$to}>", 250);
    smtp_cmd($conn, "DATA", 354);

    // Build MIME message
    $boundary  = '==PBN_' . md5(uniqid());
    $date      = date('r');
    $encoded_subject = '=?UTF-8?B?' . base64_encode($subject) . '?=';
    $from_fmt  = "=?UTF-8?B?" . base64_encode($from_name) . "?= <{$from}>";
    $to_fmt    = "=?UTF-8?B?" . base64_encode($to_name)   . "?= <{$to}>";
    $rt_fmt    = $reply_to ? "=?UTF-8?B?" . base64_encode($reply_to_name) . "?= <{$reply_to}>" : '';

    $headers  = "Date: {$date}\r\n";
    $headers .= "From: {$from_fmt}\r\n";
    $headers .= "To: {$to_fmt}\r\n";
    if ($rt_fmt) $headers .= "Reply-To: {$rt_fmt}\r\n";
    $headers .= "Subject: {$encoded_subject}\r\n";
    $headers .= "MIME-Version: 1.0\r\n";
    $headers .= "Content-Type: multipart/alternative; boundary=\"{$boundary}\"\r\n";
    $headers .= "X-Mailer: PBN-Mailer/1.0\r\n";

    $body  = "--{$boundary}\r\n";
    $body .= "Content-Type: text/plain; charset=UTF-8\r\n";
    $body .= "Content-Transfer-Encoding: base64\r\n\r\n";
    $body .= chunk_split(base64_encode($text)) . "\r\n";
    $body .= "--{$boundary}\r\n";
    $body .= "Content-Type: text/html; charset=UTF-8\r\n";
    $body .= "Content-Transfer-Encoding: base64\r\n\r\n";
    $body .= chunk_split(base64_encode($html)) . "\r\n";
    $body .= "--{$boundary}--\r\n";

    // Dot-stuffing: lines starting with '.' must be doubled
    $message = $headers . "\r\n" . $body;
    $message = str_replace("\r\n.", "\r\n..", $message);

    fwrite($conn, $message . "\r\n.\r\n");
    smtp_cmd($conn, null, 250);                                    // message accepted
    smtp_cmd($conn, "QUIT", 221);
    fclose($conn);
}