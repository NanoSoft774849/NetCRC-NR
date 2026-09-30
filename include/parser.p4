

#ifndef __parser__p4

#define __parser__p4

#include"headers.p4"

#define PARSE_PAYLOAD(c, n) \
   state parse_payload##c \
   {\
        pkt.extract(hdr.payloads.p##c);\
        transition parse_payload##n;\
   }\
//


parser IngressParser (
    packet_in pkt, 
    out ns_headers hdr,
    out meta_data meta, 
    out ingress_intrinsic_metadata_t ig_md

)
{
    Checksum() ipv4_checksum;

    state start 
    {
        pkt.extract(ig_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition meta_init;
    }
    state meta_init {
        meta.ipv4_csum_err = 0;
        meta.dst_ipv4      = 0;
        meta.md.crc = 0;
        //meta.packet_type = packet_type_t.XOR;
        transition parse_ethernet;
    }
    
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.IPV4 :  parse_ipv4;
            ether_type_t.ARP  :  parse_arp;
            ether_type_t.NETCRC  :  parse_crc;
            default:  accept;
        }
    }
    
    state parse_arp {
        pkt.extract(hdr.arp);
        transition select(hdr.arp.hw_type, hdr.arp.proto_type) {
            (0x0001, ether_type_t.IPV4) : parse_arp_ipv4;
            default: reject; // Currently the same as accept
        }
    }

    state parse_arp_ipv4 {
        pkt.extract(hdr.arp_ipv4);
        meta.dst_ipv4 = hdr.arp_ipv4.dst_proto_addr;
        transition accept;
    }  
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        meta.dst_ipv4 = hdr.ipv4.dst_addr;
        
        ipv4_checksum.add(hdr.ipv4);
        meta.ipv4_csum_err = (bit<1>)ipv4_checksum.verify();
        
        transition select(
            hdr.ipv4.ihl,
            hdr.ipv4.frag_offset,
            hdr.ipv4.protocol)
        {
            (5, 0, ip_protocol_t.ICMP) : parse_icmp;
            (_, _, ip_protocol_t.UDP)  : parse_udp;
            default: accept;
        }
    }
    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }
    state parse_udp
    {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.src_port)
        {
            (NET_CRC_UDP_SRC_PORT_RANGE): parse_crc;
            (_): accept;
        }
    }
    
    state parse_crc{
        pkt.extract(hdr.crc);
        transition parse_payload0;
    }
   
//    PARSE_PAYLOAD(0, 1) 
//    PARSE_PAYLOAD(1, 2) 
//    PARSE_PAYLOAD(2, 3) 
 
   state parse_payload0
   {
        pkt.extract(hdr.p0);
        transition parse_payload1;
   }
   state parse_payload1
   {
        pkt.extract(hdr.p1);
        transition accept;
   }
//    state parse_payload1
//    {
//         pkt.extract(hdr.p1);
//         transition accept;
//    }
//    state parse_crc24 
//    {
//         pkt.extract(hdr.crc24);
//         transition accept;
//    }


}

#endif
