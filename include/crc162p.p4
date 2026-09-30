#ifndef NR_CRC162P_P4
#define NR_CRC162P_P4

control nr_crc162p(inout ns_headers hdr, inout meta_data meta, in net_crc_payload_hdr_t tb, in net_crc_payload_hdr_t tb2)
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
        meta.crc16.hp0  = hashcrc16.get(tb);
        meta.crc16.hp1  = hashcrc16.get(tb2);
    }

   action update()
   {
        hdr.crc16.crc = meta.crc16.hp0 ^ meta.crc16.hp1;
        prev_crc = first_act.execute(0);
        hdr.crc16.crc = prev_crc;
   }
   
   action update_reset()
   {
        prev_crc = sec_act.execute(0);
        hdr.crc16.crc = hdr.crc16.crc ^ prev_crc;
        hdr.crc16.setValid(); 
   }

    action crc_aggr()
    {
        hdr.crc16.crc = meta.crc16.hp0 ^ meta.crc16.hp1;
    }
    table crc_aggregate 
    {
        actions = { crc_aggr;}
        default_action = crc_aggr();
        size = 1;
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
        //crc_aggregate.apply();
        final_step.apply();
    }

}
#endif