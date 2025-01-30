#!/bin/bash

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
# fonts color


# 交互式脚本请保持以下 DOMAIN= 为空不要修改.如无需交互式,固定申请单一证书,请参考文档自行修改以下变量.
DOMAIN=
DNSAPI='dns_cf'
API_ID='export CF_Token="xxxxxxxxxxxxx"'
API_KEY='export CF_Account_ID="xxxxxxxxxxxxx"'
# API_ZONE='export CF_Zone_ID="xxxxxxxxxxxxx"'
# 交互式脚本请保持以下 DOMAIN= 为空不要修改.如无需交互式,固定申请单一证书,请参考文档自行修改以上变量.

# 参考文档地址
# https://github.com/acmesh-official/acme.sh/wiki/dnsapi
# https://www.ioiox.com/archives/87.html
# 参考文档地址


# menu
menu(){
clear
echo -e "${Green}=========================================================================================${Font}"
echo -e "${Green}欢迎使用快速申请 Let's Encrypt 泛域名证书一键脚本${Font} \n"
echo -e "1.本脚本需要服务器有 docker 环境 \n"
echo -e "2.本脚干净纯净,会自行清理临时文件,容器和镜像. \n"
echo -e "3.使用前请提前参考以下链接获取域名服务商的 API 信息以便使用."
echo -e "${Green}  https://github.com/acmesh-official/acme.sh/wiki/dnsapi${Font}"
echo -e "${Green}  https://www.ioiox.com/archives/87.html${Font} \n"
echo -e "4.本脚本默认为交互式脚本,直接运行根据提示输入相关 API 信息即可申请."
echo -e "  为方便国内用户单次申请证书使用,交互式脚本目前仅支持腾讯云,阿里云和 CloudFlare 三个平台."
echo -e "  后期视情况更新脚本支持更多主流服务商. \n"
echo -e "5.通过修改脚本中 16 - 20 行相关变量,可将本脚本作为指定域名和服务商证书申请的常驻脚本."
echo -e "  执行无任何交互.直接开始申请步骤.同时可用于官方支持的 100 多种服务商证书申请."
echo -e "  请参考以上官方文档仔细填写 API 相关信息."
echo -e "${Green}=========================================================================================${Font}"
echo -e "${Green}请输入需要申请证书的根域名(例如:ioiox.com):${Font}"
read -p "请输入:" DOMAIN_INPUT
if [ ! -n "${DOMAIN_INPUT}" ]; then
    echo -e "${Red}输入错误,请重新运行脚本.${Font}"
    exit 0
fi
DOMAIN=$DOMAIN_INPUT
echo -e "${Green}请选择域名服务商:${Font}"
echo -e "1) 腾讯云 dnspod.cn"
echo -e "2) 阿里云 aliyun"
echo -e "3) Cloudflare"
read -p "请选择:" DNSAPI_INPUT
case "$DNSAPI_INPUT" in
    1)
    PLATFORM_NAME='dnspod.cn'
    DNSAPI='dns_dp'
    API_ID_HEADER='DP_Id'
    API_KEY_HEADER='DP_Key'
    ;;
    2)
    PLATFORM_NAME='aliyun'
    DNSAPI='dns_ali'
    API_ID_HEADER='Ali_Key'
    API_KEY_HEADER='Ali_Secret'
    ;;
    3)
    ;;
    *)
    echo -e "${Red}输入错误,请重新运行脚本.${Font}"
    exit 0
    esac

if [ "$DNSAPI_INPUT" == "3" ]; then
    echo -e "${Green}=========================================================================================${Font}"
    echo -e  "${Red}注意: Cloudflare API 有三种:${Font}"
    echo -e  "${Red}请参考 https://github.com/acmesh-official/acme.sh/wiki/dnsapi#1-cloudflare-option 选择.${Font}"
    echo "1) Using the global API key"
    echo "2) Using the new cloudflare api token"
    echo "3) Using the new cloudflare api token for Single Zone"
    read -p "请选择:" CHOICE_CLOUDFLARE_INPUT
    echo -e "${Green}=========================================================================================${Font}"
    case "$CHOICE_CLOUDFLARE_INPUT" in
        1)
        PLATFORM_NAME='Cloudflare'
        DNSAPI='dns_cf'
        API_ID_HEADER='CF_Key'
        API_KEY_HEADER='CF_Email'
        ;;
        2)
        PLATFORM_NAME='Cloudflare'
        DNSAPI='dns_cf'
        API_ID_HEADER='CF_Token'
        API_KEY_HEADER='CF_Account_ID'
        ;;
        3)
        PLATFORM_NAME='Cloudflare'
        DNSAPI='dns_cf'
        API_ID_HEADER='CF_Token'
        API_KEY_HEADER='CF_Account_ID'
        API_ZONE_HEADER='CF_Zone_ID'
        ;;
        *)
        echo -e "${Red}输入错误,请重新运行脚本.${Font}"
        exit 0
        esac
fi

read -p "请输入 $API_ID_HEADER :" API_ID_INPUT
read -p "请输入 $API_KEY_HEADER :" API_KEY_INPUT
if [ "$CHOICE_CLOUDFLARE_INPUT" == "3" ]; then
    read -p "请输入 $API_ZONE_HEADER :" API_ZONE_HEADER_INPUT
fi


