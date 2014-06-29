; *** Resident part: Hardware dependent ***

include	NDISdef.inc
include	rtl8169.inc
include	MIIdef.inc
include	misc.inc
include	DrvRes.inc

extern	DosIODelayCnt : far16

public	DrvMajVer, DrvMinVer
DrvMajVer	equ	1
DrvMinVer	equ	13h

.386

_REGSTR	segment	use16 dword AT 'RGST'
	org	0
Reg	RTL8169_Registers <>
_REGSTR	ends

_DATA	segment	public word use16 'DATA'

; --- DMA Descriptor management ---
public	VTxHead, VTxTail, VTxFreeHead, VTxFreeTail
public	TxBase, TxTail, TxHead, TxFreeCount, TxBasePhys
public	TxCopySel
VTxHead		dw	0
VTxTail		dw	0
VTxFreeHead	dw	0
VTxFreeTail	dw	0
TxBase		dw	0
TxTail		dw	0
TxHead		dw	0
TxFreeCount	dw	0
TxBasePhys	dd	0
TxCopySel	dw	0

public	VRxHead, VRxBase, VRxTail, VRxInProg
public	RxBase, RxBasePhys
VRxHead		dw	0
VRxInProg	dw	0
VRxBase		dw	0
VRxTail		dw	0
RxBase		dw	0
RxBasePhys	dd	0

; --- ReceiveChain Frame Descriptor ---
public	RxFrameLen, RxDesc	; << for debug info >>
RxFrameLen	dw	0
RxDesc		RxFrameDesc	<>

; --- System(PCI) Resource ---
;public	IOaddr, MEMSel, MEMaddr, IRQlevel, ChipRev
public	MEMSel, MEMaddr, IRQlevel, ChipRev
;IOaddr		dw	?
MEMSel		dw	?
MEMaddr		dd	?
IRQlevel	db	?
ChipRev		db	0

; --- internal timer ---
public	TimerFlag, TimerCount	; << for debug info >>
TimerFlag	db	0	; 0:stop  1:run  -1:timeout
TimerCount	dd	?

align	2
; --- Physical information ---
PhyInfo		_PhyInfo <>

public	MediaSpeed, MediaDuplex, MediaPause, MediaLink	; << for debug >>
MediaSpeed	db	0
MediaDuplex	db	0
MediaPause	db	0
MediaLink	db	0

; --- Register Contents ---
public	regIntStatus, regIntMask	; << for debug info >>
public	regReceiveMode, regHashTable
public	regDTCCRBase, regDTCCRBasePhys

regIntStatus	dw	0
regIntMask	dw	0
regReceiveMode	dd	0
regHashTable	dw	4 dup (0)
regDTCCRBase	dw	0
regDTCCRBasePhys dd	0


; --- Configuration Memory Image Parameters ---
public	cfgSLOT, cfgTXQUEUE, cfgRXQUEUE, cfgMAXFRAMESIZE
public	cfgTxMXDMA, cfgTxDRTH
public	cfgRxMXDMA, cfgRxDRTH, cfgRxAcErr
public	cfgRxChkSumIP, cfgRxChkSumTCP, cfgRxChkSumUDP
public	cfgPCIMRW, cfgPWM
public	cfgTxCompInt, cfgTxPollCnt
cfgSLOT		db	0
cfgTXQUEUE	db	24
cfgRXQUEUE	db	32


cfgTxDRTH	db	1536/32	; n*32byte  [0..3f]
cfgTxMXDMA	db	100b	; 256bytes  [0..7]

cfgRxDRTH	db	100b	; 256bytes  [2..7]
cfgRxMXDMA	db	100b	; 256bytes  [2..7]
cfgRxAcErr	db	0	; AER,AR

cfgRxChkSumIP	db	1	; IP
cfgRxChkSumTCP	db	1	; TCP
cfgRxChkSumUDP	db	1	; UDP

cfgPCIMRW	db	1	; PCI multiple read/write enable
cfgPWM		db	1	; PMEn
cfgTxCompInt	db	0	; no (no tx interrupt)
cfgTxPollCnt	dw	6144	; 184.3 micro second
cfgMAXFRAMESIZE	dw	1514

; --- Receive Buffer address ---
public	RxBufferLin, RxBufferPhys, RxBufferSize, RxBufferSelCnt, RxBufferSel
RxBufferLin	dd	?
RxBufferPhys	dd	?
RxBufferSize	dd	?
RxBufferSelCnt	dw	?
RxBufferSel	dw	6 dup (?)	; max is 6.

; --- Vendor Adapter Description ---
public	AdapterDesc
AdapterDesc	db	'Realtek RTL8169 Giga Ethernet Adapter',0

; --- Core Version Table ---
public	CoreVer			; << for debug info >>
CoreVer		db	0

_HWVERID::
	dw	highword HWVERID_8169
	db	MAC_VER_8169		; 0
	dw	highword HWVERID_8169S_D
	db	MAC_VER_8169S_D		; 1
	dw	highword HWVERID_8169S_E
	db	MAC_VER_8169S_E		; 2
	dw	highword HWVERID_8169DB
	db	MAC_VER_8169SB		; 2
	dw	highword HWVERID_8169SC
	db	MAC_VER_8169SC		; 9

	dw	highword HWVERID_8168
	db	MAC_VER_8168		; 5
	dw	highword HWVERID_8168B_B
	db	MAC_VER_8168B		; 6
	dw	highword HWVERID_8168B_C
	db	MAC_VER_8168B		; 6

	dw	highword HWVERID_8100E
	db	MAC_VER_8100E		; 7
	dw	highword HWVERID_8101E
	db	MAC_VER_8101E		; 8
_HWVERID_END::

_DATA	ends

_TEXT	segment	public word use16 'CODE'
	assume	ds:_DATA, gs:_REGSTR
	
; USHORT hwTxChain(TxFrameDesc *txd, USHORT rqh, USHORT pid)
_hwTxChain	proc	near
	push	bp
	mov	bp,sp
	push	fs
	lfs	bx,[bp+4]
	xor	di,di
	mov	si,fs:[bx].TxFrameDesc.TxImmedLen
	mov	cx,fs:[bx].TxFrameDesc.TxDataCount
	cmp	di,si
	adc	di,cx
	dec	cx
	jl	short loc_2		; immediate data only
	add	bx,offset TxFrameDesc.TxBufDesc1
loc_1:
	add	si,fs:[bx].TxBufDesc.TxDataLen
	add	bx,sizeof(TxBufDesc)
	dec	cx
	jge	short loc_1

loc_2:			; si:total frame length, di:fragments required
	push	offset semTx
	call	_EnterCrit
	mov	bx,[VTxFreeHead]
	mov	ax,[TxFreeCount]
	or	bx,bx
;	jz	short loc_or		; vtxd is unavailable
	jz	near ptr loc_or
	mov	cx,[bx].vtxd.vlink

	cmp	si,60			; pad required?
;	jc	short loc_db
	jc	near ptr loc_db

		; multiple fragments
loc_md:
	sub	ax,di			; txd is enough?
;	jc	short loc_or
	jc	near ptr loc_or

