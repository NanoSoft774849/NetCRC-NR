#ifndef __egress__p4

#define __egress__p4


// #include"nr_crc_all.p4"


/*** Egress **/

parser EgressParser(packet_in        pkt,
    /* User */
    out ns_headers          hdr,
    out meta_data         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
    // state parse_bridge
    // {
    //     pkt.extract(meta.md);
    //     transition accept;
    // }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout ns_headers                          hdr,
    inout meta_data                         meta,
    /* Intrinsic */    
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{

      //crc24_for_payload() c1;
    //   nr_crc() NR_CRC1;
   
    apply {
        // bool is_net_crc = hdr.crc.isValid();
       
        // if(is_net_crc )
        // {
        //    // NR_CRC1.apply(hdr, meta, hdr.p1);
        //     //NR_CRC1.apply(hdr, meta, hdr.p1); // it takes 9 stages when adding this...
        //     //
        // }
    }
}



    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout ns_headers                       hdr,
    in    meta_data                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    
    apply {
        pkt.emit(hdr);
    }
}

#endif