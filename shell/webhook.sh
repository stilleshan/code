#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
# fonts color

WORK_PATH=$(dirname $(readlink -f $0))
GHPROXY=https://ghproxy.com/
VERSION=2.8.0
UNAME=$(uname -m)

menu() {
  clear
  echo -e "${Green}####################################################################${Font}"
  echo -e "${Green}#                欢迎使用 Webhook 一键安装卸载脚本                 #${Font}"
  echo -e "${Green}#        本程序为 https://github.com/adnanh/webhook 开源项目       #${Font}"
  echo -e "${Green}####################################################################${Font}"
  echo -e "${Red}请注意: 脚本安装和卸载需在同一路径下执行${Font}"
  echo -e "${Green}请选择:${Font}"
  echo -e "1) 安装"
  echo -e "2) 卸载"
  read -p "请选择:" CHOICE_INPUT
  case "$CHOICE_INPUT" in
  1)
    install_check
    ;;
  2)
    uninstall_check
    ;;
  *)
    echo -e "${Red}输入错误,请重新执行脚本.${Font}"
    exit 0
    ;;
  esac
}

install_check() {
  if [ -d ${WORK_PATH}/webhook ]; then
    echo -e "${Red}已存在 ${WORK_PATH}/webhook 目录${Font}"
  fi
  if [ -f /usr/bin/webhook ]; then
    echo -e "${Red}已存在 /usr/bin/webhook 文件${Font}"
  fi
  if [ -f /etc/webhook.conf ]; then
    echo -e "${Red}已存在 /etc/webhook.conf 文件${Font}"
  fi
  if [ -f /lib/systemd/system/webhook.service ]; then
    echo -e "${Red}已存在 /lib/systemd/system/webhook.service 文件${Font}"
  fi
  port_check=$(/usr/sbin/lsof -i :9191)
  if [ "$port_check" != "" ]; then
    echo -e "${Red}已存在 9191 端口${Font}"
  fi
  if [ -d ${WORK_PATH}/webhook ] || [ -f /usr/bin/webhook ] || [ -f /etc/webhook.conf ] || [ -f /lib/systemd/system/webhook.service ] || [ "$port_check" != "" ]; then
    echo -e "${Green}请先进行手动删除,或执行卸载程序后再次安装.${Font}"
    exit 0
  else
    install
  fi
}

install() {
  echo -e "${Green}正在检测网络...${Font}"

  HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "https://www.google.com")

  if [ "${HTTP_CODE}" == "200" ] && [ $UNAME == "x86_64" ]; then
    wget https://github.com/adnanh/webhook/releases/download/${VERSION}/webhook-linux-amd64.tar.gz
  fi
  if [ "${HTTP_CODE}" == "200" ] && [ $UNAME == "aarch64" ]; then
    wget https://github.com/adnanh/webhook/releases/download/${VERSION}/webhook-linux-arm64.tar.gz
  fi
  if [ "${HTTP_CODE}" != "200" ] && [ $UNAME == "x86_64" ]; then
    wget ${GHPROXY}https://github.com/adnanh/webhook/releases/download/${VERSION}/webhook-linux-amd64.tar.gz
  fi
  if [ "${HTTP_CODE}" != "200" ] && [ $UNAME == "aarch64" ]; then
    wget ${GHPROXY}https://github.com/adnanh/webhook/releases/download/${VERSION}/webhook-linux-arm64.tar.gz
  fi

  if [ $UNAME == "aarch64" ]; then
    tar -xzf webhook-linux-arm64.tar.gz
    mv webhook-linux-arm64/webhook /usr/bin
    rm -rf webhook-linux-arm64 webhook-linux-arm64.tar.gz
  fi

  if [ $UNAME == "x86_64" ]; then
    tar -xzf webhook-linux-amd64.tar.gz
    mv webhook-linux-amd64/webhook /usr/bin
    rm -rf webhook-linux-amd64 webhook-linux-amd64.tar.gz
  fi
  
  mkdir ${WORK_PATH}/webhook

  cat >${WORK_PATH}/webhook/test.sh <<'EOF'
#!/bin/bash
echo "test $(date "+%Y-%m-%d %H:%M:%S")" >> test.log
EOF

  chmod +x ${WORK_PATH}/webhook/test.sh

  cat >/etc/webhook.conf <<EOF
[
  {
    "id": "test",
    "execute-command": "${WORK_PATH}/webhook/test.sh",
    "command-working-directory": "${WORK_PATH}/webhook",
    "response-message": "test success!\n",
    "trigger-rule":
    {
      "match":
      {
        "type": "value",
        "value": "password",
        "parameter":
        {
          "source": "url",
          "name": "token"
        }
      }
    }
  }
]
EOF

  cat >/lib/systemd/system/webhook.service <<'EOF'
[Unit]
Description=Small server for creating HTTP endpoints (hooks)
Documentation=https://github.com/adnanh/webhook/
After=network.target
[Service]
ExecStart=/usr/bin/webhook -nopanic -hotreload -verbose -port 9191 -hooks /etc/webhook.conf
User=root
Group=root
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl start webhook
  systemctl status webhook --no-pager
  systemctl enable webhook

  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}Webhook 已成功安装完毕${Font}"
  echo -e "${Green}====================================================================${Font}"
  echo -e "执行以下命令测试请求:"
  echo -e "${Red}curl http://127.0.0.1:9191/hooks/test?token=password${Font}"
  echo -e "返回 ${Green}test success!${Font} 表示测试成功"
  echo -e "执行以下命令查看日志:"
  echo -e "${Red}cat ${WORK_PATH}/webhook/test.log${Font}"
  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}Webhook 相关命令${Font}"
  echo systemctl start webhook
  echo 启动服务
  echo systemctl stop webhook
  echo 停止服务
  echo systemctl restart webhook
  echo 重启服务
  echo systemctl status webhook --no-pager
  echo 查看状态及日志
  echo systemctl enable webhook
  echo 开机自动启动
  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}Webhook 配置文件路径${Font}"
  echo cat /etc/webhook.conf
  echo -e "${Green}Webhook 测试脚本路径${Font}"
  echo cat ${WORK_PATH}/webhook/test.sh
  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}更多相关配置和使用方法,请访问: https://github.com/adnanh/webhook${Font}"
  echo -e "${Green}====================================================================${Font}"
}

uninstall_check() {
  port_check=$(/usr/sbin/lsof -i :9191)
  if [ -d ${WORK_PATH}/webhook ] || [ -f /usr/bin/webhook ] || [ -f /etc/webhook.conf ] || [ -f /lib/systemd/system/webhook.service ] || [ "$port_check" != "" ]; then
    uninstall
  else
    echo -e "${Green}当前服务器未发现 webhook 程序${Font}"
    exit 0
  fi
}

uninstall() {
  systemctl stop webhook
  systemctl disable webhook
  systemctl daemon-reload
  rm -rf ${WORK_PATH}/webhook
  rm -rf /etc/webhook.conf
  rm -rf /usr/bin/webhook
  rm -rf /lib/systemd/system/webhook.service
  echo -e "${Green}Webhook 已成功卸载完毕${Font}"
}

menu