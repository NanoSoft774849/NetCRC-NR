import argparse

import sys

from scapy.all import *
import enum;
#import numpy as np
import random;
import crcmod
#  CRCPolynomial<bit<24>>( 24w0b1100001100100110011111011, false, false, false, 0, 0) CRC24A;
#     Hash<bit<24>>(HashAlgorithm_t.CUSTOM, CRC24A) hashcrc24a;

#     // 
#     CRCPolynomial<bit<24>>( 24w0b1100000000000000001100011, false, false, false, 0, 0) CRC24B;
#     Hash<bit<24>>(HashAlgorithm_t.CUSTOM, CRC24B) hashcrc24b;

#     // 
#     CRCPolynomial<bit<24>>( 24w0b1101100101011000100010111, false, false, false, 0, 0) CRC24C;
#     Hash<bit<24>>(HashAlgorithm_t.CUSTOM, CRC24C) hashcrc24c;

#     // 
#     CRCPolynomial<bit<16>>( 16w0b10001000000100001, false, false, false, 0, 0) CRC16;
#     Hash<bit<16>>(HashAlgorithm_t.CUSTOM, CRC16) hashcrc16;
#     //
#     CRCPolynomial<bit<11>>( 11w0b111000100001, false, false, false, 0, 0) CRC11;
#     Hash<bit<11>>(HashAlgorithm_t.CUSTOM, CRC11) hashcrc11;
#     //
#     CRCPolynomial<bit<6>>( 6w0b1100001, false, false, false, 0, 0) CRC6;
#     Hash<bit<6>>(HashAlgorithm_t.CUSTOM, CRC6) hashcrc6;
PAYLOAD = 96
NET_MOD_ETHER_TYPE = 0xABCD
NET_MOD_PROTO_TYPE = 33

CRC24A_POLY = 0b1100001100100110011111011
CRC24B_POLY = 0b1100000000000000001100011
CRC24C_POLY = 0b1101100101011000100010111
CRC16_POLY = 0b10001000000100001
CRC11_POLY = 0b111000100001
CRC6_POLY = 0b1100001

CRC_POLY_LIST = [
CRC24A_POLY ,
CRC24B_POLY,
CRC24C_POLY,
CRC16_POLY,
CRC11_POLY,
CRC6_POLY
]

CRC_LAST_BIT_MASK = [
    0x800000,
    0x800000,
    0x800000,
    0x8000,
    0x400,
    0x40
]
CRC_MASK = [
    0xFFFFFF,
    0xFFFFFF,
    0xFFFFFF,
    0xFFFF,
    0x3FF,
    0x3F
]

CRC_SHIFT = [
    16,16,16,8,3,2
]
CRC_INIT = [
    0,0,0xFFFFFF,0,0,0
]

CRC24_MASK = 0xFFFFFF


def calc_use_crc_mod(_bytes, t):
    crc_fun = crcmod.mkCrcFun(poly=CRC_POLY_LIST[t], initCrc=CRC_INIT[t], rev=False, xorOut=0)
    crc = crc_fun(data= bytes(_bytes), crc=CRC_INIT[t])
    return crc

def calc_nr_crc(init, bytes, t):
    crc = init
    bin_str = ""
    # blen = len(bytes)
    # "0"*(8-len(bx))
    # new_bytes = []
    for b in bytes:
        bx = bin(b).replace("0b","")
        bin_str += ("0"*(8-len(bx)) + bx ) #[::-1]
        # new_bytes.append(b)
    # for _ in bytes:
    #     new_bytes.append(0)

    for b in bytes:
        crc = crc ^ ( b << CRC_SHIFT[t])
        for _ in range(0, 8):
            if crc & CRC_LAST_BIT_MASK[t]:
                crc = (crc << 1) ^ CRC_POLY_LIST[t]
            else:
                crc = crc <<1
        crc = crc & CRC_MASK[t]
    # print("bin:", bin_str)
    print("bin:", bin_str[::-1])
    return crc & CRC_MASK[t]


