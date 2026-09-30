#ifndef NR_CRC24_P4
#define NR_CRC24_P4

control nr_crc24(inout ns_headers hdr, inout meta_data meta, in net_crc_payload_hdr_t tb)
{

    Register<bit<32>, _>(1,0) first;
    //Register<bit<32>, _>(1,0) second;

    bit<32> prev_crc = 0;
    //bit<24> prev_crc24 = 0;

    RegisterAction < bit<32>, _, bit<32>>(first) first_act= {
        void apply(inout bit<32> value, out bit<32> rv)
        {
            value = value ^ ( bit<32>) hdr.crc24.crc;
            rv = value;
        }
    };
    RegisterAction < bit<32>, _, bit<32>>(first) sec_act= {
        void apply(inout bit<32> value, out bit<32> rv)
        {
            rv = value;
            value = 0;
        }
    };
   

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


    action calc_crc24a()
    {
        hdr.crc24.crc = hashcrc24a.get(tb);
        // hdr.crc24.setValid();
    }
    action calc_crc24b()
    {
        hdr.crc24.crc = hashcrc24b.get(tb);
        // hdr.crc24.setValid();
    }
    action calc_crc24c()
    {
        hdr.crc24.crc = hashcrc24c.get(tb);
        // hdr.crc24.setValid();
    }

   action update()
   {
        prev_crc = first_act.execute(0);
        hdr.crc24.crc = prev_crc[23:0]; 
   }
   
   action update_reset()
   {
        prev_crc = sec_act.execute(0);
        hdr.crc24.crc = hdr.crc24.crc ^ prev_crc[23:0];
        hdr.crc24.setValid(); 
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
   


    table final_step 
    {
        key = { hdr.crc.last : exact;}
        actions = { update_reset; update;}
        const entries = {
            (1):update_reset();
            (0):update();
        }
        default_action = update();
        size = 2;
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
        final_step.apply();
        
    }

}
#endif