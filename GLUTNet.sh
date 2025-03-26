#!/bin/sh
#桂工南分校园网自动登录脚本 2025.03.26
#by lingxiiii

#存储此脚本至/etc/storage/GLUTNet.sh
#设置计划任务
#系统-计划任务-在底部添加一行 */10 * * * * /etc/storage/GLUTNet.sh

# ----------配置区----------
server="10.0.0.10"
acc="" # 修改成你的账号（手机号）
pwd="123456"      # 修改成你的密码
ua="UCWEB7.0.2.37/28/999" #自定义ua（如果你想）
# ----------配置区----------

html_file="/tmp/drcom_html.log"
login_out_file="/tmp/drcom_login.log"

# 获取认证页面
if ! curl -s "${server}" > "${html_file}"; then
    logger -t "[桂工网络认证]" "错误: 无法连接到认证服务器"
    exit 1
fi

check_web=$(grep "Dr.COMWeb" "${html_file}" | head -n1)
check_status=$(grep "Dr.COMWebLoginID_0.htm" "${html_file}" | head -n1)
# Dr.COMWebLoginID_0.htm 登陆页（未登陆）
# Dr.COMWebLoginID_1.htm 注销页（已登录）
# Dr.COMWebLoginID_2.htm 登陆失败页
# Dr.COMWebLoginID_3.htm 登陆成功页

if [[ -z "${check_web}" ]]; then
    logger -t "[桂工网络认证]" "警告: 无法确认当前网络状态"
elif [[ -n "${check_status}" ]]; then
    login_url="http://${server}/drcom/login?callback=dr1003&DDDDD=${acc}&upass=${pwd}&0MKKey=${pwd}&R1=0&R2=&R3=1&R6=1&para=00&v6ip=&terminal_type=2&lang=zh-cn&lang=zh&jsVersion=4.2&v=${RANDOM}"
    
    # 发送登录请求
    if ! curl -s "${login_url}" -H "Accept-Language: zh-CN" \
        -H "Connection: keep-alive" -H "User-Agent: ${ua}" \
        > "${login_out_file}"; then
        logger -t "[桂工网络认证]" "错误: 登录请求失败"
        exit 1
    fi
    
    # 检查登录结果
    result=$(grep -Eo '"result":[0-9]' "${login_out_file}" | sed -r 's/"result":([0-9])/\1/g')
    if [[ "$result" == "1" || "$result" == "ok" ]]; then
        logger -t "[桂工网络认证]" "信息: 登录成功"
    else
        logger -t "[桂工网络认证]" "警告: 登录失败，返回结果: ${result}"
    fi
else
    logger -t "[桂工网络认证]" "信息: 当前已登录"
fi

# 清理临时文件
rm -f "${html_file}" "${login_out_file}"

logger -t "[桂工网络认证]" "信息: 定时检测完成"
exit 0
