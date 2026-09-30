#ifndef NR_CRC_P4
#define NR_CRC_P4

enum bit<4> NR_CRC_Type_t 
{
    CRC24A = 0,
    CRC24B = 1,
    CRC24C = 2,
    CRC16  = 3,
    CRC11  = 4,
    CRC6   = 5
}
control nr_crc(inout ns_headers hdr, inout meta_data meta, in net_crc_payload_hdr_t tb)
{

    CRCPolynomial<bit<24>>( 24w0b1100001100100110011111011, // poly
     false, //reversed
     false, // msb
      false, //externded
       0, // Init
       0 //  Xor
        ) CRC24A;
    Hash<bit<24>>(HashAlgorithm_t.CUSTOM, CRC24A) hashcrc24a;

    // 
    CRCPolynomial<bit<24>>( 24w0b1100000000000000001100011, false, false, false, 0, 0) CRC24B;
    Hash<bit<24>>(HashAlgorithm_t.CUSTOM, CRC24B) hashcrc24b;

    // 
    CRCPolynomial<bit<24>>( 24w0b1101100101011000100010111, false, false, false, 0xFFFFFF, 0) CRC24C;
    Hash<bit<24>>(HashAlgorithm_t.CUSTOM, CRC24C) hashcrc24c;

    // 
    CRCPolynomial<bit<16>>( 16w0b10001000000100001, false, false, false, 0, 0) CRC16;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, CRC16) hashcrc16;
    //
    CRCPolynomial<bit<11>>( 11w0b111000100001, false, false, false, 0, 0) CRC11;
    Hash<bit<11>>(HashAlgorithm_t.CUSTOM, CRC11) hashcrc11;
    //
    CRCPolynomial<bit<6>>( 6w0b1100001, false, false, false, 0, 0) CRC6;
    Hash<bit<6>>(HashAlgorithm_t.CUSTOM, CRC6) hashcrc6;

    action calc_crc24a()
    {
        hdr.crc24a.crc= hashcrc24a.get(tb);
        hdr.crc24a.setValid();
    }
    action calc_crc24b()
    {
        hdr.crc24b.crc= hashcrc24b.get(tb);
        hdr.crc24b.setValid();
    }
    action calc_crc24c()
    {
        hdr.crc24c.crc= hashcrc24c.get(tb);
        hdr.crc24c.setValid();
    }
    action calc_crc16()
    {
        hdr.crc16.crc= hashcrc16.get(tb);
        hdr.crc16.setValid();
    }

    action calc_crc11()
    {
        hdr.crc11.crc= hashcrc11.get(tb);
        hdr.crc11.setValid();
    }
    action calc_crc6()
    {
        hdr.crc6.crc= hashcrc6.get(tb);
        hdr.crc6.setValid();
    }

    
     table crc_11
    {
        actions = { calc_crc11;}
        default_action = calc_crc11();
        size = 1;
    }

     table crc_6
    {
        actions = { calc_crc6;}
        default_action = calc_crc6();
        size = 1;
    }


    table crc_24_a
    {
        actions = { calc_crc24a;}
        default_action = calc_crc24a();
        size = 1;
    }

    table crc_24_b
    {
        actions = { calc_crc24b;}
        default_action = calc_crc24b();
        size = 1;
    }
    table crc_24_c
    {
        actions = { calc_crc24c;}
        default_action = calc_crc24c();
        size = 1;
    }
    table crc_16
    {
        actions = { calc_crc16;}
        default_action = calc_crc16();
        size = 1;
    }


    apply{
       
        if( hdr.crc.crc_type == NR_CRC_Type_t.CRC24A)
        {
            crc_24_a.apply();
        }
        else if( hdr.crc.crc_type == NR_CRC_Type_t.CRC24B)
        {
            crc_24_b.apply();
        }
        else if( hdr.crc.crc_type == NR_CRC_Type_t.CRC24C)
        {
            crc_24_c.apply();
        }
        else if( hdr.crc.crc_type == NR_CRC_Type_t.CRC16)
        {
            //crc_16.apply();
        }
         else if( hdr.crc.crc_type == NR_CRC_Type_t.CRC11)
        {
            //crc_11.apply();
        } 
        else if( hdr.crc.crc_type == NR_CRC_Type_t.CRC6)
        {
            //crc_6.apply();
        }
        
    }

}
#endif