def calc_crc24(bytes):
    crc = 0
    bin_str = ""
    # blen = len(bytes)
    # "0"*(8-len(bx))
    # new_bytes = []
    for b in bytes:
        bx = bin(b).replace("0b","")
        bin_str += ("0"*(8-len(bx)) + bx ) #[::-1]
        # new_bytes.append(b)
    # for _ in bytes:
    #     new_bytes.append(0)

    for b in bytes:
        crc = crc ^ ( b << 16)
        for _ in range(0, 8):
            if crc & 0x800000:
                crc = (crc << 1) ^ CRC24A_POLY
            else:
                crc = crc <<1
    # print("bin:", bin_str)
    print("bin:", bin_str[::-1])
    return crc & CRC24_MASK
def ParseArgs():
    parser = argparse.ArgumentParser()
    # dst="00:11:22:33:44:55", src="00:aa:bb:cc:dd:ee")
    parser.add_argument("--src_mac", type=str , default="00:aa:bb:cc:dd:ee")
    parser.add_argument("--dst_mac", type=str , default="00:11:22:33:44:55")
    parser.add_argument("--t", type=int , required=False , default=0)
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

class NetCRCHeader(Packet):
    name = "NetCRCHeader"
    fields_desc = [ XBitField(name="crc_type", default=0x0,size=4),
                   XBitField(name="last", default=0x1,size=1),
                   XBitField(name="valid", default=0x0,size=1),
                   XBitField(name="rev", default=0x0,size=2),
                   XBitField(name="tb_size", default=0x0,size=16),
                   XBitField(name="seq", default=0x0,size=16)]
    def SetCRCType(self, t):
        self.setfieldval("crc_type", t)
        return self
    def setSeq(self, seq):
        self.setfieldval("seq", seq)
        return self
    def set_tb_size(self, tb_size):
        self.setfieldval("tb_size", tb_size)
        return self
    def set_last(self, last):
        self.setfieldval("last", last)
        return self



class NetCRCPayload(Packet):
    name="NetCRCPayload"
    fields_desc = [ XBitField(name=f"b{i}", default=0,size=8) for i in range(0,PAYLOAD)]
    def SetBitStream(self, _bytes):
        for i, b in zip(range(0,PAYLOAD), _bytes):
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
    payload_size= int(size/PAYLOAD)
    p = None
    for i in range(0, payload_size):
        plx = byte_s[(PAYLOAD*i):(PAYLOAD*(i+1))]
        print("len of payload : ", len(plx))
        px = NetCRCPayload()
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


    payload0 = NetCRCPayload()
    # payload1 = NetCRCPayload()
    # payload2 = NetCRCPayload()

    pbytes0 = [ (0x11 + i) for i in range(0, 16)]
   
    
    t =  modType
    npayload = PAYLOAD

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
    NetCRC = NetCRCHeader().SetCRCType(t);
    packets = []
    # Init 
    init = CRC_INIT[t]
    crc = 0
    crc_mod = 0
    packets_count = args.npkts
    # if modType == 2:
    for seq in range(0, packets_count):
        pbytes0 = [ random.randint(0x11, 0xFF) for i in range(0, npayload)]
        crc = crc ^ calc_nr_crc(init, pbytes0, t)
        crc_mod = crc_mod^calc_use_crc_mod(pbytes0 , t)
        print(f"{crc:06X}, {bin(crc)}")
        print(f"{crc_mod:06X}, {bin(crc_mod)}")
        payload0 = add_payload(pbytes0)
        is_last = 1 if seq == packets_count -1 else 0
        NetCRC.setSeq(seq)
        NetCRC.set_last(is_last)
        p = L3/NetCRC/payload0
        packets.append(p)
        ##Send The packetsss
        # p.show()
        # sendp(p, iface =  iface)
    sendp(packets, iface= iface)

    # print(f" {packets_count} are sent successfully...")








if __name__ == "__main__":
    main()



