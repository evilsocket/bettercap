# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Network
module Protos
module NTLM

# https://msdn.microsoft.com/en-us/library/ee441774.aspx
# https://developer.gnome.org/evolution-exchange/stable/ximian-connector-ntlm.html
class Packet < Network::Protos::Base
  uint8  :netbios_message_type
  bytes  :netbios_length, :size => 3

  string :smb_protocol, :size => 4, :check => "\xFFSMB"
  uint8  :smb_command
  uint32 :smb_status
  uint8  :smb_flags
  uint16 :smb_flags2
  uint16 :smb_pid_high
  bytes  :smb_signature, :size => 8
  uint16 :smb_reserved
  uint16 :smb_tid
  uint16 :smb_pid_low
  uint16 :smb_uid
  uint16 :smb_mid

  uint8  :word_count
  uint8  :and_x_command
  uint8  :reserved
  uint16 :and_x_offset
  uint16 :max_buffer
  uint16 :max_mpx_count
  uint16 :vc_number
  uint32 :session_key
  uint16 :security_blob_length
  uint32 :reserved_2
  uint32 :capabilities
  uint16 :byte_count

  bytes  :dummy, :size => 12

  string :protocol, :size => 8, :check => "NTLMSSP\x00"
  uint32 :type

  uint16 :lm_resp_len
  uint16 :lm_resp_max_len
  uint32 :lm_resp_off

  uint16 :nt_resp_len
  uint16 :nt_resp_max_len
  uint32 :nt_resp_off

  uint16 :dom_resp_len
  uint16 :dom_resp_max_len
  uint32 :dom_resp_off

  uint16 :user_resp_len
  uint16 :user_resp_max_len
  uint32 :user_resp_off

  uint16 :host_resp_len
  uint16 :host_resp_max_len
  uint32 :host_resp_off

  uint16 :session_resp_len
  uint16 :session_resp_max_len
  uint32 :session_resp_off

  uint32 :flags

  bytes  :lm_response,      :size => :lm_resp_len
  bytes  :ntlm_response,    :size => :nt_resp_len
  string :domain_name,      :size => :dom_resp_len
  string :user_name,        :size => :user_resp_len
  string :host_name,        :size => :host_resp_len
  bytes  :session_key_resp, :size => :session_resp_len

  def is_auth?
    self.type == 0x03 #NTLMSSP_AUTH
  end
end

end
end
end
end
