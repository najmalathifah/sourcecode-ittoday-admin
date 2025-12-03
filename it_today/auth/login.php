<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

session_start();
require_once "../config/db.php";

$error = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = $_POST["email"];
    $password = md5($_POST["password"]);

    $stmt = $pdo->prepare("
        SELECT u.user_id, u.full_name
        FROM admin.user_identity ui
        JOIN admin.\"User\" u ON ui.user_id = u.user_id
        WHERE ui.email = :email AND ui.hash = :password
        LIMIT 1
    ");
    $stmt->execute([":email" => $email, ":password" => $password]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $_SESSION["admin_logged_in"] = true;
        $_SESSION["admin_id"] = $user["user_id"];
        $_SESSION["admin_name"] = $user["full_name"];

        header("Location: ../admin/dashboard.php");

        exit;
    } else {
        $error = "Email atau password salah!";
    }
}
?>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Login Admin - IT Today</title>
</head>
<body>

<h2>Login Admin</h2>

<?php if(!empty($error)) : ?>
    <p style="color:red;"><?= $error ?></p>
<?php endif; ?>

<form method="POST">
    <label>Email:</label><br>
    <input type="email" name="email" required><br><br>

    <label>Password:</label><br>
    <input type="password" name="password" required><br><br>

    <button type="submit">Login</button>
</form>

</body>
</html>