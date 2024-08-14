#!/usr/bin/env bash

# author: 31n8y
# LittleCat

set -e
UNAME_M="$(uname -m)"
readonly UNAME_M

UNAME_U="$(uname -s)"
readonly UNAME_U

# COLORS
readonly COLOUR_RESET='\e[0m'
readonly aCOLOUR=(
    '\e[38;5;154m' # 绿色 - 用于行、项目符号和分隔符 0
    '\e[1m'        # 粗体白色 - 用于主要描述
    '\e[90m'       # 灰色 - 用于版权信息
    '\e[91m'       # 红色 - 用于更新通知警告
    '\e[33m'       # 黄色 - 用于强调
    '\e[34m'       # 蓝色
    '\e[35m'       # 品红
    '\e[36m'       # 青色
    '\e[37m'       # 浅灰色
    '\e[92m'       # 浅绿色9
    '\e[93m'       # 浅黄色
    '\e[94m'       # 浅蓝色
    '\e[95m'       # 浅品红
    '\e[96m'       # 浅青色
    '\e[97m'       # 白色
    '\e[40m'       # 背景黑色
    '\e[41m'       # 背景红色
    '\e[42m'       # 背景绿色
    '\e[43m'       # 背景黄色
    '\e[44m'       # 背景蓝色19
    '\e[45m'       # 背景品红
    '\e[46m'       # 背景青色21
    '\e[47m'       # 背景浅灰色
)

readonly GREEN_LINE=" ${aCOLOUR[0]}──────────────────────────────────────────────$COLOUR_RESET"
readonly GREEN_BULLET=" ${aCOLOUR[0]}-$COLOUR_RESET"
readonly GREEN_SEPARATOR="${aCOLOUR[0]}:$COLOUR_RESET"

Show() {
    # OK
    if (($1 == 0)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[0]}  OK  $COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    # FAILED
    elif (($1 == 1)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[3]}FAILED$COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
        exit 1
    # INFO
    elif (($1 == 2)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[0]} INFO $COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    # NOTICE
    elif (($1 == 3)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[4]}NOTICE$COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    fi
}

Warn() {
    echo -e "${aCOLOUR[3]}$1$COLOUR_RESET"
}

GreyStart() {
    echo -e "${aCOLOUR[2]}\c"
}

ColorReset() {
    echo -e "$COLOUR_RESET\c"
}

print_colored_prompt() {
    local color_code="$1"
    local prompt_text="$2"
    echo -e "\033[${color_code}m${prompt_text}\033[0m"
}

# 定义红色文本
RED='\033[0;31m'
# 无颜色
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW="\e[33m"

declare -a menu_options
declare -A commands

menu_options=(
    "配置小猫咪"
    "启动小猫咪"
    "停止小猫咪"
    "重启小猫咪"
    "更新小猫咪"
    "摸摸小猫咪"
    "重置小猫咪"
)

commands=(
    ["配置小猫咪"]="cat_config"
    ["启动小猫咪"]="cat_start"
    ["停止小猫咪"]="cat_stop"
    ["重启小猫咪"]="cat_restart"
    ["更新小猫咪"]="cat_update"
    ["摸摸小猫咪"]="cat_env"
    ["重置小猫咪"]="cat_reset"
)