loc_m0:
	mov	si,[TxHead]
	mov	[VTxFreeHead],cx
	mov	[TxFreeCount],ax
	mov	[bx].vtxd.head,si
	mov	[bx].vtxd.cnt,di
	shl	di,4			; x16 (sizeof(txd))
	mov	ax,[bp+8]
	mov	dx,[bp+10]
	add	di,si
	mov	[bx].vtxd.reqhandle,ax
	mov	[bx].vtxd.protid,dx
	cmp	di,[TxTail]
	mov	ax,[bp+4]
	jna	short loc_m1
	sub	di,[TxTail]
	mov	bp,[TxBase]
	lea	di,[bp+di-sizeof(txd)]
loc_m1:
	mov	bp,ax
	mov	[TxHead],di

	mov	cx,fs:[bp].TxFrameDesc.TxImmedLen
	mov	dx,fs:[bp].TxFrameDesc.TxDataCount
	test	cx,cx
	jz	short loc_m2		; no immediate data

	push	si
	push	ds
	push	ds
	pop	es
	lea	di,[bx].vtxd.immedbuf
	lds	si,fs:[bp].TxFrameDesc.TxImmedPtr
	mov	ax,cx
	shr	cx,2
	rep	movsd
	mov	cl,al
	and	cl,3
	rep	movsb
	mov	cx,ax
	pop	ds
	pop	si
	mov	eax,[bx].vtxd.immedphy
;	add	bp,(offset TxFrameDesc.TxBufDesc1) - sizeof(TxBufDesc)
	jmp	short loc_m4

loc_m2:
	dec	dx
;	jl	short loc_m5
	add	bp,offset TxFrameDesc.TxBufDesc1
loc_m3:
	cmp	fs:[bp].TxBufDesc.TxPtrType,0	; Type is Phys or Virt?
	mov	eax,fs:[bp].TxBufDesc.TxDataPtr
	mov	cx,fs:[bp].TxBufDesc.TxDataLen
	jz	short loc_m4
	push	eax
	call	_VirtToPhys
	add	sp,4
loc_m4:
	mov	[si].txd.bufptr,eax
	cmp	cx,4
	jnc	short loc_dbg
	nop
loc_dbg:
	mov	word ptr [si].txd.cmdsts,cx
	mov	ax,highword(OWN)
	cmp	si,[bx].vtxd.head		; FSD?
	jnz	short loc_m5
	or	ax,highword(FSD)
;	mov	ax,highword(FSD)		; clear OWN - set later
loc_m5:
	cmp	si,[TxTail]			; EOR?
	jnz	short loc_m6
	or	ax,highword(EOR)
loc_m6:
	add	bp,sizeof(TxBufDesc)

	dec	dx
	jl	short loc_m7
	mov	word ptr [si].txd.cmdsts[2],ax
	add	si,sizeof(txd)
	test	ax,highword(EOR)
	jz	short loc_m3
	mov	si,[TxBase]
	jmp	short loc_m3
loc_m7:
	or	ax,highword(LSD)
;	mov	di,[bx].vtxd.head
	mov	word ptr [si].txd.cmdsts[2],ax
;	or	word ptr [di].txd.cmdsts[2],highword(OWN)
;	jmp	short loc_rq
	jmp	near ptr loc_rq

		; double buffer: copy all to temporaly buffer
loc_db:
	dec	ax
	jge	short loc_b0		; txd is unavailable?
loc_or:
	call	_LeaveCrit
	mov	ax,OUT_OF_RESOURCE
	pop	cx	; stack adjust
	pop	fs
	pop	bp
	retn
loc_b0:
	mov	di,[TxHead]
	mov	[VTxFreeHead],cx
	mov	[bx].vtxd.head,di
;	mov	[bx].vtxd.tail,di
	mov	[bx].vtxd.cnt,1
	mov	[TxFreeCount],ax
	mov	cx,[bp+8]
	mov	dx,[bp+10]
	mov	bp,[bp+4]
	add	di,sizeof(txd)
	mov	[bx].vtxd.reqhandle,cx
	mov	[bx].vtxd.protid,dx
	cmp	di,[TxTail]
	jna	short loc_b1
	mov	di,[TxBase]
loc_b1:
	mov	[TxHead],di

	mov	ax,ds
	mov	es,ax
	lea	di,[bx].vtxd.immedbuf
	push	si			; frame length
	push	ax			; ds
	mov	cx,fs:[bp].TxFrameDesc.TxImmedLen
	jcxz	short loc_b2		; immediate data length is zero?
	lds	si,fs:[bp].TxFrameDesc.TxImmedPtr
	mov	ax,cx
	shr	cx,2
	and	al,3
	rep	movsd
	mov	cl,al
	rep	movsb
loc_b2:
	mov	dx,fs:[bp].TxFrameDesc.TxDataCount
	add	bp,offset TxFrameDesc.TxBufDesc1
loc_b3:
	dec	dx
	jl	short loc_b6
	cmp	fs:[bp].TxBufDesc.TxPtrType,0
	mov	cx,fs:[bp].TxBufDesc.TxDataLen
	jz	short loc_b4		; virtual address
	lds	si,fs:[bp].TxBufDesc.TxDataPtr
	jmp	short loc_b5
loc_b4:
	pop	ds			; restore ds
	push	ds
	push	cx
	push	fs:[bp].TxBufDesc.TxDataPtr
	push	[TxCopySel]
	call	_PhysToGDT
	pop	ds
	xor	si,si
	add	sp,4+2
loc_b5:
	mov	ax,cx
	shr	cx,2
	and	al,3
	rep	movsd
	mov	cl,al
	rep	movsb

	add	bp,sizeof(TxBufDesc)
	jmp	short loc_b3
loc_b6:
	pop	ds
	pop	bp			; restore total length
	mov	cx,60
;	mov	si,[bx].vtxd.tail
	mov	si,[bx].vtxd.head
	sub	cx,bp			; pad required? (yes)
	jna	short loc_b7

;	add	[bx].vtxd.immedbuf[13],cl
;	adc	[bx].vtxd.immedbuf[12],ch

	shr	cx,2
	mov	bp,60
	inc	cx
	xor	eax,eax
	rep	stosd		; fill zero to avoid previous data leak
loc_b7:
	cmp	si,[TxTail]
	setz	dl
	shl	dx,14			; EOR
	mov	eax,[bx].vtxd.immedphy
	or	dx,highword(OWN or FSD or LSD)
	mov	[si].txd.bufptr,eax
	mov	word ptr [si].txd.cmdsts,bp
	mov	word ptr [si].txd.cmdsts[2],dx

loc_rq:
	mov	gs:[Reg.TPPoll],NPQ		; kick tx queue

	xor	ax,ax
	mov	[bx].vtxd.tail,si
	mov	[bx].vtxd.vlink,ax

	cmp	ax,[VTxHead]
	jnz	short loc_11
	mov	[VTxHead],bx		; queue empty
	jmp	short loc_12
loc_11:
	mov	di,[VTxTail]		; queue not empty
	mov	[di].vtxd.vlink,bx	; vlink chain
loc_12:
	mov	[VTxTail],bx

	cmp	[cfgTxCompInt],0
	jnz	short loc_13
	call	_hwStartTimer
loc_13:
	call	_LeaveCrit
	pop	cx	; stack adjust

	mov	ax,REQUEST_QUEUED
	pop	fs
	pop	bp
	retn
_hwTxChain	endp


