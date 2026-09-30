# NetCRC — In-Switch 5G NR CRC Computation on a Barefoot Tofino

> 📄 **If you use this code in research, please cite:**
>
> ```bibtex
> @article{naji2025netcrc,
>   title={Netcrc-nr: In-network 5g nr crc accelerator},
>   author={Naji, Abdulbary and Wang, Xingfu and Liu, Ping and Hawbani, Ammar and Zhao, Liang and Xu, Xiaohua and Miao, Fuyou},
>   journal={IEEE Transactions on Computers},
>   volume={74},
>   number={4},
>   pages={1418--1430},
>   year={2025},
>   publisher={IEEE}
> }
> ```
>
> Naji *et al.*, "NetCRC-NR: In-Network 5G NR CRC Accelerator",
> *IEEE Transactions on Computers*, vol. 74, no. 4, pp. 1418–1430, 2025.

## 1. What is NetCRC?

`NetCRC` is a P4_14 / TNA (Tofino Native Architecture) data-plane program
that runs on a Barefoot Tofino switch and computes **5G NR CRCs** on
transport blocks **at line rate**, in the data plane.

In a 5G NR PHY pipeline the L1/L2 scheduler has to attach a CRC to every
downlink transport block (TB) so the UE can detect decoding errors. The
CRC length depends on the block:

| CRC      | Used for                                | Polynomial (5G NR) |
|----------|-----------------------------------------|--------------------|
| **CRC24A** | TBs for very small payloads / initial access | g_A(x) |
| **CRC24B** | TBs for larger payloads, polar coding | g_B(x) |
| **CRC24C** | LDPC BG-2 / fallback                    | g_C(x) |
| **CRC16**  | some control channels / smaller blocks  | — |
| **CRC11**  | very short blocks (e.g. DCI)            | — |
| **CRC6**   | smallest blocks                         | — |

NetCRC offloads the bit-wise XOR/shift CRC computation from the DU's
software stack into the switch ASIC. Multiple input payload chunks are
parsed, a table-driven CRC core computes the running CRC, and the result
is attached back into the packet (as `crc24_hdr_t`, `crc16_hdr_t`,
`crc11_hdr_t`, or `crc6_hdr_t`).

This repository accompanies the paper **"NetCRC-NR: In-Network 5G NR CRC
Accelerator"** by Naji *et al.*, IEEE Transactions on Computers, 2025
(see citation block at the top). The paper describes the architecture,
the table-driven CRC core, and the evaluation against a software DU.

The companion project **NetModPlus** does the same trick for IQ
constellation mapping — see `NetModPlus/README.md` for that variant.

---

## 2. Repository layout

```
NetCRC/
├── p4src/
│   ├── NetCRC.p4        # Top-level program (entry point)
│   ├── netc.p4          # Alternate / older entry
│   └── crc2p.p4         # Two-payload variant
│
├── include/
│   ├── defs.p4              # Widths, enums, CRC-type table
│   ├── headers.p4           # Header & metadata structs
│   ├── parser.p4            # Ingress parser
│   ├── egress.p4            # Egress pipeline (no-op)
│   ├── forwarder.p4         # L3 ipv4_host forwarding
│   ├── arp_icmp.p4          # ARP / ICMP responder
│   ├── CRC_Ingress.p4       # Main ingress (CRC compute + forward)
│   ├── crc11.p4 crc16.p4 crc24.p4 crc6.p4      # Per-width CRC tables
│   ├── crc162p.p4           # CRC16 two-payload variant
│   ├── crc2p_ingress.p4     # Ingress for crc2p variant
│   ├── crazy.p4 crazy_ingress.p4              # Experimental variants
│   ├── nr_crc_all.p4                          # All-NR CRC types in one
│   └── old_nr-crc.p4                          # Earlier draft
│
├── scripts/                 # Build / run / sync (Tofino SDE)
│   ├── compile.sh  run_switch.sh  kill_switch.sh
│   ├── sync_to_switch.sh  sync_to_worker.sh  utils.sh
│   ├── zlog-cfg-cur
│   └── bf_drivers.log         # (already tracked — kept for history)
│
├── setup/                   # bfshell Python (control plane)
│   ├── cp3dev.py  cp3tb.py  netccp.py
│
├── git-scripts/             # Legacy self-hosted git helper scripts
│   ├── create_rep.sh  push.sh  switch.sh
│
├── tests/
│   ├── NetCRC.py            # Scapy packet generator (NetCRC wire format)
│   ├── netmod.py            # Cross-test w/ NetModPlus payloads
│   ├── crc.c crc            # C reference implementation + prebuilt binary
│   ├── crc24.txt            # Expected CRC test vectors
│   ├── qam256Map.py         # Helper (used by NetMod too)
│   └── test.txt
│
├── error.md                 # Notes on a known compile error
└── README.md                # (this file)
```

