#! /usr/bin/env bash

get_protocol(){
    echo && echo -e "
1. brook
2. brook ws
3. brook wss
4. socks5" && echo
    echo "Select a protocol[1-4]"
    echo "选择一个协议[1-4]"
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

get_username(){
    echo "Input the username(optional)"
    echo "输入一个用户名（如果不需要可以不写）"
    read -e -p "-> " username
    [[ "$username" ]] && echo && get_password
}

get_password(){
    echo "Input the password"
    echo "输入一个密码"
    read -e -p "-> " password
    [[ -z "$password" ]] && echo "Invalid password!!!" && echo && get_password
    echo
}

get_port(){ #TODO: 檢查port是否被佔用
    echo "Select a port[1024-65535]"
    echo "选择一个端口[1024-65535]"
    read -e -p "-> " port
    case $port in
    1[1-9][0-9][0-9] | 10[3-9][0-9] | 102[4-9] | [2-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])    
        echo
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
    echo "Input a domain(eg. www.google.com)"
    echo "输入一个域名(例如 www.google.com)" #TODO: 沒有域名
    read -e -p "-> " domain
    [[ -z "$domain" ]] && echo "Invalid domain!!!" && echo && get_domain || clear
    echo "Make sure $domain -> $ip"
    echo "请确保 $domain -> $ip"
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
	[[ -z $ip ]] && echo "Sorry I can get your server's ip address" && echo "不好意思，无法取得服务器ip" && exit 1
}

install_nami(){
    source <(curl -L https://git.io/getnami) && clear
    if [[ ! $(command -v nami) ]];
    then
        clear
        echo "Fail to install nami"
        echo "安装nami时出错"
        exit 1
    fi
}

install_joker(){
    nami install github.com/txthinking/joker && clear
    if [[ ! $(command -v joker) ]];
    then
        clear
        echo "Fail to install joker"
        echo "安装joker时出错"
        exit 1
    fi
}

install_brook(){
    nami install github.com/txthinking/brook && clear
    if [[ ! $(command -v brook) ]];
    then
        clear
        echo "Fail to install brook"
        echo "安装brook时出错"
        exit 1
    fi
}

welcome(){
    clear
    echo "Version: v20210427"
    echo "Please wait..."
    echo "请耐心等待。。。"
}

check_root(){
    [[ $EUID != 0 ]] && echo "ROOT is required" && echo "请使用ROOT运行" && exit 1
}

install(){
    if [[ $(command -v nami) ]];
    then
        nami upgrade github.com/txthinking/nami
    else
        install_nami
    fi
    
    if [[ $(command -v joker) ]];
    then
        nami upgrade github.com/txthinking/joker
    else
        install_joker
    fi
    
    if [[ $(command -v brook) ]];
    then
        nami upgrade github.com/txthinking/brook
    else
        install_brook
    fi
}

run_brook(){
    case "$protocol" in 
    1)
        [[ "$port" ]] || get_port
        [[ "$password" ]] || get_password
        clear
        joker brook server -l :$port -p $password
        link=$(brook link -s $ip:$port -p $password)
        brook qr -s $ip:$port -p $password
        server=$ip:$port
        ;;
    2)
        [[ "$port" ]] || get_port
        [[ "$password" ]] || get_password
        clear
        joker brook wsserver -l :$port -p $password
        link=$(brook link -s ws://$ip:$port -p $password)
        brook qr -s ws://$ip:$port -p $password
        server=ws://$ip:$port
        ;;
    3)
        check_root
        get_domain
        get_password
        clear
        joker brook wssserver --domain $domain -p $password
        link=$(brook link -s wss://$domain:443/ws -p $password)
        brook qr -s wss://$domain:443/ws -p $password
        server=wss://$domain:443
        ;;
    4)
        get_port
        get_username
        clear
        if [[ -z "$username" ]];
        then
            joker brook socks5 --socks5 $ip:$port
            link=$(brook link -s socks5://$ip:$port)
            brook qr -s socks5://$ip:$port
        else
            joker brook socks5 --socks5 $ip:$port --username $username --password $password
            link=$(brook link -s socks5://$ip:$port --username $username --password $password)
            brook qr -s socks5://$ip:$port --username $username --password $password
        fi
        server=$ip:$port
        ;;
    esac
}

show_status(){
    echo
    echo "link     --> $link"
    echo "server   --> $server"
    [[ "$username" ]] && echo "username --> $username"
    [[ "$password" ]] && echo "password --> $password"
    echo
}


protocol=''
port=''
password=''
username=''

welcome
install

case "$1" in
    "--install-only") #只安裝 nami brook 和 joker
        echo "Brook has been installed successfully!"
        exit 0
        ;;
    "--brook-server") #自動安裝 -> brook server
        protocol=1 #指定使用 -> brook server
        port=$(LC_CTYPE=C tr -dc '2-9' < /dev/urandom | head -c 4) #生成隨機port -> 2222-9999
        password=$(LC_CTYPE=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12) #生成隨機12位密碼
        ;;
    "--brook-wsserver") #自動安裝 -> brook wsserver
        protocol=2 #指定使用 -> brook ws server
        port=$(LC_CTYPE=C tr -dc '2-9' < /dev/urandom | head -c 4) #生成隨機port -> 2222-9999
        password=$(LC_CTYPE=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12) #生成隨機12位密碼
        ;;
esac

get_ip
[[ "$protocol" ]] || get_protocol
run_brook
show_status





































