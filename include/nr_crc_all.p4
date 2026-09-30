#ifndef NR_CRC_P4

#define NR_CRC_P4

#include"crc24.p4"
#include"crc16.p4"
#include"crc11.p4"
#include"crc6.p4"


control nr_crc(inout ns_headers hdr, inout meta_data meta, in net_crc_payload_hdr_t tb)
{

     //nr_crc() ng_ran_crc;
    nr_crc24() crc24;
    nr_crc16() crc16;
    nr_crc11() crc11;
    nr_crc6() crc6;

    apply{


        if( hdr.crc.crc_type == NR_CRC_Type_t.CRC6)
        {
            crc6.apply(hdr, meta, hdr.p0);
        }
       else if(hdr.crc.crc_type == NR_CRC_Type_t.CRC11)
       {
         crc11.apply(hdr, meta , hdr.p0);
       }
       else if( hdr.crc.crc_type == NR_CRC_Type_t.CRC16)
       {
           crc16.apply(hdr, meta , hdr.p0);
       }
       else 
       {
         crc24.apply(hdr, meta , hdr.p0);
       }
    }

}

#endif