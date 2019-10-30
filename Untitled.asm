	LIST p=16f877a 			
	#include "P16f877a.inc"	


;0x33 delay counter variable
;0x35 ADC result
;0x36 stores value 100
;0x30 is used also for storing ADC result

;0x41,0x42,0x43 Division variable 

;0x45 is  the final port signal

;-----------------------------------------------------
;Input and output
banksel TRISA ;assembler directive to select bank
movlw 0xff
movwf TRISA ;set all PORTA pins as inputs

banksel TRISB ;assembler directive to select bank
movlw 0x00
movwf TRISB ;set all PORTA pins as inputs

banksel TRISC ;assembler directive to select bank
movlw 0x00
movwf TRISC ;set all PORTA pins as inputs
;-----------------------------------------------------



;-----------------------------------------------------
banksel ADCON0 ;assembler directive to select bank
movlw b'01000001'
movwf ADCON0 ; channel 0, FOSC/8, enable A/D

banksel ADCON1 ;assembler directive to select bank
movlw b'00000010'
movwf ADCON1 ;RA0,1,2,3,5 analog, VREF = VDD
;-----------------------------------------------------



;------------------------------------------------------
;An appropriate acquisition time must be
;allowed for after selecting an input channel
;l A delay loop can be used
;20us delay loop with 4MHz oscillator frequency
bcf STATUS, RP0 
bcf STATUS, RP1 
movlw 0x06
movwf 0x33 ;initialize count
loop
decfsz 0x33,F ;dec count, store in count
goto loop ;not finished
;-------------------------------------------------------




banksel ADCON0 ;select bank
bsf ADCON0,GO ;initiate conversion


;check if the conversion is done?
banksel ADCON0 ;select bank
test
btfsc ADCON0,GO ;conversion done?
goto test ;not finished




;-------------------------------------------------
;Now comes  the result part

;Here the temperature value is at max 150 so no need of the 10th bit as it considered if the ADC value is  more  than 255 but
;in our case wont happen

;Now ADRESL's last bit is least significant bit . So we dont consider  it valid
;So we avoid that also 

;Now we only need the 8 bits of the 10 bit ADC Result. So we are extracting the result as per

banksel ADRESH ;select bank

rlf  ADRESH,F

btfsc ADRESL,7
bsf  ADRESH,0

movf ADRESH,w

movwf 0x35

movwf 0x30 ;temporary storage

;result is stored in a temporary location
;-------------------------------------------------


;------------------------------------------------
;this register is used for  directly storing the 3bit decimal number 
;It this register only the MSB 2 and 1 bits are stored
;For eg 154 then 15 is stored
movlw 0x00
movf  0x45
;--------------------------------------------------







;-------------------------------------------------
;extracting hundreds place
;sublw =>  W=L-W
movlw b'01100100' ;100

subwf 0x35,f  ;f=f-w   ie f=f-100

btfsc STATUS,C
goto setONE
goto setZERO

setONE:
movlw b'00010000'
movwf 0x45
goto NEXT


setZERO:
movf 0x30,w
movwf 0x35
movlw b'00000000'
movwf 0x45
goto  NEXT
;---------------------------------------------------

;======================================================
;this is for extracting 10's place
NEXT:
movlw 0x0A
movwf 0x41

;-------------------------|
;Division Algorithm       |
;-------------------------|
;Division  0x35/0x41  ie value/10
;0x42 will serve as quotient
clrf 0x42
MOVF 0X41,W
LP1:
incf 0x42,f
SUBWF 0X35,F
BTFSC STATUS,C
GOTO LP1

movlw 0x01  ; needed for my div algo (for correct quotient)
subwf 0x42,f

movf 0x41,w ; need for the correct remainder
addwf 0x35,f

movf 0x42,w
iorwf 0x45,f
;========================================================

;-------------------------------------------------------
;Lastly extract the one's place digit
;Here it is 0x35
movf 0x35,w
movwf PORTC
;-------------------------------------------------------

movf 0x45,w
movwf PORTB







end
