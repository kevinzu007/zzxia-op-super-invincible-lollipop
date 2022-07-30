#!/bin/bash
# Create By: 猪猪侠
# License: GNU GPLv3
# Test On: CentOS 7


# 说明
# https://help.aliyun.com/document_detail/25485.html?spm=a2c4g.11186623.6.1319.435c7a12f3IXci#title-1kk-o3o-4vp


# 重启
aliyun ecs RebootInstance  --InstanceId $1

# 强制重启
aliyun ecs RebootInstance  --InstanceId $1  --ForceStop true

# 获取区域
aliyun ecs DescribeRegions
aliyun ecs DescribeRegions | jq '.Regions.Region[] | select(.LocalName == "华南3（广州）") | {RegionId}'
aliyun ecs DescribeRegions | jq '.Regions.Region[] | select(.LocalName | contains("广州")) | {RegionId}'

# 获取ecs
# https://help.aliyun.com/document_detail/151783.html
aliyun ecs DescribeInstances  --RegionId cn-guangzhou  --Tag.1.Key L --Tag.1.Value GZ  --output cols=InstanceId,InstanceName,Description,ImageId,Status rows=Instances.Instance[]
aliyun ecs DescribeInstances  --output cols=InstanceId,InstanceName,Description,ImageId,Status rows=Instances.Instance[]

aliyun ecs DescribeInstances  --output cols=InstanceId,InstanceName,Description,Status,Memory,ZoneId,VpcAttributes.PrivateIpAddress.IpAddress[0],SecurityGroupIds.SecurityGroupId,OSNameEn,RegionId rows=Instances.Instance[]