The active build path is:

```
p4src/NetCRC.p4  →  include/parser.p4
                →  include/CRC_Ingress.p4
                →  include/egress.p4
                →  TNA pipeline
```

---

## 3. Wire format

```
+-----------+-----------+-----------+-----------------+-----------+----------+
| Ethernet | IPv4 | UDP | net_crc_hdr | payload0 | payload1 | crc*_hdr |
+-----------+-----------+-----------+-----------------+-----------+----------+
  14 B       20 B       8 B        8 B             96 B       96 B    ≤ 24 B
```

* **Ethernet** – `etherType = 0xABCD` (`ether_type_t.NETCRC`).
* **IPv4** – standard; `protocol = 33` (`ip_protocol_t.NETCRC`).
* **UDP** – `src_port ∈ 55443..55505` (`NET_CRC_UDP_SRC_PORT_RANGE`).
* **`net_crc_hdr_t`** (8 bytes):

  | field      | bits | meaning |
  |------------|------|---------|
  | `crc_type` | 4    | `NR_CRC_Type_t` enum: 0=CRC24A, 1=CRC24B, 2=CRC24C, 3=CRC16, 4=CRC11, 5=CRC6 |
  | `last`     | 1    | last fragment of this TB |
  | `check`    | 1    | attach-and-verify mode |
  | `kcb`      | 1    | "key/control bit" |
  | `reserved` | 1    | future use |
  | `tb_size`  | 16   | transport-block size (bytes) |
  | `seq_id`   | 16   | sequence / TB identifier |

* **`net_crc_payload_hdr_t`** – 24 × `bs_t` (each 32 bits → 96 B). Two
  payloads (`p0`, `p1`) are pre-declared in `ns_headers`.
* **CRC trailer** – one of `crc24_hdr_t` / `crc16_hdr_t` / `crc11_hdr_t` /
  `crc6_hdr_t`, attached by the ingress control.

---

## 4. Step-by-step pipeline

### Step 0 — `p4src/NetCRC.p4`

```p4
#include<core.p4>
#include<tna.p4>
#include"../include/parser.p4"
#include"../include/egress.p4"
#include"../include/CRC_Ingress.p4"

Pipeline(IngressParser(), Ingress(), IngressDeparser(),
         EgressParser(), Egress(), EgressDeparser()) pipe;
Switch(pipe) main;
```

Standard TNA 6-stage pipeline. The CRC work is in `CRC_Ingress.p4`.

---

### Step 1 — Definitions: `include/defs.p4`

* UDP port range `NET_CRC_UDP_SRC_PORT_RANGE = 55443..55505` (NetCRC
  traffic).
* `enum NR_CRC_Type_t` — CRC24A, CRC24B, CRC24C, CRC16, CRC11, CRC6.
* `enum ether_type_t` adds `NETCRC = 0xABCD`.
* `enum ip_protocol_t` adds `NETCRC = 33`.
* Bit-width typedefs and metadata structs.

---

### Step 2 — Headers & metadata: `include/headers.p4`

* Standard L2/L3 headers (`ethernet_h`, `arp_h`, `arp_ipv4_h`, `ipv4_h`,
  `udp_h`, `icmp_h`).
