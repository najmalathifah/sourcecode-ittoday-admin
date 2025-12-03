<?php
$host = "localhost";
$dbname = "ittoday";
$user = "postgres";
$pass = "dz1234"; // atau password kamu

try {
    $pdo = new PDO("pgsql:host=$host;dbname=$dbname", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // INI WAJIB! Pindahkan semua query ke schema admin
    $pdo->exec('SET search_path TO admin, public;');

} catch (PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}
