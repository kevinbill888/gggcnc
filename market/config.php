<?php
// 检查函数是否已存在，避免重复定义
if (!function_exists('get_server_info')) {
    // 获取服务器信息函数
    function get_server_info($server_id) {
        global $servers;
        return isset($servers[$server_id]) ? $servers[$server_id] : null;
    }
}

// 检查函数是否已存在，避免重复定义
if (!function_exists('get_all_servers')) {
    // 获取所有服务器列表
    function get_all_servers() {
        global $servers;
        return $servers;
    }
}

// 检查函数是否已存在，避免重复定义
if (!function_exists('get_available_servers')) {
    // 获取可用的服务器列表（排除维护中的）
    function get_available_servers() {
        global $servers;
        $available = array();
        foreach ($servers as $server) {
            if ($server['status'] != 'maintain') {
                $available[$server['id']] = $server;
            }
        }
        return $available;
    }
}
?>
