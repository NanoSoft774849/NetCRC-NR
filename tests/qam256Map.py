import argparse

import sys

from scapy.all import *
import enum;
#import numpy as np
import random;

NET_MOD_ETHER_TYPE = 0xABCD
NET_MOD_PROTO_TYPE = 33
eCPRI_ETHER_TYPE = 0xAEFE
eCPRI_UDP_SRC_PORT = 55379
def ParseArgs():
    parser = argparse.ArgumentParser()
    # dst="00:11:22:33:44:55", src="00:aa:bb:cc:dd:ee")
    parser.add_argument("--src_mac", type=str , default="00:aa:bb:cc:dd:ee")
    parser.add_argument("--dst_mac", type=str , default="00:11:22:33:44:55")
    parser.add_argument("--t", type=int  , default=8)
    parser.add_argument("--src_ip", type=str, default="192.168.1.1")
    parser.add_argument("--dst_ip", type=str, default="192.168.1.3")
    parser.add_argument("--src_port", type=int, default=55443)
    parser.add_argument("--dst_port", type=int, default=2017)
    parser.add_argument("--iface", type=str, default="veth0")
    parser.add_argument("--npkts", type=int, default=1)
    # parser.add_argument("--nph", type=int, default=0, required=True)
    ## indicate in which type NetMod will be carried (eth, ip, udp)
    parser.add_argument("--over", type=str , default= "udp")

    args = parser.parse_args()
    return args 
class eCPRI_Common_Header(Packet):
    name="eCPR-COMMON-HEADER"
    fields_desc = [
        XBitField(name="rev", default=0, size=4),
        XBitField(name="reseved", default=0, size=3),
        XBitField(name="C", default=0, size=1),
        XBitField(name="msg_type", default=0x01, size=8),
        XBitField(name="payload_size", default=64, size=16)
    ]
    def set_msg_type(self, type):
        self.setfieldval("msg_type", type)
        return self
    def set_len(self, len):
        self.setfieldval("payload_size", len)
        return self
    
class eCPRI_Msg_Header(Packet):
    name="eCPRI-msg-header"
    fields_desc = [
        XBitField(name="pc_id", default=0, size = 16),
        XBitField(name="seq_id", default= 0, size= 16)
    ]
    def set_pc_id(self, pc_id):
        self.setfieldval("pc_id", pc_id)
        return self
    def set_seq_id(self, seq_id):
        self.setfieldval("seq_id", seq_id)
        return self

class NetModHeader(Packet):
    name = "NetModHeader"
    fields_desc = [
        XBitField(name="pc_id", default=0, size = 16),
        XBitField(name="seq_id", default= 0, size= 16)
    ]
    def set_pc_id(self, pc_id):
        self.setfieldval("pc_id", pc_id)
        return self
    def set_seq_id(self, seq_id):
        self.setfieldval("seq_id", seq_id)
        return self
    


class NetModPayload(Packet):
    name="NetModPayload"
    fields_desc = [ XBitField(name=f"b{i}", default=0,size=8) for i in range(0,16)]
    def SetBitStream(self, _bytes):
        for i, b in zip(range(0,16), _bytes):
            self.setfieldval(f"b{i}", b)
        return self


def Initialize_UDP(args):

    ether = Ether(dst=args.dst_mac, src= args.src_mac)
    ipv4 = IP(src=args.src_ip, dst=args.dst_ip)
    udp = UDP(sport = args.src_port, dport = args.dst_port)
   

    return ether/ipv4/udp

def Initialize_IP(args):

    ether = Ether(dst=args.dst_mac, src= args.src_mac)
    ipv4 = IP(src=args.src_ip, dst=args.dst_ip, proto = NET_MOD_PROTO_TYPE)

    return ether/ipv4

def Initialize_Ether(args):
    ether = Ether(dst=args.dst_mac, src= args.src_mac, type = NET_MOD_ETHER_TYPE )
    return ether

def Initialize_eCPRI_ether(args):
    ether = Ether(dst=args.dst_mac, src= args.src_mac, type = eCPRI_ETHER_TYPE )
    ecpri = eCPRI_Common_Header().set_msg_type(0x01).set_len(64 + 4 + 4)
    return ether/ecpri
def Initialize_eCPRI_IP(args):

    ether = Ether(dst=args.dst_mac, src= args.src_mac)
    ipv4 = IP(src=args.src_ip, dst=args.dst_ip)
    udp = UDP(sport = eCPRI_UDP_SRC_PORT, dport = args.dst_port)
    ecpri = eCPRI_Common_Header().set_msg_type(0x01).set_len(64)

    return ether/ipv4/udp/ecpri




def add_payload(byte_s):
    size = len(byte_s)
    payload_size= int(size/16)
    p = None
    for i in range(0, payload_size):
        plx = byte_s[(16*i):(16*(i+1))]
        print("len of payload : ", len(plx))
        px = NetModPayload()
        px.SetBitStream(plx)
        if p == None:
            p = px
            continue
        else:
            p = p/px
        
    return p

def main():

    args = ParseArgs()

    iface = args.iface
    pbytes0 = [ (0x11 + i) for i in range(0, 16)]
    
    nph = 4

    
    

    npayload = 16*(nph + 1)
    over = args.over
    is_ecpri = False 
    L3 = None
    if over == "eth":
        L3 = Initialize_Ether(args)
    elif over=="ip":
        L3 = Initialize_IP(args)
    elif over =="ecpri-eth":
        L3 = Initialize_eCPRI_ether(args)
        is_ecpri = True
    elif over =="ecpri-ip":
        L3 = Initialize_eCPRI_IP(args)
        is_ecpri = True
    else:
        L3 = Initialize_UDP(args)
    #L3 = Initialize_UDP(args)
    NETMOD = None #NetModHeader()
    if is_ecpri:
        NETMOD = eCPRI_Msg_Header()
    else:
        NETMOD = NetModHeader()
    
    packets = []
    packets_count = args.npkts
    # if modType == 2:
    nb_layers = 16
    NETMOD.set_pc_id(10)
    for seq in range(0, packets_count):
        pbytes0 = [random.randint(0x11, 0xFF) for _ in range(0, npayload)]
        payload = add_payload(pbytes0)
        layer = seq % nb_layers
        NETMOD.set_seq_id(layer)
        # NETMOD.set_pc_id()
        p = L3/NETMOD/payload
        packets.append(p)
        ##Send The packetsss
        p.show()
    sendp(packets, iface= iface)

    print(f" {packets_count} are sent successfully...")








if __name__ == "__main__":
    main()



