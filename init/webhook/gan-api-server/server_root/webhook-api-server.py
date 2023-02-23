#!/usr/bin/env python3
# -*- coding: utf-8 -*-



# 使用前请先基于【webhook_var.py.sample】创建【webhook_var.py】，并修改为自己的参数
#
# 你可能需要使他与基于【init/my_sec.sample】创建的文件路径保持一致（在非独立使用的时候）



# 从文件载入变量
from webhook_var import *


# 载入
import hmac
import hashlib
import os
import time
import re
import json
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
#from simplelog import logger



def extract_element_from_json(obj, path):
    '''
    输入关键字，就可以将关键字的值信息存放在列表中并输出
    如果关键字是对象名，则返回的对象字典信息到列表中
    如果关键字是列表名，则返回的列表信息到列表中（返回双重列表）
    '''
    def extract(obj, path, ind, arr):
        '''
        从一个嵌套的字典中提取一个元素，并返回到列表中。
        params: obj - dict - 输入字典
        params: path - list - 构成JSON路径的字符串列表
        params: ind - int - 起始索引
        params: arr - 列表 - 输出列表
        '''
        key = path[ind]
        if ind + 1 < len(path):
            if isinstance(obj, dict):
                if key in obj.keys():
                    extract(obj.get(key), path, ind + 1, arr)
                else:
                    arr.append(None)
            elif isinstance(obj, list):
                if not obj:
                    arr.append(None)
                else:
                    for item in obj:
                        extract(item, path, ind, arr)
            else:
                arr.append(None)
        if ind + 1 == len(path):
            if isinstance(obj, list):
                if not obj:
                    arr.append(None)
                else:
                    for item in obj:
                        arr.append(item.get(key, None))
            elif isinstance(obj, dict):
                arr.append(obj.get(key, None))
            else:
                arr.append(None)
        return arr
    if isinstance(obj, dict):
        return extract(obj, path, 0, [])
    elif isinstance(obj, list):
        outer_arr = []
        for item in obj:
            outer_arr.append(extract(item, path, 0, []))
        return outer_arr



# 校验用户名密码
def auth_user_pw(user, sec):
    user_db_file = open(USER_DB_FILE)
    _user = user
    _sec = sec
    _USER_PW_OK = 'N'
    for line in user_db_file:
        line = line.strip()
        print('看看行记录： ' + line)
        if re.match('^#', line) or re.match('^ *$', line):
            continue
        try:
            line_user, line_salt, line_secret = line.split('|')[2], line.split('|')[
                5], line.split('|')[6]
            line_user = line_user.strip()
            line_salt = line_salt.strip()
            line_secret = line_secret.strip()
        except:
            return {"Status": "Error", "Message": "服务器用户信息异常"}
        if line_user == _user:
            _sec = _sec[2:32]   # --- 与【user-secret-update.sh】保持一致，取30个字符
            print('sha256前_sec：' + _sec)
            _secrect = digest_hashlib_salt(line_salt, _sec)
            _secrect = _secrect[3:53]   # --- 与【user-secret-update.sh】保持一致，取50个字符
            print('计算得出_secrect：' + _secrect)
            if _secrect == line_secret:
                _USER_PW_OK = 'Y'
                break
            else:
                return {"Status": "Error", "Message": "用户名密码错"}
    #
    if _USER_PW_OK == 'Y':
        return {"Status": "Success", "Message": "验证成功"}
    else:
        return {"Status": "Error", "Message": "用户名不存在"}
    



# 验证用户token
def auth_user_token(token):
    _token = token
    _user = ''
    _TOKEN_OK = 'N'
    hand_token_file = open(USER_TOKEN_FILE)
    for line in hand_token_file:
        line = line.strip()
        if re.match('^#', line) or re.match('^ *$', line):
            continue
        try:
            line_user, line_token = line.split(' ')[0], line.split(' ')[1]
            line_user = line_user.strip()
            line_token = line_token.strip()
        except:
            return {"Status": "Error", "Message": "Token库信息异常"}
        if line_token == _token:
            _user = line_user
            _TOKEN_OK = 'Y'
            break
    #
    if _TOKEN_OK == 'Y':
        return {"Status": "Success", "Username": _user}
    else:
        return {"Status": "Error", "Message": "Token库中未找到"}



