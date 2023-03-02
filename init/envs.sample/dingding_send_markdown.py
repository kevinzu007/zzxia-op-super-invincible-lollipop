#!/usr/bin/env python3
# encoding: utf-8
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 用法： ./dingding_send_markdown.py  --title='sssss'  --message="`cat mmm.txt`"
#        ./dingding_send_markdown.py  --title 'sssss'  --message "$( echo -e "### 用户：${USER} \n### 时间：${TIME} \n\n" )"
#        ./dingding_send_markdown.py  --title 'sssss'  --message "$( echo -e "### 用户：${USER} \n### 时间：`date` \n\n" )"
# 请将变量【dingding_api_url】修改为你自己的


import sys
import getopt
import requests
import json
import traceback
import socket
import os
import time


# 钉钉api --- 引入OS变量
ENV_DIST = os.environ
#api_url = ENV_DIST.get('DINGDING_API')
dingding_api_url = "https://oapi.dingtalk.com/robot/send?access_token=你自己的钉钉机器人token"



# 获取主机名
HOSTNAME = socket.gethostname()

# 时间
DATETIME = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())

# 获取OS变量
ENV_DIST = os.environ



try:
  opts,args = getopt.getopt(sys.argv[1:],shortopts='',longopts=['title=','message='])
  #print(sys.argv[1:])
  #print(args)
  #print(opts)
  for opt,value in opts:
    #if opt == '--dingding_api_url':
    #  webhook_url = value
    if opt == '--title':
      send_title = value
    elif opt == '--message':
      send_message = value

  send_message = "### " + send_title + " \n" + "---\n" + send_message + " \n\n" + "---\n\n" + "*发自: " + HOSTNAME + "*\n\n" + "*时间: " + DATETIME + "*\n\n"
  #print(send_message)

  send_header = {
    "Content-Type": "application/json",
    "charset": "utf-8"
  }

  send_message = {
    "msgtype": "markdown",
    "markdown": {
     "title": send_title,
     "text": send_message
    }
  }
  sendData = json.dumps(send_message,indent=1)
  requests.post(url=dingding_api_url,headers=send_header,data=sendData)
except:
  traceback.print_exc(file=open('/tmp/dingding_send_markdown.py.log','w+'))