# 获取脚本工作目录绝对路径
export cat_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# 给二进制启动程序、脚本等添加可执行权限
chmod +x $cat_dir/bin/*
chmod +x $cat_dir/subconverter/subconverter

conf_dir="$cat_dir/conf"
temp_dir="$cat_dir/temp"
logs_dir="$cat_dir/logs"

# 自定义action函数，实现通用action功能
action() {
    if [ $? -eq 0 ]; then
		Show 0 $1
	else
		Show 1 $2
	fi
}

# 配置小猫咪
cat_config() {
    Show 2 "配置小猫咪"
    # 配置小猫咪订阅地址
    read -p "$(echo -e "${YELLOW}请输入小猫咪的URL订阅地址: ${NC}")" CAT_URL
    # 判断输入是否为url地址
    if [[ $CAT_URL =~ ^http(s)?://[a-zA-Z0-9.-]?.* ]]; then
        Show 0 "URL地址格式正确"
    else
        Show 1 "URL地址格式错误"
        exit 1
    fi
    echo "CAT_URL=$CAT_URL" > .env

    # 配置小猫咪仪表板登录密码
    read -p "$(echo -e "${YELLOW}请输入小猫咪的登录密码(留空则随机生成): ${NC}")" CAT_SECRET
    # 如果secret为空，则生成随机secret
    if [ -z "$CAT_SECRET" ]; then
        CAT_SECRET=$(openssl rand -hex 32)
    fi
    echo "CAT_SECRET=$CAT_SECRET" >> .env
    
    # 配置小猫咪服务IP地址
    read -p "$(echo -e "${YELLOW}请输入小喵咪的服务IP地址: ${NC}")" CAT_IP
    echo "CAT_IP=$CAT_IP" >> .env
    action "配置小猫咪成功" "配置小猫咪失败" $?
}

# 执行获取CPU架构命令
eval_cmds() {
    for cmd in "$@"; do
        if arch=$(eval "$cmd"); then
            echo "$arch"
            return
        fi
    done
    Show 1 "无法确定CPU架构"
}

# 基于Linux发行版确定CPU架构
determine_cpu_arch() {
    if [[ -f "/etc/os-release" ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint)
                eval_cmds "dpkg-architecture -qDEB_HOST_ARCH_CPU" "dpkg-architecture -qDEB_BUILD_ARCH_CPU" "uname -m"
                ;;
            centos|fedora|rhel)
                eval_cmds "uname -m" "arch" "uname"
                ;;
            *)
                Show 1 "不支持的Linux发行版"
                ;;
        esac
    elif [[ -f "/etc/redhat-release" ]]; then
        eval_cmds "uname -m" "arch" "uname"
    else
        Show 1 "不支持的Linux发行版"
    fi
}

# 获取CPU架构
get_cpu_arch() {
    Show 2 "获取CPU架构"
    cpu_arch=$(determine_cpu_arch) || Show 1 "无法获取CPU架构"
    Show 0 "CPU架构: $cpu_arch"

    # 检查是否获取到CPU架构
    if [[ -z "$cpu_arch" ]]; then
        Show 1 "无法获取CPU架构"
    fi
}

# 取消环境变量
unset_env() {
    Show 2 "取消环境变量"
    unset http_proxy
    unset https_proxy
    unset no_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset NO_PROXY
}

# 读取环境变量
source_env() {
    if [ -f ".env" ]; then
        # 加载 .env 文件
        source .env
    else
        Show 1 "无法读取环境变量, 请先配置小喵咪"
    fi
}

# 检查订阅地址是否有效
check_cat_url() {
    local status_text="订阅地址可访问!"
    local error_text="订阅地址不可访问!"

    Show 2 "正在检测订阅地址..."
    # 使用curl检查URL是否返回HTTP状态码200-299
    curl -o /dev/null -L -k -sS --retry 5 -m 10 --connect-timeout 10 -w "%{http_code}" "$CAT_URL" | grep -qE '^[23][0-9]{2}$' &>/dev/null
    action $status_text $error_text $?
}

# 下载配置文件
get_config_yaml() {
    Show 2 '正在下载配置文件...'
    local status_text="配置文件下载成功!"
    local error_text="配置文件下载失败,退出启动!"

    # 尝试使用curl进行下载
    curl -L -k -sS --retry 5 -m 10 -o $temp_dir/clash.yaml $CAT_URL
    if [ $? -ne 0 ]; then
        # 如果使用curl下载失败，尝试使用wget进行下载
        for i in {1..10}
        do
            wget -q --no-check-certificate -O $temp_dir/clash.yaml $CAT_URL
            if [ $? -eq 0 ]; then
                break
            else
                continue
            fi
        done
    fi
    action $status_text $error_text $?

    # 重命名clash配置文件
    cp -a $temp_dir/clash.yaml $temp_dir/clash_config.yaml
}

# 订阅内容转换
subconverter() {
    # 加载配置文件内容
    raw_content=$(cat ${temp_dir}/clash.yaml)

    # 判断订阅内容是否符合配置文件标准
    #if echo "$raw_content" | jq 'has("proxies") and has("proxy-groups") and has("rules")' 2>/dev/null; then
    if echo "$raw_content" | awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}'; then
        Show 2 "订阅内容符合clash标准"
        echo "$raw_content" > ${temp_dir}/clash_config.yaml
    else
        # 判断订阅内容是否为base64编码
        if echo "$raw_content" | base64 -d &>/dev/null; then
            # 订阅内容为base64编码，进行解码
            decoded_content=$(echo "$raw_content" | base64 -d)

            # 判断解码后的内容是否符合clash配置文件标准
            #if echo "$decoded_content" | jq 'has("proxies") and has("proxy-groups") and has("rules")' 2>/dev/null; then
            if echo "$decoded_content" | awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}'; then
                Show 2 "解码后的内容符合clash标准"
                echo "$decoded_content" > ${temp_dir}/clash_config.yaml
            else
                Show 2 "解码后的内容不符合Clash配置文件标准,尝试将其转换为标准格式"
                ${cat_dir}/subconverter/subconverter -g &>> ${cat_dir}/logs/subconverter.log
                converted_file=${temp_dir}/clash_config.yaml

                # 判断转换后的内容是否符合clash配置文件标准
                awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}' $converted_file
                action "配置文件已成功转换成Clash标准格式" "配置文件转换标准格式失败" $?
            fi
        else
            Show 1 "订阅内容不符合clash标准, 无法转换为配置文件"
        fi
    fi
}

# 对配置文件重新格式化及配置
format_config_yaml() {
    # 取出代理相关配置 
    #sed -n '/^proxies:/,$p' $temp_dir/clash.yaml > $temp_dir/proxy.txt
    sed -n '/^proxies:/,$p' $temp_dir/clash_config.yaml > $temp_dir/proxy.txt

    # 合并形成新的config.yaml
    cat $conf_dir/config_templete.yaml > $temp_dir/config.yaml
    cat $temp_dir/proxy.txt >> $temp_dir/config.yaml
    cp $temp_dir/config.yaml $conf_dir/

    # 配置Clash仪表板
    dashboard_dir="${cat_dir}/public"
    sed -ri "s@^# external-ui:.*@external-ui: ${dashboard_dir}@g" $conf_dir/config.yaml
    sed -ri '/^secret: /s@(secret: ).*@\1'${CAT_SECRET}'@g' $conf_dir/config.yaml
}

# 启动Clash服务
service_start() {
    Show 2 '正在启动Clash服务...'
    startup_sucess="服务启动成功！"
    startup_failed="服务启动失败！"
    if [[ $cpu_arch =~ "x86_64" || $cpu_arch =~ "amd64"  ]]; then
        nohup $cat_dir/bin/clash-linux-amd64 -d $conf_dir &> $logs_dir/clash.log &
        action $startup_sucess $startup_failed $?
    elif [[ $cpu_arch =~ "aarch64" ||  $cpu_arch =~ "arm64" ]]; then
        nohup $cat_dir/bin/clash-linux-arm64 -d $conf_dir &> $logs_dir/clash.log &
        action $startup_sucess $startup_failed $?
    elif [[ $cpu_arch =~ "armv7" ]]; then
        nohup $cat_dir/bin/clash-linux-armv7 -d $conf_dir &> $logs_dir/clash.log &
        action $startup_sucess $startup_failed $?
    else
        Show 1 "\033[31m不支持的CPU架构! \033[0m"
    fi
}

# 添加环境变量(root权限)
set_profile() {
    cat>/etc/profile.d/clash.sh<<EOF
# 开启系统代理
function cat_on() {
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export no_proxy=127.0.0.1,localhost
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export NO_PROXY=127.0.0.1,localhost
    echo -e "\033[32m[√] 已开启代理\033[0m"
}

# 关闭系统代理
function cat_off() {
    unset http_proxy
    unset https_proxy
    unset no_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset NO_PROXY
    echo -e "\033[31m[×] 已关闭代理\033[0m"
}
EOF
    Show 2 "请执行以下命令加载环境变量: source /etc/profile.d/clash.sh"
    Show 2 "请执行以下命令设置系统代理: cat_on"
    Show 2 "请执行以下命令取消系统代理: cat_off"
}

# 启动小猫咪
cat_start() {
    Show 2 "启动小猫咪"
    # 获取CPU架构
    get_cpu_arch

    # 取消环境变量
    unset_env

    # 加载.env文件
    source_env

    # 检测订阅地址
    check_cat_url

    # 获取配置文件
    get_config_yaml

    # 检测订阅内容
    if [[ $cpu_arch =~ "x86_64" || $cpu_arch =~ "amd64"  ]]; then
        Show 2 '判断订阅内容是否符合clash配置文件标准'
        subconverter
        sleep 3
    fi
    
    # 格式化配置文件
    format_config_yaml

    # 启动小猫咪服务
    service_start

    if [ $? -eq 0 ]; then
        Show 0 "启动小猫咪成功"
        Show 0 "Clash Dashboard 访问地址: http://${CAT_IP}:9090/ui"
        Show 0 "Clash Dashboard 登录密码: ${CAT_SECRET}"
        set_profile
    else
        Show 1 "启动小猫咪失败"
    fi

    # 清除临时文件
    rm -rf $temp_dir/*
}

# 停止小猫咪
cat_stop() {
    Show 2 "停止小猫咪"
    # 清除环境变量
    rm -f /etc/profile.d/clash.sh

    # 停止服务
    pid_num=$(ps -ef | grep clash-linux-a | grep -v "grep" | wc -l)
    pid=$(ps -ef | grep clash-linux-a | grep -v "grep" | awk '{print $2}')
    if [ $pid_num -ne 0 ]; then
        kill -9 $pid
        if [ $? -eq 0 ]; then
            Show 0 "停止小猫咪成功"
        else
            Show 1 "停止小猫咪失败"
        fi
    else
        Show 0 "小猫咪已停止"
    fi
}

# 重启小猫咪
cat_restart() {
    Show 2 "重启小猫咪"
    # 停止小猫咪
    cat_stop
    # 等待3秒
    sleep 3
    # 启动小猫咪
    cat_start
}

# 更新小猫咪
cat_update() {
    Show 2 "更新小猫咪"
    # 检查订阅地址
    check_cat_url
    # 获取配置文件
    get_config_yaml
    # 检测订阅内容
    subconverter
    # 格式化配置文件
    format_config_yaml
    # 重启服务
    cat_restart
}

# 获取小猫咪信息
cat_env() {
    # 读取.env文件
    source_env
    Show 2 "当前配置文件信息"
    Show 2 "订阅URL地址: ${CAT_URL}"
    Show 2 "仪表板密码: ${CAT_SECRET}"
    Show 2 "服务IP地址: ${CAT_IP}"
    Show 2 "HTTP代理地址: http://127.0.0.1:7890"
    Show 2 "Socks代理地址: socks5://127.0.0.1:7891"
    Show 2 "Redir代理端口: 7892"
    Show 2 "Mixed模式端口: 7893"
}

# 重置小猫咪
cat_reset() {
    Show 2 "重置小猫咪开始"
    # 停止小猫咪
    cat_stop
    # 等待3秒
    sleep 3
    # 取消环境变量
    unset_env
    rm -rf /etc/profile.d/clash.sh
    # 删除配置文件
    rm -rf $conf_dir/config.yaml
    # 删除日志文件
    rm -rf $logs_dir/*
    # 删除数据库文件
    rm -rf $conf_dir/cache.db
    # 删除临时文件
    rm -rf $temp_dir/*
    # 删除环境变量
    rm -rf $cat_dir/.env
    Show 2 "重置小猫咪成功"
}

# 显示菜单
show_menu() {
    clear
    YELLOW="\e[33m"
    NO_COLOR="\e[0m"

    echo -e "${GREEN_LINE}"
    echo '
    *************  LittleCat  *************

    脚本作用: 养一只小猫咪，带我们去旅行
    
                    --- Made by 31n8y ---
    '
    echo -e "${GREEN_LINE}"
    echo ">>> 请选择操作 >>> "

    # 特殊处理的项数组
    special_items=("")
    for i in "${!menu_options[@]}"; do
        if [[ " ${special_items[*]} " =~ " ${menu_options[i]} " ]]; then
            # 如果当前项在特殊处理项数组中，使用特殊颜色
            echo -e "$((i + 1)). ${aCOLOUR[7]}${menu_options[i]}${NO_COLOR}"
        else
            # 否则，使用普通格式
            echo "$((i + 1)). ${menu_options[i]}"
        fi
    done
}

# 处理用户选择
handle_choice() {
    local choice=$1
    # 检查输入是否为空
    if [[ -z $choice ]]; then
        echo -e "${RED}输入不能为空，请重新选择。${NC}"
        return
    fi

    # 检查输入是否为数字
    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo -e "${RED}请输入有效数字!${NC}"
        return
    fi

    # 检查数字是否在有效范围内
    if [[ $choice -lt 1 ]] || [[ $choice -gt ${#menu_options[@]} ]]; then
        echo -e "${RED}选项超出范围!${NC}"
        echo -e "${YELLOW}请输入 1 到 ${#menu_options[@]} 之间的数字。${NC}"
        return
    fi

    # 执行命令
    if [ -z "${commands[${menu_options[$choice - 1]}]}" ]; then
        echo -e "${RED}无效选项，请重新选择。${NC}"
        return
    fi

    "${commands[${menu_options[$choice - 1]}]}"
}

while true; do
    show_menu
    read -p ">>> 请输入选项的序号(输入q退出) >>> " choice
    if [[ $choice == 'q' || $choice == 'Q' ]]; then
        break
    fi
    handle_choice $choice
    echo ">>> 按任意键继续... <<<"
    read -n 1 # 等待用户按键
done