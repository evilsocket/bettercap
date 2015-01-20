=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require_relative '../base/ispoofer'
require_relative '../logger'
require 'nokogiri'

class InfotargetSpoofer < ISpoofer
  def initialize( iface, router_ip, targets )
    @iface        = iface
    @gw_ip        = router_ip
    @targets      = targets
  end


  def start
    if(Shell.execute("nmap --version") != "ERROR")

      if (@targets.respond_to?('each'))
        @targets.each{
          |target| scan(target[0])
        }
      else
        scan(@targets)
      end

    else
      Logger.info "Error, nmap not found in this system."
    end

    #simulate Control + c
    Process.kill 'INT', 0
  end

  def stop
    #do nothing
  end

  private
  def scan(ip)
    Shell.execute("nmap -F -Pn -sV -O -oX /tmp/#{ip}.xml #{ip}")
    parseNmapOutput("/tmp/#{ip}.xml")
  end

  def parseNmapOutput(file)
    f = File.open(file)
    doc = Nokogiri::XML(f)
    f.close

    #get ip,mac address,vendor
    addresses=doc.xpath("//address")
    infoaddr=joinInfo(addresses,method( :parseAddress ))

    if infoaddr != ""
      #get open port
      ports=doc.xpath("//portused")
      infoports=joinInfo(ports,method( :parsePort ))
      #get os
      os=doc.xpath("//osmatch")
      infoos=joinInfo(os,method( :parseOs ))
      showResult(infoaddr,infoports,infoos)
    end

  end

  def joinInfo(stringArray,functionToCall)
    out = ""
    if (stringArray.respond_to?('each'))
      stringArray.each{
        |single|
        r = functionToCall.call(single)
        if r != ""
          out+=r+"\n"
        end
      }
    else
      out= functionToCall(stringArray)
    end
    return out
  end

  def parseAddress(address)
    r=""
    if address.key?("addr") and address.key?("addrtype")
      r=address["addrtype"] +": "+ address["addr"]
    end
    if address.key?("vendor")
      r+="\nvendor: " + address["vendor"]
    end
    return r
  end

  def parsePort(port)
    r=""
    if port.key?("state") and port.key?("proto") and port.key?("portid")
      if port["state"] == "open"
        r="Port: "+port["proto"]+"->"+port["portid"]
      end
    end
    return r
  end

  def parseOs(os)
    r=""
    if os.key?("name") and os.key?("accuracy")
      r="Os:"+os["name"]
      r+="\nAccuracy:"+os["accuracy"]
    end
    return r
  end

  def showResult(infoaddr,infoports,infoos)
    printBeauty(infoaddr,"")
    printBeauty(infoports,"  ")
    printBeauty(infoos,"  ")
    Logger.info "---------------------------------"
  end

  def printBeauty(msg,padding)
    if (msg.split("\n").respond_to?('each'))
      msg.split("\n").each{
        |info| Logger.info padding + "#{info}"
      }
    else
      Logger.info padding + "#{msg}"
    end
  end

end
