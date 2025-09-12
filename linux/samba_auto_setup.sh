#!/bin/bash
# 说明：Ubuntu系统专用Samba服务自动安装配置脚本
# 运行方式：bash samba_auto_setup.sh（脚本内会提示切换su）

# 1. 检查是否以root权限运行，未使用则提示切换su
if [ "$(id -u)" -ne 0 ]; then
    echo "提示：当前未使用root权限，将为你切换到su用户（默认密码：admin123）"
    # 提示输入su密码并切换，若密码错误则退出
    if ! su -c "echo '✅ 成功切换到root用户'" > /dev/null 2>&1; then
        echo "错误：su密码输入错误，无法获取root权限，脚本终止！"
        exit 1
    fi
    # 切换root后重新执行脚本，确保后续操作均为root权限
    exec su -c "bash $0"
fi

# 2. 定义变量（按需求修改默认值）
SHARE_NAME="5GC_1"                     # Windows访问时显示的共享名称（默认改为5GC_1）
SHARE_DIR="/home/$(logname)/"          # 共享目录路径（默认改为当前用户家目录）
SAMBA_USER=$(logname)                  # Samba用户（默认使用当前登录的Ubuntu用户）

# 3. 更新软件源并安装Samba
echo -e "\n=== 1/5：更新软件源并安装Samba ==="
apt update -y > /dev/null 2>&1
apt install samba samba-common -y > /dev/null 2>&1

# 检查Samba安装是否成功
if ! command -v smbd &> /dev/null; then
    echo "错误：Samba安装失败，请检查网络或软件源！"
    exit 1
fi
echo "✅ Samba安装完成"

# 4. 确认共享目录（家目录默认存在，无需创建，仅设置权限）
echo -e "\n=== 2/5：配置共享目录权限 ==="
# 检查家目录是否存在（正常情况下用户家目录必然存在）
if [ -d "$SHARE_DIR" ]; then
    # 设置家目录权限（确保Samba用户有读写权限）
    chown "$SAMBA_USER:$SAMBA_USER" "$SHARE_DIR"
    chmod 775 "$SHARE_DIR"
    echo "✅ 共享目录 $SHARE_DIR 权限配置完成"
else
    echo "错误：共享目录 $SHARE_DIR 不存在（用户家目录异常），脚本终止！"
    exit 1
fi

# 5. 备份并修改Samba配置文件
echo -e "\n=== 3/5：配置Samba共享参数 ==="
# 备份原配置文件（仅首次备份，避免重复覆盖）
if [ ! -f "/etc/samba/smb.conf.bak" ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
    echo "✅ Samba原配置文件已备份为 /etc/samba/smb.conf.bak"
fi

# 向smb.conf末尾添加共享配置（先删除旧的同名共享配置，避免冲突）
sed -i "/\[$SHARE_NAME\]/,/^$/d" /etc/samba/smb.conf
cat << EOF | tee -a /etc/samba/smb.conf > /dev/null
# 自动配置的Samba共享（$(date +%Y-%m-%d)）
[$SHARE_NAME]
    path = $SHARE_DIR
    guest ok = no
    writable = yes
    browseable = yes
    create mask = 0775
    directory mask = 0775
    valid users = $SAMBA_USER
EOF
echo "✅ Samba共享配置添加完成"

# 6. 添加Samba用户并设置密码
echo -e "\n=== 4/5：添加Samba用户并设置密码 ==="
# 检查用户是否已存在于Samba用户列表
if ! pdbedit -L | grep -q "$SAMBA_USER"; then
    echo "请为Samba用户 $SAMBA_USER 设置密码（用于Windows访问）："
    smbpasswd -a "$SAMBA_USER"
    # 启用Samba用户（确保用户处于活跃状态）
    smbpasswd -e "$SAMBA_USER" > /dev/null 2>&1
    echo "✅ Samba用户 $SAMBA_USER 添加并启用完成"
else
    echo "ℹ️  Samba用户 $SAMBA_USER 已存在，跳过添加（若需修改密码，执行 smbpasswd $SAMBA_USER）"
fi

# 7. 重启Samba服务并开放防火墙端口
echo -e "\n=== 5/5：启动服务并配置防火墙 ==="
# 重启Samba服务
systemctl restart smbd > /dev/null 2>&1
systemctl enable smbd > /dev/null 2>&1
# 检查服务状态
if systemctl is-active --quiet smbd; then
    echo "✅ Samba服务（smbd）已启动并设置开机自启"
else
    echo "错误：Samba服务启动失败，请执行 systemctl status smbd 查看原因！"
    exit 1
fi

# 开放防火墙端口（139、445）
ufw allow 139/tcp > /dev/null 2>&1
ufw allow 445/tcp > /dev/null 2>&1
ufw reload > /dev/null 2>&1
echo "✅ 防火墙已开放Samba所需端口（139/tcp、445/tcp）"

# 8. 输出配置完成信息
echo -e "\n======================================"
echo "🎉 Samba自动配置全部完成！"
echo -e "\n【访问信息】"
echo "1. Ubuntu共享目录路径：$SHARE_DIR"
echo "2. Windows访问地址：\\\$(hostname -I | awk '{print \$1}')\\$SHARE_NAME"
echo "3. 登录用户：$SAMBA_USER"
echo "4. 登录密码：你刚才设置的Samba密码"
echo -e "\n【Windows访问方法】"
echo "   - 按 Win+R，输入访问地址（如 \\\\192.168.10.100\\$SHARE_NAME）"
echo "   - 输入用户名和密码即可访问"
echo "======================================"
