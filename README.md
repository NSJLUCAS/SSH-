# SSH 安全快速命令工具箱

## 安装
```bash
wget https://raw.githubusercontent.com/NSJLUCAS/ssh-security-toolbox/main/installer.sh
chmod +x installer.sh
sudo ./installer.sh

#卸载
# 1. 删除工具脚本
sudo rm -f /usr/local/bin/n

# 2. 清理 /etc/profile 中添加的 PATH 导出（删除包含 /usr/local/bin 的那一行）
sudo sed -i '\|/usr/local/bin|d' /etc/profile

# 3. 立即生效（或重启）
source /etc/profile

echo "✅ 已成功卸载 SSH 安全快速命令工具箱（命令 n 已移除）。"
