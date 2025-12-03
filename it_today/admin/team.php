<?php
session_start();
include "../config/db.php";
// Ambil list event untuk dropdown
$events = $pdo->query("
    SELECT event_id, title 
    FROM admin.event 
    ORDER BY event_id ASC
")->fetchAll(PDO::FETCH_ASSOC);


if (!isset($_SESSION["admin_logged_in"])) {
    header("Location: ../auth/login.php");
    exit;
}

if (isset($_GET['action']) && $_GET['action'] === 'save_new' && $_SERVER['REQUEST_METHOD'] === 'POST') {

    $stmt = $pdo->prepare("
        INSERT INTO admin.team (team_name, team_code, event_id)
        VALUES (?, ?, ?)
    ");

    $stmt->execute([
        $_POST['team_name'],
        $_POST['team_code'],
        $_POST['event_id']
    ]);

    header("Location: team.php?success=added");
    exit;
}

if (isset($_GET['action']) && $_GET['action'] === 'update' && isset($_GET['id'])) {
    $id = $_GET['id'];

    $stmt = $pdo->prepare("
        UPDATE admin.team
        SET team_name=?, team_code=?, event_id=?
        WHERE team_id=?
    ");

    $stmt->execute([
        $_POST['team_name'],
        $_POST['team_code'],
        $_POST['event_id'],
        $id
    ]);

    header("Location: team.php?success=updated");
    exit;
}

$sql = <<<SQL
SELECT 
    t.team_id,
    t.team_code,
    t.team_name,
    e.title AS event_title,
    (
        SELECT u.full_name 
        FROM admin.team_member tm 
        JOIN admin."User" u ON u.user_id = tm.user_id
        WHERE tm.team_id = t.team_id 
          AND tm.member_role = 'Leader'
        LIMIT 1
    ) AS leader_name,
    (
        SELECT COUNT(*) 
        FROM admin.team_member tm 
        WHERE tm.team_id = t.team_id
    ) AS member_count,
    t.verifying_status
FROM admin.team t
LEFT JOIN admin.event e ON e.event_id = t.event_id
ORDER BY t.team_id ASC
SQL;

$teams = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Kelola Tim</title>

<style>
body {
    font-family: 'Inter', Arial, sans-serif;
    background: #ffffff;
    padding: 25px;
}
h2 {
    font-size: 24px;
    margin-bottom: 15px;
}
.container {
    overflow-x: auto;
    border-radius: 10px;
    border: 1px solid #ddd;
    background: #fff;
}
table {
    width: 100%;
    min-width: 1200px;
    border-collapse: separate;
    border-spacing: 0;
}
th, td {
    padding: 14px 18px;
    white-space: nowrap;
    border-bottom: 1px solid #eee;
}
th {
    background: #f6f6f6;
    position: sticky;
    top: 0;
}
tr:hover {
    background: #fafafa;
}
.status {
    padding: 6px 12px;
    border-radius: 8px;
    font-size: 12px;
    font-weight: bold;
}
.status.green { background:#e6f7e9; color:#1c7c32; }
.status.yellow { background:#fff7ce; color:#7a6d00; }
.status.red { background:#ffe3e3; color:#b30000; }

a.btn-small {
    padding: 6px 10px;
    background: #eee;
    text-decoration: none;
    border-radius: 6px;
    font-size: 13px;
    margin-right: 4px;
}
a.btn-small:hover {
    background: #ddd;
}
</style>
</head>
<body>

<h2>👥 Kelola Tim</h2>

<a href="team.php?action=add" class="btn-view">➕ Tambah Team</a>
<br><br>

<?php if (isset($_GET['action']) && $_GET['action'] === 'add'): ?>

<form method="POST" action="team.php?action=save_new">
<h3>Tambah Team Baru</h3>

<label>Nama Team:</label><br>
<input type="text" name="team_name" required><br><br>

<label>Kode Team:</label><br>
<input type="text" name="team_code" placeholder="misal: T001" required><br><br>

<label>Pilih Event:</label><br>
<select name="event_id" required>
    <option value="">— Pilih Event —</option>
    <?php foreach ($events as $ev): ?>
        <option value="<?= $ev['event_id'] ?>"><?= $ev['title'] ?></option>
    <?php endforeach; ?>
</select><br><br>

<button type="submit">Simpan</button>
<a href="team.php">Batal</a>

</form>

<?php exit; ?>
<?php endif; ?>

<?php if (isset($_GET['action']) && $_GET['action'] === 'edit' && isset($_GET['id'])): ?>

<?php
$id = $_GET['id'];
$stmt = $pdo->prepare("SELECT * FROM admin.team WHERE team_id = ?");
$stmt->execute([$id]);
$team = $stmt->fetch(PDO::FETCH_ASSOC);
?>

<form method="POST" action="team.php?action=update&id=<?= $id ?>">
<h3>Edit Team</h3>

<label>Nama Team:</label><br>
<input type="text" name="team_name" value="<?= htmlspecialchars($team['team_name']) ?>" required><br><br>

<label>Kode Team:</label><br>
<input type="text" name="team_code" value="<?= $team['team_code'] ?>" required><br><br>

<label>Pilih Event:</label><br>
<select name="event_id" required>
    <?php foreach ($events as $ev): ?>
        <option value="<?= $ev['event_id'] ?>" <?= ($team['event_id']==$ev['event_id'] ? 'selected' : '') ?>>
            <?= $ev['title'] ?>
        </option>
    <?php endforeach; ?>
</select><br><br>

<button type="submit">Update</button>
<a href="team.php">Batal</a>

</form>

<?php exit; ?>
<?php endif; ?>


<div class="container">
<table>
<tr>
    <th>Team Code</th>
    <th>Team Name</th>
    <th>Event</th>
    <th>Leader</th>
    <th>Anggota</th>
    <th>Status</th>
    <th>Aksi</th>
</tr>

<?php foreach($teams as $t): ?>
<tr>
    <td><?= $t['team_code'] ?></td>
    <td><?= $t['team_name'] ?></td>
    <td><?= $t['event_title'] ?></td>
    <td><?= $t['leader_name'] ?: '-' ?></td>
    <td><?= $t['member_count'] ?></td>

    <td>
        <?php
        $st = strtolower($t['verifying_status']);
        $badge = $st === 'verified' ? 'green' : ($st === 'pending' ? 'yellow' : 'red');
        ?>
        <span class="status <?= $badge ?>"><?= $t['verifying_status'] ?></span>
    </td>

    <td>
    <a class="btn-small" href="/it_today/admin/team_manage.php?id=<?= $t['team_id'] ?>">👀 Kelola</a>
    <a class="btn-small" href="/it_today/admin/team.php?action=edit&id=<?= $t['team_id'] ?>">✏️ Edit</a>
    <a class="btn-small"
       onclick="return confirm('Hapus tim ini beserta anggotanya?')"
       href="/it_today/admin/team_delete.php?id=<?= $t['team_id'] ?>">🗑️</a>
</td>
</tr>
<?php endforeach; ?>

</table>
</div>

<br>
<a href="dashboard.php">⬅ Kembali</a>

</body>
</html>