_hwRxRelease	proc	near
	push	bp
	mov	bp,sp
	push	si
	push	offset semRx
	call	_EnterCrit

	mov	ax,[bp+4]		; ReqHandle = vrxd
	cmp	ax,[VRxTail]
	ja	short loc_ex		; out of range
	sub	ax,[VRxBase]
	jc	short loc_ex		; out of range
	and	ax,7
	jnz	short loc_ex		; alignment failure

	mov	bx,[bp+4]
	mov	cx,[bx].vrxd.flag
	or	cx,cx
	jz	short loc_ex		; zero counter. MAC own
	cmp	bx,[VRxInProg]
	jnz	short loc_1
	mov	[VRxInProg],ax		; clear In_Progress mark
					; ax=0
loc_1:
	cmp	bx,[VRxTail]
	setz	al
	mov	si,[bx].vrxd.rxd
	shl	ax,14			; EOR
	mov	[bx].vrxd.flag,0
	or	ax,highword(OWN)
	mov	word ptr [si].rxd.cmdsts,1536
	mov	word ptr [si].rxd.cmdsts[2],ax
	dec	cx
	jz	short loc_ex		; complete
	add	bx,sizeof(vrxd)		; next vrxd/rxd
	test	ax,highword(EOR)	; end of ring?
	jz	short loc_1
	mov	bx,[VRxBase]		; wrap around
	jmp	short loc_1
loc_ex:
	call	_LeaveCrit
	pop	cx	; stack adjust
	mov	ax,SUCCESS
	pop	si
	pop	bp
	retn
_hwRxRelease	endp


_ServiceIntTx	proc	near
	cld
	push	offset semTx
loc_0:
	call	_EnterCrit
	mov	bx,[VTxHead]
	or	bx,bx		; vtxd queue is empty
	jz	short loc_ex
	mov	si,[bx].vtxd.tail
	mov	ax,word ptr [si].txd.cmdsts[2]
	test	ax,highword(OWN)	; done?
	jz	short loc_1

lock	or	[drvflags],mask df_tmrreq
loc_ex:
	call	_LeaveCrit
	pop	cx	; stack adjust
	retn

; How can I know if each packet was transmitted successfully, 
; nor abortively with any error.
; It seems that a packet causes always an interrupt either of OK or ERROR.
; This driver informs the protocol drivers of the success transmission 
; on any condition.

loc_1:
	mov	cx,[bx].vtxd.cnt
	mov	dx,[bx].vtxd.vlink
	add	[TxFreeCount],cx
	mov	[VTxHead],dx
	mov	cx,[bx].vtxd.reqhandle
	mov	dx,[bx].vtxd.protid
	mov	[bx].vtxd.vlink,0

	cmp	[VTxFreeHead],0
	jnz	short loc_2
	mov	[VTxFreeHead],bx
	jmp	short loc_3
loc_2:
	mov	di,[VTxFreeTail]
	mov	[di].vtxd.vlink,bx
loc_3:
	mov	[VTxFreeTail],bx

	call	_LeaveCrit

	test	cx,cx
	jz	short loc_4	; null request handle
	mov	bx,[CommonChar.moduleID]
	mov	di,[ProtDS]
	mov	si,SUCCESS

	push	dx	; ProtID
	push	bx	; MACID
	push	cx	; ReqHandle
	push	si	; Status
	push	di	; ProtDS
	call	dword ptr [LowDisp.txconfirm]
	mov	gs,[MEMSel]	; fix gs selector
loc_4:
	cmp	[cfgTxCompInt],0
	jnz	short loc_0
lock	or	[drvflags],mask df_tmrreq
	jmp	short loc_0
_ServiceIntTx	endp


_ServiceIntRx	proc	near
	enter	2,0
ir_indc	equ	bp-2

	mov	di,[VRxInProg]
	mov	si,[RxFrameLen]
	or	di,di
	push	offset semRx
	jnz	near ptr loc_rty	; retry suspended process
loc_rep:
	call	_EnterCrit
loc_0:
	mov	di,offset RxDesc.RxBufDesc1
loc_1:
	xor	cx,cx
	mov	bx,[VRxHead]
	cmp	[bx].vrxd.flag,0
	jnz	short loc_ex		; protocol own
	mov	si,[bx].vrxd.rxd
	mov	ax,word ptr [si].rxd.cmdsts[2]
	test	ax,highword(OWN)
	jnz	short loc_ex		; imcoplete
	inc	cx
	test	ax,highword(FSD)
	jnz	short loc_fs		; first segment indicator found

loc_fsm:				; remove lotten rxd
	add	bx,sizeof(vrxd)
	and	ax,highword(EOR)
	jz	short loc_fsm1
	mov	bx,[VRxBase]
loc_fsm1:
	or	ax,highword(OWN)
	mov	word ptr [si].rxd.cmdsts,1536
	mov	word ptr [si].rxd.cmdsts[2],ax
	mov	[VRxHead],bx
	jmp	short loc_1

loc_ex:
	call	_LeaveCrit
	leave
	retn

loc_2:
	cmp	cx,8
	jnc	short loc_mlp		; too long packet detected
	cmp	[bx].vrxd.flag,0
	jnz	short loc_ex
	mov	si,[bx].vrxd.rxd
	mov	ax,word ptr [si].rxd.cmdsts[2]
	test	ax,highword(OWN)
	jnz	short loc_ex
	inc	cx
	test	ax,highword(FSD)
	jnz	short loc_mlp		; last segment indicator missing

loc_fs:
	test	ax,highword(LSD)
	jnz	short loc_ls		; last segment found
	mov	edx,[bx].vrxd.virtaddr
	mov	[di].RxBufDesc.RxDataLen,1536
	mov	[di].RxBufDesc.RxDataPtr,edx
	add	bx,sizeof(vrxd)
	add	di,sizeof(RxBufDesc)
	test	ax,highword(EOR)
	jz	short loc_2
	mov	bx,[VRxBase]
	jmp	short loc_2

loc_mlp:				; mark as lotten packet
	mov	bx,[VRxHead]
	mov	si,[bx].vrxd.rxd
	and	word ptr [si].rxd.cmdsts[2],not highword(FSD) ; clear FS indicator
lock	or	[drvflags],mask df_tmrreq
;	jmp	short loc_0		; force run removing process
	jmp	near ptr loc_0

loc_ls:
	mov	dx,word ptr [si].rxd.cmdsts

; It seems that BOVF and FOVF don't show the status of this frame, 
;  but that of somewhat register, which holds ancient events... 
; I don't have the key that resolves this misterious history.
; It is meaningless for now to test these bits.
;	test	ax,highword(BOVF or FOVF)
;	jnz	short loc_mlp		; buffer or FIFO overflow

	test	ax,highword(RES)
	jz	short loc_3		; no error

	test	ax,highword(RUNT)	; runt packet?
	jz	short loc_e1
	test	[cfgRxAcErr],ARP	; accept runt packet?
	jz	short loc_mlp
loc_e1:
	test	ax,highword(CRCE)	; CRC error?
	jnz	short loc_e2
	test	ax,highword(RWT)	; length > 4096
	jnz	short loc_3
loc_e2:
	test	[cfgRxAcErr],AER
	jz	short loc_mlp

loc_3:
	test	ax,highword(PID1 or PID0)
	jz	short loc_4		; Non-IP
	test	al,[cfgRxChkSumIP]
	jnz	short loc_mlp		; IP chechsum failure
	test	ax,highword(PID1)
	jz	short loc_cs2		; TCP/IP
	test	ax,highword(PID0)
	jnz	short loc_4		; IP
