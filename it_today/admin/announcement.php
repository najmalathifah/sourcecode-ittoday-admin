<?php
session_start();
include "../config/db.php";

if (!isset($_SESSION["admin_logged_in"])) {
    header("Location: ../auth/login.php");
    exit;
}

$action = $_GET["action"] ?? "";
$id = $_GET["id"] ?? null;

/* DELETE */
if ($action == "delete" && $id) {
    $pdo->prepare('DELETE FROM admin.announcement WHERE event_announcement_id=:id')
        ->execute([":id"=>$id]);
    header("Location: announcement.php");
    exit;
}

/* SAVE NEW */
if ($action == "save_new" && $_SERVER["REQUEST_METHOD"] == "POST") {
    $pdo->prepare("
        INSERT INTO admin.announcement
        (title, description, author, competition, event_id, user_id, created_at, updated_at)
        VALUES
        (:t, :d, :a, :c, :e, :u, NOW(), NOW())
    ")->execute([
        ":t" => $_POST["title"],
        ":d" => $_POST["description"],
        ":a" => $_POST["author"],
        ":c" => $_POST["competition"],
        ":e" => $_POST["event_id"],
    ]);

    header("Location: announcement.php");
    exit;
}

/* SAVE EDIT */
if ($action == "save_edit" && $id && $_SERVER["REQUEST_METHOD"] == "POST") {
    $pdo->prepare("
        UPDATE admin.announcement SET
        title=:t, description=:d, competition=:c,
        event_id=:e, updated_at=NOW()
        WHERE event_announcement_id=:id
    ")->execute([
        ":t" => $_POST["title"],
        ":d" => $_POST["description"],
        ":c" => $_POST["competition"],
        ":e" => $_POST["event_id"],
        ":id"=> $id
    ]);

    header("Location: announcement.php");
    exit;
}

/* GET ALL */
$ann = $pdo->query("
    SELECT a.*, e.title AS event_title
    FROM admin.announcement a
    LEFT JOIN admin.event e ON e.event_id = a.event_id
    ORDER BY a.created_at DESC
")->fetchAll(PDO::FETCH_ASSOC);


$events = $pdo->query("SELECT event_id, title FROM admin.event")->fetchAll();
$users =  $pdo->query("SELECT user_id, full_name FROM admin.\"User\"")->fetchAll();
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Announcement</title>

<style>
body { font-family: 'Inter', sans-serif; background: #fff; padding: 25px; }
table { width: 100%; border-collapse: separate; border-spacing: 0 6px; }
th,td { padding: 10px 14px; }
th { background: #eee; text-align: left; }
tr { background: #fafafa; }
.btn {
	padding:6px 12px; border-radius:6px; text-decoration:none; font-size:13px;
}
.add-btn{ background:#007bff;color:#fff; }
.edit-btn{ background:#ffa600;color:#fff; }
.del-btn{ background:#e10000;color:#fff; }
label { font-weight:600; }
input, select, textarea {
    width: 100%;
    padding: 8px;
    border-radius: 6px;
    border: 1px solid #aaa;
    margin: 4px 0 14px;
}
button { background:#007bff;color:#fff;border:none;padding:8px 14px;border-radius:6px; }
</style>

<script src="https://cdn.ckeditor.com/4.21.0/standard/ckeditor.js"></script>
</head>
<body>

<h2>📢 Announcement</h2>
<p style="color:#777;margin-top:-10px">Pengumuman untuk peserta</p>
<br>

<a class="btn add-btn" href="announcement.php?action=add">+ Tambah Announcement</a>
<br><br>

<?php if($action == "add"): ?>

<h3>Tambah Announcement</h3>
<form action="announcement.php?action=save_new" method="POST">
    <label>Judul</label>
    <input type="text" name="title" required>

    <label>Kompetisi</label>
    <input type="text" name="competition">

    <label>Event terkait</label>
    <select name="event_id">
        <?php foreach($events as $ev): ?>
        <option value="<?= $ev['event_id'] ?>"><?= $ev['title'] ?></option>
        <?php endforeach; ?>
    </select>

    <label>Deskripsi</label>
    <textarea name="description" id="desc"></textarea>
    <script>CKEDITOR.replace('desc');</script>

    <button type="submit">Simpan</button>
</form>

<br><a href="announcement.php">⬅ Kembali</a>

<?php elseif($action == "edit" && $id): 
$stm = $pdo->prepare("SELECT * FROM admin.announcement WHERE event_announcement_id=:id");
$stm->execute([":id"=>$id]);
$a = $stm->fetch(PDO::FETCH_ASSOC);
?>
<h3>Edit Announcement</h3>
<form action="announcement.php?action=save_edit&id=<?= $id ?>" method="POST">
    <label>Judul</label>
    <input type="text" name="title" value="<?= $a['title'] ?>" required>

    <label>Kompetisi</label>
    <input type="text" name="competition" value="<?= $a['competition'] ?>">

    <label>Event terkait</label>
    <select name="event_id">
        <?php foreach($events as $ev): ?>
        <option value="<?= $ev['event_id'] ?>" <?=($ev['event_id']==$a['event_id']?'selected':'')?>>
            <?= $ev['title'] ?>
        </option>
        <?php endforeach; ?>
    </select>

    <label>Deskripsi</label>
    <textarea name="description" id="desc"><?= $a['description'] ?></textarea>
    <script>CKEDITOR.replace('desc');</script>

    <button type="submit">Update</button>
</form>

<br><a href="announcement.php">⬅ Kembali</a>

<?php else: ?>

<table>
<tr>
    <th>Judul</th>
    <th>Event</th>
    <th>Created</th>
    <th>Aksi</th>
</tr>

<?php foreach($ann as $a): ?>
<tr>
    <td><?= $a['title'] ?></td>
    <td><?= $a['event_title'] ?></td>
    <td><?= date("d M Y H:i", strtotime($a['created_at'])) ?></td>
    <td>
        <a class="btn edit-btn" href="announcement.php?action=edit&id=<?= $a['event_announcement_id'] ?>">Edit</a>
        <a class="btn del-btn" 
           href="announcement.php?action=delete&id=<?= $a['event_announcement_id'] ?>"
           onclick="return confirm('Hapus pengumuman ini?')">
        Delete</a>
    </td>
</tr>
<?php endforeach; ?>
</table>

<?php endif; ?>

<br>
<a href="dashboard.php">⬅ Kembali</a>

</body>
</html>
