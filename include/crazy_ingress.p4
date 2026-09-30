#ifndef CRC24_Ingress_P4
#define CRC24_Ingress_P4

#include"forwarder.p4"
#include"nr_crc_all.p4"

// #include"nr-crc.p4"


control Ingress(
    /* User */
    inout ns_headers                       hdr,
    inout meta_data                        meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
    {
       

       Forwarder() nexthop;  
     
      nr_crc() NR_CRC0;
      nr_crc() NR_CRC1;
        
       apply{

        bool is_net_crc = hdr.crc.isValid();
       
        if(is_net_crc )
        {
            NR_CRC0.apply(hdr, meta, hdr.p0);
            NR_CRC1.apply(hdr, meta, hdr.p1); // it takes 9 stages when adding this...
            //
        }
        
         nexthop.apply(hdr, meta, ig_intr_md, ig_prsr_md, ig_dprsr_md, ig_tm_md);
       }
         
    }


control IngressDeparser(packet_out pkt,
    /* User */
    inout ns_headers                       hdr,
    in    meta_data                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    Checksum() ipv4_checksum;
    apply {

        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
                /* Adding hdr.ipv4_options.data results in an error */
            });
         //pkt.emit(meta.md); // brideg header ...
         pkt.emit(hdr);
         //pkt.emit(meta.IQ_headers);
        //  pkt.emit(meta.qpsk);
        //  pkt.emit(meta.qam16);
    }
}

#endif
