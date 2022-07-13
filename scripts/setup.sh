#!bin/sh

# d domain
# i listen ip, internal server ip
# p listen port
# t tls listening port
# e external ip, external server ip
# u turn user
# w turn password
while getopts 'd:i:p:t:e:u:w:' opt; do
  case $opt in
    d) domain="$OPTARG"
    ;;
    i) listen_ip="$OPTARG"
    ;;
    p) listen_port="$OPTARG"
    ;;
    t) tls_listen_port="$OPTARG"
    ;;
    e) external_ip="$OPTARG"
    ;;
    u) user="$OPTARG"
    ;;
    w) password="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&3
    ;;
  esac
done

printf "Domain is [%s]\n" "$domain"
printf "Internal Listen IP is [%s]\n" "$listen_ip"
printf "Listen Port is [%s]\n" "$listen_port"
printf "TLS Listening Port is [%s]\n" "$tls_listen_port"
printf "External IP is [%s]\n" "$external_ip"
printf "Relay IP is [%s]\n" "$listen_ip"
printf "Turn User is [%s]\n" "$user"
printf "Turn Password is [%s]\n" "$password"
printf "\n"

get_os_distribution() {
    if   [ -e /etc/debian_version ] ||
         [ -e /etc/debian_release ]; then
        if [ -e /etc/lsb-release ]; then
            distri_name="ubuntu"
        else
            distri_name="debian"
        fi
    elif [ -e /etc/fedora-release ]; then
        distri_name="fedora"
    elif [ -e /etc/redhat-release ]; then
        if [ -e /etc/oracle-release ]; then
            distri_name="oracle"
        else
            distri_name="redhat"
        fi
    elif [ -e /etc/arch-release ]; then
        distri_name="arch"
    elif [ -e /etc/turbolinux-release ]; then
        distri_name="turbol"
    elif [ -e /etc/SuSE-release ]; then
        distri_name="suse"
    elif [ -e /etc/mandriva-release ]; then
        distri_name="mandriva"
    elif [ -e /etc/vine-release ]; then
        distri_name="vine"
    elif [ -e /etc/gentoo-release ]; then
        distri_name="gentoo"
    else
        distri_name="unkown"
    fi

    echo ${distri_name}
}

if [ ! $(get_os_distribution) = "ubuntu" ]; then
  echo $(get_os_distribution) not supported
  exit 1;
fi

install_dependecy() {
  sudo add-apt-repository ppa:ubuntuhandbook1/coturn && sudo apt update \
  && sudo apt install coturn \
  && sudo apt install python3-certbot-apache \
  && sudo apt install certbot
}

# generate cert
sudo certbot --apache -d $domain

# install_dependecy
install_dependecy

setup_turnserver() {
  sed -i '/#/d' /etc/turnserver.conf &
  pid1=$!
  sed -i '/^$/d' /etc/turnserver.conf &
  pid2=$!
  wait $pid1 $pid2

  sed -i '/^$/d' /etc/turnserver.conf
  sed -i -e "1i # internal ip" /etc/turnserver.conf
  sed -i -e "$ a listening-ip=${listen_ip}" /etc/turnserver.conf
  sed -i -e "$ a relay-ip=${listen_ip}\n" /etc/turnserver.conf

  sed -i -e "$ a # global ip" /etc/turnserver.conf
  sed -i -e "$ a external-ip=${external_ip}\n" /etc/turnserver.conf

  sed -i -e "$ a # for an IP under NAT like amazon: internal_ip/external_ip" /etc/turnserver.conf
  sed -i -e "$ a external-ip=${listen_ip}/${external_ip}\n" /etc/turnserver.conf

  sed -i -e "$ a # enable authentication for user" /etc/turnserver.conf
  sed -i -e "$ a lt-cred-mech\n" /etc/turnserver.conf

  sed -i -e "$ a # define realm" /etc/turnserver.conf
  sed -i -e "$ a realm=${domain}\n" /etc/turnserver.conf

  sed -i -e "$ a # define user and password (usr:pass)" /etc/turnserver.conf
  sed -i -e "$ a user=${user}:${password}" /etc/turnserver.conf
  sed -i -e "$ a cli-password=${password}\n" /etc/turnserver.conf

  sed -i -e "$ a # define user and password (usr:pass)" /etc/turnserver.conf
  sed -i -e "$ a no-tlsv1" /etc/turnserver.conf
  sed -i -e "$ a no-tlsv1_1\n" /etc/turnserver.conf

  sed -i -e "$ a # DH Key bit length for tls" /etc/turnserver.conf
  sed -i -e "$ a dh-file=/usr/lib/python3/dist-packages/certbot/ssl-dhparams.pem\n" /etc/turnserver.conf

  sed -i -e "$ a # log config" /etc/turnserver.conf
  sed -i -e "$ a log-file=/var/log/coturn.log" /etc/turnserver.conf
  sed -i -e "$ a simple-log\n" /etc/turnserver.conf

  sed -i -e "$ a # ssl" /etc/turnserver.conf
  sed -i -e "$ a cert=/etc/letsencrypt/live/${domain}/fullchain.pem" /etc/turnserver.conf
  sed -i -e "$ a cert=/etc/letsencrypt/live/${domain}/privkey.pem\n" /etc/turnserver.conf
}

# setup turnserver.conf
setup_turnserver

# start turnserver
sudo turnserver -o  -c /etc/turnserver.conf