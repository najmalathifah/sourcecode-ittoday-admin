<?php
session_start();
if (!isset($_SESSION["admin_logged_in"])) {
    header("Location: ../auth/login.php");
    exit;
}
?>

<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Dashboard Admin</title>
<style>
    body {
        margin: 0;
        padding: 0;
        font-family: 'Inter', sans-serif;
        background: #f4f6f8;
        color: #222;
    }

    header {
        background: #ffffff;
        padding: 18px 30px;
        font-size: 22px;
        font-weight: bold;
        border-bottom: 1px solid #e3e3e3;
    }

    .container {
        padding: 30px;
    }

    h2 {
        margin-bottom: 20px;
        font-weight: 600;
        color: #111;
    }

    .grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
        gap: 20px;
    }

    .card {
        background: #ffffff;
        border-radius: 12px;
        padding: 22px;
        text-decoration: none;
        color: #333;
        font-size: 16px;
        font-weight: 500;
        box-shadow: 0px 4px 12px rgba(0,0,0,0.06);
        display: flex;
        align-items: center;
        gap: 14px;
        transition: 0.15s ease-in-out;
    }

    .card:hover {
        transform: translateY(-4px);
        box-shadow: 0px 8px 18px rgba(0,0,0,0.08);
    }

    .icon {
        font-size: 26px;
    }

    footer {
        margin-top: 40px;
        text-align: center;
        font-size: 14px;
        color: #777;
    }

    .logout {
        float: right;
        font-size: 14px;
        margin-top: -5px;
        padding: 6px 14px;
        background: #ff4b4b;
        color: #fff;
        border-radius: 8px;
        text-decoration: none;
        transition: .15s;
    }
    .logout:hover { background: #ff2e2e; }

</style>
</head>
<body>

<header>
    Dashboard Admin
    <a href="../auth/logout.php" class="logout">Logout</a>
</header>

<div class="container">
    <h2>Menu Utama</h2>

    <div class="grid">

        <a href="user.php" class="card">
            <span class="icon">👥</span> Kelola User
        </a>

        <a href="team.php" class="card">
            <span class="icon">🧑‍🤝‍🧑</span> Kelola Team
        </a>

        <a href="event.php" class="card">
            <span class="icon">🎪</span> Kelola Event
        </a>

        <a href="submission.php" class="card">
            <span class="icon">📂</span> Submission
        </a>

        <a href="announcement.php" class="card">
            <span class="icon">📢</span> Announcement
        </a>

    </div>
</div>

<footer>
    IT Today Admin © <?= date('Y') ?>
</footer>

</body>
</html>
