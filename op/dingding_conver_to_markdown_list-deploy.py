#!/usr/bin/env python
# encoding: utf-8
#############################################################################
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 用法： ./dingding_conver_to_markdown_list.py "[Title]"
#        ./dingding_conver_to_markdown_list.py "[Title]" "aaa"
#        ./dingding_conver_to_markdown_list.py "[Title]" "aaa" "bbb"
#        ./dingding_conver_to_markdown_list.py "[Title]" "aaa" "bbb" ... "<list>"



import requests
import json
import sys
import os
import socket
import time

# 获取主机名
HOSTNAME = socket.gethostname()

# 时间
DATETIME = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())

# 获取OS变量
ENV_DIST = os.environ


headers = {'Content-Type': 'application/json;charset=utf-8'}
api_url = ENV_DIST.get('DINGDING_API')
#api_url = "https://oapi.dingtalk.com/robot/send?access_token=f75b4e5582c3720dxxxxxxxxxxxx849eba76bd3bffcccc"


def msg(a):

    # 删除数组a[0]的值，这里a[0]是脚本本身的名字：dingding_markdown-array-deploy.py
    del a[0]

    json_text = '{"msgtype": "markdown", "markdown": {"title": '
    j=0

    for k in a:
        if j == 0 :
            json_text = json_text + '"' + k + '"'
            json_text = json_text + ', "text": "### ' + k + '\\n'
            j=1
            continue
        json_text = json_text + '- ' + k + '\\n'

    #json_text= {'msgtype': 'markdown', 'markdown': {'title': 'aa', 'text': '### 天龙盖地虎\n @1860021887\n\n- bb\n\n- cc'}, 'at': {'atMobiles':  ['1860021887'], 'isAtAll': False}}
    #json_text = json_text + "\\n\\n---\\n\\n*发自: " + HOSTNAME + "*\\n\\n" '"}, "at": {"atMobiles": ["1860021887"], "isAtAll": True}}'
    json_text = json_text + "---\\n" + "*发自: " + HOSTNAME + "*\\n\\n" + "*时间: " + DATETIME + "*\\n\\n" '"}, "at": {"atMobiles": ["1860021887"], "isAtAll": True}}'

    # http://www.pythoner.com/56.html
    #exec """print "json_text=" , json_text"""
    # https://blog.csdn.net/wangato/article/details/71104173
    json_text= eval(json_text)

    print(requests.post(api_url,json.dumps(json_text),headers=headers).content)

if __name__ == '__main__':
    msg(sys.argv)



# # https://open-doc.dingtalk.com/docs/doc.htm?spm=a219a.7629140.0.0.karFPe&treeId=257&articleId=105735&docType=1
# 目前只支持md语法的子集，具体支持的元素如下：
# 标题
# # 一级标题
# ## 二级标题
# ### 三级标题
# #### 四级标题
# ##### 五级标题
# ###### 六级标题
#
# 引用
# > A man who stands for nothing will fall for anything.
#
# 文字加粗、斜体
# **bold**
# *italic*
#
# 链接
# [this is a link](http://name.com)
#
# 图片
# ![](http://name.com/pic.jpg)
#
# 无序列表
# - item1
# - item2
#
# 有序列表
# 1. item1
# 2. item2


