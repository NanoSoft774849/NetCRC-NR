#ifndef NR_CRC6_P4
#define NR_CRC6_P4

control nr_crc6(inout ns_headers hdr, inout meta_data meta, in net_crc_payload_hdr_t tb)
{

    Register<bit<8>, _>(1,0) first;
    //Register<bit<8>, _>(1,0) second;

    bit<8> prev_crc = 0;
    //bit<24> prev_crc6 = 0;

    RegisterAction < bit<8>, _, bit<8>>(first) first_act= {
        void apply(inout bit<8> value, out bit<8> rv)
        {
            value = value ^ hdr.crc6.crc;
            rv = value;
        }
    };
    RegisterAction < bit<8>, _, bit<8>>(first) sec_act= {
        void apply(inout bit<8> value, out bit<8> rv)
        {
            rv = value;
            value = 0;
        }
    };
   
    // 
     CRCPolynomial<bit<6>>( 6w0b1100001, false, false, false, 0, 0) CRC6;
    Hash<bit<6>>(HashAlgorithm_t.CUSTOM, CRC6) hashcrc6;

     action calc_crc6()
    {
        hdr.crc6.crc[5:0] = hashcrc6.get(tb);
        //hdr.crc6.setValid();
    }

    

   action update()
   {
        prev_crc = first_act.execute(0);
        hdr.crc6.crc = prev_crc;//[10:0];
        //hdr.crc6.ch11 = 0;

   }
   
   action update_reset()
   {
        prev_crc = sec_act.execute(0);
        hdr.crc6.crc = hdr.crc6.crc ^ prev_crc;
        //hdr.crc6.ch11 = 0;
        hdr.crc6.setValid(); 
   }
    
    table crc_6
    {
        actions = { calc_crc6;}
        default_action = calc_crc6();
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
        crc_6.apply();
        final_step.apply();
    }

}
#endif