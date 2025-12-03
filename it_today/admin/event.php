<?php
session_start();
include "../config/db.php";

if (!isset($_SESSION["admin_logged_in"])) {
    header("Location: ../auth/login.php");
    exit;
}

$action = $_GET["action"] ?? "";
$event_id = $_GET["id"] ?? null;

/* 🔹 SAVE NEW */
if ($action == "save_new" && $_SERVER["REQUEST_METHOD"] == "POST") {

    $stmt = $pdo->prepare("
        INSERT INTO admin.event (event_code, title, max_member_per_team, guidebook_url, contact_person_1, contact_person_2, description)
        VALUES (:c, :t, :m, :g, :cp1, :cp2, :d)
        RETURNING event_id
    ");
    $stmt->execute([
        ":c" => $_POST["event_code"],
        ":t" => $_POST["title"],
        ":m" => $_POST["max_member_per_team"],
        ":g" => $_POST["guidebook_url"],
        ":cp1" => $_POST["cp1"],
        ":cp2" => $_POST["cp2"],
        ":d" => $_POST["description"]
    ]);
    $eid = $stmt->fetchColumn();

    if (!empty($_FILES["poster"]["name"])) {
        $poster = time() . "_" . basename($_FILES["poster"]["name"]);
        move_uploaded_file($_FILES["poster"]["tmp_name"], "../uploads/" . $poster);

        $pdo->prepare("
            INSERT INTO admin.media(name, type, created_at, event_id)
            VALUES (:n, :t, NOW(), :eid)
        ")->execute([
            ":n" => $poster,
            ":t" => $_FILES["poster"]["type"],
            ":eid" => $eid
        ]);
    }

    header("Location: event.php");
    exit;
}

/* 🔹 SAVE EDIT */
if ($action == "save_edit" && $_SERVER["REQUEST_METHOD"] == "POST" && $event_id) {

    $pdo->prepare("
        UPDATE admin.event
        SET event_code=:c, title=:t, max_member_per_team=:m,
            guidebook_url=:g, contact_person_1=:cp1, contact_person_2=:cp2,
            description=:d
        WHERE event_id=:id
    ")->execute([
        ":c" => $_POST["event_code"],
        ":t" => $_POST["title"],
        ":m" => $_POST["max_member_per_team"],
        ":g" => $_POST["guidebook_url"],
        ":cp1" => $_POST["cp1"],
        ":cp2" => $_POST["cp2"],
        ":d" => $_POST["description"],
        ":id" => $event_id
    ]);

    if (!empty($_FILES["poster"]["name"])) {
        $poster = time() . "_" . basename($_FILES["poster"]["name"]);
        move_uploaded_file($_FILES["poster"]["tmp_name"], "../uploads/" . $poster);

        $pdo->prepare("
            INSERT INTO admin.media(name, type, created_at, event_id)
            VALUES (:n, :t, NOW(), :eid)
        ")->execute([
            ":n" => $poster,
            ":t" => $_FILES["poster"]["type"],
            ":eid" => $event_id
        ]);
    }

    header("Location: event.php");
    exit;
}

/* 🔹 DELETE */
if ($action == "delete" && $event_id) {

    $files = $pdo->prepare("SELECT name FROM admin.media WHERE event_id=:id");
    $files->execute([":id"=>$event_id]);

    foreach($files->fetchAll() as $f){
        if(file_exists("../uploads/".$f["name"])){
            unlink("../uploads/".$f["name"]);
        }
    }

    $pdo->prepare("DELETE FROM admin.media WHERE event_id=:id")->execute([":id"=>$event_id]);
    $pdo->prepare("DELETE FROM admin.event WHERE event_id=:id")->execute([":id"=>$event_id]);

    header("Location: event.php");
    exit;
}

