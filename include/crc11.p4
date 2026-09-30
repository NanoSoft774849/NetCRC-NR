#ifndef NR_CRC11_P4
#define NR_CRC11_P4

control nr_crc11(inout ns_headers hdr, inout meta_data meta, in net_crc_payload_hdr_t tb)
{

    Register<bit<16>, _>(1,0) first;
    //Register<bit<16>, _>(1,0) second;

    bit<16> prev_crc = 0;
    //bit<24> prev_crc11 = 0;

    RegisterAction < bit<16>, _, bit<16>>(first) first_act= {
        void apply(inout bit<16> value, out bit<16> rv)
        {
            value = value ^ hdr.crc11.crc;
            rv = value;
        }
    };
    RegisterAction < bit<16>, _, bit<16>>(first) sec_act= {
        void apply(inout bit<16> value, out bit<16> rv)
        {
            rv = value;
            value = 0;
        }
    };
   
    // 
    CRCPolynomial<bit<11>>( 11w0b111000100001, false, false, false, 0, 0) CRC11;
    Hash<bit<11>>(HashAlgorithm_t.CUSTOM, CRC11) hashcrc11;

     action calc_crc11()
    {
        hdr.crc11.crc [10:0] = hashcrc11.get(tb);
        //hdr.crc11.setValid();
    }

    

   action update()
   {
        prev_crc = first_act.execute(0);
        hdr.crc11.crc = prev_crc;//[10:0];
        //hdr.crc11.ch11 = 0;

   }
   
   action update_reset()
   {
        prev_crc = sec_act.execute(0);
        hdr.crc11.crc = hdr.crc11.crc ^ prev_crc;
        //hdr.crc11.ch11 = 0;
        hdr.crc11.setValid(); 
   }
    
    table crc_11
    {
        actions = { calc_crc11;}
        default_action = calc_crc11();
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
        crc_11.apply();
        final_step.apply();
    }

}
#endif