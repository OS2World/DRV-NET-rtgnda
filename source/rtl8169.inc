; *** Realtek RTL8169 definition ***

; +++ registers definition +++
RTL8169_Registers	struc
IDR0		dd	?	; 00 ID0-3
IDR4		dd	?	; 04 ID4-5
MAR0		dd	?	; 08 Multicast 0-3
MAR4		dd	?	; 0c Multicast 4-7
DTCCR		dd	?,?	; 10 Dump Tally Counter Command(64bit)
		dd	?,?	; 18,1c reserved
TNPDS		dd	?,?	; 20 Transmit Normal Priority Descriptors
THPDS		dd	?,?	; 28 Transmit High Priority Descriptor
FLASH		dd	?	; 30 Flash memory read/write
ERBCR		dw	?	; 34 Early Receive Byte Count
ERSR		db	?	; 36 Early Receive Status
CR		db	?	; 37 Command
TPPoll		db	?	; 38 Transmit Priority Polling
		db	?,?,?	; 39-3b reserved
IMR		dw	?	; 3c Interrupt Mask
ISR		dw	?	; 3e Interrupt Status
TCR		dd	?	; 40 Transmit Configuration
RxCR		dd	?	; 44 Receive Configuration
TCTR		dd	?	; 48 Timer Count
MPC		dd	?	; 4c Missed Packet Counter
ECR		db	?	; 50 93C46 Command
CONFIG0		db	?	; 51 Configuration 0
CONFIG1		db	?	; 52 Configuration 1
CONFIG2		db	?	; 53 Configuration 2
CONFIG3		db	?	; 54 Configuration 3
CONFIG4		db	?	; 55 Configuration 4
CONFIG5		db	?	; 56 Configuration 5
		db	?	; 57 reserved
TimerInt	dd	?	; 58 Timer Interrupt
MULINT		dw	?	; 5c Multiple Interrupt select
		dw	?	; 5e reserved
PHYAR		dd	?	; 60 PHY Access
TBICSR0		dd	?	; 64 TBI Control Status
TBI_ANAR	dw	?	; 68 TBI AN Advertisement
TBI_LPAR	dw	?	; 6a TBI AN Link Partner Ability
PHYStatus	db	?	; 6c PHY Status
		db	?,?,?	; 6d-6f reserved
		dd	5 dup(?) ; 70-83 reserved
Wakeup0		dd	?,?	; 84 Power Management Wakeup Frame 0
Wakeup1		dd	?,?	; 8c Power Management Wakeup Frame 1
Wakeup2LD	dd	?,?	; 94 Power Management Wakeup Frame 2 LD
Wakeup2HD	dd	?,?	; 9c Power Management Wakeup Frame 2 HD
Wakeup3LD	dd	?,?	; a4 Power Management Wakeup Frame 3 LD
Wakeup3HD	dd	?,?	; ac Power Management Wakeup Frame 3 HD
Wakeup4LD	dd	?,?	; b4 Power Management Wakeup Frame 4 LD
Wakeup4HD	dd	?,?	; bc Power Management Wakeup Frame 4 HD
CRC0		dw	?	; c4 16bit CRC of Wakeup Frame 0
CRC1		dw	?	; c6 16bit CRC of Wakeup Frame 1
CRC2		dw	?	; c8 16bit CRC of Wakeup Frame 2
CRC3		dw	?	; ca 16bit CRC of Wakeup Frame 3
CRC4		dw	?	; cc 16bit CRC of Wakeup Frame 4
		dw	?	; ce
		dd	?,?	; d0 reserved
		dw	?	; d8
RMS		dw	?	; da Receive Packet Maximum Size
		dd	?	; dc reserved
CpCR		dw	?	; e0 C+ Command
		dw	?	; e2
RDSAR		dd	?,?	; e4 Recieve Descriptor Start Address
ETThR		db	?	; ec Early Transmit Threshold
		db	?,?,?	; ed
FER		dd	?	; f0 Function Event
FEMR		dd	?	; f4 Function Event Mask
FPSR		dd	?	; f8 Function Present State
FFER		dd	?	; fc Function Force Event
RTL8169_Registers	ends

; +++ Dump Tally Counter 10h 64bit +++
; 63:6 CntrAddr 64byte alignment
Cmd		equ	8	; Command (self clear)

DTCB		struc
TxOk		dd	?,?	; 00 64bit
RxOk		dd	?,?	; 08 64bit
TxEr		dd	?,?	; 10 64bit
RxEr		dd	?	; 18 32bit
MissPkt		dw	?	; 1c 16bit
FAE		dw	?	; 1e 16bit
Tx1Col		dd	?	; 20 32bit
TxMCol		dd	?	; 24 32bit
RxOkPhy		dd	?,?	; 28 64bit
RxOkBrd		dd	?,?	; 30 64bit
RxOkMul		dd	?	; 38 32bit
TxAbt		dw	?	; 3c 16bit
TxUndrn		dw	?	; 3e 16bit
DTCB		ends