* `net_crc_hdr_t` — the 8-byte CRC-control header.
* `net_crc_payload_hdr_t` — 24 × 32-bit input bits per payload.
* `net_crc_md_hdr_t` — internal metadata: running `crc`,
  `table_index`, `crc_shift8/16`, `_select`, `is_net_crc`.
* CRC result headers: `crc24_hdr_t`, `crc16_hdr_t`, `crc11_hdr_t`,
  `crc6_hdr_t`.
* `struct ns_headers` — concatenation of every header that may appear on
  the wire.
* `struct meta_data` — `dst_ipv4`, `ipv4_csum_err`, `md` (CRC state),
  `tb_size`, `crc`, `done`, `crc16`.

---

### Step 3 — Ingress parser: `include/parser.p4`

Walks the wire format diagram:

1. `start` – extract `ig_md`, advance `PORT_METADATA_SIZE`.
2. `parse_ethernet` – branch on `ether_type` (IPv4 / ARP / NETCRC).
3. `parse_arp` / `parse_arp_ipv4` – standard ARP.
4. `parse_ipv4` – extract, *verify* header checksum, branch on protocol.
5. `parse_icmp` – accept.
6. `parse_udp` – branch on `src_port` falling in
   `NET_CRC_UDP_SRC_PORT_RANGE` → `parse_crc`.
7. `parse_crc` – extract `hdr.crc`.
8. `parse_payload0`, `parse_payload1` – chained payload extract.
9. On non-NETCRC traffic the parser takes the normal IPv4/UDP/ICMP path
   and accepts.

---

### Step 4 — Forwarder: `include/forwarder.p4`

`ipv4_host` table, key on `hdr.ipv4.dst_addr`, with `send`, `send_back`,
`drop` actions — identical pattern to NetModPlus. NetCRC piggy-backs on
the same L3 forwarding logic.

---

### Step 5 — ARP/ICMP responder: `include/arp_icmp.p4`

Standard `send_arp_reply` / `send_icmp_echo_reply` actions so the switch
responds to ping and ARP for its own IPs.

---

### Step 6 — CRC compute: `include/CRC_Ingress.p4`

This is the heart of the program. The CRC is computed with a
**table-driven** approach:

* For each `bs_t` (32 bits) in `payload0` / `payload1`, look up the next
  partial CRC in a match-action table (`crc11_table`, `crc16_table`,
  `crc24_table`, `crc6_table` — see [crc11.p4](include/crc11.p4),
  [crc16.p4](include/crc16.p4), [crc24.p4](include/crc24.p4),
  [crc6.p4](include/crc6.p4)).
* Each table maps `{ current_crc_lo8, input_byte }` (for CRC24-style
  byte-at-a-time) or `{ current_crc, input_bits }` (bit-at-a-time for
  CRC11/CRC6) to the next CRC value.
* Tables are pre-populated at compile time via `const entries` so they
  fit in a single match stage. The values come from the standard 5G NR
  polynomial — see `tests/crc.c` (the C reference) and `tests/crc24.txt`
  (expected vectors).
* `meta.crc`, `meta.crc_shift8`, `meta.crc_shift16` track the running
  state. `_select` toggles which input half-word is being fed.
* After all payload bits are consumed, the chosen CRC width is taken
  from `hdr.crc.crc_type` and the result is *attached* to the packet by
  setting one of the `crc24_hdr_t` / `crc16_hdr_t` / `crc11_hdr_t` /
  `crc6_hdr_t` headers.
* If `hdr.crc.check` is set, the switch also verifies a previously
  attached CRC and drops packets that don't match.

The `apply { ... }` body of `Ingress` selects the right CRC variant
based on `hdr.crc.crc_type` (an `if/else if` cascade) and then calls
`nexthop.apply(...)` to forward.

---

### Step 7 — IngressDeparser

Recomputes the IPv4 header checksum and emits the full `hdr` chain
(including the freshly-attached CRC trailer) followed by `meta` if any
scratch data needs to be carried.

---

