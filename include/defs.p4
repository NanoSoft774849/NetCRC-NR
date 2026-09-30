#ifndef __defs__p4
#define __defs__p4

//#define NET_MOD_ETHER_TYPE 0x
#define NET_CRC_UDP_SRC_PORT_RANGE 55443..55505
#define ECPRI_MOD_SRC_PORT_RANGE 55379..55442
// table size for MODulations types 
#define MOD_TABLE_SIZE 32
// Number of bits per IQ symbol
#define IQ_BITS_PER_SYMBOL  30
//the number of bits in the b's in the net_mod_payload_hdr_t 
#define PAYLOAD_BITS_PER_B  32
// The number of IQs in the main header struct 
#define IQ_HDRS_COUNT  16
// the number of payloads in the main header struct
#define PAYLOAD_HDRS_COUNT  8
// the number of s_i in the net_mod_iq_hdr_t
#define IQ_HDR_S_COUNT 16
// the number of b_i in the net_mod_payload_hdr_t
#define PAYLOAD_HDR_B_COUNT 16

#define NET_MOD_RECIRCULATION_PORT 192

#define NET_MOD_LAYER_TYPE 8
//#define hs_IQ_count (PAYLOAD_HDR_B_COUNT * PAYLOAD_BITS_PER_B * hdr.mod.mhl)

typedef bit<IQ_BITS_PER_SYMBOL> iq_t;
typedef bit<PAYLOAD_BITS_PER_B>   bs_t;
typedef bit<NET_MOD_LAYER_TYPE> layer_t;


enum bit<4> NR_CRC_Type_t 
{
    CRC24A = 0,
    CRC24B = 1,
    CRC24C = 2,
    CRC16  = 3,
    CRC11  = 4,
    CRC6   = 5
}


typedef bit<48> mac_addr_t;
//typedef bit<32> int32;
//typedef bit<32> key_t;
//typedef bit<32> var_t;
typedef bit<16> port_addr_t;
typedef bit<32> ipv4_addr_t;

typedef bit<32> index_t;
//typedef bit<32> counter_t;

//#define NEXTHOP_ID_WIDTH 14
//typedef bit<NEXTHOP_ID_WIDTH> nexthop_id_t;
//const int NEXTHOP_SIZE = 1 << NEXTHOP_ID_WIDTH;

/* Header Stuff */
enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    ARP  = 0x0806,
    IPV6 = 0x86DD,
    MPLS = 0x8847,
    eCPRI = 0xAEFE,
    NETCRC = 0xABCD
}

enum bit<8> ip_protocol_t {
    ICMP = 1,
    IGMP = 2,
    TCP  = 6,
    UDP  = 17,
    NETCRC = 33
}

enum bit<16> arp_opcode_t {
    REQUEST = 1,
    REPLY   = 2
}


enum bit<8> icmp_type_t {
    ECHO_REPLY   = 0,
    ECHO_REQUEST = 8
}
enum bit<8> ecpri_msg_type_t 
{
    IQ_DATA = 0, 
    BIT_SEQ = 1, 
    RT_CTRL_DATA =2
}
enum bit<4> packet_type_t 
{
    SHIFT_0=0,
    SHIFT_1=1,
    SHIFT_2=2,
    SHIFT_3=3,
    SHIFT_4=4,
    SHIFT_5=5,
    SHIFT_6=6,
    SHIFT_7=7,
    XOR = 8,
    READ = 9
}

// enum bit<3> Mod_type 
// {
//     BPSK = 1, 
//     QPSK = 2,
//     QAM16= 3, 
//     QAM64 = 4,
//     QAM256 = 
// }

#endif