loc_cs1:				; UDP/IP
	test	dx,UDPF
	jz	short loc_4		; UDP checksum OK
	cmp	[cfgRxChkSumUDP],0	; accept error?
	jz	short loc_4
	jmp	short loc_mlp		; reject
loc_cs2:
	test	dx,TCPF
	jz	short loc_4		; TCP checksum OK
	cmp	[cfgRxChkSumTCP],0	; accept error?
	jnz	short loc_mlp

loc_4:
	and	dx,not (UDPF or TCPF)
	sub	dx,4			; frame length
	jna	short loc_mlp		; length <=0 !?
	cmp	dx,[cfgMAXFRAMESIZE]
	ja	short loc_mlp

	mov	ax,cx
	mov	si,1536
	mov	[RxDesc.RxDataCount],cx
	dec	ax
	xchg	dx,si
	mul	dx
	sub	ax,si
	jc	short loc_5		; valid last length

	sub	[di-sizeof(RxBufDesc)].RxBufDesc.RxDataLen,ax	; size adjust
	dec	[RxDesc.RxDataCount]		; count adjust
	jmp	short loc_6
loc_5:
	neg	ax			; last fragment length
	mov	edx,[bx].vrxd.virtaddr
	mov	[di].RxBufDesc.RxDataLen,ax
	mov	[di].RxBufDesc.RxDataPtr,edx
loc_6:
	add	bx,sizeof(vrxd)
	mov	di,[VRxHead]
	cmp	bx,[VRxTail]
	jna	short loc_7
	mov	bx,[VRxBase]
loc_7:
	mov	[VRxHead],bx		; next vrxd head
	mov	[di].vrxd.flag,cx	; MAC own indicator

	mov	[VRxInProg],di		; for delayed process
	mov	[RxFrameLen],si

	call	_LeaveCrit
loc_rty:
	call	_IndicationChkOFF
	or	ax,ax
	jz	short loc_spd	; indicate off - suspend...
	mov	ax,[ProtDS]
	mov	cx,[CommonChar.moduleID]
	mov	byte ptr [ir_indc],-1
	push	di			; current vrxd = handle
	lea	bx,[ir_indc]

	push	cx		; MACID
	push	si		; FrameSize
	push	di		; ReqHandle
	push	ds
	push	offset RxDesc	; RxFrameDesc
	push	ss
	push	bx		; Indicate
	push	ax		; Protocol DS
	cld
	call	dword ptr [LowDisp.rxchain]
	mov	gs,[MEMSel]	; fix gs selector
lock	or	[drvflags],mask df_idcp or mask df_tmrreq

	cmp	ax,WAIT_FOR_RELEASE
	jz	short loc_9		; wait RxRelase called by protocol
	call	_hwRxRelease
	pop	di	; adjust stack
loc_8:
	cmp	byte ptr [ir_indc],-1
	jnz	short loc_spd		; indication remains OFF
	call	_IndicationON
	jmp	near ptr loc_rep

loc_9:
	pop	di	; adjust stack
	call	_EnterCrit
	mov	[VRxInProg],0
	call	_LeaveCrit
	jmp	short loc_8

loc_spd:
lock	or	[drvflags],mask df_rxsp or mask df_tmrreq
	leave
	retn

_ServiceIntRx	endp

_hwServiceInt	proc	near
	enter	2,0
loc_0:
	mov	ax,gs:[Reg.ISR]
lock	or	[regIntStatus],ax
	mov	cx,[regIntMask]
	mov	ax,[regIntStatus]
	mov	gs:[Reg.ISR],cx
	and	ax,cx
	jz	short loc_tmr

loc_1:
	mov	[bp-2],ax

	test	ax,TimeOut
	jz	short loc_2
	push	offset semInd
	call	_EnterCrit
	mov	[TimerFlag],-1		; timeout
	call	_LeaveCrit
	pop	cx	; stack adjust

loc_2:
	mov	ax,TOK or TER or SWInt or TimeOut
	test	[bp-2],ax
	jz	short loc_n1
	not	ax
lock	and	[regIntStatus],ax
	call	_ServiceIntTx

loc_n1:
	mov	ax,ROK or RER or RDU or FOVW or SWInt or TimeOut
	test	[bp-2],ax
	jz	short loc_n2
	cmp	[Indication],0		; rx enable
	jnz	short loc_n2
	not	ax
lock	and	[regIntStatus],ax
	call	_ServiceIntRx

loc_n2:
lock	btr	[drvflags],df_rxsp
	jnc	short loc_0

loc_tmr:
	cmp	[cfgTxCompInt],0
	jnz	short loc_ex
lock	btr	[drvflags],df_tmrreq
	jnc	short loc_tmr1
	call	_hwRestartTimer
	jmp	short loc_ex
loc_tmr1:
		; explicit clear rx related isr state.
	mov	gs:[Reg.ISR],ROK or RER or RDU or FOVW
	call	_hwStopTimer
loc_ex:
	leave
	retn
_hwServiceInt	endp

_hwCheckInt	proc	near
	mov	ax,gs:[Reg.ISR]
lock	or	[regIntStatus],ax
	mov	ax,[regIntStatus]
	test	ax,[regIntMask]
	setnz	al
	mov	ah,0
	retn
_hwCheckInt	endp

_hwEnableInt	proc	near
	mov	ax,[regIntMask]
	mov	gs:[Reg.IMR],ax		; set IMR
	retn
_hwEnableInt	endp

_hwDisableInt	proc	near
	mov	gs:[Reg.IMR],0		; clear IMR
	retn
_hwDisableInt	endp

_hwIntReq	proc	near
	mov	gs:[Reg.TPPoll],FSWInt
	retn
_hwIntReq	endp

_hwEnableRxInd	proc	near
	push	ax
	cmp	[TimerFlag],0
	jnz	short loc_1		; polling mode
lock	or	[regIntMask],ROK or RER or RDU or FOVW
	cmp	[semInt],0
	jnz	short loc_1
	mov	ax,[regIntMask]
	mov	gs:[Reg.IMR],ax
loc_1:
	pop	ax
	retn
_hwEnableRxInd	endp

_hwDisableRxInd	proc	near
	push	ax
lock	and	[regIntMask],not(ROK or RER or RDU or FOVW)
	cmp	[semInt],0
	jnz	short loc_1
	mov	ax,[regIntMask]
	mov	gs:[Reg.IMR],ax
loc_1:
	pop	ax
	retn
_hwDisableRxInd	endp

_hwStartTimer	proc	near
			; 0:stop -->> 1:start
	push	offset semInd
	call	_EnterCrit
	cmp	[TimerFlag],0		; timer stop?
	jg	short loc_1		; already run
	jl	short loc_2		; expired, timer request flag
	mov	[TimerFlag],1
	call	_hwDisableRxInd		; turn into polling mode
	mov	eax,[TimerCount]
	mov	gs:[Reg.TCTR],eax	; timer start by any write
	mov	gs:[Reg.TimerInt],eax	; timer counter
loc_1:
	call	_LeaveCrit
	pop	ax	; stack adjust
	retn
loc_2:
lock	or	[drvflags],mask df_tmrreq
	jmp	short loc_1
_hwStartTimer	endp

_hwRestartTimer	proc	near
			; 0:stop, -1:expire -->> 1:start
	push	offset semInd
	call	_EnterCrit
	mov	al,1
	xchg	al,[TimerFlag]
	cmp	al,1			; run if stop or timeout
	jz	short loc_1
	call	_hwDisableRxInd		; turn into polling mode
	mov	eax,[TimerCount]
	mov	gs:[Reg.TCTR],eax	; timer start by any write
	mov	gs:[Reg.TimerInt],eax	; timer counter
