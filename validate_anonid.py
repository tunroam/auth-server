#!/usr/bin/env python3

# export PREPROCESS_IGNORE_SOCKET_TESTS=TRUE

# import pesp # we use RAW sockets instead
import ipaddress
import re
import socket
from os import getenv
from sys import argv

# The following code is to get the radiusd script
#/etc/freeradius/3.0/mods-config/python/radiusd.py
# Its commented out since we use it in the python2 code
#import os
#FREERADIUSCONFDIR = '/etc/freeradius/'
#FREERADIUSCONFDIR += os.listdir(FREERADIUSCONFDIR)[0] # get version number
# https://stackoverflow.com/questions/67631/how-to-import-a-module-given-the-full-path
#import importlib.util
#spec = importlib.util.spec_from_file_location("radiusd", FREERADIUSCONFDIR + "/mods-config/python/radiusd.py")
#radiusd = importlib.util.module_from_spec(spec)
#spec.loader.exec_module(radiusd)


# https://tools.ietf.org/html/rfc4648 section 6
BASE32_STR = 'abcdefghijklmnopqrstuvwxyz234567'
SUBDOMAIN = 'tunroam'
WHITELIST_PORTS = [22,443,500] #well-known ports
WHITELIST_IPPROTO = [ # grep \ \ IPPROTO /usr/include/netinet/in.h
  socket.IPPROTO_TCP,
  socket.IPPROTO_UDP
# NOTE, the following requires RAW socket
# which in turn requires cap_net_raw or sudo
#  socket.IPPROTO_GRE,
#  socket.IPPROTO_ESP,
#  socket.IPPROTO_AH
]

# src: https://stackoverflow.com/questions/2532053/validate-a-hostname-string
def is_valid_hostname(hostname):
    if len(hostname) > 255:
        return False
    if hostname[-1] == ".":
        hostname = hostname[:-1] # strip exactly one dot from the right, if present
    allowed = re.compile("(?!-)[A-Z\d-]{1,63}(?<!-)$", re.IGNORECASE)
    return all(allowed.match(x) for x in hostname.split("."))


def flagChar2flags(char: str):
  flagint = BASE32_STR.find(char)
  flagstr = bin(flagint)[2:].zfill(5)
  return {
    'validate_certificate': int(flagstr[4]),
    'RESERVED0': int(flagstr[3]),
    'RESERVED1': int(flagstr[2]),
    'RESERVED2': int(flagstr[1]),
    'RESERVED3': int(flagstr[0]),
  }



def validateSocket(loc: str, ipproto: int, port: str):
  if ipproto not in WHITELIST_IPPROTO:
    return False

  addrRequiresPort = ipproto in [socket.IPPROTO_TCP,socket.IPPROTO_UDP]
  if addrRequiresPort:
    if port and port.isdigit():
      p = int(port)
    else:
      return False
    if p < 1024 and p not in WHITELIST_PORTS: #well-known ports
      return False

  addr = loc
  # https://docs.python.org/3/library/socket.html#constants
  if isinstance('TODO HARDCODED we only allow IPv4',str):
    ipv = socket.AF_INET
    if addrRequiresPort:
      addr = (loc,p)
  else:
    ipv = socket.AF_INET6
    if addrRequiresPort:
      addr = (loc,p,'flowinfo', 'scopeid')

  if getenv('PREPROCESS_IGNORE_SOCKET_TESTS') == "TRUE":
    print("WARNING socket is not verified!", loc, ipproto)
    return True
  
  if ipproto == socket.IPPROTO_TCP:
    socktype = socket.SOCK_STREAM
  elif ipproto == socket.IPPROTO_UDP:
    socktype = socket.SOCK_DGRAM
  else: # NOTE this need extra capabilities (cap_net_raw) or sudo
    socktype = socket.SOCK_RAW

  sock = socket.socket(ipv, socktype, ipproto)
  try:
    exitcode = sock.connect_ex(addr)
    if exitcode == 0:
      return True
    else:
      return False
  except Exception as e:
    return False
  finally:
    sock.close()


def socket2rule(addr: str, ipproto: int, port: str):
  """
  Example code, still need to be implemented
  
  We ought to create a chain per hour (e.g. 2019-11-02T22)
  and remove >12h chains every hour with a job.
  This job also needs to remove (the oldest) duplicate chains.
  
  https://wiki.nftables.org/wiki-nftables/index.php/Scripting
  https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes
  https://wiki.nftables.org/wiki-nftables/index.php/Simple_rule_management
  """
  result = "iptables-nft -A OUTPUT -j ACCEPT -d " + addr + " --protocol " + str(ipproto)
  if port and port.isdigit():
    result += " --dport " + port
  return result


