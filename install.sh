#! /usr/bin/env bash

get_protocol(){
    echo && echo -e "
1. brook
2. brook ws
3. brook wss
4. socks5" && echo
    echo "Select a protocol[1-4]" && echo "選擇一個協定[1-4]"
    read -e -p "-> " protocol
    case "$protocol" in 
        [1-4])
            echo
            ;;
        *)
            clear
            echo "Invalid protocol!!!" && echo
            get_protocol
    esac
}

get_password(){
    echo "Input the password" && echo "輸入一個密碼"
    read -e -p "-> " password
    [ -z "$password" ] && echo "Invalid password!!!" && echo && get_password
    echo
}

get_port(){
    echo "Select a port[1025-65535]" && echo "選擇一個端口[1025-65535]"
    read -e -p "-> " port
    case $port in
    1[1-9][0-9][0-9] | 10[3-9][0-9] | 102[5-9] | [2-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])    
        clear
        ;;
    *)
        clear
        echo "Invalid port!!!" && echo
        get_port
        ;;
    esac
}

get_domain(){
    port = 443
    echo "Input a domain(eg. www.google.com)" && echo "輸入一個域名(例如 www.google.com)"
    read -e -p "-> " domain
    [ -z "$domain" ] && echo "Invalid domain!!!" && echo && get_domain || clear
    echo "Make sure $domain -> $ip"
    echo "請確保 $domain -> $ip"
}

get_ip() {
	ip=$(curl -s https://ipinfo.io/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ip.sb/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ipify.org)
	[[ -z $ip ]] && ip=$(curl -s https://ip.seeip.org)
	[[ -z $ip ]] && ip=$(curl -s https://ifconfig.co/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && ip=$(curl -s icanhazip.com)
	[[ -z $ip ]] && ip=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && echo "Sorry I can get your server's ip address" && echo "不好意思，無法取得伺服器ip" && exit 1
}

install_nami(){
    curl -sL https://git.io/getnami | bash > /dev/null 2>&1 && sleep 6 && export PATH=$HOME/.nami/bin:$PATH && clear
    if not command -v nami > /dev/null 2>&1;
    then
        clear
        echo "Fail to install nami"
        echo "安裝nami時出錯"
        exit 1
    fi
}

install_joker(){
    nami install github.com/txthinking/joker && echo
    if not command -v joker > /dev/null 2>&1;
    then
        clear
        echo "Fail to install joker" && echo "安裝joker時出錯"
        exit 1
    fi
}

install_brook(){
    nami install github.com/txthinking/brook && echo
    if not command -v brook > /dev/null 2>&1;
    then
        clear
        echo "Fail to install brook" && echo "安裝brook時出錯"
        exit 1
    fi
}

welcome(){
    clear && echo "Version: v20201029"
    echo "Please wait..." && echo "請耐心等待。。。"
}

check_root(){
    [[ $EUID != 0 ]] && echo "ROOT is required" && echo "請使用ROOT運行" && exit 1
}

install(){
    install_nami
    install_joker
    install_brook
}

run_brook(){
    case "$protocol" in 
    1)
        get_port
        joker brook server -l :$port -p $password
        link=$(brook link -s $ip:$port -p $password)
        server=$ip:$port
	brook qr -s $ip:$port -p $password
        ;;
    2)
        get_port
        joker brook wsserver -l :$port -p $password
        link=$(brook link -s ws://$ip:$port -p $password)
	brook qr -s ws://$ip:$port -p $password
        server=ws://$ip:$port
        ;;
    3)
        check_root
        get_domain
        joker brook wsserver --domain $domain -p $password
        link=$(brook link -s wss://$domain:443/ws -p $password)
	brook qr -s wss://$domain:443/ws -p $password
        server=wss://$domain:443
        ;;
    4)
        get_port
        joker brook socks5 --socks5 $ip:$port
        link=$(brook link -s socks5://$ip:$port)
	brook qr -s socks5://$ip:$port
        server=$ip:$port
        ;;
    esac
}

show_status(){
    echo
    echo "link     --> $link"
    echo "server   --> $server"
    echo "password --> $password"
    echo
}

welcome
install
get_protocol
get_password
get_ip
run_brook
show_status