# 获取用户token
def get_user_token(user):
    _user = user
    _my_token = ''
    _TOKEN_OK = 'N'
    hand_token_file = open(USER_TOKEN_FILE)
    for line in hand_token_file:
        line = line.strip()
        if re.match('^#', line) or re.match('^ *$', line):
            continue
        try:
            line_user, line_token = line.split(' ')[0], line.split(' ')[1]
            line_user = line_user.strip()
            line_token = line_token.strip()
        except:
            return {"Status": "Error", "Message": "Token库信息异常"}
        if line_user == _user:
            _my_token = line_token
            _TOKEN_OK = 'Y'
            break
    #
    if _TOKEN_OK == 'Y':
        return {"Status": "Success", "Token": _my_token}
    else:
        return {"Status": "Error", "Message": "Token库中未找到"}




# 摘要1-hashlib（不加盐）
# sha256
def digest_hashlib(msg):
    _msg = msg.encode('utf-8')
    _msg_hashlib = hashlib.sha256(_msg)
    _msg_hashlib_digest = _msg_hashlib.hexdigest()
    return _msg_hashlib_digest

# 摘要2-hashlib（加盐）
# sha256
def digest_hashlib_salt(salt, msg):
    _msg = salt + msg
    _msg = _msg.encode('utf-8')
    _msg_hashlib = hashlib.sha256(_msg)
    _msg_hashlib_digest = _msg_hashlib.hexdigest()
    return _msg_hashlib_digest

# 摘要3-hmac（不清楚hmac的实现原理，故无法在shell下对等实现）
# sha256
def digest_hmac_sha256(key, msg):
    _key = key.encode('utf-8')
    _msg = msg.encode('utf-8')
    _msg_hmac = hmac.new(_key, _msg, digestmod='sha256')
    _msg_hmac_digest = _msg_hmac.hexdigest()
    return _msg_hmac_digest
# sha1
def digest_hmac_sha1(key, msg):
    _key = key.encode('utf-8')
    _msg = msg.encode('utf-8')
    _msg_hmac = hmac.new(_key, _msg, digestmod='sha1')
    _msg_hmac_digest = _msg_hmac.hexdigest()
    return _msg_hmac_digest



# web应用框架Flask
app = Flask(__name__)
gan_cmd = ''
CORS(app, supports_credentials=True)    #--- 开启全局跨域，调试用



# 根据用户名密码获取用户token
#
@app.route('/get/token', methods=['POST'])
def get_token():
    #
    # header【"user: kevin", "sec: md5(用户名+密码)"】
    #
    recive_header = request.headers
    print("请求头：")
    print(recive_header)
    print('')

    # header处理
    #
    user = recive_header.get('user', '').split('=')[-1]
    sec = recive_header.get('sec', '').split('=')[-1]
    print('用户名：' + user + '\n' + '密码：' + sec)

    # 用户验证
    if user != '' and sec != '':
        # 校验用户名密码
        auth_result = auth_user_pw(user, sec)
        #auth_result = json.loads(auth_result)
        auth_result_status = extract_element_from_json(auth_result, ["Status"])[0]
        print(auth_result_status)
        if auth_result_status == 'Success':
            get_user_token_result = get_user_token(user)
            #get_user_token_result = json.loads(get_user_token_result)
            return jsonify(get_user_token_result)
        else:
            return jsonify(auth_result)
    else:
        return jsonify({"Status": "Error", "Message": "请提供登录信息"})



