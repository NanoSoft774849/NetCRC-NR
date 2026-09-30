#ifndef NR_CRC16_P4
#define NR_CRC16_P4

control nr_crc16(inout ns_headers hdr, inout meta_data meta, in net_crc_payload_hdr_t tb)
{

    Register<bit<16>, _>(1,0) first;
    //Register<bit<16>, _>(1,0) second;

    bit<16> prev_crc = 0;
    //bit<24> prev_crc16 = 0;

    RegisterAction < bit<16>, _, bit<16>>(first) first_act= {
        void apply(inout bit<16> value, out bit<16> rv)
        {
            value = value ^ hdr.crc16.crc;
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
    CRCPolynomial<bit<16>>( 16w0b10001000000100001, false, false, false, 0, 0) CRC16;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, CRC16) hashcrc16;

     action calc_crc16()
    {
        hdr.crc16.crc= hashcrc16.get(tb);
        //hdr.crc16.setValid();
    }

    

   action update()
   {
        prev_crc = first_act.execute(0);
        hdr.crc16.crc = prev_crc;
   }
   
   action update_reset()
   {
        prev_crc = sec_act.execute(0);
        hdr.crc16.crc = hdr.crc16.crc ^ prev_crc;
        hdr.crc16.setValid(); 
   }
    
    table crc_16
    {
        actions = { calc_crc16;}
        default_action = calc_crc16();
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
        crc_16.apply();
        final_step.apply();
    }

}
#endif