; +++ Flash Memory Read/Write 30h 32bit +++
MD07		equ	0ff000000h	; MD7-MD0 (mask)
ROMCSB		equ	   100000h	; Chip Select
OEB		equ	    80000h	; Output Enable
WEB		equ	    40000h	; Write Enable
SWRWEn		equ	    20000h	; Enable software access to flash
MA016		equ	    1ffffh	; MA16-MA0 (mask)

; Early Receive Status 36h 8bit +++
ERGood		equ	8	; Early Rx good packet (st)
ERBad		equ	4	; Early Rx bad packet (st)
EROVW		equ	2	; Early Rx overwrite (st)
EROK		equ	1	; Early Rx Ok (sc)

; +++ Command 37h 8bit +++
RST		equ	10h	; Reset
RE		equ	8	; receiver Enable
TE		equ	4	; transmit Enable

; +++ Transmit Priority Polling 38h 8bit +++
HPQ		equ	80h	; High Priority queue polling (sc)
NPQ		equ	40h	; Normal Priority queue polling (sc)
FSWInt		equ	1	; force Software Interrupt (sc)

; +++ Interrupt Mask 3ch / Status 3eh 16bit +++
SERR		equ	8000h	; System Error
TimeOut		equ	4000h	; Time Out
SWInt		equ	 100h	; Software Interrupt
TDU		equ	  80h	; Tx Descriptor Unavailable
FOVW		equ	  40h	; Rx FIFO Overflow
PUN_LinkChg	equ	  20h	; Packet Underrun / Link Change
RDU		equ	  10h	; Rx Descriptor Unavailable
TER		equ	   8	; Tx Error
TOK		equ	   4	; Tx Ok
RER		equ	   2	; Rx Error
ROK		equ	   1	; Rx Ok

; +++ Transmit Configuration 40h 32bit +++
HWVERID0	equ	7c000000h	; Hardware Version ID0
IFG1		equ	 2000000h	; Inter Frame Gap 1
IFG0		equ	 1000000h	; Inter Frame Gap 0
HWVERID1	equ	  800000h	; Hardware Version ID1
IFG2		equ	   80000h	; Inter Frame Gap 2
LBK1		equ	   40000h	; Loopback test 1
LBK0		equ	   20000h	; Loopback test 0
ACRC		equ	   10000h	; Append CRC
TxMXDMA		equ	     700h	; Max DMA burst size (mask)

; +++ Receive Configuration 44h 32bit +++
MulERINT	equ	1000000h	; Multiple Early Interrupt Select
RER8		equ	  10000h	; Calculate CRC larger than 8 bytes
RXFTH		equ	  0e000h	; Rx FIFO Threshold (mask)
RxMXDMA		equ	    700h	; Max DMA burst size (mask)
EEP_SEL		equ	     40h	; EEPROM used is 9356
AER		equ	     20h	; Accept Error packet
ARP		equ	     10h	; Accept Runt packet
AB		equ	      8		; Accept Broadcast
AM		equ	      4		; Accept Multicast
APM		equ	      2		; Accept Physical Match
AAP		equ	      1		; Accept All

; +++ 93C46 Command 50h 8bit +++
EEM		equ	0c0h	; Operation Mode (mask)
EEM_Normal	equ	 00h	; Normal operation
EEM_AutoLoad	equ	 40h	; Auto-Load
EEM_Program	equ	 80h	; programing (EEPROM Access Enable)
EEM_Config	equ	0c0h	; Config Registers write enable
EECS		equ	  8	; ?? Chip Select
EESK		equ	  4	; ?? clock
EEDI		equ	  2	; ?? input pin
EEDO		equ	  1	; ?? output pin

; +++ Config0 51h 8bit +++
BS20		equ	7	; Select Boot ROM Size

; +++ Config1 52h 8bit +++
LEDS1		equ	80h	; LED Pin definitions
LEDS0		equ	40h	; 
DRVLOAD		equ	20h	; Driver Load (clear write cmd/pci)
LWACT		equ	10h	; LWAKE Active Mode
MEMMAP		equ	 8	; Memory mapping
IOMAP		equ	 4	; I/O mapping
VPD		equ	 2	; Vital Product Data
PMEn		equ	 1	; Power Management Enable

; +++ Config2 43h 8bit +++
Aux_Status	equ	10h	; Auxiliary Power Present Status
PCIBusWidth	equ	 8	; PCI Bus Width
PCICLKF		equ	 7	; PCI clock frequency (mask)

; +++ Config3 54h 8bit +++
GNTSel		equ	80h	; Grant Select
Magic		equ	20h	; Magic Packet (enable)
LinkUp		equ	10h	; Link Up (wakeup enable)
CardB_En	equ	 8	; Card Bus Enable
CLKRUN_En	equ	 4	; CLKRUN Enable
FuncRegEn	equ	 2	; Functions Registers Enable
FBtBEn		equ	 1	; Fast Back to Back Enable

; +++ Config4 55h 8bit +++
LWPME		equ	10h	; LANWAKE vs PMEB
LWPTN		equ	 4	; LWAKE Pattern

