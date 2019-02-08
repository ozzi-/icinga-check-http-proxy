# Icinga2 check_http_proxy

Check a HTTP/HTTPS endpoint using a proxy and wget.

## Usage

```
check_http_proxy.sh -P proxy:port -H hostname
```

More parameters are available:
```
Usage: check_http_proxy [OPTIONS]
  [OPTIONS]:
  -p PORT        port to check (default: 80)
  -u URL         url path (default: /)
  -H HOSTNAME    destination Hostname
  -a USERAGENT   set user agent
  -s             use SSL via HTTPS (default: 443)
  -P PROXY       proxy access (hostname:port)
  -w WARNING     warning threshold in milliseconds (default: 700)
  -c CRITICAL    critical threshold in milliseconds (default: 2000)
  -n TRIES       number of times to try (default: 1)
  -t TIMEOUT     amount of time to wait in seconds (default: 8)
  -C CERTIFICATE client certificate stored in file location (PEM AND DER file types allowed)
  -b IP          bind ip address used by wget (default: primary system address)
```

