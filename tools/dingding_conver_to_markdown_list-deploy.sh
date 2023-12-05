#!/bin/bash
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################

# 用法： ./dingding_conver_to_markdown_list.sh "[Title]"
#        ./dingding_conver_to_markdown_list.sh "[Title]" "aaa"
#        ./dingding_conver_to_markdown_list.sh "[Title]" "aaa" "bbb"
#        ./dingding_conver_to_markdown_list.sh "[Title]" "aaa" "bbb" ... "<list>"


# 钉钉api --- 引入环境变量
dingding_api_url=$DINGDING_API
#dingding_api_url="https://oapi.dingtalk.com/robot/send?access_token=你自己的钉钉机器人token"



# 获取主机名
HOSTNAME=$(hostname)

# 时间
DATETIME=$(date "+%Y-%m-%d %H:%M:%S %z")

# Header
headers="Content-Type: application/json;charset=utf-8"

msg() {
    local title="$1"
    shift
    local items=("$@")

    local text="### $title\n"
    for item in "${items[@]}"; do
        text="$text- $item\n"
    done

    text="$text\n---\n*发自: $HOSTNAME*\n\n*时间: $DATETIME*"

    local json_text="{\"msgtype\": \"markdown\", \"markdown\": {\"title\": \"$title\", \"text\": \"$text\"}, \"at\": {\"atMobiles\": [\"1860021887\"], \"isAtAll\": true}}"

    curl -s -X POST -H "$headers" -d "$json_text" "$dingding_api_url" || { echo "Error sending message"; exit 1; }
}

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 [Title] [Item1] [Item2] ... [ItemN]"
    exit 1
fi

msg "$@"