; +++ Config5 56h 8bit +++
BWF		equ	40h	; Broadcast Wakeup Frame
MWF		equ	20h	; Multicast Wakeup Frame
UWF		equ	10h	; Unicast Wakeup Frame
LANWake		equ	 2	; LANWake signal Enable
PME_STS		equ	 1	; PME_Status

; +++ PHY Access 60h 32bit +++
Flag		equ	80000000h	; direction flag
RegAddr04	equ	  1f0000h	; register address
Data015		equ	   0ffffh	; register data

; +++ PHY Status 6ch 8bit +++
EnTBI		equ	80h	; TBI Enable
TxFlow		equ	40h	; Tx Flow Control
RxFlow		equ	20h	; Rx Flow Control
L1000MF		equ	10h	; 1000Mbps full duplex
L100M		equ	 8	; 100Mbps
L10M		equ	 4	; 10Mbps
LinkSts		equ	 2	; Link status
FullDup		equ	 1	; duplex mode

; +++ C+ Command e0h 16bit +++
ENDIAN		equ	200h	; Endian Mode
RxVLAN		equ	 40h	; Receive VLAN De-tagging Enable
RxChkSum	equ	 20h	; Receive Checksum Offload Enable
DAC		equ	 10h	; PCI Dual Address Cycle Enable
MulRW		equ	  8	; PCI Multiple Read/Write Enable


; +++ chip revision +++ (from solaris driver)
IF 0
__rev_b		equ	0	; RTL8169 ver.B
__rev_d		equ	1	; RTL8169S/8110S ver.D
__rev_e		equ	2	; RTL8169S/8110S ver.E
__rev_f		equ	3	; RTL8169S/8110S ver.F
ELSE
HWVERID_8169	equ	0
HWVERID_8169S_D	equ	00800000h
HWVERID_8169S_E	equ	04000000h
HWVERID_8169DB	equ	10000000h
HWVERID_8169SC	equ	18000000h

HWVERID_8168	equ	20000000h
HWVERID_8168B_B	equ	30000000h
HWVERID_8168B_C	equ	38000000h

HWVERID_8100E	equ	30800000h
HWVERID_8101E	equ	34000000h


MAC_VER_8169	equ	0
MAC_VER_8169S_D	equ	1
MAC_VER_8169S_E	equ	2
MAC_VER_8169SB	equ	3

MAC_VER_8168	equ	5
MAC_VER_8168B	equ	6

MAC_VER_8100E	equ	7
MAC_VER_8101E	equ	8
MAC_VER_8169SC	equ	9
ENDIF

; +++ tramsmit descriptor +++
txd		struc
cmdsts		dd	?	; command/status
vlansts		dd	?	; VLAN command/status
bufptr		dd	?	; buffer pointer (low 32bit)
bufptr_hi	dd	?	; buffer pointer (high 32bit)
txd		ends

; +++ receive descriptor +++
rxd		struc
cmdsts		dd	?	; command/status
vlansts		dd	?	; VLAN command/status
bufptr		dd	?	; buffer pointer (low 32bit)
bufptr_hi	dd	?	; buffer pointer (high 32bit)
rxd		ends

; ++ descriptor command/status +++
OWN		equ	80000000h	; Ownership
EOR		equ	40000000h	; End of descriptor ring
FSD		equ	20000000h	; First Segment descriptor
LSD		equ	10000000h	; Last Segment descriptor

; +++ tx descriptor command/status +++
LGSEN		equ	 8000000h	; Large Send
IPCS		equ	   40000h	; IP Checksum offload
UDPCS		equ	   20000h	; UDP Checksum offload
TCPCS		equ	   10000h	; TCP Checksum offload

; +++ rx descriptor command/status +++
MAR		equ	 8000000h	; Multicast received
PAM		equ	 4000000h	; Physical matched
BAR		equ	 2000000h	; Braodcast received
BOVF		equ	 1000000h	; Buffer Overflow
FOVF		equ	  800000h	; FIFO Overflow
RWT		equ	  400000h	; Receive watchdog timer expired
RES		equ	  200000h	; Receive error summary
RUNT		equ	  100000h	; Runt packet
CRCE		equ	   80000h	; CRC error
PID1		equ	   40000h	; Protocol ID1
PID0		equ	   20000h	; Protocol ID0
IPF		equ	   10000h	; IP checksum failure
UDPF		equ	    8000h	; UDP checksum failure
TCPF		equ	    4000h	; TCP checksum failure

; +++ virtual tx frame descriptor (for driver) +++
vtxd		struc
head		dw	?	; head descriptor
tail		dw	?	; tail descriptor
reqhandle	dw	?	; request handle
protid		dw	?	; protocol id
cnt		dw	?	; number of descriptors
vlink		dw	?	; virtual link
immedphy	dd	?	; physical address of immediate data
immedbuf	db	64 dup(?) ; buffer for immediate data
;alignbuf	db	8*12 dup(?) ; buffer for adjust alignment
vtxd		ends

; +++ virtual rx frame descriptor (for driver) +++
vrxd		struc
rxd		dw	?	; related rxd
flag		dw	?	; mac/protocol own, frame number
virtaddr	dd	?	; virtual address of buffer
vrxd		ends
