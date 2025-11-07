<?php
// api.php — Minimal PHP backend for ecommerce_db schema

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

// ---- CONFIG ----
// Update these to your local DB credentials
$DB_HOST = '127.0.0.1';
$DB_NAME = 'ecommerce_db';
$DB_USER = 'root';
$DB_PASS = ''; // set your password

// ---- UTIL ----
function json_body() {
  $raw = file_get_contents('php://input');
  $d = json_decode($raw, true);
  return is_array($d) ? $d : [];
}
function respond($data, $code=200) { http_response_code($code); echo json_encode($data); exit; }
function fail($msg, $code=400) { respond(['error'=>$msg], $code); }

try {
  $pdo = new PDO("mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4", $DB_USER, $DB_PASS, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  ]);
} catch (Exception $e) { fail('DB connection failed: '.$e->getMessage(), 500); }

$action = $_GET['action'] ?? '';

// Very light auth emulation (JWT is out of scope for single-file demo)
function get_auth_user($pdo) {
  $h = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
  if (!str_starts_with($h, 'Bearer ')) return null;
  $token = substr($h, 7);
  // For demo, token is "user:{user_id}"
  if (!str_starts_with($token, 'user:')) return null;
  $uid = intval(substr($token, 5));
  $st = $pdo->prepare("SELECT user_id, username, email, created_at FROM users WHERE user_id = ?");
  $st->execute([$uid]);
  return $st->fetch() ?: null;
}

// ---- ROUTES ----

if ($action === 'get_categories') {
  $rows = $pdo->query("SELECT category_id, category_name FROM categories ORDER BY category_name")->fetchAll();
  respond($rows);
}

if ($action === 'get_products') {
  $q = $_GET['q'] ?? '';
  $category_id = $_GET['category_id'] ?? '';
  $sql = "
    SELECT p.product_id, p.product_name, p.description, p.price, p.stock,
           c.category_name,
           (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.product_id LIMIT 1) AS image_url
    FROM products p
    LEFT JOIN categories c ON c.category_id = p.category_id
    WHERE 1=1
  ";
  $params = [];
  if ($q !== '') { $sql .= " AND (p.product_name LIKE ? OR p.description LIKE ?)"; $params[]="%$q%"; $params[]="%$q%"; }
  if ($category_id !== '') { $sql .= " AND p.category_id = ?"; $params[] = $category_id; }
  $sql .= " ORDER BY p.product_id DESC LIMIT 200";
  $st = $pdo->prepare($sql); $st->execute($params);
  respond($st->fetchAll());
}

if ($action === 'get_or_create_cart') {
  $b = json_body();
  $user_id = intval($b['user_id'] ?? 0);
  if ($user_id <= 0) fail('user_id required');
  // Find cart
  $st = $pdo->prepare("SELECT cart_id FROM cart WHERE user_id = ? LIMIT 1");
  $st->execute([$user_id]);
  $row = $st->fetch();
  if ($row) respond(['cart_id'=>$row['cart_id']]);
  // Create
  $st = $pdo->prepare("INSERT INTO cart (user_id) VALUES (?)");
  $st->execute([$user_id]);
  respond(['cart_id'=>$pdo->lastInsertId()]);
}

