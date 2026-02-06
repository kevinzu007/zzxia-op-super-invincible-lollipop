#!/bin/bash

if [[ -f /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh ]]; then
    . /etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh
else
    echo -e "\n猪猪侠警告：未找到环境变量文件【/etc/profile.d/zzxia-op-super-invincible-lollipop.run-env.sh】，退出！\n"
    exit 1
fi

ansible-playbook  install-config-my_private_envs.yml  -e "RUN_ENV=${RUN_ENV}"  -e "MY_PRIVATE_ENVS_DIR=${MY_PRIVATE_ENVS_DIR}"


