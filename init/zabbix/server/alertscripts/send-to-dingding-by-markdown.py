#!/usr/bin/env python
# encoding: utf-8
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 用法： ./alert_for_zabbix_by_dingding.py   --webhook_url='https://oapi.dingtalk.com/robot/send?access_token=fffffffffffff7ce23e'  --webhook_title='sssss'  --alert_message="`cat mmm.txt`"


import sys
import getopt
import requests
import json
import traceback

import socket
import time

# 获取主机名
HOSTNAME = socket.gethostname()

# 时间
DATETIME = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())


try:
  opts,args = getopt.getopt(sys.argv[1:],shortopts='',longopts=['webhook_url=','webhook_title=','alert_message='])
  #print(sys.argv[1:])
  #print(args)
  #print(opts)
  for opt,value in opts:
    if opt == '--webhook_url':
      webhook_url = value
    elif opt == '--webhook_title':
      webhook_title = value
    elif opt == '--alert_message':
      alert_message = value

  alert_message = "### " + webhook_title + " \n" + "--- \n" + alert_message + " \n\n" + "---\n\n" + "*发自: " + HOSTNAME + "*\n\n" + "*时间: " + DATETIME + "*\n\n"
  #print(alert_message)

  webhook_header = {
    "Content-Type": "application/json",
    "charset": "utf-8"
  }

  webhook_message = {
    "msgtype": "markdown",
    "markdown": {
     "title": webhook_title,
     "text": alert_message
    }
  }
  sendData = json.dumps(webhook_message,indent=1)
  requests.post(url=webhook_url,headers=webhook_header,data=sendData)
except:
  traceback.print_exc(file=open('/tmp/send-to-dingding-by-markdown.py.log','w+'))


