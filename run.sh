#!/bin/bash

#place into fusion360.exe folder

fusion_exe="Fusion360.exe"

if test ! -f $fusion_exe
then
	echo "\"$fusion_exe\" not found"
	exit 1
fi

#check all needed programm
exe_needed="firejail"

if test "$1" = "-newif"
then
	exe_needed=$exe_needed" brctl"
fi

for i in $exe_needed
do
	find_path=$(echo $PATH | sed 's/:/ /g')

	if test -z $(find $find_path -name $i)
	then
		echo "pls, install \"$i\""
		exit 1
	fi
done

#check firejail config
fj_conf="/etc/firejail/firejail.config"
check_yes="network"
check_no="restricted-network"

for i in $check_yes
do
	if test $(grep -E "^\s{0,}$i\s{1,}yes" $fj_conf | grep -v \# > /dev/null 2>&1 ; echo $?) -ne 0
	then
		echo "pls, set \"$i\" to \"yes\" in \"$fj_conf\""
	fi
done

for i in $check_no
do
	if test $(grep -E "^\s{0,}$i\s{1,}no" $fj_conf | grep -v \# > /dev/null 2>&1 ; echo $?) -ne 0
	then
		cho "pls, set \"$i\" to \"no\" in \"$fj_conf\""
	fi
done


def_route_iface=$(ip route show default | grep -Eo -m 1 'dev\s\S{1,}\s' | cut -d' ' -f 2)

dns="8.8.8.8"

network_settings="--dns=$dns"

#changing mac on wifi probably do not possible
if test $(iw $def_route_iface info > /dev/null 2>&1; echo $?) -ne  0
then
	#if mac will be changed - fusion360 ask to login  account
	#for this reason we generate random mac and then save it to file
	mac=$(tr -dc A-F0-9 < /dev/urandom | head -c 10 | sed -r 's/(..)/\1:/g;s/:$//;s/^/02:/')
	if test -f run.mac
	then
		mac=$(cat run.mac)
	else
		echo $mac > run.mac
	fi
	network_settings="--mac=$mac "$network_settings
fi

if test "$1" = "-newif"
then
	bridge="fusion360"
	bridge_ip="192.168.150.1/24"

	#dedicated iface need for sniff fusion360 only traffic
	if test $(ip link show $bridge > /dev/null 2>&1; echo $?) -ne 0
	then
		echo "add net-iface dedicated for fusion360"
		sudo brctl addbr $bridge
		sudo ip link set dev $bridge up

		echo "add ip addr"
		sudo ip addr add $bridge_ip dev $bridge

		echo "enable traffic forwarding"
		sudo /bin/sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

		echo "enable NAT"
		sudo iptables -t nat -A POSTROUTING -o $def_route_iface -j MASQUERADE
	fi

	network_settings="--net=$bridge "$network_settings
else
	network_settings="--net=$def_route_iface "$network_settings
fi

wine_home="$HOME/.wine"

WINEDEBUG="fixme-all"
GNUTLS_DEBUG_LEVEL=0
#exist possibility to enable/disable tls versions an cipher-suites
GNUTLS_SYSTEM_PRIORITY_FILE="$wine_home/gnutls.config"


#  --env=DXVK_HUD=1 \
#  --env=DXVK_CONFIG_FILE= \
# none|error|warn|info|debug
#  --env=DXVK_LOG_LEVEL=debug \

firejail $network_settings \
  --env=GNUTLS_DEBUG_LEVEL=$GNUTLS_DEBUG_LEVEL \
  --env=GNUTLS_SYSTEM_PRIORITY_FILE=$GNUTLS_SYSTEM_PRIORITY_FILE \
  --env=WINEDEBUG=$WINEDEBUG wine Fusion360.exe
