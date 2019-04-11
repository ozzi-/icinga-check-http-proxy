# Icinga2 check_http_proxy

Monitor a HTTP/HTTPS endpoint using a proxy (powered by wget).

## Usage

### Manually

```
check_http_proxy.sh -P proxy:port -H hostname
```

More parameters are available:
```
Usage: check_http_proxy [OPTIONS]
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
```

### Icinga
Use the following Icinga2 CheckCommand:
https://github.com/ozzi-/icinga-check-http-proxy/blob/master/commands.conf

An example of monitoring a host is shown in:
https://github.com/ozzi-/icinga-check-http-proxy/blob/master/hosts.conf
