#ifndef __headers__p4

#define __headers__p4


#include"defs.p4"

// 6 + 6+ 2 = 14 bytes 
header ethernet_h{
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ecpri_h 
{
    bit<4> rev;
    bit<3> reserved;
    bit<1> C; // Concatenate : indicate that there still eCPRI header after...
    bit<8> msg_type;
    bit<16> payload_len;
}
header ecpri_msg_hdr_t 
{
    bit<16> pc_id; // phyical channel ID.. ( a user, a layer, am antenna port) related to PHY processing...
    bit<16> seq_id; // an Identifier of OFDM symbol, a block of sub-carrier...r
}
// 1 + 1 + 2 + 2 + 2 + 1 + 1 + 2 + 8 = 20 bytes 
header ipv4_h {
    bit<4>   version;
    bit<4>   ihl;
    // Type of Service field : bit6-7 are reserved therefore it can be used to distinguish NetMod from other protocols..
    bit<8>   diffserv;
    bit<16>  total_len;
    bit<16>  identification;
    bit<3>   flags;
    bit<13>  frag_offset;
    bit<8>   ttl;
    bit<8>   protocol;
    bit<16>  hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}
// 2 + 2 + 2 + 2 = 8
header udp_h 
{
    // An reserved Port address can be used to distinguish NetMod protocol from other network protocols ;
    // We used 55442 as a reserved port ...
    port_addr_t src_port;
    port_addr_t dest_port;
    bit<16> len;
    bit<16> checksum;
}

header icmp_h {
    icmp_type_t msg_type;
    bit<8>      msg_code;
    bit<16>     checksum;
}

header arp_h {
    bit<16>       hw_type;
    ether_type_t  proto_type;
    bit<8>        hw_addr_len;
    bit<8>        proto_addr_len;
    arp_opcode_t  opcode;
} 

header arp_ipv4_h {
    mac_addr_t   src_hw_addr;
    ipv4_addr_t  src_proto_addr;
    mac_addr_t   dst_hw_addr;
    ipv4_addr_t  dst_proto_addr;
}




// 1 + 2 + 4 + 1 = 8
header net_crc_hdr_t
{
   
   bit<4> crc_type;
   bit<1> last;
   bit<1> check;
   bit<1> kcb;
   bit<1> reserved;
   bit<16> tb_size; // Transport block size...
   bit<16> seq_id;
}

// Input payload header
header net_crc_payload_hdr_t
{
    bs_t b0; 
    bs_t b1;
    bs_t b2;
    bs_t b3;
    bs_t b4;
    bs_t b5;
    bs_t b6;
    bs_t b7;
    bs_t b8;
    bs_t b9;
    bs_t b10; 
    bs_t b11;
    bs_t b12;
    bs_t b13;
    bs_t b14;
    bs_t b15;
    bs_t b16;
    bs_t b17;
    bs_t b18;
    bs_t b19;
    bs_t b20; 
    bs_t b21;
    bs_t b22;
    bs_t b23;
}


// struct net_crc_payload_hdr_str_t
// {
//     net_crc_payload_hdr_t p0;
//     // net_crc_payload_hdr_t p1;
//     // net_crc_payload_hdr_t p2;
//     // net_crc_payload_hdr_t p3;

// }



// header net_mod_circ_hdr_t 
// {
//     // time to recirc
//     bit<8> ttc;
//     bit<8> index;
//     PortId_t inport;
//     bit<7> padd;
// }

header net_crc_md_hdr_t 
{
   // bit<32> poly;
    bit<24> crc;
    //bit<24> start;
    //bit<3>  type;
    bit<32> table_index;
    bit<32> crc_shift8;
    bit<32> crc_shift16;
   
    bit<1> _select;
    bit<1> is_net_crc;
    bit<6> padd;
}

header crc24_hdr_t 
{
    bit<24> crc;
}

header crc16_hdr_t 
{
    bit<16> crc;
}
header crc11_hdr_t 
{
    bit<16> crc;
    //bit<5> ch11;
}
header crc6_hdr_t 
{
    bit<8> crc;
    //bit<2> ch6;
}

struct ns_headers 
{
    ethernet_h  ethernet;
    arp_h       arp;
    arp_ipv4_h  arp_ipv4;
    ipv4_h      ipv4;
    icmp_h      icmp;
    udp_h       udp;
    //ecpri_h     ecpri;
    //ecpri_msg_hdr_t ecpri_msg;
    net_crc_hdr_t crc;
    net_crc_payload_hdr_t p0;
    net_crc_payload_hdr_t p1;

    //net_crc_payload_hdr_str_t payloads;
    crc24_hdr_t crc24;

    //crc24_hdr_t crc24a;
    //crc24_hdr_t crc24b;
   // crc24_hdr_t crc24c;
    crc16_hdr_t crc16;
    crc11_hdr_t crc11;
    crc6_hdr_t  crc6;

    
}

struct netcrc_crc16_md_t 
{
    bit<16> hp0;
    bit<16> hp1;
}
struct meta_data 
{
    ipv4_addr_t   dst_ipv4;
    bit<1>        ipv4_csum_err;
    bit<8> rst;
    
    net_crc_md_hdr_t md;
    bit<32> tb_size;
    bit<32> crc;
    bool done; 

    netcrc_crc16_md_t crc16;



    //layer_t layer;
}

#endif