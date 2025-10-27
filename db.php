<?php
// 强制加载配置文件，使用绝对路径
$config_file = __DIR__ . '/config.php';
if (!defined('CONFIG_LOADED')) {
    require_once $config_file;
    define('CONFIG_LOADED', true);
}

// 确保配置已加载
if (!isset($servers) || empty($servers)) {
    die("配置加载失败：\$servers 变量未定义");
}


class Database {
    private static $connections = array();
    private $server_id;
    private $db_type;
    
    public function __construct($server_id, $db_type = 'account') {
        $this->server_id = $server_id;
        $this->db_type = $db_type;
        
        // 生成连接键
        $connection_key = $server_id . '_' . $db_type;
        
        // 如果连接不存在，创建新连接
        if (!isset(self::$connections[$connection_key])) {
            $this->connect($server_id, $db_type, $connection_key);
        }
    }
    
    private function connect($server_id, $db_type, $connection_key) {
        $server = get_server_info($server_id);
        
        if (!$server) {
            throw new Exception("服务器 '$server_id' 不存在");
        }
        
        // 根据db_type获取数据库名
        $db_name = $server['db_' . $db_type];
        
        // 安全获取数据库用户名和密码
        $db_user = isset($server['user']) ? $server['user'] : 'sa';
        $db_pass = isset($server['pass']) ? $server['pass'] : 'zzgm99w4$1';
        
        try {
            // SQL Server 连接
            $dsn = "sqlsrv:Server={$server['host']};Database={$db_name}";
            $conn = new PDO($dsn, $db_user, $db_pass, array(
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::SQLSRV_ATTR_ENCODING => PDO::SQLSRV_ENCODING_UTF8
            ));
            
            self::$connections[$connection_key] = $conn;
            
        } catch(PDOException $e) {
            // 提供更详细的错误信息，但隐藏敏感信息
            $safe_host = str_replace(',', ':', $server['host']);
            die("连接服务器 {$server['name']} 的 {$db_type} 数据库失败: " . $e->getMessage() . 
                "<br>连接信息: {$safe_host} -> {$db_name} (用户: " . substr($db_user, 0, 2) . "***)");
        }
    }
    
    public function getConnection() {
        $connection_key = $this->server_id . '_' . $this->db_type;
        return self::$connections[$connection_key];
    }
    
    // 添加 prepare() 方法
    public function prepare($sql) {
        return $this->getConnection()->prepare($sql);
    }
    
    public function query($sql, $params = array()) {
        try {
            $stmt = $this->getConnection()->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch(PDOException $e) {
            $server = get_server_info($this->server_id);
            die("查询失败 [服务器: {$server['name']}, 数据库: {$this->db_type}]: " . $e->getMessage() . "<br>SQL: " . $sql);
        }
    }
    
    public function insert($table, $data) {
        $columns = implode(',', array_keys($data));
        $placeholders = implode(',', array_fill(0, count($data), '?'));
        $sql = "INSERT INTO $table ($columns) VALUES ($placeholders)";
        $this->query($sql, array_values($data));
        return $this->getConnection()->lastInsertId();
    }
    
    public function update($table, $data, $where, $whereParams = array()) {
        $setParts = array();
        foreach ($data as $column => $value) {
            $setParts[] = "$column = ?";
        }
        $setClause = implode(',', $setParts);
        $sql = "UPDATE $table SET $setClause WHERE $where";
        $params = array_merge(array_values($data), $whereParams);
        return $this->query($sql, $params);
    }
    
    public function fetchAll($sql, $params = array()) {
        $stmt = $this->query($sql, $params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function fetch($sql, $params = array()) {
        $stmt = $this->query($sql, $params);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    public function exec($sql, $params = array()) {
        try {
            $stmt = $this->getConnection()->prepare($sql);
            return $stmt->execute($params);
        } catch(PDOException $e) {
            $server = get_server_info($this->server_id);
            die("执行失败 [服务器: {$server['name']}, 数据库: {$this->db_type}]: " . $e->getMessage());
        }
    }
    
    // 开始事务
    public function beginTransaction() {
        return $this->getConnection()->beginTransaction();
    }
    
    // 提交事务
    public function commit() {
        return $this->getConnection()->commit();
    }
    
    // 回滚事务
    public function rollBack() {
        return $this->getConnection()->rollBack();
    }
}

// 获取数据库连接的辅助函数
function get_db($server_id, $db_type = 'account') {
    return new Database($server_id, $db_type);
}

// 为了向后兼容，创建默认的数据库实例（使用默认服务器）
$default_server_id = defined('DEFAULT_SERVER_ID') ? DEFAULT_SERVER_ID : '1';
$db_account = new Database($default_server_id, 'account');
$db_cash = new Database($default_server_id, 'cash');
$db_character = new Database($default_server_id, 'character');
$db = $db_account;
?>