def parseAnonymousIdentity(anonid: str):
  if '@' not in anonid:
    return "ERROR no delimiter found"
  if len(anonid.split('@')) is not 2:
    return "ERROR please use userpart@realmpart"
  user, realm = anonid.split('@')
  if len(user) < 3:
    return "ERROR userpart must contain IP protocols and flag char"

  flagchar = user[-1].lower()
  if flagchar not in BASE32_STR:
    return "ERROR invalid flag char"

  rawtuples = user[:-1]
  tuples = []
  for t in rawtuples.split('_'):
    if len(t) < 2:
      return "ERROR IP protocol id not in correct hex format"
    try:
      ipproto = int(t[:2],16) # hex to dec
    except Exception as e:
      return "ERROR IP protocol must be hex"
    additional = t[2:]
    if additional and not additional.isdigit():
      print("WARNING the additional value is not a port number")
    tuples.append((ipproto,additional))

  try:
    a = ipaddress.ip_address(realm)
    if isinstance(a,ipaddress.IPv6Address): # TODO future work: IPv6 support
      return "ERROR IPv6 is not supported on this Access Point"
    realmIsFQDN = False
  except ValueError:
    if is_valid_hostname(realm):
      realmIsFQDN = True
      if (SUBDOMAIN + '.') not in realm:
        return "ERROR missing the required subdomain " + SUBDOMAIN
    else:
      return "ERROR realm part is not an IP addr or FQDN"

  return {
    'userpart': user,
    'flags': flagChar2flags(flagchar),
    'realm': realm,
    'isFQDN' : realmIsFQDN,
    'ip_protocols': tuples
  }


def validateVPNendpoint(realm, tuples: list):
  rules = set()
  for ipproto, port in tuples:
    result = validateSocket(realm, ipproto, port)
    if result and len(rules) < 5: # we only allow the first 4 rules that worked (thus ESP and AH are skipped behind NAT)
      rule = socket2rule(realm,ipproto,port)
      rules.add(rule)

  if len(rules) == 0:
    return False
  return rules


def validateAnonymousIdentity(anonid: str):
  idobj = parseAnonymousIdentity(anonid)
  if isinstance(idobj,str):
    return idobj
  
  if idobj['flags']['validate_certificate']:
    return "ERROR proxying request not implemented = future work. TODO"
    eap_addr = idobj['realm']
    if idobj['isFQDN']:
      vpn_addr = 'vpn.' + idobj['realm']
    else:
      vpn_addr = eap_addr # an IP addr
  else:
    eap_addr = 'localhost' # no proxy needed
    vpn_addr = idobj['realm']

  rules = validateVPNendpoint(vpn_addr,idobj['ip_protocols'])
  if not rules:
    return 'ERROR no valid IP protocols found'
  else:
    print("WARNING setting whitelist rules is not implemented = future work. TODO")
    print(rules)
  
  responseid = idobj['userpart'] + '@' + eap_addr
  return 'INFO Welcome aboard ' + responseid



# NOTE that the exit codes in python are different from exec !!!!
# https://github.com/FreeRADIUS/freeradius-server/blob/v3.0.x/src/modules/rlm_python/radiusd.py
# https://github.com/FreeRADIUS/freeradius-server/blob/master/raddb/mods-available/exec
#  | = 0  | ok        | the module succeeded.
#  | = 1  | reject    | the module rejected the user.
#  | = 2  | fail      | the module failed.
EXEC_OK     = 0
EXEC_REJECT = 1
EXEC_FAIL   = 2

if __name__ == '__main__':
  example_anonid = '11443_1153_32_33a@8.8.8.8'
  reply = ( ('Reply-Message', 'reply from freeradius to hostapd'), )
  config = ( ('Cleartext-Password', 'password'), ) # The hardcode password as in spec.

  if len(argv) != 2:
    reply = ( ('Reply-Message',"ERROR we expect only one Anonymous-identity"), )
    exitcode = EXEC_FAIL
  else:
	  anonid = argv[1].split('=')[-1]
	
	  result = validateAnonymousIdentity(anonid)
	  if "error" in result.lower():
	    reply = ( ('Reply-Message', result), )
	    exitcode = EXEC_REJECT
	  else:
	    exitcode = EXEC_OK

  # TODO The following source:
  # https://github.com/FreeRADIUS/freeradius-server/blob/v3.0.x/src/modules/rlm_python/example.py#L79
  # tells us that we can't update the request in this old version
  # therefore we do not support proxying for now
  #result_tuple = exitcode, reply, config
  #print(result_tuple)
  print(reply)
  print(config)
  exit(exitcode)

