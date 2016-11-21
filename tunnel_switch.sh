#!/bin/bash
localwan_ip=
remotewan_ip=
localmpls_ip=
remotempls_ip=
remotelan=
mpls_device=

#切换状态默认是0
Switch_config="/etc/openvpn/switch_status"
#加载路由模块
modprobe ipip
modprobe ip_gre

ifconfig|grep tunnel1
if [ $? -ne 0 ];then 
	#添加隧道
	ip tunnel add tunnel1 mode gre local $localwan_ip remote $remotewan_ip ttl 255
	ip link set tunnel1 up
	ip addr add 10.10.10.1 peer 10.10.10.2 dev tunnel1
	iptables -t nat -A POSTROUTING -o tunnel1 -j MASQUERADE
else
	echo "tunnel is existed"
fi

#线路切换
switch_status=`cat $Switch_config`
ping $remotempls_ip -I $mpls_device -c 2 >/dev/null 2>&1
if [ $? -eq 0 ];then
	if [ $switch_status -eq 0 ];then
		echo "don't neet to switch"
	else
	    #切回线路
		ip ro del $remotelan via 10.10.10.1 dev tunnel1
		ip ro add $remotelan via $localmpls_ip dev $mpls_device
		echo "0" > $Switch_config
	fi
else
    if [ $switch_status -eq 0];then
		#切换到gre隧道上
		ip ro del $remotelan via $localmpls_ip dev $mpls_device
		ip ro add $remotelan via 10.10.10.1 dev tunnel1
		
	else
		echo "route has been switched"
	fi
fi


	
	
	