/* 🔹 GET ALL EVENT */
$events = $pdo->query("
    SELECT e.*, 
    (SELECT name FROM admin.media WHERE event_id = e.event_id ORDER BY media_id DESC LIMIT 1) AS poster
    FROM admin.event e ORDER BY e.event_id ASC
")->fetchAll(PDO::FETCH_ASSOC);

?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Kelola Event</title>

<style>
body { font-family:'Inter',sans-serif; background:#fff; padding:25px; }
table { width:100%; min-width:1200px; border-collapse:separate; border-spacing:0; }
th,td { padding:12px 16px; white-space:nowrap; border-bottom:1px solid #eee; }
th { background:#f6f6f6; position:sticky; top:0; }
.btn {
    padding:6px 10px; background:#eee; border-radius:6px;
    text-decoration:none; font-size:13px;
}
.btn:hover { background:#ddd; }
.thumbnail { width:50px;height:50px;object-fit:cover;border-radius:6px; }
.add-btn { background:#007bff;color:white;padding:8px 14px;border-radius:6px;text-decoration:none; }
.add-btn:hover { background:#005fcc; }
input,textarea { width:300px;padding:8px;margin:6px 0 14px;border-radius:6px;border:1px solid #ccc; }
button { background:#007bff;color:white;padding:8px 14px;border:none;border-radius:6px; }
button:hover { background:#005fcc; }
label{font-weight:600;}
</style>
</head>
<body>

<?php if ($action == "add" || ($action == "edit" && $event_id)): ?>

<?php
$e = [
    "event_code" => "",
    "title" => "",
    "max_member_per_team" => 3,
    "guidebook_url" => "",
    "contact_person_1" => "",
    "contact_person_2" => "",
    "description" => ""
];
if($action=="edit"){
    $stmt = $pdo->prepare("SELECT * FROM admin.event WHERE event_id=:id");
    $stmt->execute([":id"=>$event_id]);
    $e = $stmt->fetch(PDO::FETCH_ASSOC);
}
?>

<h2><?= ($action=="edit"?"✏️ Edit Event":"➕ Tambah Event") ?></h2>

<form method="POST" enctype="multipart/form-data"
      action="event.php?action=<?= $action=="edit"?"save_edit&id=$event_id":"save_new" ?>">

<label>Kode Event</label><br>
<input type="text" name="event_code" value="<?= $e['event_code'] ?>" required><br>

<label>Nama Event</label><br>
<input type="text" name="title" value="<?= $e['title'] ?>" required><br>

<label>Max Member per Team</label><br>
<input type="number" name="max_member_per_team" value="<?= $e['max_member_per_team'] ?>" required><br>

<label>Guidebook URL</label><br>
<input type="url" name="guidebook_url" value="<?= $e['guidebook_url'] ?>"><br>

<label>Contact Person 1</label><br>
<input type="text" name="cp1" value="<?= $e['contact_person_1'] ?>"><br>

<label>Contact Person 2</label><br>
<input type="text" name="cp2" value="<?= $e['contact_person_2'] ?>"><br>

<label>Poster (opsional)</label><br>
<input type="file" name="poster"><br>

<label>Deskripsi</label><br>
<textarea name="description"><?= $e['description'] ?></textarea><br>

<button type="submit">Simpan</button>
</form>



<?php else: ?>

<h2>🎪 Kelola Event</h2>

<a class="add-btn" href="event.php?action=add">➕ Tambah Event</a><br><br>

<table>
<tr>
    <th>Code</th>
    <th>Nama Event</th>
    <th>Max</th>
    <th>Poster</th>
    <th>Aksi</th>
</tr>

<?php foreach($events as $ev): ?>
<tr>
    <td><?= $ev['event_code'] ?></td>
    <td><?= htmlspecialchars($ev['title']) ?></td>
    <td><?= $ev['max_member_per_team'] ?> org</td>
    <td>
        <?php if ($ev['poster']): ?>
            <img src="../uploads/<?= $ev['poster'] ?>" class="thumbnail">
        <?php else: ?> - <?php endif; ?>
    </td>
    <td>
        <a class="btn" href="event.php?action=edit&id=<?= $ev['event_id'] ?>">✏️</a>
        <a class="btn" href="event.php?action=delete&id=<?= $ev['event_id'] ?>"
           onclick="return confirm('Hapus event ini?')">🗑</a>
    </td>
</tr>
<?php endforeach; ?>
</table>

<?php endif; ?>

<br><a href="dashboard.php">⬅ Kembali</a>

</body>
</html>
