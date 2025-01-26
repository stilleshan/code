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
VERSION=1.5.0
UNAME=$(uname -m)

menu() {
  clear
  echo -e "${Green}####################################################################${Font}"
  echo -e "${Green}#            欢迎使用 GitHub Webhook 一键安装卸载脚本              #${Font}"
  echo -e "${Green}#   本程序为 https://github.com/yezihack/github-webhook 开源项目   #${Font}"
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
  if [ -d ${WORK_PATH}/github-webhook ]; then
    echo -e "${Red}已存在 ${WORK_PATH}/github-webhook 目录${Font}"
  fi
  if [ -f /usr/local/sbin/github-webhook ]; then
    echo -e "${Red}已存在 /usr/local/sbin/github-webhook 文件${Font}"
  fi
  if [ -f /lib/systemd/system/github-webhook.service ]; then
    echo -e "${Red}已存在 /lib/systemd/system/github-webhook.service 文件${Font}"
  fi
  port_check=$(/usr/sbin/lsof -i :2020)
  if [ "$port_check" != "" ]; then
    echo -e "${Red}已存在 2020 端口${Font}"
  fi
  if [ -d ${WORK_PATH}/github-webhook ] || [ -f /usr/local/sbin/github-webhook ] || [ -f /lib/systemd/system/github-webhook.service ] || [ "$port_check" != "" ]; then
    echo -e "${Green}请先进行手动删除,或执行卸载程序后再次安装.${Font}"
    exit 0
  else
    install
  fi
}

install() {
  echo -e "${Green}请输入用于验证的 Secret :${Font}"
  read -p "请输入:" SECRET
  echo -e "${Green}正在检测网络...${Font}"

  HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "https://www.google.com")

  if [ "${HTTP_CODE}" == "200" ] && [ $UNAME == "x86_64" ]; then
    wget https://github.com/yezihack/github-webhook/releases/download/v${VERSION}/github-webhook${VERSION}.linux-amd64.tar.gz
  fi
  if [ "${HTTP_CODE}" == "200" ] && [ $UNAME == "aarch64" ]; then
    echo "github-webhook 暂不支持 ARM 架构"
    exit 0
    # wget https://
  fi
  if [ "${HTTP_CODE}" != "200" ] && [ $UNAME == "x86_64" ]; then
    wget ${GHPROXY}https://github.com/yezihack/github-webhook/releases/download/v${VERSION}/github-webhook${VERSION}.linux-amd64.tar.gz
  fi
  if [ "${HTTP_CODE}" != "200" ] && [ $UNAME == "aarch64" ]; then
    echo "github-webhook 暂不支持 ARM 架构"
    exit 0
    # wget ${GHPROXY}https://
  fi

  tar zxvf github-webhook${VERSION}.linux-amd64.tar.gz
  mv github-webhook /usr/local/sbin
  rm -rf github-webhook${VERSION}.linux-amd64.tar.gz
  chmod u+x /usr/local/sbin/github-webhook
  mkdir ${WORK_PATH}/github-webhook

  cat >${WORK_PATH}/github-webhook/hook.sh <<'EOF'
#!/bin/bash
echo "test $(date "+%Y-%m-%d %H:%M:%S")" >> test.log

EOF

  chmod +x ${WORK_PATH}/github-webhook/hook.sh

  cat >/lib/systemd/system/github-webhook.service <<EOF
[Unit]
Description=github-webhook
Documentation=https://github.com/yezihack/github-webhook
After=network.target
 
[Service]
Type=simple
ExecStart=/usr/local/sbin/github-webhook --bash ${WORK_PATH}/github-webhook/hook.sh --secret ${SECRET}
Restart=on-failure
RestartSec=5s
 
[Install]
WantedBy=multi-user.target

EOF

  systemctl daemon-reload
  systemctl daemon-reload
  systemctl start github-webhook
  systemctl status github-webhook --no-pager
  systemctl enable github-webhook

  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}github-webhook 已成功安装完毕${Font}"
  echo -e "${Green}====================================================================${Font}"
  echo -e "执行以下命令测试请求:"
  echo -e "${Red}curl http://127.0.0.1:2020/ping${Font}"
  echo -e "返回 ${Green}PONG${Font} 表示测试成功"
  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}github-webhook 测试脚本路径${Font}"
  echo cat ${WORK_PATH}/github-webhook/hook.sh
  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}GitHub 设置如下${Font}"
  echo -e "${Red}GitHub Payload UR ${Font}: ${Yellow}http://ip:2020/web-hook${Font}"
  echo -e "${Red}Content type ${Font}: ${Yellow}application/json${Font}"
  echo -e "${Red}Secret ${Font}: ${Yellow}${SECRET}${Font}"
  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}github-webhook 相关命令${Font}"
  echo systemctl start github-webhook
  echo 启动服务
  echo systemctl stop github-webhook
  echo 停止服务
  echo systemctl restart github-webhook
  echo 重启服务
  echo systemctl status github-webhook --no-pager
  echo 查看状态及日志
  echo systemctl enable github-webhook
  echo 开机自动启动
  echo -e "${Green}====================================================================${Font}"
  echo -e "${Green}更多参数配置,请访问: https://github.com/yezihack/github-webhook${Font}"
  echo -e "${Green}====================================================================${Font}"
}

uninstall_check() {
  port_check=$(/usr/sbin/lsof -i :2020)
  if [ -d ${WORK_PATH}/github-webhook ] || [ -f /usr/local/sbin/github-webhook ] || [ -f /lib/systemd/system/github-webhook.service ] || [ "$port_check" != "" ]; then
    uninstall
  else
    echo -e "${Green}当前服务器未发现 github-webhook 程序${Font}"
    exit 0
  fi
}

uninstall() {
  systemctl stop github-webhook
  systemctl disable github-webhook
  systemctl daemon-reload
  rm -rf ${WORK_PATH}/github-webhook
  rm -rf /usr/local/sbin/github-webhook
  rm -rf /lib/systemd/system/github-webhook.service
  echo -e "${Green}github-webhook 已成功卸载完毕${Font}"
}

menu