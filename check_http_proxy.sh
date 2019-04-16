#!/bin/bash
# Author: ozzi- , forked from scott.liao (https://github.com/shazi7804/icinga-check-http-proxy)
# Description: ICINGA2 http check with proxy support

# startup checks
if [ -z "$BASH" ]; then
  echo "Please use BASH."
  exit 3
fi
if [ ! -e "/usr/bin/which" ]; then
  echo "/usr/bin/which is missing."
  exit 3
fi
wget=$(which wget)
if [ $? -ne 0 ]; then
  echo "Please install wget."
  exit 3
fi

# Default Values
ssl=""
useragent=""
host=""
port=""
proxy=""
url=""
times=1
timeout=8
warning=700
critical=2000
certificate=""
bindaddress=""

#set system proxy from environment
getProxy() {
  if [ -z "$1" ]; then
    echo $http_proxy | awk -F'http://' '{print $2}'
  else
    echo $https_proxy | awk -F'http://' '{print $2}'
  fi
}

# Usage Info
usage() {
  echo '''Usage: check_http_proxy [OPTIONS]
  [OPTIONS]:
  -p PORT               Port to check (default: 80)
  -u URL                URL path (default: /)
  -H HOSTNAME           Destination Hostname
  -a USERAGENT          Set user agent
  -s                    Use SSL via HTTPS (default: 443)
  -B BODY CONTAINS      If not contained in response body, CRITICAL will be returned
  -N BODY NOT CONTAINS  If contained in the response body, the check is run again ONCE
  -P PROXY              Proxy access (hostname:port)
  -w WARNING            Warning threshold in milliseconds (default: 700)
  -c CRITICAL           Critical threshold in milliseconds (default: 2000)
  -n TRIES              Number of times to try (default: 1)
  -t TIMEOUT            Amount of time to wait in seconds (default: 8)
  -C CERTIFICATE        Client certificate stored in file location (PEM AND DER file types allowed)
  -b IP                 Bind ip address used by wget (default: primary system address)'''
}

# Check which threshold was reached
checkTime() {
  if [ $1 -gt $critical ]; then
    echo -n "CRITICAL"
  elif [ $1 -gt $warning ]; then
    echo -n "WARNING"
  else
    echo -n "OK"
  fi
}

# Return code value
getStatus() {
  if [ $1 -gt $critical ]; then
    return 2
  elif [ $1 -gt $warning ]; then
    return 1
  else
    return 0
  fi
}

#main
#get options
while getopts "c:p:s:a:w:u:P:H:n:t:C:b:B:N:" opt; do
  case $opt in
    c)
      critical=$OPTARG
      ;;
    p)
      port=$OPTARG
      ;;
    s)
      ssl=1
      ;;
    a)
      useragent=$OPTARG
      ;;
    w)
      warning=$OPTARG
      ;;
    u)
      url=$OPTARG
      ;;
    P)
      proxy=$OPTARG
      ;;
    H)
      hostname=$OPTARG
      ;;
    n)
      times=$OPTARG
      ;;
    t)
      timeout=$OPTARG
      ;;
    C)
      client_certificate=$OPTARG
      ;;
    b)
      bindaddress=$OPTARG
      ;;
    B)
      bodycontains=$OPTARG
      ;;
    N)
      bodynotcontains=$OPTARG
      ;;
    *)
      usage
      exit 3
      ;;
  esac
done

#define host with last parameter
host=$hostname

#hostname is required
if [ -z "$host" ] || [ $# -eq 0 ]; then
  echo "Error: host is required"
  usage
  exit 3
fi

#set proxy from environment if available and no proxy option is given
if [ -z "$proxy" ]; then
  proxy="$(getProxy ssl)"
fi

#use ssl or not
if [ -z "$ssl" ]; then
  header="HTTP"
  proxy_cmd="http_proxy=$proxy"
  url_prefix="http://"
else
  header="HTTPS"
  proxy_cmd="https_proxy=$proxy"
  url_prefix="https://"
fi

#different port
if [ -z "$port" ]; then
  url="${url_prefix}${host}${url}"
else
  url="${url_prefix}${host}:${port}${url}"
fi

doCheck() {
  start=$(echo $(($(date +%s%N)/1000000)))
  if [ -z "$useragent" ]; then
    if [ -z "$client_certificate" ]; then
      #execute and capture execution time and return status of wget
      body=$($wget -t $times --timeout $timeout -qO- -e $proxy_cmd --server-response --bind-address=${bindaddress} $url 2>&1)
      status=$?
    elif [ -n "$client_certificate" ]; then
      #execute and capture execution time and return status of wget with client certificate
      body=$($wget -t $times --timeout $timeout -qO- -e $proxy_cmd --server-response --bind-address=${bindaddress} --certificate=$client_certificate $url 2>&1)
      status=$?
    fi
  else
    if [ -n "$client_certificate" ]; then
      body=$($wget -t $times --timeout $timeout -qO- -e $proxy_cmd --server-response --bind-address=${bindaddress} --certificate=$client_certificate $url --header="User-Agent: $useragent" 2>&1)
      status=$?
    else
      #execute with fake user agent and capture execution time and return status of wget
      body=$($wget -t $times --timeout $timeout -qO- -e $proxy_cmd --server-response --bind-address=${bindaddress} $url --header="User-Agent: $useragent" 2>&1)
      status=$?
    fi
  fi
  responsecode=$(echo "$body" | grep "^  HTTP\/[1-2]\.[0-9]" | tail -1 | grep "[1-9][0-9][0-9]" -o)
  end=$(echo $(($(date +%s%N)/1000000)))
}

doCheck

#decide to rerun if bodynotcontains is contained
if [ $status -eq 0 ] && [ -n "$bodynotcontains" ] && [[ $body == *$bodynotcontains* ]]; then
  sleep 1
  doCheck
fi


#decide output by return code
if [ $status -eq 0 ] ; then
  timeoutms=$(($timeout * 1000))
  duration=$((end - start))
  if [ -n "$bodycontains" ]; then
    if [[ ! $body == *$bodycontains* ]]; then
      echo "${header} NOK: body does not contain '${bodycontains}' '$responsecode' |time=${duration}ms;${warning};${critical};0;$timeoutms"
      exit 2
    fi
  fi
  echo "${header} $(checkTime $duration): ${duration}ms - ${url} '$responsecode' |time=${duration}ms;${warning};${critical};0;$timeoutms"
  getStatus $((end - start))
  exit $?
else
  case $status in
    1)
      echo "${header} CRITICAL: Generic error code ($status) - ${url}"
      ;;
    2)
      echo "${header} CRITICAL: Parse error ($status) - ${url}"
      ;;
    3)
      echo "${header} CRITICAL: File I/O error ($status) - ${url}"
      ;;
    4)
      echo "${header} CRITICAL: Network failure ($status) - ${url}"
      ;;
    5)
      echo "${header} CRITICAL: SSL verification failure ($status) - ${url}"
      ;;
    6)
      echo "${header} CRITICAL: Authentication failure ($status) - ${url}"
      ;;
    7)
      echo "${header} CRITICAL: Protocol errors ($status) - ${url}"
      ;;
    8)
      echo "${header} CRITICAL: Server issued an error response '$responsecode'  ($status) - ${url}"
      ;;
    *)
      echo "${header} UNKNOWN: $status - ${url}"
      exit 3
      ;;
  esac
  exit 2
fi
