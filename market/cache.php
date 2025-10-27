<?php
// 市场缓存管理类
class MarketCache {
    private $cache_dir;
    private $default_time = 60; // 默认1分钟缓存
    
    public function __construct() {
        $this->cache_dir = __DIR__ . '/cache/';
        if (!file_exists($this->cache_dir)) {
            mkdir($this->cache_dir, 0755, true);
        }
    }
    
    // 获取缓存文件路径
    private function getCacheFile($key) {
        return $this->cache_dir . md5($key) . '.cache';
    }
    
    // 设置缓存
    public function set($key, $data, $time = null) {
        $file = $this->getCacheFile($key);
        $cache_time = $time ?? $this->default_time;
        $cache_data = [
            'data' => $data,
            'time' => time(),
            'expire' => time() + $cache_time
        ];
        file_put_contents($file, serialize($cache_data), LOCK_EX);
    }
    
    // 获取缓存
    public function get($key) {
        $file = $this->getCacheFile($key);
        if (!file_exists($file)) {
            return null;
        }
        
        $cache_data = unserialize(file_get_contents($file));
        if (time() > $cache_data['expire']) {
            unlink($file);
            return null;
        }
        
        return $cache_data['data'];
    }
    
    // 清除缓存
    public function clear($key = null) {
        if ($key) {
            $file = $this->getCacheFile($key);
            if (file_exists($file)) {
                unlink($file);
            }
        } else {
            // 清除所有缓存
            $files = glob($this->cache_dir . '*.cache');
            foreach ($files as $file) {
                unlink($file);
            }
        }
    }
}
