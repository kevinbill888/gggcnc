<?php
require_once 'config.php';
require_once 'db.php';

// 简单的身份验证（实际使用时应该更安全）
session_start();
if (!isset($_SESSION['admin_logged'])) {
    // 可以添加简单的密码验证
    if ($_POST['password'] == 'admin123') {
        $_SESSION['admin_logged'] = true;
    } else {
        ?>
        <!DOCTYPE html>
        <html>
        <head>
            <title>管理员登录</title>
            <style>
                body { font-family: Arial; background: #f5f5f5; display: flex; justify-content: center; align-items: center; height: 100vh; }
                .login { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
                input { padding: 10px; margin: 10px 0; width: 200px; }
                button { padding: 10px 20px; background: #007bff; color: white; border: none; cursor: pointer; }
            </style>
        </head>
        <body>
            <div class="login">
                <h2>管理员登录</h2>
                <form method="post">
                    <input type="password" name="password" placeholder="输入密码" required>
                    <button type="submit">登录</button>
                </form>
            </div>
        </body>
        </html>
        <?php
        exit;
    }
}

// 处理搜索
$where = "1=1";
$params = array();

if (!empty($_GET['search'])) {
    $search = trim($_GET['search']);
    if (is_numeric($search)) {
        $where .= " AND PayNo LIKE ?";
        $params[] = "%$search%";
    } else {
        $where .= " AND UserName LIKE ?";
        $params[] = "%$search%";
    }
}

if (!empty($_GET['status']) && $_GET['status'] != '') {
    $where .= " AND trade_status = ?";
    $params[] = intval($_GET['status']);
}

if (!empty($_GET['date_start'])) {
    $where .= " AND PayTime >= ?";
    $params[] = $_GET['date_start'] . ' 00:00:00';
}

if (!empty($_GET['date_end'])) {
    $where .= " AND PayTime <= ?";
    $params[] = $_GET['date_end'] . ' 23:59:59';
}

// 分页
$page = max(1, intval($_GET['page'] ?? 1));
$pageSize = 20;
$offset = ($page - 1) * $pageSize;

// 获取总记录数
$total = $db->query("SELECT COUNT(*) as count FROM PayLog WHERE $where", $params)->fetch(PDO::FETCH_ASSOC)['count'];
$totalPages = ceil($total / $pageSize);

// 获取订单列表
$orders = $db->query("SELECT TOP $pageSize * FROM PayLog WHERE $where ORDER BY ID DESC OFFSET $offset ROWS", $params)->fetchAll(PDO::FETCH_ASSOC);

// 统计数据
$stats = $db->query("
    SELECT 
        COUNT(*) as total_orders,
        SUM(CASE WHEN trade_status = 1 THEN Amount ELSE 0 END) as success_amount,
        SUM(CASE WHEN trade_status = 0 THEN Amount ELSE 0 END) as pending_amount,
        SUM(Amount) as total_amount
    FROM PayLog WHERE $where
", $params)->fetch(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>充值订单管理</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .header { background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 10px; text-align: center; }
        .stat-value { font-size: 24px; font-weight: bold; color: #007bff; }
        .stat-label { color: #666; margin-top: 5px; }
        .search-form { background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .search-form form { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; align-items: end; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
        .form-group input, .form-group select { padding: 8px; width: 100%; border: 1px solid #ddd; border-radius: 5px; }
        .btn { padding: 8px 20px; background: #007bff; color: white; border: none; border-radius: 5px; cursor: pointer; }
        .btn:hover { background: #0056b3; }
        .orders-table { background: white; border-radius: 10px; overflow: hidden; }
        .table { width: 100%; border-collapse: collapse; }
        .table th, .table td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
        .table th { background: #f8f9fa; font-weight: bold; }
        .table tr:hover { background: #f8f9fa; }
        .status { padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; }
        .status.success { background: #d4edda; color: #155724; }
        .status.pending { background: #fff3cd; color: #856404; }
        .status.failed { background: #f8d7da; color: #721c24; }
        .pagination { display: flex; justify-content: center; gap: 10px; margin-top: 20px; }
        .pagination a, .pagination span { padding: 8px 12px; border: 1px solid #ddd; border-radius: 5px; text-decoration: none; }
        .pagination a:hover { background: #007bff; color: white; }
        .pagination .current { background: #007bff; color: white; }
        .logout { background: #dc3545; }
        .logout:hover { background: #c82333; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><i class="fas fa-chart-line"></i> 充值订单管理</h1>
            <a href="?logout=1" class="btn logout"><i class="fas fa-sign-out-alt"></i> 退出</a>
        </div>

        <!-- 统计数据 -->
        <div class="stats">
            <div class="stat-card">
                <div class="stat-value"><?php echo $stats['total_orders']; ?></div>
                <div class="stat-label">总订单数</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">￥<?php echo number_format($stats['total_amount'], 2); ?></div>
                <div class="stat-label">总金额</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">￥<?php echo number_format($stats['success_amount'], 2); ?></div>
                <div class="stat-label">成功金额</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">￥<?php echo number_format($stats['pending_amount'], 2); ?></div>
                <div class="stat-label">待支付金额</div>
            </div>
        </div>

        <!-- 搜索表单 -->
        <div class="search-form">
            <form method="get">
                <div class="form-group">
                    <label>搜索</label>
                    <input type="text" name="search" value="<?php echo htmlspecialchars($_GET['search'] ?? ''); ?>" placeholder="订单号或用户名">
                </div>
                <div class="form-group">
                    <label>状态</label>
                    <select name="status">
                        <option value="">全部</option>
                        <option value="0" <?php echo ($_GET['status'] ?? '') == '0' ? 'selected' : ''; ?>>待支付</option>
                        <option value="1" <?php echo ($_GET['status'] ?? '') == '1' ? 'selected' : ''; ?>>成功</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>开始日期</label>
                    <input type="date" name="date_start" value="<?php echo htmlspecialchars($_GET['date_start'] ?? ''); ?>">
                </div>
                <div class="form-group">
                    <label>结束日期</label>
                    <input type="date" name="date_end" value="<?php echo htmlspecialchars($_GET['date_end'] ?? ''); ?>">
                </div>
                <div class="form-group">
                    <button type="submit" class="btn"><i class="fas fa-search"></i> 搜索</button>
                </div>
            </form>
        </div>

        <!-- 订单列表 -->
        <div class="orders-table">
            <table class="table">
                <thead>
                    <tr>
                        <th>订单号</th>
                        <th>用户名</th>
                        <th>金额</th>
                        <th>游戏币</th>
                        <th>赠送</th>
                        <th>支付方式</th>
                        <th>状态</th>
                        <th>支付时间</th>
                        <th>IP</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($orders as $order): ?>
                        <tr>
                            <td><?php echo htmlspecialchars($order['PayNo']); ?></td>
                            <td><?php echo htmlspecialchars($order['UserName']); ?></td>
                            <td>￥<?php echo number_format($order['Amount'], 2); ?></td>
                            <td><?php echo number_format($order['GameCash']); ?></td>
                            <td><?php echo number_format($order['GivecCash']); ?></td>
                            <td><?php echo $order['servicer'] == 'alipay' ? '<i class="fab fa-alipay"></i> 支付宝' : htmlspecialchars($order['servicer']); ?></td>
                            <td>
                                <?php if ($order['trade_status'] == 1): ?>
                                    <span class="status success">成功</span>
                                <?php elseif ($order['trade_status'] == 0): ?>
                                    <span class="status pending">待支付</span>
                                <?php else: ?>
                                    <span class="status failed">失败</span>
                                <?php endif; ?>
                            </td>
                            <td><?php echo $order['PayTime']; ?></td>
                            <td><?php echo htmlspecialchars($order['PayIP']); ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>

        <!-- 分页 -->
        <div class="pagination">
            <?php if ($page > 1): ?>
                <a href="?<?php echo http_build_query(array_merge($_GET, ['page' => $page - 1])); ?>">上一页</a>
            <?php endif; ?>
            
            <?php for ($i = max(1, $page - 5); $i <= min($totalPages, $page + 5); $i++): ?>
                <?php if ($i == $page): ?>
                    <span class="current"><?php echo $i; ?></span>
                <?php else: ?>
                    <a href="?<?php echo http_build_query(array_merge($_GET, ['page' => $i])); ?>"><?php echo $i; ?></a>
                <?php endif; ?>
            <?php endfor; ?>
            
            <?php if ($page < $totalPages): ?>
                <a href="?<?php echo http_build_query(array_merge($_GET, ['page' => $page + 1])); ?>">下一页</a>
            <?php endif; ?>
        </div>
    </div>

    <?php if (isset($_GET['logout'])): ?>
        <?php session_destroy(); ?>
        <script>window.location.href = '?';</script>
    <?php endif; ?>
</body>
</html>
