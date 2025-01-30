#!/bin/bash

# 修改以下最大单个日志文件尺寸和日志路径变量.
# 根据需求自定计划任务运行.
# 当日志文件尺寸大于 MAX_SIZE 则删除 10000 行 (可自行修改),循环检查尺寸并环删除行,直到尺寸小于 MAX_SIZE 结束.

MAX_SIZE=100000000
# 100M
LOG_PATH=/root/dnmp/logs/nginx
# LOG_PATH=/home/wwwlogs
# 日志路径

for LOG in $(ls -1 ${LOG_PATH}/*.log)
do
    SIZE=`ls -l $LOG | awk '{print $5}'`
    while [ $SIZE -gt $MAX_SIZE ]
    do
        sed -i '1,100000d' $LOG
        SIZE=`ls -l $LOG | awk '{print $5}'`
    done
done
