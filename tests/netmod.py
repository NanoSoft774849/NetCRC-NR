import argparse

import sys

from scapy.all import *
import enum;
#import numpy as np
import random;

NET_MOD_ETHER_TYPE = 0xABCD
NET_MOD_PROTO_TYPE = 33

def ParseArgs():
    parser = argparse.ArgumentParser()
    # dst="00:11:22:33:44:55", src="00:aa:bb:cc:dd:ee")
    parser.add_argument("--src_mac", type=str , default="00:aa:bb:cc:dd:ee")
    parser.add_argument("--dst_mac", type=str , default="00:11:22:33:44:55")
    parser.add_argument("--t", type=int , required=True , default=4)
    parser.add_argument("--src_ip", type=str, default="192.168.1.1")
    parser.add_argument("--dst_ip", type=str, default="192.168.1.3")
    parser.add_argument("--src_port", type=int, default=55443)
    parser.add_argument("--dst_port", type=int, default=2017)
    parser.add_argument("--iface", type=str, default="veth0")
    parser.add_argument("--npkts", type=int, default=1)
    parser.add_argument("--nph", type=int, default=0, required=True)
    ## indicate in which type NetMod will be carried (eth, ip, udp)
    parser.add_argument("--over", type=str , default= "udp")

    args = parser.parse_args()
    return args 

class NetModHeader(Packet):
    name = "NetModHeader"
    fields_desc = [ XBitField(name="nph", default=0x0,size=4), XBitField(name="qm", default=0x4,size=4), XBitField(name="mhl", default=0x0000,size=16), 
                   XBitField(name="seq", default=0x01,size=32), XBitField(name="ttc", default=0x0,size=8)]
    def SetLen(self, t):
        self.setfieldval("mhl", t)
        return self
    def SetBitsPerSymbols(self, bps):
        self.setfieldval("qm", bps & 0xF)
        return self
    def SetMod_Level(self, M):
        return self
    def setSeq(self, seq):
        self.setfieldval("seq", seq)
        return self
    def setNph(self, nph):
        self.setfieldval("nph", nph&0x7)
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
    modType = args.t


    payload0 = NetModPayload()
    # payload1 = NetModPayload()
    # payload2 = NetModPayload()

    pbytes0 = [ (0x11 + i) for i in range(0, 16)]
    # pbytes1 = [ (0x31 + i) for i in range(0, 16)]
    # pbytes2 = [ (0x51 + i) for i in range(0, 16)]

    # payload0.SetBitStream(pbytes0)
    # payload1.SetBitStream(pbytes1)
    # payload2.SetBitStream(pbytes2)
    nph = args.nph-1

    if( nph > 4 or nph < 0):
        print("Number of payload headers should not exceed the 3.. given = ", nph)
        return
    
    t =  modType

    if t == 1 and nph > 0 :
        print("Warning : Only one payload header is supported for BPSK(", nph, ") is given")
        nph = 0
    
    if t == 2 and nph > 1:
        print("Warning : Only 2 payload headers ")
        nph = 1
    elif t > 2 and nph > 3:
        print("Warning the given number of headers is not supported ...")
        nph = 3
    

    npayload = 16*(nph + 1)

    # if modType ==1:
    #     npayload = 16
    # elif modType==2:
    #     npayload = 32
    # else:
    #     npayload = 64
    over = args.over 
    L3 = None
    if over == "eth":
        L3 = Initialize_Ether(args)
    elif over=="ip":
        L3 = Initialize_IP(args)
    else:
        L3 = Initialize_UDP(args)
    #L3 = Initialize_UDP(args)
    NETMOD = NetModHeader().SetBitsPerSymbols(args.t).SetLen(0).setNph(nph= nph & 0xF)
    packets = []
    packets_count = args.npkts
    # if modType == 2:
    for seq in range(0, packets_count):
        pbytes0 = [random.randint(0x11, 0xFF) for _ in range(0, npayload)]
        payload0 = add_payload(pbytes0)
        NETMOD.setSeq(seq)
        p = L3/NETMOD/payload0
        packets.append(p)
        ##Send The packetsss
        p.show()
    sendp(packets, iface= iface)

    print(f" {packets_count} are sent successfully...")








if __name__ == "__main__":
    main()



