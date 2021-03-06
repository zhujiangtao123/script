#!/bin/bash
SERVER_DIR="/opt/new_ahero/online1025_svc"
SERVER_NAME=$(ls $SERVER_DIR/bin)
SERVER_ID=$(cat $SERVER_DIR/bind.conf | grep -v '#' | awk '{print $1}')
online_stop()
{
    ps -ef | grep -v grep | grep -q $SERVER_NAME
    if [ $? -eq 0 ];then
        pkill -SIGTERM $SERVER_NAME
        sleep 5
        ps -ef | grep -v grep | grep -q  $SERVER_NAME
        if [ $? -eq 0 ];then
            pkill -9 $SERVER_NAME
            sleep 5
            ps -ef | grep -v grep | grep -q $SERVER_NAME
            if [ $? -eq 0 ];then
                echo -e "Online-$SERVER_ID Stopping  \033[31m[FAILED]\033[0m"
                exit 1
	    else
	        echo -e "Online-$SERVER_ID Stopping  \033[31m[OK]\033[0m"
            fi
	else
	    echo -e "Online-$SERVER_ID Stopping  \033[31m[OK]\033[0m"
        fi

    else
        echo -e "Online-$SERVER_ID Stopping  \033[31m[OK]\033[0m"
    fi
}

online_start()
{
    ps -ef | grep -v grep | grep  -q $SERVER_NAME-$SERVER_ID
    if [ $? -eq 0 ];then
        echo -e "Online-$SERVER_ID  \033[31m[Starting FAILED]\033[0m"
        echo -e "Online-$SERVER_ID  \033[31m[Already Running]\033[0m"
	exit 1
    else
        cd $SERVER_DIR
        ./bin/$SERVER_NAME  ./bench.conf >/dev/null 2>&1
        sleep 5
        ps -ef | grep -v grep | grep  -q $SERVER_NAME-$SERVER_ID
        if [ $? -eq 0 ];then
            echo -e "Online-$SERVER_ID Starting  \033[31m[OK]\033[0m"
        else
            echo -e "Online-$SERVER_ID Starting  \033[31m[FAILED]\033[0m"
        fi
    fi
}

online_status()
{
    ps -ef | grep -v grep | grep  -q $SERVER_NAME-$SERVER_ID
    if [ $? -eq 0 ];then
        echo -e "Online-$SERVER_ID  \033[31m[Running]\033[0m"
    else
        echo -e "Online-$SERVER_ID   \033[31m[Stopped]\033[0m"
    fi
}

online_update()
{
    TIME=$(date "+%F-%T")
    [ -d /tmp/backup/ ] || mkdir /tmp/backup/
    if [ "$1" = "libonline.so" ];then
        if [ ! -f /root/lush/libonline.so ];then
	    echo -e "$1 \033[31m[doesn't exit]\033[0m"
	    exit 1
	fi
	MD5_NEW1=$(md5sum /root/lush/libonline.so | awk '{print $1}')
	if [ -f $SERVER_DIR/libonline.so ];then
	    \cp -a $SERVER_DIR/libonline.so /tmp/backup/libonline.so$TIME
	    \cp -a /root/lush/libonline.so $SERVER_DIR/
            MD5_NEW2=$(md5sum $SERVER_DIR/libonline.so | awk '{print $1}')
	    if [ "$MD5_NEW1" = "$MD5_NEW2" ];then
	        echo -e "libonline.so updating  \033[31m[OK]\033[0m"
	    else
	        echo -e "libonline.so updating  \033[31m[FAILED]\033[0m"
		exit 2
	    fi
	else
	    echo -e "libonline.so \033[31m[doesn't exit]\033[0m"
	fi
    elif [ -f $SERVER_DIR/conf/$1 -a -f /root/lush/$1 ];then
        MD5_NEW1=$(md5sum /root/lush/$1 | awk '{print $1}')
	\cp -a $SERVER_DIR/conf/$1 /tmp/backup/$1$TIME >/dev/null 2>&1
	\cp -a /root/lush/$1 $SERVER_DIR/conf/ >/dev/null 2>&1
	MD5_NEW2=$(md5sum $SERVER_DIR/conf/$1 | awk '{print $1}')
	if [ "$MD5_NEW1" = "$MD5_NEW2" ];then
	    echo -e "$1 updating  \033[31m[OK]\033[0m"
	else
	    echo -e "$1 updating  \033[31m[FAILED]\033[0m"
	    exit 3
	fi
    else
        echo -e "./online.sh update [libonline.so | *.xml]"
        exit 4
    fi

}

if [ "$1" = "stop" ];then
    online_stop
elif [ "$1" = "start" ];then
    online_start
elif [ "$1" = "restart" ];then
    online_stop
    online_start
elif [ "$1" = "status" ];then
    online_status
elif [ "$1" = "update" ];then
    online_stop
    online_update $2
    online_start
else
    echo "./online.sh [stop|start|restart|status|update file]"
    exit 5
fi
