#!/bin/sh
set -e

# 设置 WEB_PORT 默认值
export WEB_PORT=${WEB_PORT:-80}

echo "Starting CDT-Monitor..."
echo "Web port: $WEB_PORT"

# 0. 渲染 Nginx 配置模板
# 使用 envsubst 仅替换 ${WEB_PORT}，保留 Nginx 自有的 $variable 不被误替换
envsubst '${WEB_PORT}' < /etc/nginx/http.d/default.conf.template > /etc/nginx/http.d/default.conf

# 1. 确保数据目录权限正确
# Docker 挂载卷时可能会导致权限归属为 root，这里强制修正为 www-data
if [ -d "/var/www/html/data" ]; then
    chown -R www-data:www-data /var/www/html/data
fi

# 2. 启动 Cron 服务 (后台运行)
# Alpine 使用 dcron，-b 表示后台运行，-L 指定日志级别
crond -b -l 8
echo "Cron daemon started."

# 3. 启动 PHP-FPM (后台运行)
# -D 表示 Daemonize (守护进程模式)
php-fpm -D
echo "PHP-FPM started."

# 4. 启动 Nginx (前台运行)
# 保持 Nginx 在前台运行作为容器主进程，防止容器退出
echo "Nginx started."
exec nginx -g 'daemon off;'