# git仓库用hook
#
@app.route('/hook/gitlab', methods=['POST'])
def hook_gitlab():
    # msg: {env=dev,do=gogogo,skiptest=yes,version=5.5,gray=yes}
    recive_header = request.headers
    recive_raw_body = request.data
    recive_json_body = recive_raw_body.decode('utf-8')
    #--logger.info(f'raw_data:{recive_raw_body}')
    #--logger.info(
    #--    f"recive_json_body:{recive_json_body}，type:{type(recive_json_body)}")
    #
    # 调试信息
    print("请求头：")
    print(recive_header)
    print("请求body：")
    print(recive_json_body)
    print('')
    
    # header处理
    #
    #git_event = recive_header.get('X-Gitlab-Event', '')
    gitlab_event = recive_header.get('X-Gitlab-Event', '').split('=')[-1]
    print('X-Gitlab-Event为: ' + gitlab_event)
    #
    gitlab_token = recive_header.get('X-Gitlab-Token', '').split('=')[-1]
    print('git_token为：' + gitlab_token)
    if gitlab_token != GITLAB_SECRET_TOKEN:
        return jsonify({"Status": "Error", "Message": "Token错误"})
    
    # body处理
    #
    #exec('kv=' + recive_json_body)                  #--- 支持curl -d '{}'     和"{}"
    kv = json.loads(recive_json_body)                #--- 支持curl -d '{}'，不支持"{}"
    #
    gan_project = extract_element_from_json(kv, ["repository", "name"])
    gan_project = gan_project[0]
    #
    gan_project_branch = extract_element_from_json(kv, ["ref"])
    gan_project_branch = gan_project_branch[0].split('/')[2]
    #
    gan_user_username = extract_element_from_json(kv, ["user_username"])
    gan_user_username = gan_user_username[0]
    #
    gan_repo_commits_count = extract_element_from_json(kv, ["total_commits_count"])
    gan_repo_commits_count = gan_repo_commits_count[0]
    #
    gan_repo_commits_message = extract_element_from_json(
        kv, ["commits", "message"])
    gan_repo_commits_message = gan_repo_commits_message[gan_repo_commits_count - 1]
    #
    #gan_user_email = extract_element_from_json(kv, ["user_email"])    #--- 为啥他有的为空
    gan_user_email = extract_element_from_json(
        kv, ["commits", "author", "email"])
    gan_user_email = gan_user_email[gan_repo_commits_count - 1]
    
    
    print('项目:' + gan_project)
    print('分支:' + gan_project_branch)
    print('用户名:' + gan_user_username)
    print('用户邮箱:' + gan_user_email)
    print('提交次数: %d' % gan_repo_commits_count)
    print('提交次数:' + str(gan_repo_commits_count))
    print('提交信息:' + gan_repo_commits_message)
    #
    if gan_repo_commits_message.find('{') == -1 or gan_repo_commits_message.find('}') == -1 :
        return jsonify({"Status": "Error", "Message": "wehook信息不存在或不完整"})
    #
    gan_arg = gan_repo_commits_message
    gan_arg = gan_arg.split('{')[1]
    gan_arg = gan_arg.split('}')[0]
    gan_arg = gan_arg.replace(' ','')
    gan_arg = gan_arg.replace('"','')
    gan_arg = gan_arg.replace("'", '')
    gan_arg = gan_arg.lower()
    #
    split_char = ','
    num = gan_arg.count(split_char) + 1
    #
    gan_env = ''
    gan_do = ''
    gan_version = ''
    gan_gray = ''
    gan_skiptest = ''
    print('gan_arg参数：' + gan_arg)
    for i in range(num):
        gan_kv = gan_arg.split(split_char)[i].strip()
        gan_k = gan_kv.split('=')[0].strip()
        gan_v = gan_kv.split('=')[1].strip()
        if gan_k == 'env' and gan_v != '':
            gan_env = gan_v
        elif gan_k == 'do' and gan_v != '':
            gan_do = gan_v
        elif gan_k == 'version' and gan_v != '':
            gan_version = gan_v
        elif gan_k == 'gray' and gan_v != '':
            gan_gray = gan_v
        elif gan_k == 'skiptest':
            gan_skiptest = gan_v
    #
    #
    # 必须参数
    if gan_env == '':
        # 退出
        return jsonify({"Status": "Error", "Message": "wehook信息之【env】不存在"})
    else:
        gan_cmd_0 = 'export HOOK_GAN_ENV=' + gan_env
    #
    # 必须参数
    if gan_do == 'build':
        gan_cmd = GAN_CMD_HOME + '/deploy/build.sh'
    elif gan_do == 'gogogo':
        gan_cmd = GAN_CMD_HOME + '/deploy/gogogo.sh'
        # deploy
        if gan_version != '':
            gan_cmd = gan_cmd + ' --release-version ' + gan_version
        if re.match(r'yes|YES|y|yes', gan_gray):
            gan_cmd = gan_cmd + ' --gray '
    else:
        # 退出
        return jsonify({"Status": "Error","Message": "wehook信息之【do】不存在、错误或超出范围"})
    # 
    if re.match(r'^yes|^YES|^y|^yes', gan_skiptest):
        gan_cmd = gan_cmd + ' --skiptest '
    if gan_user_email != '':
        gan_cmd = gan_cmd + ' --email ' + gan_user_email
    #
    gan_cmd = gan_cmd + ' --branch ' + gan_project_branch + ' ' + gan_project


    # 运行shell脚本
    #
    # hook/gitlab
    hook_time = time.strftime("%Y-%m-%d_T_%H%M%S", time.localtime())
    web_hook_logfile = WEB_ROOT + '/web_hook_gitlab---' + hook_time + '.log'
    run_result = os.system(gan_cmd_0 + ' ; ' + gan_cmd +
                           ' > ' + web_hook_logfile + ' 2>&1')
    #return send_file(web_hook_logfile, mimetype='text/plain')
    return jsonify({"Status": "OK", "Logfile": web_hook_logfile})