if ($action === 'get_cart') {
  $user_id = intval($_GET['user_id'] ?? 0);
  $cart_id = null;
  if ($user_id > 0) {
    $st = $pdo->prepare("SELECT cart_id FROM cart WHERE user_id = ? LIMIT 1");
    $st->execute([$user_id]);
    $r = $st->fetch();
    $cart_id = $r['cart_id'] ?? null;
  }
  if (!$cart_id) {
    // fallback to the seeded cart 1
    $cart_id = 1;
  }
  // Items and total
  $items = $pdo->prepare("
    SELECT ci.cart_item_id, ci.quantity, p.product_name, p.price
    FROM cart_items ci
    JOIN products p ON p.product_id = ci.product_id
    WHERE ci.cart_id = ?
    ORDER BY ci.cart_item_id DESC
  ");
  $items->execute([$cart_id]);
  $rows = $items->fetchAll();
  $total = 0.0;
  foreach ($rows as $r) { $total += floatval($r['price']) * intval($r['quantity']); }
  respond(['cart_id'=>$cart_id, 'items'=>$rows, 'total'=>$total]);
}

if ($action === 'add_to_cart') {
  $b = json_body();
  $cart_id = intval($b['cart_id'] ?? 0);
  $product_id = intval($b['product_id'] ?? 0);
  $quantity = max(1, intval($b['quantity'] ?? 1));
  if ($cart_id<=0 || $product_id<=0) fail('cart_id and product_id required');

  // Merge if same product already in cart
  $st = $pdo->prepare("SELECT cart_item_id, quantity FROM cart_items WHERE cart_id=? AND product_id=?");
  $st->execute([$cart_id, $product_id]);
  $row = $st->fetch();
  if ($row) {
    $newq = $row['quantity'] + $quantity;
    $up = $pdo->prepare("UPDATE cart_items SET quantity=? WHERE cart_item_id=?");
    $up->execute([$newq, $row['cart_item_id']]);
    respond(['cart_item_id'=>$row['cart_item_id'], 'quantity'=>$newq]);
  } else {
    $ins = $pdo->prepare("INSERT INTO cart_items (cart_id, product_id, quantity) VALUES (?, ?, ?)");
    $ins->execute([$cart_id, $product_id, $quantity]);
    respond(['cart_item_id'=>$pdo->lastInsertId(), 'quantity'=>$quantity]);
  }
}

if ($action === 'update_cart_item') {
  $b = json_body();
  $cart_item_id = intval($b['cart_item_id'] ?? 0);
  $quantity = intval($b['quantity'] ?? 0);
  if ($cart_item_id<=0 || $quantity<=0) fail('valid cart_item_id and quantity required');
  $up = $pdo->prepare("UPDATE cart_items SET quantity=? WHERE cart_item_id=?");
  $up->execute([$quantity, $cart_item_id]);
  respond(['ok'=>true]);
}

if ($action === 'remove_cart_item') {
  $b = json_body();
  $cart_item_id = intval($b['cart_item_id'] ?? 0);
  if ($cart_item_id<=0) fail('cart_item_id required');
  $del = $pdo->prepare("DELETE FROM cart_items WHERE cart_item_id=?");
  $del->execute([$cart_item_id]);
  respond(['ok'=>true]);
}

if ($action === 'checkout') {
  $b = json_body();
  $user_id = intval($b['user_id'] ?? 0);
  if ($user_id<=0) fail('Login required', 403);

  // Ensure user has a cart
  $st = $pdo->prepare("SELECT cart_id FROM cart WHERE user_id = ? LIMIT 1");
  $st->execute([$user_id]);
  $row = $st->fetch();
  if (!$row) fail('No cart for user');
  // Call stored procedure place_order(userId)
  $pdo->exec("CALL place_order($user_id)");
  respond(['message'=>'order placed']);
}

if ($action === 'login') {
  $b = json_body();
  $username = trim($b['username'] ?? '');
  $password = trim($b['password'] ?? '');
  if ($username==='' || $password==='') fail('username and password required');
  $st = $pdo->prepare("SELECT user_id, username, email, password FROM users WHERE username=? LIMIT 1");
  $st->execute([$username]);
  $u = $st->fetch();
  if (!$u || $u['password'] !== $password) fail('invalid credentials', 401);
  // Demo token "user:{id}"
  $token = 'user:' . $u['user_id'];
  respond(['token'=>$token, 'user'=>['user_id'=>$u['user_id'], 'username'=>$u['username'], 'email'=>$u['email']]]);
}

if ($action === 'register') {
  $b = json_body();
  $username = trim($b['username'] ?? '');
  $email = trim($b['email'] ?? '');
  $password = trim($b['password'] ?? '');
  if ($username==='' || $email==='' || $password==='') fail('all fields required');
  // basic uniqueness check
  $st = $pdo->prepare("SELECT user_id FROM users WHERE username=? OR email=? LIMIT 1");
  $st->execute([$username, $email]);
  if ($st->fetch()) fail('username or email already exists');
  $ins = $pdo->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
  $ins->execute([$username, $email, $password]); // For demo only: plaintext
  // create a cart for this user
  $uid = $pdo->lastInsertId();
  $pdo->prepare("INSERT INTO cart (user_id) VALUES (?)")->execute([$uid]);
  respond(['ok'=>true, 'user_id'=>$uid], 201);
}

// Fallback
fail('Unknown action', 404);
