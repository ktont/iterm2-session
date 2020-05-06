BEGIN{
  FS = "\t"
  OFS = "\t"
  outpun = 1
  gzmodem = 0
}

{
  gsub(/[\[\]"]/,"",$1) # remove [""]
  gsub(/^"|"$/,"",$2) # remove ""
  line[NR] = $0
}

function contains(arr, val) {
  for(i in arr) {
    if(arr[i] == val) return 1
  }
  return 0
}

function parseBlock(block, protocol, user, host, port, sudo, zmodem, passwords, commands, menu) {
  passwords[0] = ""
  commands[0] = ""; delete commands[0]
  menu[0] = ""; delete menu[0]
  blocn = length(block)
  for(i=1; i<=blocn; i++) {
    split(block[i], sp, "\t")
    if(sp[1] == "protocol") {
      protocol = sp[2]
      if(protocol != "ssh" && protocol != "telnet") {
        print "ssh/telnet support only"
        exit 1
      }
    } else if(sp[1] == "host") {
      host = sp[2]
      n=split(host, sp, "@")
      if(n == 2) {
        user = sp[1]
        host = sp[2]
      } else if(n > 2) {
        print "wrong: `host` `"host"` expect `root@111.222.333.444:555`"
        exit 1
      }
      n=split(host, sp, ":")
      if(n == 2) {
        host = sp[1]
        port = sp[2]
      } else if(n > 2) {
        print "wrong: `host` `"host"` expect `root@111.222.333.444:555`"
        exit 1
      }
    } else if(sp[1] == "user") {
      user = sp[2]
    } else if(sp[1] == "port") {
      port = sp[2]
    } else if(sp[1] == "zmodem") {
      zmodem = sp[2]
      if(zmodem != "true" && zmodem != "false") {
        print "wrong: `zmodem` expect boolean"
        exit 1
      }
      zmodem = zmodem == "true" ? 1 : 0
    } else if(sp[1] == "sudo") {
      sudo = sp[2]
      if(sudo != "true" && sudo != "false") {
        print "wrong: `sudo` expect boolean"
        exit 1
      }
      sudo = sudo == "true" ? 1 : 0
    } else if(sp[1] == "password") {
      passwords[0] = sp[2]
    } else if(match(sp[1], /^password,[0-9]+$/)) {
      passwords[substr(sp[1], 10)] = sp[2]
    } else if(sp[1] == "command") {
      commands[0] = sp[2]
    } else if(match(sp[1], /^command,[0-9]+$/)) {
      commands[substr(sp[1], 9)] = sp[2]
    } else if(sp[1] == "menu") {
      menu[0] = sp[2]
    } else if(match(sp[1], /^menu,[0-9]+$/)) {
      menu[substr(sp[1], 6)] = sp[2]
    }
  }

  if(!protocol) {
    print "invalid conf, no protocol"
    exit 1
  }

  if(!host) {
    print "invalid conf, no host"
    exit 1
  }

  n = length(passwords)
  if(!contains(passwords, "")) passwords[n++] = ""

  if(!port) port = protocol == "ssh" ? 22 : 23
  if(!sudo) sudo = 0
  if(!zmodem) zmodem = 1

  output[0]++
  output[1] = zmodem || output[1] ? 1 : 0;
  output[++outpun] = protocol
  output[++outpun] = user
  output[++outpun] = host
  output[++outpun] = port
  output[++outpun] = sudo
  output[++outpun] = zmodem

  n = length(passwords)
  output[++outpun] = n
  for(i=0; i<n; i++)
    output[++outpun] = passwords[i]

  n = length(commands)
  output[++outpun] = n
  for(i=0; i<n; i++)
    output[++outpun] = commands[i]

  n = length(menu)
  output[++outpun] = n
  for(i=0; i<n; i++)
    output[++outpun] = menu[i]
}

END {
  linn=NR
  while(linn) {
    k=0
    m=0
    for(i=1; i<=linn; i++) {
      split(line[i], sp, "\t")

      if(sp[1] ~ /^jump,/) {
        temp[++k] = substr(line[i],6)
      } else {
        current[++m] = line[i]
      }
    }
    
    #print "---------------------"
    #for(i in current) print line[i];
    #print "====================="

    parseBlock(current)

    for(i=1; i<=linn; i++) delete line[i]
    for(i=1; i<=k; i++) line[i] = temp[i]
    for(i=1; i<=k; i++) delete temp[i]
    for(i=1; i<=m; i++) delete current[i]
    linn=k
  }

  n = length(output)
  if(!n) {
    print "no conf"
    exit 1
  }
  for(i=0; i<n; i++)
    printf("PARAMS+=(\"%s\")\n", output[i])
}

