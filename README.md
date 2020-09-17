# aranix
ArangoDB monitoring

This script is part of a monitoring solution that allows to monitor several
services and applications.

For more information about this monitoring solution please check out this post
on my [site](https://sergiotocalini.github.io/project/monitoring).

# Dependencies
## Packages
* ksh
* curl
* jq

### Debian/Ubuntu

``` bash
~# sudo apt install ksh curl jq
~#
```
### Red Hat

```bash
~# sudo yum install ksh curl jq
~#
```

# Deploy
Default variables:

NAME|VALUE
----|-----
ARANGODB_URL|http://localhost:8529

*__Note:__ these variables has to be saved in the config file (aranix.conf) in
the same directory than the script.*

## Zabbix

``` bash
~# git clone https://github.com/sergiotocalini/aranix.git
~# sudo ./aranix/deploy_zabbix.sh -u "http://localhost:8529"
~# sudo systemctl restart zabbix-agent
```
*__Note:__ the installation has to be executed on the zabbix agent host and you have
to import the template on the zabbix web. The default installation directory is
/etc/zabbix/scripts/agentd/aranix*
