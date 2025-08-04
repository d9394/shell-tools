#!/bin/sh

check_and_fix_hosts() {
    aa=$(nslookup raw.githubusercontent.com 4.2.2.2 | grep "Address 1:" | awk '{print $3}')
    grep -v "raw.githubusercontent.com" /etc/hosts > /tmp/hosts.tmp

    if [ -n "$aa" ]; then
        echo "$aa raw.githubusercontent.com" >> /tmp/hosts.tmp
        mv /tmp/hosts.tmp /etc/hosts
    fi
}

# 检查文件中是否每行都含有合法IPv4地址
is_valid_ip_file() {
    file="$1"

    # 取所有实际配置行（忽略空行和注释）
    config_lines=$(grep -vE '^\s*$|^\s*#' "$file")

    # 检查是否有任何一行没有包含 IPv4 地址
    bad_lines=$(echo "$config_lines" | grep -vE '([0-9]{1,3}\.){3}[0-9]{1,3}')

    if [ -z "$bad_lines" ]; then
        return 0  # 所有行都含IP，合法
    else
        echo "Invalid lines found:"
        echo "$bad_lines"
        return 1
    fi
}

# 下载函数（含校验和重试）
download_file() {
    url="$1"
    dest="$2"
    symlink="$3"
    max_retry=10
    retry=0

    while [ "$retry" -lt "$max_retry" ]; do
        wget -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)" \
            --no-check-certificate -O "$dest" "$url"

        if [ $? -eq 0 ] && is_valid_ip_file "$dest"; then
            [ -n "$symlink" ] && ln -sf "$dest" "$symlink"
            return 0
        else
            echo "Download failed or content invalid. Retrying... ($((retry+1))/$max_retry)"
            retry=$((retry+1))
            sleep 2
        fi
    done

    echo "Download failed after $max_retry attempts: $url"
    return 1
}

# 主流程
check_and_fix_hosts

mkdir -p /etc/config/dnsmasq.d
mkdir -p /tmp/html

# 下载并验证文件
download_file \
    "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/bogus-nxdomain.china.conf" \
    "/etc/config/dnsmasq.d/bogus-nxdomain.china.conf" \
    "/tmp/html/bogus-nxdomain.china.conf"

download_file \
    "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf" \
    "/etc/config/dnsmasq.d/accelerated-domains.china.conf" \
    "/tmp/html/accelerated-domains.china.conf"

# 若成功，修改 accelerated-domains 文件内容
if [ -f /etc/config/dnsmasq.d/accelerated-domains.china.conf ]; then
    sed -i 's/114.114.114.114/202.96.128.86/' /etc/config/dnsmasq.d/accelerated-domains.china.conf
    echo server=/ham.gd/202.96.128.86/ >> /etc/config/dnsmasq.d/accelerated-domains.china.conf
    echo server=/noip.cn/202.96.128.86/ >> /etc/config/dnsmasq.d/accelerated-domains.china.conf
	echo server=/3322.org/4.2.2.2/ >> /etc/config/dnsmasq.d/accelerated-domains.china.conf
fi

echo "Download and verification complete."