# for手动执行hook
# 支持用户验证及token验证
#
@app.route('/hook/hand', methods=['POST'])
def hook_hand():

    # header【"token: sdlffsekwodksdlfolsefksdfpofefpsefop34pfsdf"】
    # header【"user: kevin", "sec: sha1(用户名+密码)"】
    #
    # body = {"do":"build|deploy|gogogo","branch":"master","version":"5.5","gray":"yes","skiptest":"yes","force":"yes","category":"java","projects":["pj1","pj2","pj3"]}
    # {
    #     "do": "build|deploy|gogogo",
    #     "branch": "master",
    #     "version": "5.5",
    #     "gray": "yes",
    #     "skiptest": "yes",
    #     "force": "yes",
    #     "category": "java",
    #     "projects": [
    #         "pj1",
    #         "pj2",
    #         "pj3"
    #     ]
    # }
    
    recive_header = request.headers
    recive_raw_body = request.data
    recive_json_body = recive_raw_body.decode('utf-8')
    #--logger.info(f'raw_data:{recive_raw_body}')
    #--logger.info(
    #--    f"recive_json_body:{recive_json_body}，type:{type(recive_json_body)}")
    # 调试信息
    print("请求头：")
    print(recive_header)
    print("请求body：")
    print(recive_json_body)
    print('')

    # header处理
    #
    hand_token = recive_header.get('token', '').split('=')[-1]
    print('hand_token为：' + hand_token)
    user = recive_header.get('user', '').split('=')[-1]
    sec = recive_header.get('sec', '').split('=')[-1]
    print('用户名：' + user + '\n' + '密码：' + sec)
    x_user_sign = recive_header.get('X-ZZXia-Signature', '').split('=')[-1]

    # 用户验证
    if hand_token != '':
        # 校验token
        auth_user_token_result = auth_user_token(hand_token)
        auth_user_token_result_status = extract_element_from_json(auth_user_token_result, ["Status"])[0]
        auth_user_token_result_username = extract_element_from_json(auth_user_token_result, ["Username"])[0]
        #auth_user_token_result_message = extract_element_from_json(auth_user_token_result, ["Message"])[0]
        if auth_user_token_result_status == 'Success':
            user = auth_user_token_result_username
            print('Token验证成功')
        else:
            return jsonify(auth_user_token_result)
    elif user != '' and sec != '':
        # 校验用户名密码
        auth_result = auth_user_pw(user, sec)
        #auth_result = json.loads(auth_result)
        print(auth_result)
        auth_result_status = extract_element_from_json(auth_result, ["Status"])[0]
        if auth_result_status == 'Error':
            return jsonify(auth_result)
    else:
        return jsonify({"Status": "Error", "Message": "请提供登录信息"})
    # 赋值
    gan_user_username = user


    # body处理
    #
    # 完整性签名验证
    if X_ZZXIA_SIGN_CHECK == True:
        x_server_sign = digest_hmac_sha1(X_ZZXIA_SIGN_SECRET, recive_raw_body)
        if x_user_sign != x_server_sign:
            return jsonify({"Status": "Error", "Message": "X-ZZXia-Signature 验证失败"})
    #
    #exec('kv=' + recive_json_body)      #--- 支持curl -d '{}'     和"{}"
    kv = json.loads(recive_json_body)    # --- 支持curl -d '{}'，不支持"{}"
    #
    gan_do = extract_element_from_json(kv, ["do"])
    gan_do = gan_do[0]
    #
    gan_version = extract_element_from_json(kv, ["version"])
    gan_version = gan_version[0]
    #
    gan_gray = extract_element_from_json(kv, ["gray"])
    gan_gray = gan_gray[0]
    #
    gan_project_branch = extract_element_from_json(kv, ["branch"])
    gan_project_branch = gan_project_branch[0]
    #
    gan_skiptest = extract_element_from_json(kv, ["skiptest"])
    gan_skiptest = gan_skiptest[0]
    #
    gan_force = extract_element_from_json(kv, ["force"])
    gan_force = gan_force[0]
    #
    gan_category = extract_element_from_json(kv, ["category"])
    gan_category = gan_category[0]
    #
    gan_projects = extract_element_from_json(kv, ["projects"])
    gan_projects = gan_projects[0]


    print('干:', gan_do)
    print('代码分支:', gan_project_branch)
    print('发布版本:', gan_version)
    print('灰度发布:', gan_gray)
    print('跳过测试:', gan_skiptest)
    print('强制构建:', gan_force)
    print('项目类别:', gan_category)
    print('项目列表:', gan_projects)
    #
    if not re.match(r'build|deploy|gogogo', gan_do):
        return jsonify({"Status": "Error", "Message": "wehook信息不存在或错误"})
    #
    #
    # 必须参数
    if gan_user_username == '':
        # 退出
        return jsonify({"Status": "Error", "Message": "Hook用户名为空，绝无可能"})
    else:
        gan_cmd_0 = 'export HOOK_USER=' + gan_user_username
    #
    # 关键参数
    if gan_do == 'build':
        gan_cmd = GAN_CMD_HOME + '/deploy/build.sh'
    elif gan_do == 'gogogo':
        gan_cmd = GAN_CMD_HOME + '/deploy/gogogo.sh'
        # deploy
        if gan_version != '':
            gan_cmd = gan_cmd + ' --release-version ' + gan_version
        if re.match(r'yes|YES|y|yes',gan_gray):
            gan_cmd = gan_cmd + ' --gray '
    elif gan_do == 'deploy':
        gan_cmd = GAN_CMD_HOME + '/deploy/deploy.sh  待完成 '
    else:
        # 退出
        return jsonify({"Status": "Error", "Message": "wehook信息之【do】不存在或错误"})
    #
    if re.search ('deploy', gan_do):
        if gan_projects != '':
            gan_projects_str = " ".join(map(str, gan_projects))
            gan_cmd = gan_cmd + '  ' + gan_projects_str
    else:
        if gan_project_branch != '':
            gan_cmd = gan_cmd + ' --branch ' + gan_project_branch
        if re.match(r'^yes|^YES|^y|^yes', gan_skiptest):
            gan_cmd = gan_cmd + ' --skiptest '
        if re.match(r'^yes|^YES|^y|^yes', gan_force):
            gan_cmd = gan_cmd + ' --force '
        if gan_category != '':
            gan_cmd = gan_cmd + ' --category ' + gan_category
        if gan_projects != '':
            gan_projects_str = " ".join(map(str, gan_projects))
            gan_cmd = gan_cmd + '  ' + gan_projects_str

    

    # 运行shell脚本
    #
    # hook/hand
    hook_time = time.strftime("%Y-%m-%d_T_%H%M%S", time.localtime())
    web_hook_logfile = WEB_ROOT + '/web_hook_hand---' + hook_time + '.log'
    run_result = os.system(gan_cmd_0 + ' ; ' + gan_cmd +
                           ' > ' + web_hook_logfile + ' 2>&1')
    
    return send_file(web_hook_logfile, mimetype='text/plain')