echo -e "${Green}=========================================================================================${Font}"
echo -e "${Red}请确认以下信息正确无误!${Font}"
echo -e "${Green}域名: ${Font}${Red}${DOMAIN}${Font}"
echo -e "${Green}域名服务商: ${Font}${Red}${PLATFORM_NAME}${Font}"
echo -e "${Green}${API_ID_HEADER}:${Font} ${Red}${API_ID_INPUT}${Font}"
echo -e "${Green}${API_KEY_HEADER}:${Font} ${Red}${API_KEY_INPUT}${Font}"
if [ "$CHOICE_CLOUDFLARE_INPUT" == "3" ]; then
    echo -e "${Green}${API_ZONE_HEADER}:${Font} ${Red}${API_ZONE_HEADER_INPUT}${Font}"
fi
echo -e "${Red}请再次确认以上信息正确无误!${Font}"
echo -e "${Green}=========================================================================================${Font}"
echo -e "${Green}本次将申请${Font} ${Red}*.${DOMAIN}${Font} ${Green}泛域名证书.${Font}"
echo -e "1) 开始申请证书"
echo -e "2) 退出脚本"
read -p "请输入:" START_INPUT
case "$START_INPUT" in
    1)
    echo -e "${Green}开始申请中......${Font}"
    accout_conf $*
    ;;
    2)
    exit 0
    ;;
    *)
    echo -e "${Red}输入有误,请重新运行脚本.${Font}"
    exit 0
    esac
}


# accout.conf
accout_conf (){
WORK_PATH=$(dirname $(readlink -f $0))
TEMP=${RANDOM}
mkdir -p ${WORK_PATH}/${TEMP}
cat >${WORK_PATH}/${TEMP}/account.conf<<EOF
export ${API_ID_HEADER}="${API_ID_INPUT}"
export ${API_KEY_HEADER}="${API_KEY_INPUT}"
EOF
if [ "$CHOICE_CLOUDFLARE_INPUT" == "3" ]; then
    echo "export ${API_ZONE_HEADER}=\"${API_ZONE_HEADER_INPUT}\"" >> ${WORK_PATH}/${TEMP}/account.conf
fi
acme $*
}


noninteractive (){
WORK_PATH=$(dirname $(readlink -f $0))
TEMP=${RANDOM}
mkdir -p ${WORK_PATH}/${TEMP}
cat >${WORK_PATH}/${TEMP}/account.conf<<EOF
${API_ID}
${API_KEY}
${API_ZONE}
EOF
acme $*
}


acme (){
    echo -e "${Green}准备 docker 部署${Font}"
    docker run -itd \
    --name=${TEMP} \
    --restart=always \
    --net=host \
    -v ${WORK_PATH}/${TEMP}:/acme.sh \
    neilpang/acme.sh \
    daemon

    echo -e "${Green}升级 acme.sh 程序${Font}"
    docker exec ${TEMP} --upgrade

    echo -e "${Green}开始申请证书${Font}"
    docker exec ${TEMP} --register-account  -m your@domain.com --server zerossl
    docker exec ${TEMP} --issue $* --keylength 2048 --dns ${DNSAPI} -d ${DOMAIN} -d \*.${DOMAIN}

    # docker exec ${TEMP} --issue --server letsencrypt $* --dns ${DNSAPI} -d ${DOMAIN} -d \*.${DOMAIN}

    # deploy
    if [ -f "${WORK_PATH}/${TEMP}/${DOMAIN}/fullchain.cer" ] ; then
        if [ ! -d "${WORK_PATH}/${DOMAIN}" ]; then
            mv ${WORK_PATH}/${TEMP}/${DOMAIN} ${WORK_PATH}/
            echo -e "${Green}=========================================================================================${Font}"
            echo -e "${Green}证书申请成功,相关临时文件及容器镜像已清理完毕.${Font}"
            echo -e "${Green}证书文件目录:${Font} ${Red}${WORK_PATH}/${DOMAIN}${Font}"
            echo -e "${Green}全链证书文件:${Font} ${Red}fullchain.cer${Font}"
            echo -e "${Green}证书密钥文件:${Font} ${Red}${DOMAIN}.key${Font}"
            echo -e "${Green}=========================================================================================${Font}"
        else
            mv ${WORK_PATH}/${TEMP}/${DOMAIN} ${WORK_PATH}/${DOMAIN}-new-${TEMP}
            echo -e "${Green}=========================================================================================${Font}"
            echo -e "${Green}证书申请成功,相关临时文件及容器镜像已清理完毕.${Font}"
            echo -e "${Red}检测到 ${WORK_PATH}/${DOMAIN} 目录已存在,已创建新的证书文件目录.${Font}"
            echo -e "${Green}证书文件目录:${Font} ${Red}${WORK_PATH}/${DOMAIN}-new-${TEMP}${Font}${Font}"
            echo -e "${Green}全链证书文件:${Font} ${Red}fullchain.cer${Font}"
            echo -e "${Green}证书密钥文件:${Font} ${Red}${DOMAIN}.key${Font}"
            echo -e "${Green}=========================================================================================${Font}"
        fi
    else
        echo -e "${Red}证书申请失败,请检查日志,或修改参数重新尝试.${Font}"
    fi

    # clean
    docker stop ${TEMP} >/dev/null 2>&1
    docker rm ${TEMP} >/dev/null 2>&1
    docker rmi neilpang/acme.sh >/dev/null 2>&1
    rm -rf ${WORK_PATH}/${TEMP}
}


# start
if ! type docker >/dev/null 2>&1; then
    echo -e "${Red}本机未安装 docker 已退出脚本.${Font}";
    exit 0
fi


if [ ! -n "${DOMAIN}" ]; then
    menu
else
    noninteractive $*
fi

# curl -O https://raw.githubusercontent.com/stilleshan/code/main/shell/acme_docker.sh && chmod +x swap.sh && ./swap.sh
# curl -O https://github.ioiox.com/stilleshan/code/raw/branch/main/shell/acme_docker.sh && chmod +x swap.sh && ./swap.sh
