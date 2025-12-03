<?php
session_start();
include "../config/db.php";

if (!isset($_SESSION["admin_logged_in"])) {
    header("Location: ../auth/login.php");
    exit;
}

$team_id = $_GET["id"] ?? null;
if (!$team_id) {
    header("Location: team.php");
    exit;
}

/* 1️⃣ Ambil Data Tim */
$stmt = $pdo->prepare("
    SELECT 
    t.team_id,
    t.team_name,
    t.team_code,
    t.event_id, -- ➜ Tambahkan ini!
    COALESCE(t.max_member, 3) AS max_member_per_team,
    e.title AS event_title
FROM admin.team t
JOIN admin.event e ON e.event_id = t.event_id
WHERE t.team_id = :id

");
$stmt->execute([":id" => $team_id]);
$team = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$team) die("Tim tidak ditemukan.");

$eventId = (int)$team["event_id"];

$max_members = ($eventId == 1 || $eventId == 2) ? 1 : 3;

/* 2️⃣ Hapus anggota (kecuali leader) */
if (isset($_GET["delete_member"])) {
    $member_id = $_GET["delete_member"];

    $check = $pdo->prepare("SELECT member_role FROM admin.team_member WHERE team_member_id = :mid");
    $check->execute([":mid" => $member_id]);
    if ($check->fetchColumn() !== "Leader") {
        $pdo->prepare("DELETE FROM admin.team_member WHERE team_member_id = :mid")
            ->execute([":mid" => $member_id]);
    }
    header("Location: team_manage.php?id=".$team_id);
    exit;
}

/* 3️⃣ Ambil Anggota Tim */
$stmtMembers = $pdo->prepare("
    SELECT tm.team_member_id, tm.member_role, u.full_name
    FROM admin.team_member tm
    JOIN admin.\"User\" u ON u.user_id = tm.user_id
    WHERE tm.team_id = :id
    ORDER BY tm.member_role DESC, u.full_name ASC
");
$stmtMembers->execute([":id" => $team_id]);
$members = $stmtMembers->fetchAll(PDO::FETCH_ASSOC);

$current_members = count($members);
$remaining = $max_members - $current_members;

/* 4️⃣ User eligible untuk tim */
$stmtAvail = $pdo->prepare("
    SELECT u.user_id, u.full_name 
    FROM admin.\"User\" u
    JOIN admin.event_participant ep ON ep.user_id = u.user_id
    WHERE ep.event_id = :e
      AND u.user_id NOT IN (
            SELECT user_id FROM admin.team_member WHERE team_id = :id
      )
    ORDER BY u.full_name
");
$stmtAvail->execute([
    ":id" => $team_id,
    ":e" => $team["event_id"]
]);


/* 5️⃣ Tambah anggota */
if (isset($_POST["add_member"]) && $remaining > 0) {

    $user_id = $_POST["user_id"] ?? null;

    // Cek apakah event user sesuai dengan event tim
    $checkEvent = $pdo->prepare("
        SELECT 1 FROM admin.event_participant
        WHERE user_id = :u AND event_id = :e
    ");
    $checkEvent->execute([":u" => $user_id, ":e" => $team["event_id"]]);

    if (!$checkEvent->fetchColumn()) {
        echo "<script>alert('User tidak terdaftar pada event ini!');</script>";
        exit;
    }

    // Cek apakah user sudah ada di tim lain dalam event ini
    $checkTeam = $pdo->prepare("
        SELECT 1 FROM admin.team_member tm
        JOIN admin.team t ON t.team_id = tm.team_id
        WHERE tm.user_id = :u AND t.event_id = :e
    ");
    $checkTeam->execute([":u" => $user_id, ":e" => $team["event_id"]]);

    if ($checkTeam->fetchColumn()) {
        echo "<script>alert('User sudah terdaftar di tim lain dalam event ini!');</script>";
        exit;
    }

    // Jika semua aman → insert
    $pdo->prepare("
        INSERT INTO admin.team_member (member_role, user_id, team_id)
        VALUES ('Member', :u, :t)
    ")->execute([":u" => $user_id, ":t" => $team_id]);

    header("Location: team_manage.php?id=".$team_id);
    exit;
}

?>

<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Kelola Team</title>
<style>
    body { font-family: Arial }
    .leader { background:#007bff;color:#fff;padding:3px 6px;border-radius:4px;font-size:11px; }
    .del { color:red;font-weight:bold;text-decoration:none }
    .del:hover { text-decoration:underline }
    .table { border-collapse: collapse; width: 70% }
    .table th, .table td {
        border: 1px solid #888;
        padding: 8px;
    }
</style>
</head>
<body>

<h2>Kelola Anggota Tim: <?= htmlspecialchars($team["team_name"]) ?> (<?= $team["team_code"] ?>)</h2>
<p>Event: <?= htmlspecialchars($team["event_title"]) ?></p>
<p>Anggota: <?= $current_members ?>/<?= $max_members ?>
<?php if ($remaining > 0): ?>
 — <b><?= $remaining ?></b> slot tersisa
<?php else: ?>
 — <span style="color:red;">Penuh</span>
<?php endif; ?>
</p>

<!-- Table Anggota -->
<table class="table">
<tr><th>Nama</th><th>Role</th><th>Aksi</th></tr>
<?php foreach ($members as $m): ?>
<tr>
    <td><?= htmlspecialchars($m["full_name"]) ?></td>
    <td><?= $m["member_role"] === "Leader" ? "<span class='leader'>Leader</span>" : "Member" ?></td>
    <td>
        <?php if ($m["member_role"] !== "Leader"): ?>
        <a class="del" href="?id=<?= $team_id ?>&delete_member=<?= $m['team_member_id'] ?>"
           onclick="return confirm('Hapus anggota ini?')">Hapus</a>
        <?php else: ?> — <?php endif; ?>
    </td>
</tr>
<?php endforeach; ?>
</table>

<br><hr>
<?php if ($remaining > 0): ?>
<h3>Tambah Anggota</h3>
<form method="POST">
    <select name="user_id" required>
        <option value="">-- Pilih User --</option>
        <?php foreach ($available_users as $u): ?>
        <option value="<?= $u['user_id'] ?>"><?= htmlspecialchars($u['full_name']) ?></option>
        <?php endforeach; ?>
    </select>
    <button type="submit" name="add_member">Tambah</button>
</form>
<?php else: ?>
<p style="color:red;">Anggota sudah penuh.</p>
<?php endif; ?>

<br>
<a href="team.php">⬅ Kembali</a>

</body>
</html>
