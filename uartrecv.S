;	ORG $80000
;	LOAD $80000
	JUMPPTR init
*** Serial file receive tool
* Polled with interrupts disabled
* Roc Valles
*** setup
init:
	move.l #0,a4 ;will later contain dosbase
	move.l $4,a5 ;execbase
	move.l a5,a6
	move.l #0,a1
	jsr -294(a6) ;FindTask()
	move.l d0,a0
	move.l 58(a0),d0 ;TC_SPLOWER
	cmp.l sp,d0
	bhi fakestacksize ;shouldn't be needed, but asmtwo.
	move.l sp,d1
	sub.l d0,d1
	br init1
fakestacksize:
	move.w #$f0f,$dff180
;	br fakestacksize
	move.l #4000,d1
init1:
	sub.l #256,d1 ;leave some for dos.library
	move.l d1,a3
	lea dosname,a1
	move.l a5,a6
	jsr -408(a6) ;OldOpenLibrary
	move.l d0,a4
	lea filename,a0
	move a0,d1
	move.l #1006,d2 ;MODE_NEWFILE
	move.l a4,a6
	jsr -30(a6) :Open()
	move.l d0,d7
	move.l a5,a6
	jsr -120(a6) ;Disable()
*** uart setup
	move.w #6,$dff032 ;SERPER
	move.w #$0800,$dff09c ;INTREQ RBF clear
	br waitremote
	EVEN
dosname: dc.b 'dos.library',0
	EVEN
filename: dc.b 'RAM:test.lha',0
	EVEN
*** wait for remote end to pop up.
waitremote:
	btst #6,$bfe001
	beq cleanup ;left mouse button bailout
	move.w $dff018,d1 ;SERDATR RBF
	btst #14,d1 ;SERDATR RBF
	beq.s waitremote
	move.w #$0800,$dff09c ;INTREQ RBF clear 
	cmp.b #33,d1
	bne waitremote
	move.w a3,d1
	lsr.w #8,d1
	and.w #$00FF,d1
	or.w #$0100,d1
sendmaxsize:
	btst #13,$dff018 ;SERDATR TBE
	beq sendmaxsize	
	move.w d1,$dff030
*** get size
getsiz:
	btst #12,$dff018 ;SERDATR TSRE
	beq getsiz
	move.w #$0141,$dff030
	move.w #$0800,$dff09c ;INTREQ RBF clear 
waitsizhi:
	btst #14,$dff018 ;SERDATR RBF
	beq.s waitsizhi
	move.w $dff018,d6
	move.w #$0800,$dff09c ;INTREQ RBF clear 
waitsizlo:
	btst #14,$dff018 ;SERDATR RBF
	beq.s waitsizlo
	move.w $dff018,d1
	move.w #$0800,$dff09c ;INTREQ RBF clear 
	lsl.w #8,d6
	move.b d1,d6
	tst.w d6
	beq cleanup
	cmp a3,d6
	bhi getsiz
	;move.w #$ff0,$dff180
	move.l d6,d0
	move.l sp,a2
	sub.w d6,a2
	move.l a2,d5
	sub.w #1,d0
	clr.w d2
acksiz:
	btst #13,$dff018 ;SERDATR TBE	
	beq acksiz
	move.w #$0144,$dff030
receiveblk:
	move.w $dff018,d1 ;SERDATR RBF
	btst #15,d1
	bne.s overflow
	btst #14,d1
	beq.s receiveblk
	move.w #$0800,$dff09c ;INTREQ RBF clear 
	move.b d1,(a2)+
	and.w #$FF,d1
	add.w d1,d2
	move.w d2,$dff180
	dbf d0,receiveblk
*** Prepare send cksum
	move.w d2,d1
	rol.w #8,d1
	and.w #$00ff,d1
	or.w #$0100,d1
	bra sendcksum
overflow:
	move.w #$0800,$dff09c ;INTREQ RBF clear 
	sub.w #2,d0
	;move.w #$f00,$dff180
	bra.s receiveblk
sendcksum:
	btst #13,$dff018 ;SERDATR TBE
	beq sendcksum		
	move.w #$0143,$dff030
sendcksum1:
	btst #13,$dff018 ;SERDATR TBE
	beq sendcksum1
	move.w d1,$dff030	
	move.w d2,d1
	and.w #$00ff,d1
	or.w #$0100,d1
sendcksum2:
	btst #13,$dff018 ;SERDATR TBE
	beq sendcksum2
	move.w d1,$dff030	
aftercksum:
	btst #14,$dff018 ;SERDATR RBF
	beq aftercksum
	move.w $dff018,d1
	move.w #$0800,$dff09c ;INTREQ RBF clear
	cmp.b #$57,d1
	beq writeblk
	bra red
writeblk:
	;move.b #252,$bfe001 ;LED
	move.l sp,d4 ;backup stack
	move.l d5,sp ;stack below buffer
	btst #0,d5 ;is stack even?
	beq writeblkeven
	sub #1,sp
writeblkeven:
	move.l d7,d1 ;file
	move.l d5,d2 ;buffer
	move.l d6,d3 ;length
	move.l a5,a6
	jsr -126(a6) ;Enable()
	move.l a4,a6
	jsr -48(a6) ;Write()
	move.l a5,a6
	jsr -120(a6) ;Disable()
	move.l d4,sp ;restore stack
	bra getsiz
red:
	move.w #$f00,$dff180
	bra getsiz
cleanup:
	btst #13,$dff018 ;SERDATR TBE	
	beq cleanup
	move.w #$0146,$dff030
	move.l a5,a6
	jsr -126(a6) ;Enable()
	move.l d7,d1
	move.l a4,a6
	jsr -36(a6) ;Close()
	move.l a4,a1
	beq cleanup1	
	move.l a5,a6
	jsr -414(a6) ;CloseLibrary()
cleanup1:
	clr.l d0
	rts