loc_1:
	call	_LeaveCrit
	pop	ax	; stack adjust
	retn
_hwRestartTimer	endp

_hwStopTimer	proc	near
			; -1:expired -->> 0:stop
	push	offset semInd
	call	_EnterCrit
	xor	eax,eax
	cmp	[TimerFlag],al		; timeout?
	jns	short loc_1		; do nothing if not timeout
	mov	[TimerFlag],al
	mov	gs:[Reg.TimerInt],eax
	cmp	[Indication],ax
	jnz	short loc_1
	call	_hwEnableRxInd		; turn into rx interrupt mode
loc_1:
	call	_LeaveCrit
	pop	ax	; stack adjust
	retn
_hwStopTimer	endp


_hwPollLink	proc	near
	call	_ChkLink
	test	al,MediaLink
	jz	short loc_0	; Link status change/down
	retn
loc_0:
	or	al,al
	mov	MediaLink,al
	jnz	short loc_1	; change into Link Active
	call	_ChkLink	; link down. check again.
	or	al,al
	mov	MediaLink,al
	jnz	short loc_1	; short time link down
	retn
loc_1:
	call	_GetPhyMode

	cmp	al,MediaSpeed
	jnz	short loc_2
	cmp	ah,MediaDuplex
	jnz	short loc_2
	cmp	dl,MediaPause
	jz	short loc_3
loc_2:
	mov	MediaSpeed,al
	mov	MediaDuplex,ah
	mov	MediaPause,dl
	call	_SetSpeedStat
loc_3:
	retn
_hwPollLink	endp

_hwOpen		proc	near	; call in protocol bind process?
	call	_ResetPhy
	cmp	ax,SUCCESS
	jnz	short loc_e
	call	_AutoNegotiate
	mov	MediaSpeed,al
	mov	MediaDuplex,ah
	mov	MediaPause,dl
	call	_SetSpeedStat

	call	_SetMacEnv
	call	_hwUpdatePktFlt
	call	_hwUpdateMulticast

	mov	ax,ROK or RER or RDU or FOVW or SWInt or TimeOut
	cmp	[cfgTxCompInt],0
	jz	short loc_poll
	or	ax,TOK or TER
loc_poll:
	mov	[regIntStatus],0
	mov	[regIntMask],ax
	mov	gs:[Reg.ISR],-1		; clear interrupt status
	mov	gs:[Reg.IMR],ax		; enable interrupt

	mov	ax,SUCCESS
loc_e:
	retn
_hwOpen		endp

_SetMacEnv	proc	near
	xor	edx,edx
	mov	ax,[cfgMAXFRAMESIZE]
	mov	cl,[cfgTxDRTH]

	cmp	[CoreVer],MAC_VER_8168
	jc	short loc_1
	cmp	[CoreVer],MAC_VER_8101E
	ja	short loc_1
			; RTL8168: MTPS - Max Tx Packet Size register
			; set max value... 
	mov	cl,3fh
loc_1:

; if RMS is 1514+4 (= 1518 = 0x5ee), it seems that the corruption of 
;  the tail of the maximum sized frames may occur.
; I gess that RMS  SHOULD BE  double word alignment... 
; The corruption shows 8bytes alignment is required?
;	add	ax,4			; add CRC length(4)
;	add	ax,4+3			; add CRC length(4) / dword aligment
;	and	al,-4
	add	ax,4+7
	and	al,-8

	mov	gs:[Reg.ETThR],cl	; MTPS if the core is RTL8168.
	mov	gs:[Reg.RMS],ax

;	mov	gs:[Reg.MULINT],dx	; kill early rx interrupt
	and	gs:[Reg.MULINT],0f000h	; Undoc bit. from solaris driver.

	mov	eax,[TxBasePhys]
	mov	ecx,[RxBasePhys]
	mov	gs:[Reg.TNPDS],eax
	mov	gs:[Reg.TNPDS+4],edx
	mov	gs:[Reg.RDSAR],ecx
	mov	gs:[Reg.RDSAR+4],edx
	mov	al,[cfgRxDRTH]
	mov	dh,[cfgRxMXDMA]
	mov	cx,highword(IFG1 or IFG0)
	shl	al,5
	mov	dl,[cfgRxAcErr]
	or	dh,al
	shl	ecx,16
	mov	eax,gs:[Reg.RxCR]
	and	al,AB or AM or APM or AAP
	mov	ch,[cfgTxMXDMA]
	or	dl,al
	mov	gs:[Reg.CR],RE or TE
	mov	gs:[Reg.RxCR],edx	; writeable after RE?
	mov	gs:[Reg.TCR],ecx	; writeable after TE

	retn
_SetMacEnv	endp


_ChkLink	proc	near
	push	miiBMSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	and	ax,miiBMSR_LinkStat
	add	sp,2*2
	shr	ax,2
	retn
_ChkLink	endp


_AutoNegotiate	proc	near
	enter	2,0
	push	0
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite		; clear ANEnable bit
	add	sp,3*2

	push	33
	call	_Delay1ms
	push	miiBMCR_ANEnable or miiBMCR_RestartAN
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite		; restart Auto-Negotiation
	add	sp,(1+3)*2

	mov	word ptr [bp-2],12*30	; about 12sec.
loc_1:
	push	33
	call	_Delay1ms
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,(1+2)*2
	test	ax,miiBMCR_RestartAN	; AN in progress?
	jz	short loc_2
	dec	word ptr [bp-2]
	jnz	short loc_1
	jmp	short loc_f
loc_2:
	push	33
	call	_Delay1ms
	push	miiBMSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,(1+2)*2
	test	ax,miiBMSR_ANComp	; AN Base Page exchange complete?
	jnz	short loc_3
	dec	word ptr [bp-2]
	jnz	short loc_2
	jmp	short loc_f
loc_3:
	push	33
	call	_Delay1ms
	push	miiBMSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,(1+2)*2
	test	ax,miiBMSR_LinkStat	; link establish?
	jnz	short loc_4
	dec	word ptr [bp-2]
	jnz	short loc_3
loc_f:
	xor	ax,ax			; AN failure.
	xor	dx,dx
	leave
	retn
loc_4:
	call	_GetPhyMode
	leave
	retn
_AutoNegotiate	endp

_GetPhyMode	proc	near
	push	miiANLPAR
	push	[PhyInfo.Phyaddr]
	call	_miiRead		; read base page
	add	sp,2*2
	mov	[PhyInfo.ANLPAR],ax

	test	[PhyInfo.BMSR],miiBMSR_ExtStat
	jz	short loc_2

	push	mii1KSTSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.GSTSR],ax
;	shl	ax,2
;	and	ax,[PhyInfo.GSCR]
	shr	ax,2
	and	ax,[PhyInfo.GTCR]
;	test	ax,mii1KSCR_1KTFD
	test	ax,mii1KTCR_1KTFD
	jz	short loc_1
	mov	al,3			; media speed - 1000Mb
	mov	ah,1			; media duplex - full
	jmp	short loc_p
loc_1:
;	test	ax,mii1KSCR_1KTHD
	test	ax,mii1KTCR_1KTHD
	jz	short loc_2
	mov	al,3			; 1000Mb
	mov	ah,0			; half duplex
	jmp	short loc_p
