; *** Hardware dependent resident part definition

; --- DMA Descriptor management ---
extern	VTxHead : word
extern	VTxTail : word
extern	VTxFreeHead : word
extern	VTxFreeTail : word
extern	TxBase : word
extern	TxTail : word
extern	TxHead : word
extern	TxFreeCount : word
extern	TxBasePhys : dword
extern	TxCopySel : word

extern	VRxHead : word
extern	VRxInProg : word
extern	VRxBase : word
extern	VRxTail : word
extern	RxBase : word
extern	RxBasePhys : dword

; --- statistics management ---
extern	regDTCCRBase : word
extern	regDTCCRBasePhys : dword

; --- System(PCI) Resource ---
;extern	IOaddr : word
extern	MEMSel : word		; selector for MEMaddr
extern	MEMaddr : dword
extern	IRQlevel : byte
extern	ChipRev : byte

; --- Configuration Memory Image Parameters ---
extern	cfgSLOT : byte
extern	cfgTXQUEUE : byte
extern	cfgRXQUEUE : byte
extern	cfgMAXFRAMESIZE : word

extern	cfgTxDRTH : byte
extern	cfgTxMXDMA : byte
extern	cfgRxDRTH : byte
extern	cfgRxMXDMA : byte
extern	cfgRxAcErr : byte

extern	cfgRxChkSumIP : byte
extern	cfgRxChkSumTCP : byte
extern	cfgRxChkSumUDP : byte
extern	cfgPCIMRW : byte
extern	cfgPWM : byte

extern	cfgTxCompInt : byte
extern	cfgTxPollCnt : word

; --- Receive Buffer Address ---
extern	RxBufferLin : dword
extern	RxBufferPhys : dword
extern	RxBufferSize : dword
extern	RxBufferSelCnt : word
extern	RxBufferSel : word


; ---Vendor Adapter Description ---
extern	AdapterDesc : byte


; --- Hardware Depended Services ---
extern	_hwTxChain : near16
extern	_hwRxRelease : near16
extern	_hwEnableRxInd : near16
extern	_hwDisableRxInd : near16
extern	_hwSetMACaddr : near16
extern	_hwOpen : near16
extern	_hwClose : near16
extern	_hwIntReq : near16
extern	_hwUpdatePktFlt : near16
extern	_hwUpdateMulticast : near16
extern	_hwUpdateStat : near16
extern	_hwClearStat : near16
extern	_hwReset : near16

extern	_hwCheckInt : near16
extern	_hwDisableInt : near16
extern	_hwEnableInt : near16
extern	_hwServiceInt : near16
extern	_hwPollLink : near16


; --- Driver Version ---
extern	DrvMajVer : abs
extern	DrvMinVer : abs

