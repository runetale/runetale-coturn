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

# install_dependecy
install_dependecy

# setup turnserver.conf

# generate cert
sudo certbot --apache -d $domain