loc_2:
	mov	ax,[PhyInfo.ANAR]
	and	ax,[PhyInfo.ANLPAR]
	test	ax,miiAN_100FD
	jz	short loc_3
	mov	al,2			; 100Mb
	mov	ah,1			; full duplex
	jmp	short loc_p
loc_3:
	test	ax,miiAN_100HD
	jz	short loc_4
	mov	al,2			; 100Mb
	mov	ah,0			; half duplex
	jmp	short loc_p
loc_4:
	test	ax,miiAN_10FD
	jz	short loc_5
	mov	al,1			; 10Mb
	mov	ah,1			; full duplex
	jmp	short loc_p
loc_5:
	test	ax,miiAN_10HD
	jz	short loc_e
	mov	al,1			; 10Mb
	mov	ah,0			; half duplex
	jmp	short loc_p
loc_e:
	xor	ax,ax
	sub	dx,dx
	retn
loc_p:
	cmp	ah,1			; full duplex?
	mov	dh,0
	jnz	short loc_np
	mov	cx,[PhyInfo.ANLPAR]
	test	cx,miiAN_PAUSE		; symmetry
	mov	dl,3			; tx/rx pause
	jnz	short loc_ex
	test	cx,miiAN_ASYPAUSE	; asymmetry
	mov	dl,2			; rx pause
	jnz	short loc_ex
loc_np:
	mov	dl,0			; no pause
loc_ex:
	retn
_GetPhyMode	endp


_ResetPhy	proc	near
	enter	2,0
;;	call	_miiReset	; Reset Interface
	push	miiPHYID2
	push	1		; phyaddr 1
	call	_miiRead
	add	sp,2*2
	or	ax,ax		; ID2 = 0
	jz	short loc_1
	inc	ax		; ID2 = -1
	jnz	short loc_2
loc_1:
	mov	ax,HARDWARE_FAILURE
	leave
	retn
loc_2:
	mov	[PhyInfo.Phyaddr],1
	push	miiBMCR_Reset
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite	; Reset PHY
	add	sp,3*2

	push	1536		; wait for about 1.5sec.
	call	_Delay1ms
	pop	ax

;;	call	_miiReset	; interface reset again
	mov	word ptr [bp-2],64  ; about 2sec.
loc_3:
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	test	ax,miiBMCR_Reset
	jz	short loc_4
	push	33
	call	_Delay1ms	; wait reset complete.
	pop	ax
	dec	word ptr [bp-2]
	jnz	short loc_3
	jmp	short loc_1	; PHY Reset Failure
loc_4:
	call	_WorkAroundPhy

	push	miiBMSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.BMSR],ax
	push	miiANAR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.ANAR],ax
	test	[PhyInfo.BMSR],miiBMSR_ExtStat
	jz	short loc_5	; extended status exist?
	push	mii1KTCR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.GTCR],ax
	push	mii1KSCR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.GSCR],ax
	xor	cx,cx
	test	ax,mii1KSCR_1KTFD or mii1KSCR_1KXFD
	jz	short loc_41
	or	cx,mii1KTCR_1KTFD
loc_41:
			; kill 1000BASE half-duplex advertisement
IF 1	; we must set this bit?
	test	ax,mii1KSCR_1KTHD or mii1KSCR_1KXHD
	jz	short loc_42
	or	cx,mii1KTCR_1KTHD
ENDIF
loc_42:
	mov	ax,[PhyInfo.GTCR]
	and	ax,not (mii1KTCR_MSE or mii1KTCR_Port or \
		  mii1KTCR_1KTFD or mii1KTCR_1KTHD)
	or	ax,cx
	mov	[PhyInfo.GTCR],ax
	push	ax
	push	mii1KTCR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,2*2
loc_5:
	mov	ax,[PhyInfo.BMSR]
	mov	cx,miiAN_PAUSE
	test	ax,miiBMSR_100FD
	jz	short loc_61
	or	cx,miiAN_100FD
loc_61:
	test	ax,miiBMSR_100HD
	jz	short loc_62
	or	cx,miiAN_100HD
loc_62:
	test	ax,miiBMSR_10FD
	jz	short loc_63
	or	cx,miiAN_10FD
loc_63:
	test	ax,miiBMSR_10HD
	jz	short loc_64
	or	cx,miiAN_10HD
loc_64:
	mov	ax,[PhyInfo.ANAR]
	and	ax,not (miiAN_ASYPAUSE + miiAN_T4 + \
	  miiAN_100FD + miiAN_100HD + miiAN_10FD + miiAN_10HD)
	or	ax,cx
	mov	[PhyInfo.ANAR],ax
	push	ax
	push	miiANAR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2
	mov	ax,SUCCESS
	leave
	retn
_ResetPhy	endp

_WorkAroundPhy	proc	near
IF 0	; remove rev specific code temporarily
		; Built-in PHY specific work-around. from solaris driver.
		; for Ver.D, Ver.F chips.
	mov	al,[ChipRev]
	cmp	al,__rev_d
	jz	short loc_rev_d
	cmp	al,__rev_f
	jnz	short loc_ex

loc_rev_f:		; M4? what does this sign means?
	push	1
	push	1fh
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2

	push	273ah
	push	9	; 1000BASE-T control
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2

	push	7bfbh
	push	0eh	; reserved register
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2

	push	841eh
	push	1bh
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2

	push	2
	push	1fh
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2

	push	90d0h
	push	1	; basic mode status
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2

	push	0
	push	1fh
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2
	jmp	short loc_ex

loc_rev_d:		; M2?
	mov	byte ptr gs:[Reg.Wakeup0-2],0	; reg.82h? undoc.

	push	0
	push	0bh	; reserved register
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2
ENDIF
loc_ex:
	retn
_WorkAroundPhy	endp


_hwUpdateMulticast	proc	near
	enter	2,0
	push	si
	push	di
	push	offset semFlt
	call	_EnterCrit
	mov	di,offset regHashTable
	push	ds
	pop	es
	xor	eax,eax
	stosd			; clear hash table
	stosd

	mov	cx,MCSTList.curnum
	dec	cx
	jl	short loc_2
	mov	[bp-2],cx
loc_1:
	mov	ax,[bp-2]
	shl	ax,4		; 16bytes
	add	ax,offset MCSTList.multicastaddr1
	push	ax
	call	_CRC32
	shr	eax,26		; the 6 most significant bits
	mov	di,ax
	pop	cx
	shr	di,4
	and	ax,0fh		; the bit index in word
	add	di,di		; the word index (2byte)
	bts	word ptr regHashTable[di],ax
	dec	word ptr [bp-2]
	jge	short loc_1
loc_2:
	mov	si,offset regHashTable
	mov	di,offset Reg.MAR0
	push	gs
	pop	es
	movsd			; write MAR0-7
	movsd

	call	_LeaveCrit
	pop	cx
	mov	ax,SUCCESS
	pop	di
	pop	si
	leave
	retn
_hwUpdateMulticast	endp

_CRC32		proc	near
POLYNOMIAL_be   equ  04C11DB7h
POLYNOMIAL_le   equ 0EDB88320h

	push	bp
	mov	bp,sp

	push	si
	push	di
	or	ax,-1
	mov	bx,[bp+4]
	mov	ch,3
	cwd

loc_1:
	mov	bp,[bx]
	mov	cl,10h
	inc	bx
