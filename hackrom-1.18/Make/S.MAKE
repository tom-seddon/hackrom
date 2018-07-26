	EXEC	make
	ORG	&6000

begin
; -------------------------------------
; Source for MAKE
;
;
; Uses MAKFILE for dependencies
;
; Creates file in dir M with name of
;   executable
;
; Syntax :
;   MAKE <SRC> (-A<OBJECT> -F<"FLAGS">
;              -N -O<ADDR> )
;
; -A<OBJECT> will overide the
;   executable filename in the Makefile
; -F<"FLAGS"> will overide the flags
;   set in the Makefile but if the
;   quotes are single (') the flags
;   will be added to those in the
;   Makefile
;   Flags must be in quotes
; -N will instruct MAKE not to run the
;   assembler
; -O will overide the execution address
;   set in the Makefile
;
; -------------------------------------
obj_opt	EQU	'A'
flag_opt	EQU	'D'
no_ass_opt	EQU	'N'
org_opt	EQU	'O'
mak_opt	EQU	'F'
chn_opt	EQU	'C'
inc_opt	EQU	'I'

chndef	EQU	&00
incdef	EQU	&FF

chnincdef	EQU	chndef

VERSION	ASET	"1.2"

temp_line_ptr	EQU	&70 ; &71
line_ptr	EQU	&72 ; &73
line_num	EQU	&74 ; &75
list_ptr	EQU	&76 ; &77
src_ptr	EQU	&78 ; &79
start_ptr	EQU	&7A ; &7B
temp_src_ptr	EQU	&7C ; &7D
file_handle	EQU	&7E
file_count	EQU	&7F
temp_stack_ptr	EQU	&8F

tab	EQU	&DD



; new_line trap and close_bracket trap
new_line_trap
	DB	&0D,')'
eof
	DB	>(new_line_trap+1)
	DB	<(new_line_trap+1)

tmp_cli_ptr
	DB	&00
tmp_F2
	DB	&00
	DB	&00


makefile
	STR	"MAKFILE"
makeblock
	DB	>makefile
	DB	<makefile
load_addr
	DB	[4]0
exec_addr
	DB	[4]0
file_len
	DB	[4]0
end_addr
	DB	[4]0


org
	DB	[2]0

flags
	DB	[80]0
num_flags
	DB	0

mfilename
	ASC	"M."
exc
	ASC	"OUT"
	DB	&0D
	DB	[4]0
exc_flag
	DB	&00

n
	DB	0

src
	DB	[40]0

ass_cli
	ASC	"*ASSEMBLE M."
	DB	[&FF+ass_cli-*]0

exec_str
	DB	[32]0

exec_flag
	DB	&00

chn_inc_flag
	DB	chnincdef

tmp_key_buf
	DB	[&100]0

disp_syntax
	JSR	pc_print
	ASC	"Syntax :"
	DB	&0D
	DB	&0D
	ASC	"MAKE source"
	DB	&0D
	ASC	"     (-"
	DB	obj_opt
	ASC	"(object))"
	DB	&0D
	ASC	"     (-"
	DB	flag_opt
	ASC	'"'
	ASC	"("
	DB	flag_opt
	ASC	")-flags"
	ASC	'"'
	ASC	")"
	DB	&0D
	ASC	"     (-"
	DB	no_ass_opt
	ASC	")"
	DB	&0D
	ASC	"     (-"
	DB	org_opt
	ASC	"addr)"
	DB	&0D
	ASC	"     (-"
	DB	mak_opt
	ASC	"makefile)"
	DB	&0D
	ASC	"     (-"
	DB	chn_opt
	ASC	")"
	DB	&0D
	ASC	"     (-"
	DB	inc_opt
	ASC	")"
	DB	&0D
	DB	&0D
	DB	0
	JMP	fatal

make
	TYA
	PHA
	JSR	pc_print
	ASC	"65C02 MAKE"
	DB	&0D
	DB	&0D
	DB	&00
	PLA
	TAY

	TSX
	STX	temp_stack_ptr
	TYA
	PHA
	LDY	#&00
copy_key_buf
	LDA	(&F2),Y
	STA	tmp_key_buf,Y
	INY
	CMP	#&0D
	BNE	copy_key_buf
	PLA
	TAY
	LDA	&F2
	STA	tmp_F2
	LDA	&F3
	STA	tmp_F2+1
	JSR	rdstr
	BEQ	n_disp_syntax
	JMP	disp_syntax
n_disp_syntax
	STX	endstr
	TYA
	CLC
	ADC	endstr
	STA	endstr
	LDA	newy
	STA	tmp_cli_ptr
	LDX	#&01
	LDA	#tab
	STA	src
make_loop0
	LDA	(&F2),Y
	STA	src,X
	INX
	INY
	CPY	endstr
	BNE	make_loop0
	LDA	#&0D
	STA	src,X
	STA	src+2,X
	LDA	#')'
	STA	src+1,X

	LDY	newy
make_opt
	JSR	rdstr
	BNE	no_prob
	JMP	syntax_error
no_prob
	CMP	#'-'
	BNE	go_load
	JSR	rdstr
	STX	endstr
	TYA
	CLC
	ADC	endstr
	STA	endstr
	LDA	(&F2),Y
	CMP	#mak_opt
	BNE	not_m_flag
	INY
	LDX	#&00
new_makefile
	LDA	(&F2),Y
	STA	makefile,X
	INX
	INY
	CPY	endstr
	BNE	new_makefile
	LDA	#&0D
	STA	makefile,X
	JMP	go_load
not_m_flag
	LDY	newy
	JMP	make_opt

go_load
	JSR	pc_print
	ASC	"65C02 Make @VERSION"
	DB	&0D
	ASC	"1992 Stephen Youell"
	DB	&0D
	ASC	"     Warwick University"
	DB	&0D
	DB	&0D
	ASC	"Make : "
	DB	&00
	LDX	#&01
srcloop
	LDA	src,X
	JSR	&FFE3
	INX
	CMP	#&0D
	BNE	srcloop
	JSR	load_makefile
	JSR	search_args
	LDA	#>src
	STA	line_ptr
	LDA	#<src
	STA	line_ptr+1
	JSR	search_source
	BEQ	goto
	JSR	pc_print
	DB	&0D
	ASC	"****** Err :"
	DB	&0D
	ASC	" Source not found in makefile"
	DB	&0D
	DB	&0D
	DB	&00
	JMP	fatal
goto
	JMP	into_main_loop


end_block
	PLA
	STA	line_ptr+1
	PLA
	STA	line_ptr
	TSX
	CPX	temp_stack_ptr
	BNE	main_loop
	JMP	sort

main_loop
	JSR	read_line
	LDY	#&00
	LDA	(line_ptr),Y
	CMP	#')'
	BEQ	end_block
	LDA	(line_ptr),Y
	CMP	#tab
	BNE	arg_check
into_main_loop
	JSR	search_source
	BEQ	push_line_ptr
	LDY	#&00
	LDA	line_ptr
	STA	(list_ptr),Y
	INY
	LDA	line_ptr+1
	STA	(list_ptr),Y
	LDA	list_ptr
	SEC
	SBC	#&02
	STA	list_ptr
	LDA	list_ptr+1
	SBC	#&00
	STA	list_ptr+1
	CLC
	JMP	main_loop

push_line_ptr
	LDA	line_ptr
	PHA
	LDA	line_ptr+1
	PHA
	LDA	src_ptr
	STA	line_ptr
	LDA	src_ptr+1
	STA	line_ptr+1
	JMP	main_loop

arg_check
	JSR	set_arg
	JMP	main_loop

search_args
	LDA	start_ptr
	STA	line_ptr
	LDA	start_ptr+1
	STA	line_ptr+1

sargs_loop0
	JSR	read_line
	BEQ	sargs_not_eof
	RTS
sargs_not_eof

	LDY	#&00
sargs_loop1
	LDA	(line_ptr),Y
	CMP	#&0D
	BEQ	out_sargs
	INY
	BNE	sargs_loop1
out_sargs
	DEY
	LDA	(line_ptr),Y
	CMP	#'('
	BEQ	ok_open
	JSR	set_arg
	JMP	sargs_loop0
ok_open
	JSR	read_line
	LDY	#&00
	LDA	(line_ptr),Y
	CMP	#')'
	BNE	ok_open
	JMP	sargs_loop0

sort
	SEC
	LDA	start_ptr
	SBC	#&02
	STA	src_ptr
	STA	start_ptr
	STA	temp_src_ptr
	LDA	start_ptr+1
	SBC	#&00
	STA	src_ptr+1
	STA	start_ptr+1
	STA	temp_src_ptr+1

sort_loop0

	LDA	start_ptr
	STA	line_ptr
	LDA	start_ptr+1
	STA	line_ptr+1

sort_loop1

	JSR	strcmp
	BEQ	sort_over0

sort_over3
	LDA	line_ptr
	CMP	src_ptr
	BNE	sort_over1
	LDA	line_ptr+1
	CMP	src_ptr+1
	BEQ	sort_over2

sort_over1
	SEC
	LDA	line_ptr
	SBC	#&02
	STA	line_ptr
	LDA	line_ptr+1
	SBC	#&00
	STA	line_ptr+1
	JMP	sort_loop1

sort_over2
	SEC
	LDA	src_ptr
	SBC	#&02
	STA	src_ptr
	LDA	src_ptr+1
	SBC	#&00
	STA	src_ptr+1

	LDY	#&00
	LDA	(temp_src_ptr),Y
	STA	(src_ptr),Y
	INY
	LDA	(temp_src_ptr),Y
	STA	(src_ptr),Y

sort_over0
	SEC
	LDA	temp_src_ptr
	SBC	#&02
	STA	temp_src_ptr
	LDA	temp_src_ptr+1
	SBC	#&00
	STA	temp_src_ptr+1

	LDA	temp_src_ptr
	CMP	list_ptr
	BNE	sort_loop0
	LDA	temp_src_ptr+1
	CMP	list_ptr+1
	BNE	sort_loop0
	SEC
	LDA	src_ptr
	SBC	#&02
	STA	src_ptr
	LDA	src_ptr+1
	SBC	#&00
	STA	src_ptr+1
	JMP	read_comm_loopx

; start_ptr points to start of sorted
; list, src_ptr points to last item

synerr
	JMP	syntax_error

bad_arg
	PHA
	JSR	pc_print
	DB	&0D
	ASC	"****** Err :"
	DB	&0D
	DB	' '
	DB	&00
	JSR	&FFEE
	JSR	pc_print
	ASC	" is not a valid option"
	DB	&0D
	DB	&00
	JMP	fatal

no_org
	JSR	pc_print
	DB	&0D
	ASC	"****** Err :"
	DB	&0D
	ASC	" No ORG specified with -"
	DB	org_opt
	ASC	" option"
	DB	&0D
	DB	&00
	JMP	fatal

no_flags
	JSR	pc_print
	DB	&0D
	ASC	"****** Err :"
	DB	&0D
	ASC	" No flags specified with -"
	DB	flag_opt
	ASC	" option"
	DB	&0D
	DB	&00
	JMP	fatal


read_comm_loopx
	LDA	tmp_F2
	STA	&F2
	LDA	tmp_F2+1
	STA	&F3
	LDY	#&00
rcloop
	LDA	tmp_key_buf,Y
	STA	(&F2),Y
	INY
	CMP	#&0D
	BNE	rcloop
	LDY	tmp_cli_ptr

read_comm_loop
	JSR	rdstr
	BNE	no_syntax_error
	JMP	syntax_error
no_syntax_error
	CMP	#'-'
	BEQ	more_args
	JMP	no_more_args
more_args
	LDA	(&F2),Y
	CMP	#inc_opt
	BNE	ninc_opt
	LDA	#incdef
	STA	chn_inc_flag
	INY
	JMP	read_comm_loop

ninc_opt
	CMP	#chn_opt
	BNE	nchn_opt
	LDA	#chndef
	STA	chn_inc_flag
	INY
	JMP	read_comm_loop

nchn_opt
	CMP	#obj_opt
	BEQ	read_a_arg
	CMP	#flag_opt
	BNE	n_read_f_arg
	JMP	read_f_arg
n_read_f_arg
	CMP	#mak_opt
	BEQ	read_m_arg
	CMP	#no_ass_opt
	BNE	not_read_n_arg
	JMP	read_n_arg
not_read_n_arg
	CMP	#org_opt
	BEQ	good_arg
	JMP	bad_arg
good_arg
	INY
	JSR	rdnum
	BEQ	nno_org
	JMP	no_org
nno_org
	LDA	clibuf
	STA	org
	LDA	clibuf+1
	STA	org+1
	JMP	read_comm_loop

read_m_arg
	INY
	JSR	rdstr
	LDY	newy
	JMP	read_comm_loop

read_a_arg
	INY
	JSR	rdstr
	BEQ	ok_a_arg
	DEY
	PHA
	LDA	#&FF
	STA	exc_flag
	PLA
	CMP	#&2D
	BEQ	a_arg_over
	JMP	no_more_args
ok_a_arg
	STX	endstr
	TYA
	CLC
	ADC	endstr
	STA	endstr
	CPY	endstr
	BNE	raa_over
a_arg_over
	LDA	#&FF
	STA	exc_flag
	JMP	read_comm_loop
raa_over
	LDA	#&00
	STA	exc_flag
	LDX	#&FF
raa_loop
	INX
	LDA	(&F2),Y
	STA	exc,X
	INY
	CPY	endstr
	BNE	raa_loop
	INX
	LDA	#&0D
	STA	exc,X
	LDY	newy
	JMP	read_comm_loop

read_f_arg
	INY
	LDA	(&F2),Y
	CMP	#'"'
	BEQ	ok_f_arg
	JMP	syntax_error
ok_f_arg
	JSR	rdstr
	BEQ	rfa
rfa_exit
	LDY	newy
	JMP	read_comm_loop
rfa
	STX	endstr
	TYA
	CLC
	ADC	endstr
	STA	endstr

	LDA	(&F2),Y
	CMP	#flag_opt
	BNE	double_q

	LDX	num_flags
	JMP	floop
double_q
	LDX	#&00
	DEY
floop
	INY
	LDA	(&F2),Y
	STA	flags,X
	INX
	CPY	endstr
	BNE	floop
	DEX
	LDA	#&00
	STA	flags,X
	STX	num_flags
	LDY	newy
	JMP	read_comm_loop

read_n_arg
	LDA	#&FF
	STA	n
	INY
	JMP	read_comm_loop

no_more_args
	LDA	exc
	BNE	open_file
	JSR	pc_print
	DB	&0D
	ASC	"****** Err :"
	DB	&0D
	ASC	" No include file defined"
	DB	&0D
	DB	&00
	JMP	fatal
open_file
	JSR	pc_print
	DB	&0D
	ASC	"++++ Creating "
	DB	&00
	LDX	#&FF
file_print
	INX
	LDA	mfilename,X
	JSR	&FFE3
	CMP	#&0D
	BNE	file_print
	JSR	&FFE7
	LDA	#&80
	LDX	#>mfilename
	LDY	#<mfilename
	JSR	&FFCE
	STA	file_handle
	JSR	pc_file_write
	ASC	"; -------------------------------------"
	DB	&0D
	ASC	"; Make source : "
	DB	&00
	LDX	#&00
iloop
	LDA	exc,X
	JSR	write_byte
	INX
	CMP	#&0D
	BNE	iloop
	JSR	pc_file_write
	ASC	"; -------------------------------------"
	DB	&0D
	DB	&0D
	DB	tab
	ASC	"ORG"
	DB	tab
	ASC	"&"
	DB	&00
	LDA	org+1
	JSR	hex_asc
	STY	tmp
	JSR	write_byte
	LDA	tmp
	JSR	write_byte
	LDA	org
	JSR	hex_asc
	STY	tmp
	JSR	write_byte
	LDA	tmp
	JSR	write_byte

	LDA	exec_flag
	BEQ	no_exec
	JSR	pc_file_write
	DB	&0D
	DB	tab
	ASC	"EXEC"
	DB	tab
	DB	&00
	LDX	#&FF
	TXA
	PHA
se_loop3
	PLA
	TAX
	INX
	TXA
	PHA
	LDA	exec_str,X
	JSR	write_byte
	CMP	#&0D
	BNE	se_loop3
	PLA
no_exec
	LDA	chn_inc_flag
	CMP	#chndef
	BEQ	chn
	JSR	include
	JMP	done_intrmdte
chn
	JSR	chain
done_intrmdte
	LDA	n
	BEQ	assemble
	JMP	fatal
assemble
	LDY	#&0A
	LDX	#&00
ass_loop0
	LDA	mfilename,X
	CMP	#&0D
	BEQ	break_loop
	STA	ass_cli,Y
	INX
	INY
	JMP	ass_loop0
break_loop
	LDA	exc_flag
	BNE	ass_over
	LDA	#' '
	STA	ass_cli,Y
	INY
	LDA	#'A'
	STA	ass_cli,Y
	INY
	LDA	#'.'
	STA	ass_cli,Y
	LDX	#&00
ass_loop1
	INY
	LDA	exc,X
	CMP	#&0D
	BEQ	break_loop1
	STA	ass_cli,Y
	INX
	JMP	ass_loop1
break_loop1
ass_over
	LDA	num_flags
	BEQ	fflags
	LDA	#' '
	STA	ass_cli,Y
	LDX	#&FF
ass_loop2
	INX
	INY
	LDA	flags,X
	STA	ass_cli,Y
	CPX	num_flags
	BNE	ass_loop2
fflags
	LDA	#&0D
	STA	ass_cli,Y
	LDX	temp_stack_ptr
	TSX
	LDA	#' '
	JSR	&FFEE
	LDX	#&00
ass_cli_loop
	LDA	ass_cli,X
	JSR	&FFEE
	INX
	CMP	#&0D
	BNE	ass_cli_loop
	JSR	&FFE7
	JSR	&FFE7
	LDX	#>ass_cli
	LDY	#<ass_cli
	JMP	&FFF7



pc_file_write
	PLA
	STA	numlo
	PLA
	STA	numhi
	LDY	#1
fprint1
	TYA
	PHA
	LDA	(numlo),Y
	BEQ	fprint2
	JSR	write_byte
	PLA
	TAY
	INY
	BNE	fprint1
fprint2
	PLA
	TYA
	CLC
	ADC	numlo
	TAX
	LDA	numhi
	ADC	#0
	PHA
	TXA
	PHA
	RTS






write_byte
	LDY	file_handle
	JMP	&FFD4


strcmp
	LDY	#&00
	LDA	(temp_src_ptr),Y
	CMP	(line_ptr),Y
	BNE	strcmp_exit
	INY
	LDA	(temp_src_ptr),Y
	CMP	(line_ptr),Y
strcmp_exit
	BNE	strcmp2
	RTS

strcmp2
	LDY	#&00
	LDA	(temp_src_ptr),Y
	STA	line_num
	LDA	(line_ptr),Y
	STA	temp_line_ptr
	INY
	LDA	(temp_src_ptr),Y
	STA	line_num+1
	LDA	(line_ptr),Y
	STA	temp_line_ptr+1

	LDY	#&00
	LDA	(temp_line_ptr),Y
	CMP	#tab
	BNE	strcmp2_exit
strcmploop
	LDA	(temp_line_ptr),Y
	CMP	(line_num),Y
	BNE	strcmp2_exit
	INY
	CMP	#&0D
	BEQ	strcmp2_exit
	BNE	strcmploop
strcmp2_exit
	RTS


read_line
	LDA	line_ptr
	STA	temp_line_ptr
	LDA	line_ptr+1
	STA	temp_line_ptr+1
	LDY	#&00
search_newline
	LDA	(temp_line_ptr),Y
	CMP	#&0D
	BEQ	got_next
	INY
	BNE	search_newline
	INC	temp_line_ptr+1
	JMP	search_newline
got_next
	INY
	TYA
	CLC
	ADC	temp_line_ptr
	STA	temp_line_ptr
	LDA	temp_line_ptr+1
	ADC	#&00
	STA	temp_line_ptr+1
	LDY	#&00
	LDA	(temp_line_ptr),Y
	CMP	#';'
	BEQ	search_newline
	CMP	#&0D
	BEQ	search_newline

	LDA	temp_line_ptr
	CMP	eof
	BNE	not_eof
	LDA	temp_line_ptr+1
	CMP	eof+1
	BNE	not_eof
	LDA	#&FF
	RTS
not_eof
	LDA	temp_line_ptr
	STA	line_ptr
	LDA	temp_line_ptr+1
	STA	line_ptr+1
	LDA	#&00
	RTS


search_source
	LDA	line_ptr
	STA	temp_src_ptr
	PHA
	LDA	line_ptr+1
	STA	temp_src_ptr+1
	PHA
	LDA	start_ptr
	STA	line_ptr
	LDA	start_ptr+1
	STA	line_ptr+1

ss_loop0
	JSR	read_line
	BNE	got_eof
	LDY	#&FF
ss_loop1
	INY
	LDA	(line_ptr),Y
	CMP	#&0D
	BNE	ss_loop1
	DEY
	LDA	(line_ptr),Y
	CMP	#'('
	BEQ	exit_ss
	JMP	ss_loop0

ss_return
	INY
ss_loop2
	LDA	(line_ptr),Y
	CMP	#')'
	BEQ	got_close
	INY
	BNE	ss_loop2
	INC	line_ptr+1
	JMP	ss_loop2
got_close
	TYA
	CLC
	ADC	line_ptr
	STA	line_ptr
	LDA	line_ptr+1
	ADC	#&00
	STA	line_ptr+1
	JMP	ss_loop0
got_eof
	PLA
	STA	line_ptr+1
	PLA
	STA	line_ptr
	LDA	#&FF
	RTS


exit_ss
	LDY	#&00
ss_loop3
	LDA	(line_ptr),Y
	INY
	CMP	(temp_src_ptr),Y
	BEQ	ss_loop3
	CMP	#' '
	BNE	ss_return
	LDA	(temp_src_ptr),Y
	CMP	#&0D
	BNE	ss_return
	LDA	line_ptr
	STA	src_ptr
	LDA	line_ptr+1
	STA	src_ptr+1
	PLA
	STA	line_ptr+1
	PLA
	STA	line_ptr
	LDA	#&00
	RTS


make_error
	LDY	#&00
	STY	line_num
	STY	line_num+1
merr_loop0
	LDA	(start_ptr),Y
	CMP	#&0D
	BEQ	count_line
	INY
	BNE	merr_loop0
	INC	start_ptr
	JMP	merr_loop0
count_line
	SED
	LDA	line_num
	CLC
	ADC	#&01
	STA	line_num
	LDA	line_num+1
	ADC	#&00
	STA	line_num+1
	CLD
	INY
	TYA
	CLC
	ADC	start_ptr
	STA	start_ptr
	LDA	start_ptr+1
	ADC	#&00
	STA	start_ptr+1
	LDY	#&00
	LDA	start_ptr
	CMP	line_ptr
	BNE	merr_loop0
	LDA	start_ptr+1
	CMP	line_ptr+1
	BNE	merr_loop0
	JSR	pc_print
	DB	&0D
	ASC	"****** Err :"
	DB	&0D
	ASC	" Makefile error at line "
	DB	&00
	LDA	line_num
	PHA
	LDA	line_num+1
	JSR	wdigit
	PLA
	JSR	wdigit
	JSR	&FFE7
	JSR	&FFE7
	JMP	fatal


syntax_error
	JSR	pc_print
	DB	&0D
	ASC	"****** Err :"
	DB	&0D
	STR	" Make command line syntax error"
	DB	&0D
	DB	0
	JMP	fatal


load_makefile
	LDA	#&05
	LDX	#>makeblock
	LDY	#<makeblock
	JSR	&FFDD
	SEC
	LDA	#>begin
	SBC	file_len
	STA	load_addr
	STA	start_ptr
	LDA	#<begin
	SBC	file_len+1
	STA	load_addr+1
	STA	start_ptr+1
	CLC
	LDA	#&00
	STA	makeblock+6
	LDA	#&FF
	JSR	&FFDD
	SEC
	LDA	start_ptr
	SBC	#&01
	STA	start_ptr
	LDA	start_ptr+1
	SBC	#&00
	STA	start_ptr+1
	LDA	start_ptr
	SBC	#&02
	STA	list_ptr
	LDA	start_ptr+1
	SBC	#&00
	STA	list_ptr+1
	LDY	#&02
	LDA	#&0D
	STA	(list_ptr),Y
	RTS


set_arg
	LDY	#&00
	LDA	(line_ptr),Y
	CMP	#'A'
	BEQ	match_aflags
	CMP	#'B'
	BEQ	match_binary
	CMP	#'O'
	BEQ	match_org
	CMP	#'S'
	BEQ	match_sflags
	CMP	#'T'
	BEQ	match_text
	CMP	#'E'
	BEQ	match_exec

	JMP	make_error

msflags
	ASC	"SFLAGS"
	DB	tab
maflags
	ASC	"AFLAGS"
	DB	tab
mbinary
	ASC	"BINARY"
	DB	tab
morg
	ASC	"ORG"
	DB	tab
mtxt
	ASC	"TEXT"
	DB	tab
mexec
	ASC	"EXEC"
	DB	tab

match_sflags
msf_loop
	INY
	CMP	#tab
	BEQ	set_flags
	LDA	(line_ptr),Y
	CMP	msflags,Y
	BEQ	msf_loop
	JMP	make_error

match_aflags
maf_loop
	INY
	CMP	#tab
	BEQ	add_flags
	LDA	(line_ptr),Y
	CMP	maflags,Y
	BEQ	maf_loop
	JMP	make_error

match_binary
mb_loop
	INY
	CMP	#tab
	BEQ	set_binary
	LDA	(line_ptr),Y
	CMP	mbinary,Y
	BEQ	mb_loop
	JMP	make_error

match_org
mo_loop
	INY
	CMP	#tab
	BEQ	set_org
	LDA	(line_ptr),Y
	CMP	morg,Y
	BEQ	mo_loop
	JMP	make_error

match_text
mt_loop
	INY
	CMP	#tab
	BEQ	jmp_set_text
	LDA	(line_ptr),Y
	CMP	mtxt,Y
	BEQ	mt_loop
	JMP	make_error
jmp_set_text
	JMP	set_text

match_exec
meloop
	INY
	CMP	#tab
	BEQ	jmp_set_exec
	LDA	(line_ptr),Y
	CMP	mexec,Y
	BEQ	meloop
	JMP	make_error
jmp_set_exec
	JMP	set_exec

set_flags
	LDX	#&00
sfloop
	LDA	(line_ptr),Y
	CMP	#&0D
	BEQ	exit_sf
	STA	flags,X
	INY
	INX
	JMP	sfloop
exit_sf
	STX	num_flags
	RTS


add_flags
	LDX	num_flags
afloop
	LDA	(line_ptr),Y
	CMP	#&0D
	BEQ	exit_af
	STA	flags,X
	INY
	INX
	JMP	afloop
exit_af
	STX	num_flags
	RTS

set_binary
	LDX	#&00
eloop
	LDA	(line_ptr),Y
	STA	exc,X
	CMP	#&0D
	BEQ	exit_e
	INY
	INX
	JMP	eloop
exit_e
	RTS

set_org
	LDA	#&00
	STA	org
	STA	org+1
oloop
	LDA	(line_ptr),Y
	CMP	#&0D
	BEQ	exit_o
	CMP	#'&'
	BEQ	o_over
	JSR	convert
	ASL	A
	ASL	A
	ASL	A
	ASL	A
	LDX	#&03
oloop1
	ASL	A
	ROL	org
	ROL	org+1
	DEX
	BPL	oloop1
o_over
	INY
	JMP	oloop
exit_o
	RTS

set_text
	CLC
	TYA
	ADC	line_ptr
	LDY	#&00
	STA	(list_ptr),Y
	LDA	line_ptr+1
	ADC	#&00
	INY
	STA	(list_ptr),Y
	LDA	list_ptr
	SEC
	SBC	#&02
	STA	list_ptr
	LDA	list_ptr+1
	SBC	#&00
	STA	list_ptr+1
	CLC
	RTS

set_exec
	LDA	#&FF
	STA	exec_flag
	LDX	#&00
seloop0
	LDA	(line_ptr),Y
	STA	exec_str,X
	CMP	#&0D
	BEQ	exit_se
	INY
	INX
	JMP	seloop0
exit_se
	LDA	#&00
seloop1
	INX
	STA	exec_str,X
	CPX	#&1F
	BNE	seloop1
	RTS

chain
	JSR	pc_file_write
	DB	&0D
	DB	&0D
	ASC	"; Chained files :"
	DB	&0D
	DB	&0D
	DB	&00
	LDA	#&00
	STA	file_count
x_include_loop0

	LDY	#&00
	LDA	(start_ptr),Y
	STA	line_ptr
	INY
	LDA	(start_ptr),Y
	STA	line_ptr+1
	LDY	#&00
	LDA	(line_ptr),Y
	CMP	#tab
	BNE	x_include_loop9

	JSR	pc_file_write
	ASC	"FILE"
	DB	&00
	LDA	file_count
	JSR	hex_asc
	CMP	#'0'
	BEQ	ripple_blank
	TAX
	TYA
	PHA
	TXA
	JSR	write_byte
	PLA
	TAY
ripple_blank
	TYA
	JSR	write_byte
	JSR	pc_file_write
	DB	&DD
	ASC	"ASET"
	DB	&DD
	DB	&27
	DB	&00
	LDA	file_count
	SED
	CLC
	ADC	#&01
	STA	file_count
	CLD
	LDY	#&01
x_include_loop9
	TYA
	PHA
	LDA	(line_ptr),Y
	CMP	#&0D
	BEQ	x_include_out
	JSR	write_byte
	PLA
	TAY
	INY
	JMP	x_include_loop9
x_include_out
	LDY	#&00
	LDA	(line_ptr),Y
	CMP	#tab
	BNE	not_tab
	LDA	#&27
	JSR	write_byte
not_tab
	LDA	#&0D
	JSR	write_byte
	PLA
	SEC
	LDA	start_ptr
	SBC	#&02
	STA	start_ptr
	LDA	start_ptr+1
	SBC	#&00
	STA	start_ptr+1
	LDA	start_ptr
	CMP	src_ptr
	BNE	x_include_loop0
	LDA	start_ptr+1
	CMP	src_ptr+1
	BEQ	no_jmp_inclp0
	JMP	x_include_loop0
no_jmp_inclp0
	JSR	pc_file_write
	DB	&0D
	DB	&0D
	ASC	"ACC"
	DB	&DD
	ASC	"ASET"
	DB	&DD
	ASC	"0"
	DB	&0D
	DB	&DD
	ASC	"CHN"
	DB	&DD
	DB	&40
	ASC	"FILE0"
	DB	&0D
	DB	&00

	LDA	#&00
	LDY	file_handle
	JSR	&FFCE
	RTS

include
	JSR	pc_file_write
	DB	&0D
	DB	&0D
	ASC	"; Include files :"
	DB	&0D
	DB	&0D
	DB	&00
include_loop0
	LDY	#&00
	LDA	(start_ptr),Y
	STA	line_ptr
	INY
	LDA	(start_ptr),Y
	STA	line_ptr+1
	LDY	#&00
	LDA	(line_ptr),Y
	CMP	#tab
	BNE	include_loop9
	JSR	pc_file_write
	DB	tab
	ASC	"INCLUDE"
	DB	tab
	DB	&00
	LDY	#&01
include_loop9
	TYA
	PHA
	LDA	(line_ptr),Y
	JSR	write_byte
	CMP	#&0D
	BEQ	include_out
	PLA
	TAY
	INY
	JMP	include_loop9
include_out
	PLA
	SEC
	LDA	start_ptr
	SBC	#&02
	STA	start_ptr
	LDA	start_ptr+1
	SBC	#&00
	STA	start_ptr+1
	LDA	start_ptr
	CMP	src_ptr
	BNE	include_loop0
	LDA	start_ptr+1
	CMP	src_ptr+1
	BNE	include_loop0
	LDA	#&00
	LDY	file_handle
	JSR	&FFCE
	RTS


	CHN	S.MAKELIB