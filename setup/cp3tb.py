
P4 = bfrt.NetCRC.pipe
Ingress = P4.Ingress
# NETMOD = Ingress.NetMod
nexthop = Ingress.nexthop.ipv4_host
l2_switch = Ingress.nexthop.l2_switch
PORT_TABLE = bfrt.port.port


def clear_table(table):
    table.clear();

# def Configure_Generic():
#     Configure_QAM256_tables()
#     Configure_QAM64_tables()


def add_with_send(ip, port):
    nexthop.add_with_send(dst_addr = ip, port = port)

def add_with_send_many( _list):
    for (port, ip) in _list:
        add_with_send(ip = ip, port = port)


def add_l2_route(dst_mac, port):
    l2_switch.add_with_l2_send(dst_addr= dst_mac, port = port)

def main():
    
    
    # recirc_ports = [ 68 , 69 , 70 , 71]
    # add_recirc_ports(recirc_ports)
    # Configure_NetMod_tables()
    # ports = [ 172, 180 , 140, 132]
    # for port in ports :
    #     PORT_TABLE.add(port, "BF_SPEED_100G", "BF_FEC_TYP_RS", 4, True)
    
    # Configure_NetMod_tables()
    # Configure_QAM64_tables()
   

    clear_table(nexthop)
    clear_table(l2_switch)
    # add The IPV4 table entries..
    # add_with_send(ip = "198.18.0.2", port = 64) # this will forward any incoming packet to the port 2 ( veth5, veth4)
    # add_with_send(ip = "198.18.0.1", port = 64)
    # add_with_send(ip = "192.168.1.3",port = 64)

    for i in range(0, 16):
        port = 64
        ip = f"192.168.1.{i}"
        add_with_send(ip = ip, port = port)

    # add_with_send(ip = "192.168.1.1", port = 0xAC) # 172 || server 1
    # add_with_send(ip = "192.168.1.2", port = 0xB4) # 180 || server 2
    # add_with_send(ip = "192.168.1.3", port = 0x8C) # 140 || server 3
    # add_with_send(ip = "192.168.1.4", port = 0x84) # 132 || server 4
    add_l2_route(dst_mac="00:11:22:33:44:55", port = 64)
    bfrt.complete_operations()

if __name__=="__main__":
    main()