loc_2:
IF 1
		; big endian

	ror	bp,1
	mov	si,dx
	xor	si,bp
	shl	ax,1
	rcl	dx,1
	sar	si,15
	mov	di,si
	and	si,highword POLYNOMIAL_be
	and	di,lowword POLYNOMIAL_be
ELSE
		; litte endian
	mov	si,ax
	ror	bp,1
	ror	si,1
	shr	dx,1
	rcr	ax,1
	xor	si,bp
	sar	si,15
	mov	di,si
	and	si,highword POLYNOMIAL_le
	and	di,lowword POLYNOMIAL_le
ENDIF
	xor	dx,si
	xor	ax,di
	dec	cl
	jnz	short loc_2
	inc	bx
	dec	ch
	jnz	short loc_1
	push	dx
	push	ax
	pop	eax
	pop	di
	pop	si
	pop	bp
	retn
_CRC32		endp

_hwUpdatePktFlt	proc	near
	push	offset semFlt
	call	_EnterCrit

	mov	cx,MacStatus.sstRxFilter

	mov	eax,gs:[Reg.RxCR]
	and	al,not (AAP or APM or AM or AB)

	test	cl,mask fltdirect
	jz	short loc_1
	or	al,APM or AM		; physical match and multicast
loc_1:
	test	cl,mask fltbroad
	jz	short loc_2
	or	al,AB			; broadcast
loc_2:
	test	cl,mask fltprms
	jz	short loc_3
	mov	al,AAP			; promiscous
loc_3:
	mov	gs:[Reg.RxCR],eax

	call	_LeaveCrit
	pop	cx
	mov	ax,SUCCESS
	retn
_hwUpdatePktFlt	endp

_hwSetMACaddr	proc	near
	push	si
	push	offset semFlt
	call	_EnterCrit
	mov	si,offset MacChar.mctcsa
	mov	ax,[si]
	or	ax,[si+2]
	or	ax,[si+4]
	jnz	short loc_1
;	mov	si,offset MacChar.mctpsa
	mov	ecx,dword ptr [MacChar.mctpsa]
	mov	ax,word ptr [MacChar.mctpsa][4]
	mov	[si],ecx
	mov	[si+4],ax
loc_1:
	xor	eax,eax
	mov	ecx,[si]
	mov	ax,[si+4]
	mov	dl,gs:[Reg.ECR]
	mov	gs:[Reg.ECR],EEM_Config	; ID0-5 are write-protected?
	mov	gs:[Reg.IDR0],ecx
	mov	gs:[Reg.IDR4],eax
	mov	gs:[Reg.ECR],dl

	call	_LeaveCrit
	pop	cx
	mov	ax,SUCCESS
	pop	si
	retn
_hwSetMACaddr	endp

_hwUpdateStat	proc	near
	push	si
	push	offset semStat
	call	_EnterCrit

	mov	eax,[regDTCCRBasePhys]
	or	al,Cmd
	mov	gs:[Reg.DTCCR],eax
loc_1:
	mov	eax,gs:[Reg.DTCCR]
	test	al,Cmd
	jnz	short loc_1

	mov	bx,offset MacStatus
	mov	si,[regDTCCRBase]

	mov	eax,[si].DTCB.TxOk
	add	[bx].mst.txframe,eax

	mov	eax,[si].DTCB.RxOk
	add	[bx].mst.rxframe,eax

	mov	eax,[si].DTCB.RxEr
	add	[bx].mst.rxframecrc,eax

	movzx	eax,[si].DTCB.MissPkt
	add	[bx].mst.rxframebuf,eax

	mov	eax,[si].DTCB.RxOkBrd
	add	[bx].mst.rxframebroad,eax

	mov	eax,[si].DTCB.RxOkMul
	add	[bx].mst.rxframemulti,eax

	movzx	eax,[si].DTCB.TxUndrn
	add	[bx].mst.txframehw,eax

	sub	ax,[si].DTCB.TxAbt
	neg	ax
	add	[bx].mst.txframeto,eax

	mov	gs:[Reg.MPC],eax	; clear

	call	_LeaveCrit
	pop	ax
	pop	si
	retn
_hwUpdateStat	endp

_hwClearStat	proc	near
	mov	gs:[Reg.MPC],eax
	retn
_hwClearStat	endp

_SetSpeedStat	proc	near
	mov	al,MediaSpeed
	mov	ah,0
	mov	dx,[cfgTxPollCnt]
	dec	ax
	jz	short loc_10M
	dec	ax
	jz	short loc_100M
	dec	ax
	jz	short loc_1G
	xor	cx,cx
	xor	bx,bx
	jmp	short loc_1
loc_10M:
	mov	cx,highword 10000000
	mov	bx,lowword  10000000
loc_1:
	mov	ax,100
	mul	dx
	jmp	short loc_2
loc_100M:
	mov	cx,highword 100000000
	mov	bx,lowword  100000000
	mov	ax,10
	mul	dx
	jmp	short loc_2
loc_1G:
;	xor	ax,ax
	mov	cx,highword 1000000000
	mov	bx,lowword  1000000000
	xchg	ax,dx
loc_2:
			; timer synchronize with PCI bus clock?
	cmp	[CoreVer],MAC_VER_8168
	jc	short loc_3
	cmp	[CoreVer],MAC_VER_8101E
	ja	short loc_3
	shld	dx,ax,2		; PCI-E 125MHz - mul 4
	shl	ax,2
	jmp	short loc_4
loc_3:
	test	gs:[Reg.CONFIG2],PCICLKF
	jz	short loc_4
	shl	ax,1
	rcl	dx,1	; PCI 66MHz - twice
loc_4:
	mov	word ptr [MacChar.linkspeed],bx
	mov	word ptr [MacChar.linkspeed][2],cx
	mov	word ptr [TimerCount],ax
	mov	word ptr [TimerCount][2],dx
	retn
_SetSpeedStat	endp


_hwClose	proc	near
	push	offset semTx
	call	_EnterCrit
	push	offset semRx
	call	_EnterCrit

	xor	ax,ax
	mov	[regIntMask],ax
	mov	gs:[Reg.CR],al
	mov	gs:[Reg.IMR],ax
	dec	ax
	mov	gs:[Reg.ISR],ax

	call	_LeaveCrit
	pop	dx
	call	_LeaveCrit
	pop	dx

	mov	ax,SUCCESS
	retn
_hwClose	endp

_hwReset	proc	near	; call in bind process
	enter	6,0

	xor	ax,ax
	mov	gs:[Reg.IMR],ax		; clear IMR
	dec	ax
	mov	gs:[Reg.ISR],ax		; clear ISR

	mov	gs:[Reg.CR],RST		; reset
	mov	byte ptr [bp-2],16	; about 3 second.
loc_1:
	push	192
	call	_Delay1ms
	pop	ax
	test	gs:[Reg.CR],RST		; reset complete?
	jz	short loc_2
	dec	byte ptr [bp-2]
	jnz	short loc_1
	mov	ax,HARDWARE_FAILURE
	leave
	retn

loc_2:
					; kill/active Power Management
	mov	ah,gs:[Reg.ECR]
	mov	gs:[Reg.ECR],EEM_Config	; writeable CONFIGx
	mov	al,gs:[Reg.CONFIG1]
	and	al,not PMEn
	or	al,cfgPWM
	mov	gs:[Reg.CONFIG1],al
	mov	gs:[Reg.ECR],ah
					; kill WOL
