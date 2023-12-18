; usrfunction-0-4.asm
; version 6

        getadr = $b7f7
        givayf = $b391
        
        *= $c000
        
                jsr getadr      ; convert real into unsigned int 
                                ; in .A & .Y (hi/lo)
                sty testnum     ; save for later use
                sta testnum+1
                ldx #$00
                stx isprime     ; assume it is not a prime
                cpy #$02        ; is testnum less than 2?
                lda testnum+1
                sbc #$00
                bcs okay        ; testnum >= 2
                jmp foundit     ; no, then output value of isprime
        okay:

        ; test if test number is equal to one of the prime numbers

                ldx #53
                stx order       ; start with 53th prime
        loop1:        
                ldx order
                bmi loop1x      ; if < 0 then exit loop

                jsr prime       ; get nth prime in .X
                cpx testnum     ; is testnum == prime?
                bne loop1a      ; no, then next prime
                lda testnum+1
                bne loop1a

                ldy #$ff        ; yes, then
                sty isprime     ; it is a prime
                bne foundit     ; skip to the end
        loop1a:
                dec order       ; try previous prime
                clc
                bcc loop1       ; continue loop
        loop1x: 
        
                lda #$ff
                sta isprime     ; assume testnum is prime
                
                lda #$00
                sta order       ; start with 0th prime
                
        loop2:
                ldx order
                jsr prime       ; find the nth prime
                stx temp        ; store for later use
                txa
                jsr square      ; square the prime
                
                cmp testnum     ; prime * prime == testnum ?
                bne loop2a
                cpy testnum+1
                bne loop2a
                ldy #$00
                sty isprime     ; yes, then it is not a prime
                beq foundit
                
        loop2a:
                cmp testnum     ; is prime * prime > testnum?
                tya
                sbc testnum+1
                bcs foundit     ; then exit the loop
                
                ldx temp        ; prime is divisor
                lda testnum     ; testnum is dividend
                ldy testnum+1
                jsr modulo
                
                cmp #$00        ; is remainder zero?
                bne loop2b      ; no, then next prime
                cpy #$00
                bne loop2b
                ldy #$00        ; yes, then
                sty isprime     ; it is not a prime
                beq foundit
                
        loop2b:
                inc order       ; try next prime
                clc
                bcc loop2       ; continue loop
                
        foundit:
                lda isprime     ; primality flag is
                tay             ; either $0000 or $ffff
                jmp givayf      ; make it real & return to Basic
    
        
        testnum:
                .word $ffff     ; container for number to be tested
        order:
                .byte $ff       ; container for n, as in nth prime
        isprime:
                .byte $ff       ; container for flag that signals
                                ; primality
        temp
                .byte $ff       ; temporary storage for prime


; prime
; Finds the nth prime on the number line.
; E.g. prime(0) = 2, prime(1) = 3, etc.
;
; input .X order n
;
; output .X nth prime number
;
; effects on .A, .X, .M, .Z
                                
        prime:
                lda primes,x    ; load from list of primes
                tax             ; put it in .X
                rts
        ; ordered list of all 54 prime numbers less than 256
        primes  .byte   2,   3,   5,   7,  11 
                .byte  13,  17,  19,  23,  29
                .byte  31,  37,  41,  43,  47
                .byte  53,  59,  61,  67,  71
                .byte  73,  79,  83,  89,  97
                .byte 101, 103, 107, 109, 113
                .byte 127, 131, 137, 139, 149
                .byte 151, 157, 163, 167, 173
                .byte 179, 181, 191, 193, 197
                .byte 199, 211, 223, 227, 229
                .byte 233, 239, 241, 251
        
                
; square
; Calculates the 16-bit unsigned square of an 8-bit unsigned integer.
;
; input .A number to be squared
; output .A, .Y squared number (lo/hi)
;
; Destroys all registers.

        number = $61            ; 8-bit value to be squared
        nsquare = $62           ; 16-bit value of squared number
        tnumber = $64           ; temporary storage for number
        
        square:
                sta number      ; put .A in number
                lda #$00        ; clear A
                sta nsquare     ; clear square low byte
                                ; (no need to clear the high byte,
                                ; it gets shifted out)
                lda number      ; get number in .A
                sta tnumber     ; save original for later use
                ldx #$08        ; 8 bits to process
        sqloop:
                asl nsquare     ; shift square to left
                rol nsquare+1   ; (i.e. multiply by 2)
                asl a           ; get next highest bit of number
                bcc sqnoadd     ; don't do add if carry is zero
                tay             ; save .A for later use
                clc
                lda tnumber     ; add original number value
                adc nsquare     ; to square
                sta nsquare
                lda #$00        ; add a possible carry
                adc nsquare+1   ; to the high byte of square
                sta nsquare+1
                tya             ; get .A back
        sqnoadd:
                dex             ; decrement bit counter
                bne sqloop      ; go do next bit
                lda nsquare     ; lo byte of square in .A
                ldy nsquare+1   ; hi byte of square in .Y
                rts
                
                
; modulo
; Calculate the modulo of an 8-bit number with a 16-bit number.
;
; input .A, .Y dividend
;       .X divisor
;
; output .A, .Y remainder
;
; Destroys all registers.

        num1 = $61      ; 16-bit dividend
        num2 = $63      ; 8-bit divisor
        rem = $64       ; 16-bit remainder
        
modulo:
        sta num1        ; .A lo byte of dividend
        sty num1+1      ; .Y hi byte of dividend
        stx num2        ; .X divisor
        lda #$00        ; clear remainder
        sta rem
        sta rem+1
        ldx #16         ; do 16 bits
modloop:
        asl num1        ; shift num1 to the left
        rol num1+1
        rol rem         ; into remainder
        rol rem+1
        sec
        lda rem         ; do trial subtraction
        sbc num2        ; with divisor
        tay
        lda rem+1
        sbc #$00        ; divisor is 8-bit value
        bcc modnosub    ; was there a borrow, 
                        ; then skip subtraction
        sta rem+1       ; save the result
        sty rem
modnosub:
        dex             ; repeat for 16 bits
        bne modloop
        lda rem         ; lo byte of remainder in .A
        ldy rem+1       ; hi byte of remainder in .Y
        rts