### Step 8 — Egress: `include/egress.p4`

Trivial pass-through — extracts `eg_intr_md`, deparser emits `hdr`. The
heavy lifting is in the ingress; egress only matters for the bypass case
on recirculation (not used in the active build).

---

## 5. End-to-end packet journey

1. **Wire** – `Ethernet(NETCRC) / IPv4 / UDP(NETCRC port) /
   net_crc_hdr / payload0 / payload1` arrives.
2. **IngressParser** – recognizes the `NETCRC` etherType / UDP port,
   pulls the CRC header and both payloads.
3. **Ingress / `CRC_Ingress`** – runs the table-driven CRC loop over
   `payload0.b0..b23` and `payload1.b0..b23`, accumulating the result in
   `meta.crc`. Final width is chosen by `hdr.crc.crc_type`.
4. **IngressDeparser** – attaches the appropriate `crc*_hdr_t`, re-checksums
   IPv4, emits the packet.
5. **nexthop** – `ipv4_host` chooses the egress port.
6. **Egress / TM** – packet exits the switch with the CRC in the trailer.

---

## 6. Build & deploy

Same `scripts/` workflow as NetModPlus — see
`NetModPlus/README.md` §6 for the full walk-through. Quick reference:

```bash
cd NetCRC
./scripts/compile.sh p4src/NetCRC.p4 build/
./scripts/run_switch.sh NetCRC
```

> **Note** — `git-scripts/create_rep.sh`, `push.sh`, and `switch.sh`
> predate the GitHub move and reference a self-hosted server at
> `210.45.124.105`. They are kept in-tree for history; for current
> GitHub usage use plain `git push origin master`.

---

## 7. Control plane

`setup/cp3dev.py` (and the older `netccp.py`, `cp3tb.py`) are bfshell
Python helpers that:

* program the per-width CRC tables (`crc11_table`, `crc16_table`,
  `crc24_table`, `crc6_table`) with the polynomial-correct entries, and
* populate the `ipv4_host` nexthop table.

Run from bfshell after boot:

```bfshell
python3 /path/to/NetCRC/setup/cp3dev.py
```

---

## 8. Test / verification

* **`tests/NetCRC.py`** — Scapy generator that builds NetCRC packets.
* **`tests/crc.c` + `tests/crc`** — reference CRC computation in C, used
  as the gold standard against which the switch output is compared.
* **`tests/crc24.txt`** — expected test vectors (CRC24, all three
  polynomials).
* **`tests/netmod.py`** — cross-tests NetModPlus payload generation.
* **`tests/qam256Map.py`** — helper used by NetMod tests too.
* **`error.md`** — notes on a known compile-time error encountered
  during development.

---

## 9. Variants

`include/` keeps several exploratory variants:

| File | Purpose |
|------|---------|
| `crc11.p4` / `crc16.p4` / `crc24.p4` / `crc6.p4` | Per-width CRC table blocks |
| `crc162p.p4` + `crc2p_ingress.p4` + `p4src/crc2p.p4` | Two-payload path |
| `nr_crc_all.p4` | Unified control that switches on `crc_type` |
| `old_nr-crc.p4` | Earlier draft |
| `crazy.p4` + `crazy_ingress.p4` | Experimental layout / stage-budget probe |
| `netc.p4` (`p4src/`) | Earlier top-level program |

The **active** program is `p4src/NetCRC.p4` → `include/CRC_Ingress.p4`.
The others are kept for reference and ablation.

---

## 10. Summary

NetCRC computes 5G NR CRCs (CRC24A/B/C, CRC16, CRC11, CRC6) on
transport blocks **inside the Tofino ASIC**, eliminating the software
CRC pass on the DU. The wire format uses an `NETCRC` etherType /
`NETCRC` UDP-port / dedicated header to flag CRC traffic to the
ingress parser, then a table-driven loop over the payload bits
produces the running CRC, which is finally attached as a small trailer
header. The host-side C reference (`tests/crc.c`) and Python generator
(`tests/NetCRC.py`) round out the verification loop.