;	and	gs:[Reg.CONFIG5],not (BWF or MWF or UWF or LANWake or PME_STS)
	and	gs:[Reg.CONFIG5],not (BWF or MWF or UWF or LANWake)

	call	_QueryCoreVer
	mov	[CoreVer],al

	mov	ax,gs:[Reg.CpCR]
	and	ax,not (ENDIAN or RxVLAN or DAC or MulRW)
	cmp	[cfgPCIMRW],0
	jz	short loc_3
	or	ax,MulRW
loc_3:
IF 0	; remove rev specific code temporarily
		; What is this work-around code? from solaris driver.
	cmp	[ChipRev],__rev_d
	jc	short loc_4
	cmp	[ChipRev],__rev_e
	ja	short loc_4
	or	ax,4000h	; undocumented bit
ENDIF
loc_4:
	or	ax,RxChkSum		; IP/UDP/TCP checksum
	mov	gs:[Reg.CpCR],ax

		; undocumented register. What? from solaris driver.
	mov	gs:[Reg.CpCR][2],word ptr 0

	xor	eax,eax
	mov	gs:[Reg.TimerInt],eax
	mov	gs:[Reg.TNPDS],eax
	mov	gs:[Reg.TNPDS+4],eax
	mov	gs:[Reg.THPDS],eax
	mov	gs:[Reg.THPDS+4],eax
	mov	gs:[Reg.RDSAR],eax
	mov	gs:[Reg.RDSAR+4],eax
	mov	gs:[Reg.DTCCR+4],eax

		; get Station address for EEPROM
	push	7		; IDR0,1
	call	_eepRead
	mov	[bp-6],ax
	
	push	8		; IDR2,3
	call	_eepRead
	mov	[bp-4],ax

	push	9		; IDR4,5
	call	_eepRead
	mov	[bp-2],ax

	push	offset semFlt
	call	_EnterCrit
	mov	ax,[bp-6]
	mov	cx,[bp-4]
	mov	dx,[bp-2]
	mov	word ptr MacChar.mctpsa,ax	; parmanent
	mov	word ptr MacChar.mctpsa[2],cx
	mov	word ptr MacChar.mctpsa[4],dx
;	mov	word ptr MacChar.mctcsa,ax	; current
;	mov	word ptr MacChar.mctcsa[2],cx
;	mov	word ptr MacChar.mctcsa[4],dx
	mov	word ptr MacChar.mctVendorCode,ax ; vendor
	mov	byte ptr MacChar.mctVendorCode,cl
	call	_LeaveCrit
	add	sp,4*2
	call	_hwSetMACaddr		; update IDRs
	mov	ax,SUCCESS
	leave
	retn
_hwReset	endp

_QueryCoreVer	proc	near
	mov	eax,gs:[Reg.TCR]
	shr	eax,16
	and	ax,highword(HWVERID0 or HWVERID1)
	mov	bx,offset _HWVERID
loc_1:
	cmp	bx,offset _HWVERID_END
	jnc	short loc_2
	cmp	ax,[bx]
	jz	short loc_3
	add	bx,3
	jmp	short loc_1
loc_2:
	mov	bx,offset _HWVERID	; not found.
loc_3:
	mov	al,[bx+2]
	retn
_QueryCoreVer	endp


; USHORT miiRead( UCHAR phyaddr, UCHAR phyreg)
; << phyaddr is ignored. >>
_miiRead	proc	near
	push	bp
	mov	bp,sp
	push	offset semMii
	call	_EnterCrit
	mov	bx,offset Reg.PHYAR

	mov	al,[bp+6]
	mov	ah,0
	and	al,highword(RegAddr04)
	shl	eax,16
	mov	gs:[bx],eax

	mov	cx,32
	push	16
loc_1:
	call	__IODelayCnt
	mov	eax,gs:[bx]
	test	eax,Flag
	jnz	short loc_2
	dec	cx
	jnz	short loc_1

loc_2:
	pop	cx	; stack adjust
	call	_LeaveCrit
	leave
	retn
_miiRead	endp

; VOID miiWrite( UCHAR phyaddr, UCHAR phyreg, USHORT value)
; << phyaddr is ignored. >>
_miiWrite	proc	near
	push	bp
	mov	bp,sp
	push	offset semMii
	call	_EnterCrit
	mov	bx,offset Reg.PHYAR

	mov	al,[bp+6]		; register
	mov	ah,high(highword(Flag))
	and	al,highword(RegAddr04)
	shl	eax,16
	mov	ax,[bp+8]		; content
	mov	gs:[bx],eax

	mov	cx,32
	push	16
loc_1:
	call	__IODelayCnt
	test	dword ptr gs:[bx],Flag
	jz	short loc_2
	dec	cx
	jnz	short loc_1

loc_2:
	pop	cx	; stack adjust
	call	_LeaveCrit
	leave
	retn
_miiWrite	endp

; How can we reset MII interface??
; VOID miiReset( VOID )
;_miiReset	proc	near
;	retn
;_miiReset	endp

; USHORT eepRead( UCHAR addr )
; read opcode 01b
; address mask 3fh(6bit)
_eepRead	proc	near
	push	bp
	mov	bp,sp
	mov	bx,offset Reg.ECR

	mov	ah,gs:[bx]
	mov	al,EEM_Program	; EEPROM access mode
	mov	gs:[bx],al	; chip select - low
;	push	1
	push	4
	call	__IODelayCnt
	or	al,EESK
	mov	gs:[bx],al
	call	__IODelayCnt

	mov	dl,[bp+4]
	mov	dh,0
;	mov	cx,(1 + 2 + 6) -1
	test	gs:[Reg.RxCR],EEP_SEL	; 93C56?
	jz	short loc_0

	and	dl,7fh
	mov	dh,3
	mov	cx,(1 + 2 + 8) -1
	jmp	short loc_1
loc_0:
	and	dl,3fh
	mov	cx,(1 + 2 + 6) -1
	or	dx,110b shl 6
loc_1:
	mov	al,(EEM_Program or EECS) shr 2
	bt	dx,cx
	rcl	al,2
	mov	gs:[bx],al
	call	__IODelayCnt
	or	al,EESK
	mov	gs:[bx],al
	call	__IODelayCnt
	dec	cx
	jge	short loc_1

	mov	cx,16
	xor	dx,dx
loc_2:
	mov	al,EEM_Program or EECS
	mov	gs:[bx],al
	call	__IODelayCnt
	or	al,EESK
	mov	gs:[bx],al
	call	__IODelayCnt
	mov	al,gs:[bx]
	shr	al,1
	rcl	dx,1
	dec	cx
	jnz	short loc_2

	mov	al,EEM_Program
	mov	gs:[bx],al
	call	__IODelayCnt
	or	al,EESK
	mov	gs:[bx],al
	call	__IODelayCnt
	mov	gs:[bx],ah
	pop	cx
	mov	ax,dx
	pop	bp
	retn
_eepRead	endp

; void _IODelayCnt( USHORT count )
__IODelayCnt	proc	near
	push	bp
	mov	bp,sp
	push	cx
	mov	bp,[bp+4]
loc_1:
	mov	cx,offset DosIODelayCnt
	dec	bp
	loop	$
	jnz	short loc_1
	pop	cx
	pop	bp
	retn
__IODelayCnt	endp


_TEXT	ends
end
