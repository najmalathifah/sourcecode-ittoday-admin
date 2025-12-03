<?php
session_start();
include "../config/db.php";

if (!isset($_SESSION["admin_logged_in"])) {
    header("Location: ../auth/login.php");
    exit;
}

$action = $_GET["action"] ?? "";
$sub_id = $_GET["id"] ?? null;

/* ===========================================================
   DELETE SUBMISSION
=========================================================== */
if ($action == "delete" && $sub_id) {
    $stmt = $pdo->prepare("
        SELECT submission_object 
        FROM admin.submission 
        WHERE competition_submission_id = :id
    ");
    $stmt->execute([":id"=>$sub_id]);
    $file = $stmt->fetchColumn();

    if ($file && file_exists("../submission/" . $file)) {
        unlink("../submission/" . $file);
    }

    $pdo->prepare("
        DELETE FROM admin.submission 
        WHERE competition_submission_id = :id
    ")->execute([":id"=>$sub_id]);

    header("Location: submission.php");
    exit;
}

/* ===========================================================
   SAVE UPLOAD SUBMISSION
=========================================================== */
/* ===========================================================
   SAVE / REPLACE SUBMISSION
=========================================================== */
if ($action == "save" && $_SERVER["REQUEST_METHOD"] == "POST") {

    $team_id  = $_POST["team_id"];
    $event_id = $_POST["event_id"];

    /* 🔎 Cek apakah sudah ada submission untuk tim + event */
    $check = $pdo->prepare("
        SELECT competition_submission_id, submission_object 
        FROM admin.submission 
        WHERE team_id = :t AND event_id = :e
    ");
    $check->execute([
        ":t" => $team_id,
        ":e" => $event_id
    ]);
    $existing = $check->fetch(PDO::FETCH_ASSOC);

    /* 📌 Upload file baru */
    $fileName = time() . "_" . basename($_FILES["file"]["name"]);
    move_uploaded_file($_FILES["file"]["tmp_name"], "../submission/" . $fileName);

    /* 🔄 Jika sudah ada → hapus file lama + update */
    if ($existing) {
        if ($existing["submission_object"] && file_exists("../submission/" . $existing["submission_object"])) {
            unlink("../submission/" . $existing["submission_object"]);
        }

        $pdo->prepare("
            UPDATE admin.submission 
            SET submission_object = :f, updated_at = NOW()
            WHERE competition_submission_id = :id
        ")->execute([
            ":f"  => $fileName,
            ":id" => $existing["competition_submission_id"]
        ]);

    } else {
        /* ✨ Kalau belum ada submission → insert baru */
        $pdo->prepare("
            INSERT INTO admin.submission (submission_object, created_at, updated_at, team_id, event_id)
            VALUES (:f, NOW(), NOW(), :t, :e)
        ")->execute([
            ":f" => $fileName,
            ":t" => $team_id,
            ":e" => $event_id
        ]);
    }

    header("Location: submission.php");
    exit;
}


/* ===========================================================
   GET ALL SUBMISSIONS
=========================================================== */
$submissions = $pdo->query("
SELECT 
    s.competition_submission_id,
    s.submission_object,
    s.created_at,
    t.team_code,
    t.team_name,
    e.title AS event_title
FROM admin.submission s
JOIN admin.team t ON t.team_id = s.team_id
JOIN admin.event e ON e.event_id = s.event_id
ORDER BY s.created_at DESC
")->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Kelola Submission</title>

<style>
body { font-family:'Inter',sans-serif; background:#fff; padding:25px; }
table { width:100%; border-collapse:separate; border-spacing:0 6px; }
th,td { padding:12px 14px; white-space:nowrap; }
th { background:#eeeeee; }
tr { background:#fafafa; }
a.btn {
	padding:6px 10px;
	text-decoration:none;
	background:#eee;
	border-radius:6px;
	font-size:13px;
}
a.btn:hover { background:#ddd; }
.download { color:#007bff; }
.delete { color:#e10000; }
.add-btn {
    padding:8px 12px;
    background:#007bff;
    color:white;
    border-radius:6px;
    text-decoration:none;
}
.add-btn:hover { background:#005fcc; }
input,select {
    padding:8px;
    border-radius:6px;
    border:1px solid #ccc;
    margin:6px 0 12px;
}
button {
    background:#007bff;
    color:white;
    border:none;
    padding:8px 14px;
    border-radius:6px;
}
button:hover { background:#005fcc; }
label { font-weight:600; }
</style>

</head>
<body>

<h2>📦 Kelola Submission</h2>
<p style="color:#777;margin-top:-10px;">Daftar file yang dikumpulkan peserta</p>
<br>

<a class="add-btn" href="submission.php?action=add">➕ Upload Submission</a>
<br><br>

<?php if ($action == "add"): ?>

<h3>➕ Upload Submission</h3>

<form method="POST" action="submission.php?action=save" enctype="multipart/form-data">

<label>Pilih Event</label><br>
<select name="event_id" id="eventSelect" required>
    <option value="">-- Pilih Event --</option>
    <?php
    $events = $pdo->query("SELECT event_id, title FROM admin.event")->fetchAll();
    foreach ($events as $ev): ?>
        <option value="<?= $ev['event_id'] ?>"><?= htmlspecialchars($ev['title']) ?></option>
    <?php endforeach; ?>
</select><br>

<label>Pilih Tim</label><br>
<select name="team_id" id="teamSelect" required>
    <option value="">-- Pilih Event dulu --</option>
</select><br>

<label>File Submission (ZIP/PDF)</label><br>
<input type="file" name="file" required accept=".zip,.pdf,.jpg,.jpeg,.png">


<button type="submit">Upload</button>

</form>

<br><a href="submission.php">⬅ Batal</a>

<script>
document.getElementById("eventSelect").addEventListener("change", function() {
    var id = this.value;
    fetch("team_api.php?event_id=" + id)
      .then(r => r.json())
      .then(data => {
        const select = document.getElementById("teamSelect");
        select.innerHTML = "";
        data.forEach(t => {
            const opt = document.createElement("option");
            opt.value = t.team_id;
            opt.textContent = t.team_code + " — " + t.team_name;
            select.appendChild(opt);
        });
    });
});
</script>

<?php else: ?>

<table>
<tr>
    <th>Team</th>
    <th>Event</th>
    <th>File</th>
    <th>Uploaded</th>
    <th>Aksi</th>
</tr>

<?php foreach($submissions as $s): ?>
<tr>
    <td><?= $s['team_code'] ?> — <?= htmlspecialchars($s['team_name']) ?></td>
    <td><?= htmlspecialchars($s['event_title']) ?></td>
    <td><?= htmlspecialchars($s['submission_object']) ?></td>
    <td><?= date("d M Y H:i", strtotime($s['created_at'])) ?></td>
    <td>
        <a class="btn download" href="../submission/<?= $s['submission_object'] ?>" download>🔽 Download</a>
        <a class="btn delete"
           href="submission.php?action=delete&id=<?= $s['competition_submission_id'] ?>"
           onclick="return confirm('Hapus file ini?')">🗑 Delete</a>
    </td>
</tr>
<?php endforeach; ?>

</table>

<?php endif; ?>

<br>
<a href="dashboard.php">⬅ Kembali</a>
</body>
</html>
