#!/bin/bash
# SSH 安全快速命令工具箱 - 通用版（含自更新 & 暂停功能）
# 适用 Debian / Ubuntu 系统
# 请将 GITHUB_USER 改成你的 GitHub 用户名

GITHUB_USER="NSJLUCAS"
REPO="ssh-security-toolbox"
RAW_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main"

# 检查并安装软件包函数
ensure_pkg() {
    local cmd=$1 pkg=$2
    if ! command -v "$cmd" &> /dev/null; then
        echo "检测到缺少命令 '$cmd'，正在安装 ${pkg}..."
        apt update && apt install -y "$pkg"
    fi
}

# 预检查常用依赖
ensure_pkg journalctl systemd
ensure_pkg iptables iptables
ensure_pkg fail2ban fail2ban
ensure_pkg netfilter-persistent iptables-persistent
ensure_pkg wget wget

while true; do
    clear
    echo "============================================"
    echo "🧰 SSH 安全快速命令工具箱"
    echo "============================================"
    echo " 1) 安装或更新 Fail2Ban（自动封禁爆破IP）"
    echo " 2) 查看爆破来源 IP（前20）"
    echo " 3) 查看被爆破用户名（前20）"
    echo " 4) 统计 SSH 登录失败总次数"
    echo " 5) 实时查看 SSH 爆破日志"
    echo " 6) 手动封禁某个 IP"
    echo " 7) 保存防火墙规则"
    echo " 8) 查看 Fail2Ban 封禁状态"
    echo " 9) 查看已封禁的 IP（iptables）"
    echo "10) 清空所有 iptables 规则（危险！）"
    echo "11) 查看 Fail2Ban 封禁 IP（仅 IP 列表）"
    echo "12) 更新脚本到最新版本"
    echo " 0) 退出"
    echo "============================================"
    read -p "输入数字选择功能: " choice

    case "$choice" in
        1)
            echo
            echo ">>> 安装/更新 Fail2Ban..."
            apt update && apt install -y fail2ban
            ;;
        2)
            echo
            echo ">>> 爆破来源 IP 排名前20："
            journalctl -u ssh.service \
              | grep 'Failed password' \
              | awk '{print $(NF-3)}' \
              | sort | uniq -c | sort -nr \
              | head -20
            ;;
        3)
            echo
            echo ">>> 被爆破用户名 排名前20："
            journalctl -u ssh.service \
              | grep 'Failed password' \
              | awk '{print $(NF-5)}' \
              | sort | uniq -c | sort -nr \
              | head -20
            ;;
        4)
            echo
            echo ">>> SSH 登录失败总次数："
            journalctl -u ssh.service | grep 'Failed password' | wc -l
            ;;
        5)
            echo
            echo ">>> 实时查看 SSH 爆破日志（Ctrl+C 结束）"
            journalctl -u ssh.service -f | grep 'Failed password'
            ;;
        6)
            echo
            read -p "请输入需要封禁的 IP: " banip
            ensure_pkg iptables iptables
            iptables -A INPUT -s "$banip" -j DROP && echo "已封禁 $banip"
            ;;
        7)
            echo
            echo ">>> 保存防火墙规则..."
            ensure_pkg netfilter-persistent iptables-persistent
            netfilter-persistent save && echo "规则已保存"
            ;;
        8)
            echo
            echo ">>> Fail2Ban SSH jail 状态："
            ensure_pkg fail2ban fail2ban
            fail2ban-client status sshd
            ;;
        9)
            echo
            echo ">>> 当前已封禁的 IP（iptables）："
            ensure_pkg iptables iptables
            iptables -L INPUT -n --line-numbers | grep DROP
            ;;
        10)
            echo
            echo ">>> ⚠️ 此操作将清空所有 iptables 规则，确认请按 y："
            read -p "[y/N] " confirm
            if [ "$confirm" = "y" ]; then
                ensure_pkg iptables iptables
                iptables -F
                ensure_pkg netfilter-persistent iptables-persistent
                netfilter-persistent save
                echo "所有规则已清空并保存。"
            else
                echo "操作已取消"
            fi
            ;;
        11)
            echo
            echo ">>> Fail2Ban 当前封禁 IP 列表："
            ensure_pkg fail2ban fail2ban
            fail2ban-client status sshd \
              | grep 'Banned IP list' \
              | awk -F: '{print $2}'
            ;;
        12)
            echo
            echo ">>> 正在更新脚本到最新版本…"
            wget "${RAW_URL}/installer.sh" -O /tmp/installer.sh \
              && chmod +x /tmp/installer.sh \
              && bash /tmp/installer.sh \
              && rm -f /tmp/installer.sh
            echo "✅ 更新完成，请重新登录或执行 'source /etc/profile' 后输入 'n' 运行"
            exit 0
            ;;
        0)
            echo
            echo "已退出。"
            exit 0
            ;;
        *)
            echo
            echo "无效选择，请重新输入。"
            ;;
    esac

    # 每次操作后暂停，等用户按键
    echo
    read -n1 -r -p "按任意键返回主菜单…" key
done