if __name__ == '__main__':
    app.run(host = "0.0.0.0", port = 9527, debug = False)




# 注意事项：
""" 
x = '{"Status": "Error", "Message": "请提供登录信息"}'
y = {"Status": "Error", "Message": "请提供登录信息"}

# 对于【x】，需要使用【json.loads】格式化，例如： 
xx = json.loads(y)
xxx = extract_element_from_json(xx, ["Status"])[0]
# 对于【y】，不需要需要使用【json.loads】格式化，例如：
yyy = extract_element_from_json(y, ["Status"])[0]

 """


#  用法：
""" 
# 获取token
#
curl - X POST \
    - H "Content-Type: application/json"  \
    - H "user: kevin"  \
    - H "sec: 47326cfc1e19fb380329440c00149a80a2a0b8d7"  \
    http: // 192.168.11.81: 9527/get/token
#
^_ ^ kevin@TM1701-b38cbc23: ~$ curl - X POST - H  "Content-Type: application/json" - H "token: 62062998434f08cdd1a0f39366a179ab"    http: // 192.168.11.81: 9527/hook/hand - d    '{"do":"build","branch":"dev_deploy","version":"5.5","gray":"yes","skiptest":"yes","force":"yes","category":"java","projects":["pj1","pj2"]}'
{"Status": "Success", "Username": "kevin"}
^_ ^ kevin@TM1701-b38cbc23: ~$ curl - X POST \
    > -H  "Content-Type: application/json"  \
    > -H "user: kevin"  \
    > -H "sec: 47326cfc1e19fb380329440c00149a80a2a0b8d7"  \
    > http: // 192.168.11.81: 9527/get/token
{"Status": "Success", "Token": "62062998434f08cdd1a0f39366a179ab"}


# 手动hook，通过用户名密码
#
curl - X POST \
    - H "Content-Type: application/json"  \
    - H "user: kevin"  \
    - H "sec: 47326cfc1e19fb380329440c00149a80a2a0b8d7"  \
    http: // 192.168.11.81: 9527/hook/hand - d  \
    '{"do":"build","branch":"dev_deploy","version":"5.5","gray":"yes","skiptest":"yes","force":"yes","category":"java","projects":["pj1","pj2"]}'
#
^_ ^ kevin@TM1701-b38cbc23: ~$ curl - X POST \
    > -H  "Content-Type: application/json"  \
    > -H "user: kevin"  \
    > -H "sec: 47326cfc1e19fb380329440c00149a80a2a0b8d7"  \
    > http: // 192.168.11.81: 9527/hook/hand - d  \
    > '{"do":"build","branch":"dev_deploy","version":"5.5","gray":"yes","skiptest":"yes","force":"yes","category":"java","projects":["pj1","pj2"]}'


# 手动hook，通过用户token
#
curl - X POST \
    - H "Content-Type: application/json"  \
    - H "token: 62062998434f08cdd1a0f39366a179ab"  \
    http: // 192.168.11.81: 9527/hook/hand - d  \
    '{"do":"build","branch":"dev_deploy","version":"5.5","gray":"yes","skiptest":"yes","force":"yes","category":"java","projects":["pj1","pj2"]}'
#
^_ ^ kevin@TM1701-b38cbc23: ~$ curl - X POST - H  "Content-Type: application/json" - H "token: 62062998434f08cdd1a0f39366a179ab"    http: // 192.168.11.81: 9527/hook/hand - d    '{"do":"build","branch":"dev_deploy","version":"5.5","gray":"yes","skiptest":"yes","force":"yes","category":"java","projects":["pj1","pj2"]}'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN" >
<title > 500 Internal Server Error < /title >
<h1 > Internal Server Error < /h1 >
<p > The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application. < /p >
^_ ^ kevin@TM1701-b38cbc23: ~$
^_ ^ kevin@TM1701-b38cbc23: ~$ curl - X POST - H  "Content-Type: application/json" - H "token: 62062998434f08cdd1a0f39366a179ab"    http: // 192.168.11.81: 9527/hook/hand - d    '{"do":"build","branch":"dev_deploy","version":"5.5","gray":"yes","skiptest":"yes","force":"yes","category":"java","projects":["pj1","pj2"]}'


# 手动gitlab hook模拟
#
curl  -X POST  \
        -H "Content-Type: application/json"  \
        -H "X-Gitlab-Event: Push Hook"  \
        -H "X-Gitlab-Token: QQQQQ12345"  \
        http://192.168.11.81:9527/hook/gitlab  \
        -d  @gitlab-push-body.json

"""


