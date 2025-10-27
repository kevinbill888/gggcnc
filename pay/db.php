<?php
require_once 'config.php';

class Database {
    private static $connections = array();
    private $db_name;
    
    public function __construct($db_name = 'account') {
        $this->db_name = $db_name;
        
        // 如果连接不存在，创建新连接
        if (!isset(self::$connections[$db_name])) {
            $this->connect($db_name);
        }
    }
    
    private function connect($db_name) {
        global $db_configs;
        
        if (!isset($db_configs[$db_name])) {
            throw new Exception("数据库配置 '$db_name' 不存在");
        }
        
        $config = $db_configs[$db_name];
        
        try {
            // SQL Server 连接
            $dsn = "sqlsrv:Server={$config['host']};Database={$config['name']}";
            $conn = new PDO($dsn, $config['user'], $config['pass']);
            
            // 设置错误模式
            $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $conn->setAttribute(PDO::SQLSRV_ATTR_ENCODING, PDO::SQLSRV_ENCODING_UTF8);
            
            self::$connections[$db_name] = $conn;
            
        } catch(PDOException $e) {
            die("连接数据库 '$db_name' 失败: " . $e->getMessage());
        }
    }
    
    public function getConnection() {
        return self::$connections[$this->db_name];
    }
    
    public function query($sql, $params = array()) {
        try {
            $stmt = $this->getConnection()->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch(PDOException $e) {
            die("查询失败 [{$this->db_name}]: " . $e->getMessage() . "<br>SQL: " . $sql);
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
            die("执行失败 [{$this->db_name}]: " . $e->getMessage());
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

// 创建不同数据库的实例
$db_account = new Database('account');
$db_cash = new Database('cash');
$db_character = new Database('character');

// 为了向后兼容，创建默认的 $db 变量
$db = $db_account;
?>
