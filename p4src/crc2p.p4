#include<core.p4>
#include<tna.p4>
//#define MULTI_PAYLOAD 1

#include"../include/parser.p4"
#include"../include/egress.p4"
#include"../include/crc2p_ingress.p4"

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
