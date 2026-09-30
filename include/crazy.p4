#ifndef __crazy__p4
#define __crazy__p4

control crazy(inout ns_headers hdr, inout meta_data meta, in net_crc_payload_hdr_t pl)
{

    action perform(bit<24> poly)
    {
        CRCPolynomial<bit<24>>( poly, // poly
        false, //reversed
        false, // msb
        false, //externded
        0, // Init
        0 //  Xor
            ) CRC24A;
        Hash<bit<24>>(HashAlgorithm_t.CUSTOM, CRC24A) hashcrc24a;
         hdr.crc24.crc = hashcrc24a.get(pl);
    }
    table crazy_table 
    {
        key = { hdr.crc.crc_type : exact;}
        actions ={
            perform;
        }
        size = 16;
    }

    apply{
        crazy_table.apply();
    }
}
#endif