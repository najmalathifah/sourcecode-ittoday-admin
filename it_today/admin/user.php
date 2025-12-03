<?php
session_start();
include "../config/db.php";

if (!isset($_SESSION["admin_logged_in"])) {
    header("Location: ../auth/login.php");
    exit;
}

$action = $_GET['action'] ?? null;


// === SAVE NEW USER ===
if (isset($_GET['action']) && $_GET['action'] === 'save_new' && $_SERVER['REQUEST_METHOD'] === 'POST') {

    $ktmFile = null;
    $twibbonFile = null;

    if (!empty($_FILES['ktm_key']['name'])) {
        $ext = pathinfo($_FILES['ktm_key']['name'], PATHINFO_EXTENSION);
        $ktmFile = "ktm_" . time() . "." . $ext;
        move_uploaded_file($_FILES['ktm_key']['tmp_name'], "../uploads/" . $ktmFile);
    }

    if (!empty($_FILES['twibbon_key']['name'])) {
        $ext = pathinfo($_FILES['twibbon_key']['name'], PATHINFO_EXTENSION);
        $twibbonFile = "twibbon_" . time() . "." . $ext;
        move_uploaded_file($_FILES['twibbon_key']['tmp_name'], "../uploads/" . $twibbonFile);
    }

    $stmt = $pdo->prepare("
        INSERT INTO admin.\"User\"
        (user_code, full_name, email, phone_number, nama_sekolah, pendidikan,
         id_instagram, id_discord, id_line, jenis_kelamin,
         registration_status, ktm_key, twibbon_key)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)
    ");

    $stmt->execute([
        $_POST['user_code'],
        $_POST['full_name'],
        $_POST['email'],
        $_POST['phone_number'],
        $_POST['nama_sekolah'],
        $_POST['pendidikan'],
        $_POST['id_instagram'],
        $_POST['id_discord'],
        $_POST['id_line'],
        $_POST['jenis_kelamin'],
        $ktmFile,
        $twibbonFile
    ]);

    $newUserId = $pdo->lastInsertId();

if (!empty($_POST['event_id'])) {
    $stmtEvent = $pdo->prepare("
        INSERT INTO admin.event_participant (user_id, event_id, payment_verification)
        VALUES (?, ?, 'pending')
    ");
    $stmtEvent->execute([$newUserId, $_POST['event_id']]);
}

    header("Location: user.php?success=added");
    exit;
}

// === UPDATE USER ===
if (isset($_GET['action']) && $_GET['action'] === 'update' && isset($_GET['id'])) {
    $id = $_GET['id'];

    // optional upload replacement
    $ktmFile = $_POST['old_ktm'] ?? null;
    $twibbonFile = $_POST['old_twibbon'] ?? null;

    if (!empty($_FILES['ktm_key']['name'])) {
        $ext = pathinfo($_FILES['ktm_key']['name'], PATHINFO_EXTENSION);
        $ktmFile = "ktm_" . time() . "." . $ext;
        move_uploaded_file($_FILES['ktm_key']['tmp_name'], "../uploads/" . $ktmFile);
    }

    if (!empty($_FILES['twibbon_key']['name'])) {
        $ext = pathinfo($_FILES['twibbon_key']['name'], PATHINFO_EXTENSION);
        $twibbonFile = "twibbon_" . time() . "." . $ext;
        move_uploaded_file($_FILES['twibbon_key']['tmp_name'], "../uploads/" . $twibbonFile);
    }

    $stmt = $pdo->prepare("
    UPDATE admin.\"User\"
    SET user_code=?, full_name=?, email=?, phone_number=?, nama_sekolah=?,
        pendidikan=?, id_instagram=?, id_discord=?, id_line=?, jenis_kelamin=?,
        registration_status=?, ktm_key=?, twibbon_key=?
    WHERE user_id=?
");

    $stmt->execute([
    $_POST['user_code'],
    $_POST['full_name'],
    $_POST['email'],
    $_POST['phone_number'],
    $_POST['nama_sekolah'],
    $_POST['pendidikan'],
    $_POST['id_instagram'],
    $_POST['id_discord'],
    $_POST['id_line'],
    $_POST['jenis_kelamin'],
    $_POST['registration_status'],
    $ktmFile,
    $twibbonFile,
    $id
]);

// Update event participant
if (!empty($_POST['event_id'])) {
    $pdo->prepare("
        INSERT INTO admin.event_participant (user_id, event_id, payment_verification)
        VALUES (?, ?, 'pending')
        ON CONFLICT (user_id) DO UPDATE SET event_id = EXCLUDED.event_id
    ")->execute([$id, $_POST['event_id']]);
}


    header("Location: user.php?success=updated");
    $user_id = $pdo->lastInsertId();
$event_id = $_POST['event_id'];

$pdo->prepare("
    INSERT INTO admin.event_participant (user_id, event_id, payment_verification)
    VALUES (?, ?, 'Pending')
")->execute([$user_id, $event_id]);

    exit;
}


// Ambil data user lengkap
$users = $pdo->query('
    SELECT 
        u.user_id,
        u.user_code,
        u.full_name,
        u.email,
        u.phone_number,
        u.nama_sekolah,
        u.pendidikan,
        u.id_instagram,
        u.id_discord,
        u.id_line,
        u.jenis_kelamin,
        u.registration_status,
        u.ktm_key,
        u.twibbon_key,
        u.entry_source,
        t.team_code,
        e.title AS event_title
    FROM admin."User" u
    LEFT JOIN admin.event_participant ep ON ep.user_id = u.user_id
    LEFT JOIN admin.event e ON e.event_id = ep.event_id
    LEFT JOIN admin.team_member tm ON tm.user_id = u.user_id
    LEFT JOIN admin.team t ON t.team_id = tm.team_id

    ORDER BY u.user_id ASC
')->fetchAll(PDO::FETCH_ASSOC);

// === DELETE USER ===
if (isset($_GET['action']) && $_GET['action'] === 'delete' && isset($_GET['id'])) {
    $id = $_GET['id'];

    // Hapus dari event_participant dulu (FK constraint)
    $pdo->prepare("DELETE FROM admin.event_participant WHERE user_id = ?")->execute([$id]);

    // Hapus dari team_member (jika pernah masuk tim)
    $pdo->prepare("DELETE FROM admin.team_member WHERE user_id = ?")->execute([$id]);

    // Baru hapus data user
    $pdo->prepare('DELETE FROM admin."User" WHERE user_id = ?')->execute([$id]);

    header("Location: user.php?success=deleted");
    exit;
}

?>

<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Kelola User</title>

<style>
    body {
    font-family: 'Inter', Arial, sans-serif;
    background: #ffffff;
    margin: 0;
    padding: 20px;
}

h2 {
    font-size: 24px;
    margin-bottom: 20px;
    color: #333;
}

.container {
    overflow-x: auto;
    border-radius: 10px;
    border: 1px solid #ddd;
    background: #fff;
    padding-bottom: 10px;
}

/* TABEL */
table {
    border-collapse: separate;
    border-spacing: 0;
    width: 100%;
    min-width: 1800px; /* BIAR LEBARAN */
}

th, td {
    padding: 14px 18px; /* lebih lebar */
    text-align: left;
    white-space: nowrap; /* biar ga patah */
}

th {
    background: #f6f6f6;
    font-weight: 600;
    border-bottom: 2px solid #ddd;
    position: sticky;
    top: 0;
    z-index: 2;
}

tr:hover {
    background: #fafafa; /* hover effect kayak Notion */
}

/* BADGE */
.status {
    padding: 6px 12px;
    border-radius: 8px;
    font-size: 12px;
    font-weight: 600;
}
.status.green { background:#e6f7e9; color:#1c7c32; }
.status.yellow { background:#fff7ce; color:#7a6d00; }
.status.red { background:#ffe3e3; color:#b30000; }

/* BUTTON */
a.btn-view {
    text-decoration: none;
    padding: 6px 12px;
    border-radius: 8px;
    background: #eeeeee;
    font-size: 13px;
}
a.btn-view:hover {
    background: #e0e0e0;
}

.gender {
    font-size: 18px;
}

</style>
</head>
<body>

<?php if ($action === 'add'): ?>

<h3>Tambah User Baru</h3>

<form method="POST" action="user.php?action=save_new" enctype="multipart/form-data" style="margin-bottom:20px;">

<label>Kode User:</label><br>
<input type="text" name="user_code" required><br><br>

<label>Nama Lengkap:</label><br>
<input type="text" name="full_name" required><br><br>

<label>Email:</label><br>
<input type="email" name="email" required><br><br>

<label>No HP:</label><br>
<input type="text" name="phone_number" required><br><br>

<label>Nama Sekolah:</label><br>
<input type="text" name="nama_sekolah"><br><br>

<label>Pendidikan:</label><br>
<select name="pendidikan">
    <option value="SMA">SMA</option>
    <option value="Kuliah">Kuliah</option>
</select><br><br>

<label>Instagram:</label><br>
<input type="text" name="id_instagram"><br><br>

<label>Discord:</label><br>
<input type="text" name="id_discord"><br><br>

<label>Line:</label><br>
<input type="text" name="id_line"><br><br>

<label>Gender:</label><br>
<select name="jenis_kelamin">
    <option value="L">Laki-laki</option>
    <option value="P">Perempuan</option>
</select><br><br>

<label>Upload KTM (opsional):</label><br>
<input type="file" name="ktm_key"><br><br>

<label>Upload Twibbon (opsional):</label><br>
<input type="file" name="twibbon_key"><br><br>

<label>Pilih Event:</label><br>
<select name="event_id" required>
    <option value="">— Pilih Event —</option>
    <option value="1">CPToday</option>
    <option value="2">UXToday</option>
    <option value="3">HackToday</option>
    <option value="4">MineToday</option>
    <option value="5">GameToday</option>
</select>

<button type="submit">Simpan</button>
<a href="user.php">Batal</a>

</form>

<?php exit; ?>
<?php endif; ?>


<h2>📋 Daftar User IT Today</h2>

<a href="user.php?action=add" class="btn-view">➕ Tambah User</a>
<br><br>

<?php if (isset($_GET['action']) && $_GET['action'] === 'edit' && isset($_GET['id'])): ?>

<?php
$id = $_GET['id'];
$u = $pdo->prepare('SELECT * FROM admin."User" WHERE user_id = ?');
$u->execute([$id]);
$user = $u->fetch(PDO::FETCH_ASSOC);

// Ambil event user dari event_participant
$getEvent = $pdo->prepare("
    SELECT event_id 
    FROM admin.event_participant 
    WHERE user_id = ? 
    LIMIT 1
");
$getEvent->execute([$id]);
$user_event_id = $getEvent->fetchColumn() ?? '';


?>


<form method="POST" action="user.php?action=update&id=<?= $id ?>" enctype="multipart/form-data" style="margin-bottom:20px;">
<h3>Edit User</h3>

<input type="text" name="user_code" value="<?= $user['user_code'] ?>" required><br><br>
<input type="text" name="full_name" value="<?= htmlspecialchars($user['full_name']) ?>" required><br><br>
<input type="email" name="email" value="<?= $user['email'] ?>" required><br><br>
<input type="text" name="phone_number" value="<?= $user['phone_number'] ?>" required><br><br>

<input type="text" name="nama_sekolah" value="<?= $user['nama_sekolah'] ?>"><br><br>
<input type="text" name="pendidikan" value="<?= $user['pendidikan'] ?>"><br><br>

<input type="text" name="id_instagram" value="<?= $user['id_instagram'] ?>"><br><br>
<input type="text" name="id_discord" value="<?= $user['id_discord'] ?>"><br><br>
<input type="text" name="id_line" value="<?= $user['id_line'] ?>"><br><br>

<select name="jenis_kelamin">
    <option value="L" <?= $user['jenis_kelamin']=='L'?'selected':'' ?>>Laki-laki</option>
    <option value="P" <?= $user['jenis_kelamin']=='P'?'selected':'' ?>>Perempuan</option>
</select><br><br>

<label>Pilih Event:</label><br>
<select name="event_id" required>
    <option value="1" <?= ($user_event_id == 1 ? 'selected' : '') ?>>CP Today</option>
    <option value="2" <?= ($user_event_id == 2 ? 'selected' : '') ?>>UX Today</option>
    <option value="3" <?= ($user_event_id == 3 ? 'selected' : '') ?>>Hack Today</option>
    <option value="4" <?= ($user_event_id == 4 ? 'selected' : '') ?>>Mine Today</option>
    <option value="5" <?= ($user_event_id == 5 ? 'selected' : '') ?>>Game Today</option>
</select><br><br>



<label>Status Registrasi:</label><br>
<select name="registration_status">
    <option value="verified" <?= ($user['registration_status']=='verified' ? 'selected' : '') ?>>Verified</option>
    <option value="pending" <?= ($user['registration_status']=='pending' ? 'selected' : '') ?>>Pending</option>
    <option value="rejected" <?= ($user['registration_status']=='rejected' ? 'selected' : '') ?>>Rejected</option>
</select>
<br><br>

<label>Ganti KTM:</label><br>
<input type="file" name="ktm_key"><br><br>

<label>Ganti Twibbon:</label><br>
<input type="file" name="twibbon_key"><br><br>

<button type="submit">Update</button>
<a href="user.php">Batal</a>

</form>

<?php exit; ?>
<?php endif; ?>



<div class="container">
<table>
<tr>
    <th>Kode User</th>
    <th>Nama</th>
    <th>Email</th>
    <th>No HP</th>
    <th>Sekolah</th>
    <th>Pendidikan</th>
    <th>Instagram</th>
    <th>Discord</th>
    <th>Line</th>
    <th>Event</th>
    <th>Team</th>
    <th>Gender</th>
    <th>Status</th>
    <th>KTM</th>
    <th>Twibbon</th>
    <th>Aksi</th>
</tr>

<?php foreach($users as $u): ?>
<tr>
    <td><?= $u['user_code'] ?></td>
    <td><?= htmlspecialchars($u['full_name']) ?></td>
    <td><?= $u['email'] ?></td>
    <td><?= $u['phone_number'] ?></td>
    <td><?= $u['nama_sekolah'] ?></td>
    <td><?= $u['pendidikan'] ?></td>
    <td><?= $u['id_instagram'] ?: '-' ?></td>
    <td><?= $u['id_discord'] ?: '-' ?></td>
    <td><?= $u['id_line'] ?: '-' ?></td>
    <td><?= $u['event_title'] ?: '-' ?></td>
    <td><?= $u['team_code'] ?: '-' ?></td>

    <td class="gender"><?= $u['jenis_kelamin'] == 'L' ? '♂' : '♀' ?></td>

    <td>
        <?php
        $st = strtolower($u['registration_status']);
        $badge = $st === 'verified' ? 'green' : ($st === 'pending' ? 'yellow' : 'red');
        ?>
        <span class="status <?= $badge ?>"><?= $u['registration_status'] ?></span>
    </td>

    <td>
        <?php if ($u['ktm_key']): ?>
           <a class="btn-view" href="/it_today/uploads/<?= $u['ktm_key'] ?>" target="_blank">📄 Lihat</a>

        <?php else: ?> - <?php endif; ?>
    </td>

    <td>
        <?php if ($u['twibbon_key']): ?>
           <a class="btn-view" href="/it_today/uploads/<?= $u['twibbon_key'] ?>" target="_blank">🖼️ Lihat</a>
        <?php else: ?> - <?php endif; ?>
    </td>
    <td>
    <a class="btn-view" href="user.php?action=edit&id=<?= $u['user_id'] ?>">✏️ Edit</a>
    &nbsp;
    <a class="btn-view"
       onclick="return confirm('Hapus user ini? Data akan hilang permanen!')"
       href="user.php?action=delete&id=<?= $u['user_id'] ?>">🗑️</a>
</td>

</tr>
<?php endforeach; ?>

</table>
</div>

<br>
<a href="dashboard.php">⬅ Kembali</a>

</body>
</html>
