<?php
include "../config/db.php";

$event_id = $_GET["event_id"] ?? 0;

$stmt = $pdo->prepare("
    SELECT team_id, team_code, team_name
    FROM admin.team
    WHERE event_id = :id
    ORDER BY team_code
");
$stmt->execute([":id"=>$event_id]);

echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
