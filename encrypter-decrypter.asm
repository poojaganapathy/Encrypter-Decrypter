	.data
menu0: 	.asciiz	"Please select an option from the menu below:\n"
menu1:	.asciiz	"1: Encrypt the file.\n"
menu2:	.asciiz	"2: Decrypt the file.\n"
menu3:	.asciiz	"3: Exit.\n"
error1:	.asciiz	"Sorry, your input is invalid. Please enter '1', '2', or '3' (without the quotes) only.\n"
error2:	.asciiz	"Sorry, you need to include the extension of the file. Returning to menu.\n"
error3:	.asciiz	"Sorry, only .txt files can be encrypted by this program. Returning to menu.\n"
error4:	.asciiz	"Sorry, only .enc files can be decrypted by this program. Returning to menu.\n"
error5:	.asciiz	"Sorry, this file could not be opened. It is possible that the file does not exist. Returning to menu.\n"
error6:	.asciiz	"Sorry, the key needs to contain at least one character (the newline character does not count). Returning to menu.\n"
prompt1:	.asciiz	"Please enter the name of the file to be encrypted. (Filenames can have a maximum of 1000 characters.)\n"
prompt2:	.asciiz	"Please enter the name of the file to be decrypted. (Filenames can have a maximum of 1000 characters.)\n"
prompt3:	.asciiz	"Please enter the encryption key. (The key can have a maximum of 60 characters.)\n"
prompt4:	.asciiz	"Please enter the decryption key. (The key can have a maximum of 60 characters.)\n"
filename:	.space	1002	# will store the user-inputted name of the file to be encrypted/decrypted and will later store the name of the file to be written to
key:	.space	62	# will store the user-inputted encryption/decryption key
buffer:	.space	1024	# will store a block of text read from the input file
choice:	.word	0	# will store the user's selection from the menu (1, 2, or 3)
per_pos:	.word	0	# will store the position of the period in the filename inputted by the user
inpt_dsc:	.word	0	# will store the file descriptor for the input file
length:	.word	0	# will store the length of the key
otpt_dsc:	.word	0	# will store the file descriptor for the output file
numChars:	.word	0	# will store the number of characters read in from the input file in a particular block
buf_pos:	.word	0	# will store the current position in the block of text that was read in (i.e. the buffer)
key_pos:	.word	0	# will store the current position in the key

	.text
	
# displays menu and prompts user to make a selection, then branches accordingly
menu:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, menu0	# loads the address of the string that prompts the user to make a selection from the menu
	syscall			# issues syscall instruction
	
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, menu1	# loads the address of the string containing the first option on the menu (encrypting the file)
	syscall			# issues syscall instruction
	
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, menu2	# loads the address of the string containing the second option on the menu (decrypting the file)
	syscall			# issues syscall instruction
	
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, menu3	# loads the address of the string containing the third option on the menu (exiting the program)
	syscall			# issues syscall instruction
	
	li	$v0, 5		# loads the service number for reading in an integer
	syscall			# issues syscall instruction (and thus the user's choice is read in and stored in $v0)
	
	sw	$v0, choice	# the user's choice is copied from $v0 to choice
	
	beq	$v0, 1, getFilename1	# if the user's choice was 1 (i.e., encryption), jump to function getFilename1
	beq	$v0, 2, getFilename2	# if the user's choice was 2 (i.e., decryption), jump to function getFilename2
	beq	$v0, 3, exit		# if the user's choice was 3 (i.e., exiting the program), jump to the exit function
	
	# if we get this far in the function, it means the user entered something other than 1, 2, or 3, which is invalid
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, error1	# loads the address of the string containing an error message explaining the issue
	syscall			# issues syscall instruction
	
	j	menu		# jumps to the beginning of the function to display the menu again

# displays prompt asking user to input the name of the file to be encrypted	
getFilename1:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, prompt1	# loads the address of the string containing the prompt
	syscall			# issues syscall instruction
	
	j	getFilename3	# jump to part 3 of the function

# displays prompt asking user to input the name of the file to be decrypted
getFilename2:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, prompt2	# loads the address of the string containing the prompt
	syscall			# issues syscall instruction

# reads in the name of the file inputted by the user
getFilename3:
	li	$v0, 8		# loads the service number for reading in a string
	la	$a0, filename	# indicates that the input will be stored in 'filename'
	li	$a1, 1002		# allows 1001 characters to be read in (including the newline character) and includes space for a null terminator
	syscall			# issues syscall instruction
	
	li	$t0, 0		# resets the value of $t0 to 0 for use in the next function
	
# finds the location of the period ('.') in the filename
findPeriod:
	sw	$t0, per_pos	# stores the position in 'filename' of the character to be read (initially 0)
	la	$t1, filename	# loads the address of the first character in 'filename' into $t1
	add	$t1, $t1, $t0	# adds the position of the character to be checked to the address of filename in order to reach that character
	lb	$t2, ($t1)	# loads the character at that location into $t2
	beq	$t2, '.', checkExtension	# if that character is a period, jump to function checkExtension
	beq	$t2, 0x0a, FPError	# if the newline character is reached, it means there was no period in the name, so jump to function FPError
	addi	$t0, $t0, 1	# adds 1 to $t0 in order to move to the next character
	j	findPeriod	# jumps back to the beginning of the function to check the next character
	
# informs the user that they need to include the extension when entering the filename (there was no period in the name, so there was no extension)
FPError:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, error2	# loads the address of the string containing an error message explaining the issue
	syscall			# issues syscall instruction
	
	li	$t0, 0		# resets the value of $t0 to 0 for use in the function clearFilename
	j	clearFilename	# jumps to function clearFilename
	
# prepares for checking if the file is of the correct type
checkExtension:
	lw	$t0, choice 	# loads the user's choice (1 for encryption, 2 for decryption) into $t0
	la	$t1, filename	# loads the address of 'filename' into $t1
	lw	$t2, per_pos	# loads the position of the period into $t2
	add	$t1, $t1, $t2	# adds $t2 to $t1 in order to reach the location of the period in the filename
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character (i.e. the first letter of the extension)
	lb	$t3, ($t1)	# loads that character into $t3
	beq	$t0, 2, checkExtension2	# if the user chose decryption, jump to function checkExtension2

# checks if the extension of the input file is ".txt" if the user chose encryption
# register $t1 contains the location of the first character after the period in the filename and $t3 contains the character
checkExtension1:
	bne	$t3, 't', CEError1 # checks if the first character after the period is 't'; if not, jump to function CEError1
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	lb	$t3, ($t1)	# loads that character into $t3
	bne	$t3, 'x', CEError1	# checks if the character is 'x'; if not, jump to function CEError1
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	lb	$t3, ($t1)	# loads that character into $t3
	bne	$t3, 't', CEError1	# checks if the character is 't'; if not, jump to function CEError1
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	lb	$t3, ($t1)	# loads that character into $t3
	bne	$t3, 0x0a, CEError1 # checks if the character is the newline character; if not, jump to function CEError1 (since it means there are more characters after the last 't')

	li	$t0, 0		# resets the value of $t0 to 0 for use in the function fixFilename
	j	fixFilename	# jumps to function fixFilename

# checks if the extension of the input file is ".enc" if the user chose decryption
# register $t1 contains the location of the first character after the period in the filename and $t3 contains the character
checkExtension2:	
	bne	$t3, 'e', CEError2	# checks if the first character after the period is 'e'; if not, jump to function CEError2
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	lb	$t3, ($t1)	# loads that character into $t3
	bne	$t3, 'n', CEError2	# checks if the character is 'n'; if not, jump to function CEError2
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	lb	$t3, ($t1)	# loads that character into $t3
	bne	$t3, 'c', CEError2 # checks if the character is 'c'; if not, jump to function CEError2
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	lb	$t3, ($t1)	# loads that character into $t3
	bne	$t3, 0x0a, CEError2	 # checks if the character is the newline character; if not, jump to function CEError2 (since it means there are more characters after the last 'c')
	
	li	$t0, 0		# resets the value of $t0 to 0 for use in the function fixfilename
	j	fixFilename	# jumps to function fixFilename

# informs the user that the input file needs to be of type .txt for encryption	
CEError1:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, error3	# loads the address of the string containing an error message explaining the issue
	syscall			# issues syscall instruction
	
	li	$t0, 0		# resets the value of $t0 to 0 for use in the function clearFilename
	j	clearFilename	# jumps to function clearFilename

# informs the user that the input file needs to be of type .enc for decryption
CEError2:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, error4	# loads the address of the string containing an error message explaining the issue
	syscall			# issues syscall instruction
	
	li	$t0, 0		# resets the value of $t0 to 0 for use in the function clearFilename
	j	clearFilename	# jumps to function clearFilename

# replaces the newline character in the filename with a null terminator
# register $t0 initially contains 0
fixFilename:
	la	$t1, filename	# loads the address of 'filename' into $t1
	add	$t1, $t1, $t0	# adds $t0 to $t1 to reach the location of the character to be checked ($t0 contains the position of the character in 'filename')
	lb	$t2, ($t1)	# loads that character into $t2
	addi	$t0, $t0, 1	# adds 1 to $t0 to move to the next character
	bne	$t2, 0x0a, fixFilename # if the current character (not the one at position $t0) is not the newline character, loop through function fixFilename again
	
	li	$t0, '\0'		# loads the null terminator into $t0
	sb	$t0, ($t1)	# stores the null termninator in the location where the newline character is
	
# attempts to open the input file
openInputFile:
	li	$v0, 13		# loads the service number for opening a file
	la	$a0, filename	# loads the address of the filename into $a0
	li	$a1, 0		# sets the flag to 0 (i.e., the file should be opened as a read-only file)
	li	$a2, 0		# the mode is ignored
	syscall			# issues syscall instruction; the file descriptor will be stored in $v0
	
	sw	$v0, inpt_dsc	# copies the file descriptor from $v0 to variable 'inpt_dsc'
	
	bltz	$v0, OIFError	# if the file descriptor is negative, there was an error in opening the file, so jump to function OIFError
	
	lw	$t0, choice	# loads the user's choice (1 for encryption, 2 for decryption) into $t0
	beq	$t0, 1, getKey1	# if the user chose encryption, jump to function getKey1
	j	getKey2		# if not (i.e., if they chose decryption), jump to function getKey2

# informs the user that the file could not be opened
OIFError:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, error5	# loads the address of the string containing an error message explaining the issue
	syscall			# issues syscall instruction
	
	li	$t0, 0		# resets the value of $t0 to 0 for use in the function clearFilename
	j	clearFilename	# jumps to function clearFilename
	
# prompts user for encryption key
getKey1:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, prompt3	# loads the address of the string containing a prompt for the user to enter the encryption key
	syscall			# issues syscall instruction
	
	j	getKey3		# jumps to part 3 of the function

# prompts user for decryption key
getKey2:
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, prompt4	# loads the address of the string containing a prompt for the user to enter the decryption key
	syscall			# issues syscall instruction

# stores the user's input (i.e., the key)
getKey3:
	li	$v0, 8		# loads the service number for reading in a string
	la	$a0, key		# indicates that the input will be stored in 'key'
	li	$a1, 62		# allows 61 characters to be read in (including the newline character) and includes space for a null terminator
	syscall			# issues syscall instruction
	
	li	$t0, 0		# resets the value of $t0 to 0 for use in the next function

# finds the number of characters (excluding the newline character) in the key
# register $t0 initially contains 0
findKeyLength:
	la	$t1, key		# loads the address of 'key' into $t1
	add	$t1, $t1, $t0	# adds $t0 to $t1 to reach the location of the character to be checked
	lb	$t2, ($t1)	# copies the character into $t2
	beq	$t2, 0x0a, findKeyLength2	# if the character is the newline character, jump to function findKeyLength2 (since we have reached the end of the key)
	addi	$t0, $t0, 1	# adds 1 to $t0 to move to the next character
	sw	$t0, length	# stores $t0 (i.e., the number of character checked so far) into variable 'length'
	j	findKeyLength	# jumps back to the beginning of the function

# checks if the key has at least one character aside from the newline character	
findKeyLength2:
	lw	$t0, length	# loads the length of the key (excluding the newline character) into $t0
	blez 	$t0, FKLError	# if the length is 0, jump to function FKLError
	
	lw	$t0, per_pos	# load the position of the period in the filename into $t0
	addi	$t0, $t0, 1	# add 1 to $t0 to move to the character after the period in the filename
	la	$t1, filename	# loads the address of 'filename' into $t1
	add	$t1, $t1, $t0	# $adds $t0 to $t1 to reach the location of that character
	
	lw	$t2, choice	# loads the user's choice into $t2
	beq	$t2, 1, nameOutputFile1	# if the user chose encryption, jump to function nameOutputFile1
	
	j 	nameOutputFile2	# if the user chose decryption, jump to function nameOutputFile2

# informs the user that the key needs to contain at least 1 character aside from the newline character
FKLError:
	li	$v0, 16		# loads the service number for closing a file
	lw	$a0, inpt_dsc	# loads the file descriptor of the input file into $a0
	syscall			# issues syscall instruction (i.e., the input file is closed)
		
	li	$v0, 4		# loads the service number for printing a string
	la	$a0, error6	# loads the address of the string containing an error message explaining the issue
	syscall			# issues syscall instruction
	
	li	$t0, 0		# resets the value of register $t0 to 0 for use in the function clearKey
	j	clearKey		# jumps to function clearKey
	
# modifies the original filename to the name of the output file (in the case of encryption)
# register $t1 contains the location of the first letter of the extension in the filename
nameOutputFile1:
	li	$t2, 'e'		# loads the character 'e' (actually the ascii value) into $t2
	sb	$t2, ($t1)	# stores this value where the first 't' was in the original extension
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	li	$t2, 'n'		# loads the character 'n' into $t2
	sb	$t2, ($t1)	# stores this value where 'x' was in the original extension
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	li	$t2, 'c'		# loads the character 'c' into $t2
	sb	$t2, ($t1)	# stores this value where the second 't' was in the original extension
	
	j	openOutputFile	# jump to function openOutputFile
	
# modifies the original filename to the name of the output file (in the case of decryption)
# register $t1 contains the location of the first letter of the extension in the filename
nameOutputFile2:
	li	$t2, 't'		# loads the character 't' (actually the ascii value) into $t2
	sb	$t2, ($t1)	# stores this value where 'e' was in the original extension
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	li	$t2, 'x'		# loads the character 'x' into $t2
	sb	$t2, ($t1)	# stores this value where 'n' was in the original extension
	
	addi	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	li	$t2, 't'		# loads the character 't' into $t2
	sb	$t2, ($t1)	# stores this value where 'c' was in the original extension
	
# creates and opens the output file
openOutputFile:
	li	$v0, 13		# loads the service number for opening a file
	la	$a0, filename	# loads the address of 'filename' into $a0
	li	$a1, 1		# sets the flag to 1 for opening the file as a write-only file
	li	$a2, 0		# mode is ignored
	syscall			# issues syscall instruction; the file descriptor will be stored in $v0
	
	sw	$v0, otpt_dsc	# copies the file descriptor from $v0 to variable 'otpt_dsc'
	
# reads the content of the input file one block at a time, where each block can contain a maximum of 1024 characters
readInputFile:
	la	$t0, buffer	# loads the address of the buffer where the block will be stored
	lw	$t1, buf_pos	# loads the current position in the buffer into $t1
	
	li	$v0, 14		# loads the service number for reading a file
	lw	$a0, inpt_dsc	# loads the file descriptor of the input file into $a0
	add	$a1, $t0, $t1	# adds the buffer position to $t0 to reach the location where the next character should be stored
	li	$a2, 1024		# indicates that up to 1024 characters can be read in
	syscall			# issues syscall instruction; $v0 returns the number of characters read in
	
	beqz	$v0, doneReading	# if $v0 contains 0, it means the end of the file has been reached. jump to function doneReading
	
	sw	$v0, numChars	# store the value in $v0 (i.e., the number of characters read in) into numChars
	
	lw	$s0, choice	# load the user's choice (encryption or decryption) into $s0
	
# load certain values into registers in order to prepare for encryption or decryption
loadValues:
	la	$t0, buffer	# load the address of the buffer into $t0
	la	$t1, key		# load the address of the key into $t1
	lw	$t2, buf_pos	# load into $t2 the position in the buffer where the next character to be converted is
	lw	$t3, key_pos	# load into $t3 the position of the next character in the key to be used
	
	add	$t0, $t0, $t2	# add $t2 to $t0 to reach the correct location in the buffer
	add	$t1, $t1, $t3	# add $t3 to $t1 to reach the correct location in the key
	
	lb	$t5, ($t0)	# stores int $t5 the character to be converted
	lb	$t6, ($t1)	# stores in $t6 the character from the key to be used for conversion
	
	beq	$s0, 1, encryption	# if the user chose encryption, jump to function encryption
	j	decryption	# if the user chose decryption, jump to function decryption

# encrypts the current character	
encryption:
	addu	$t5, $t5, $t6	# adds the character from the key to the character in the buffer using unsigned addition
	sb	$t5, ($t0)	# stores the result in the location where the original character was
	
	j	updater		# jump to function updater

# decrypts the current character	
decryption:
	subu	$t5, $t5, $t6	# subtracts the character in the key from the character in the buffer using unsigned subtraction
	sb	$t5, ($t0)	# stores the result in the location where the original character was

# updates the values of the variables	
updater:
	lw	$t0, buf_pos	# loads the current buffer position into $t0
	add	$t0, $t0, 1	# adds 1 to $t0 to move to the next character
	sw	$t0, buf_pos	# stores the new position in 'buf_pos'
	
	lw	$t1, key_pos	# loads the current key position into $t1
	add	$t1, $t1, 1	# adds 1 to $t1 to move to the next character
	sw	$t1, key_pos	# stores the new position in 'key_pos'
	
	lw	$t2, numChars	# loads the number of characters in the block into $t2
	lw	$t3, length	# loads the number of characters in the key into $t3
	
	beq	$t0, $t2, writeToOutputFile	# if $t0 == $t2, it means we have reached the end of the block, so jump to function weriteToOutputFile
	bne	$t1, $t3, loadValues	# if $t1 != $t3, it means we haven't reached the end of the key yet, so jump back to the beginning of loadValues
	
	sw	$zero, key_pos	# if we have reached the end of the key, change the position back to 0 to go back to the beginning of the key
	j	loadValues	# jump to loadValues to encrypt/decrypt the next character
	
# writes the encrypted/decrypted version of the block to the output file
writeToOutputFile:
	li	$v0, 15		# loads the service number for writing to a file
	lw	$a0, otpt_dsc	# loads the value of the file descriptor of the output file
	la	$a1, buffer	# loads the address of the buffer
	lw	$a2, numChars	# loads the number of characters to be written
	syscall			# issues syscall instruction
	
	sw	$zero, buf_pos	# resets the value of the buffer position to zero
	
	li	$t0, 0		# resets the value of $t0 to 0 for use in the next function
	
# clears the buffer by replacing every character with 0
# register $t0 contains 0 and $a2 contains the number of characters in the buffer
clearBuffer:
	la	$t1, buffer	# loads the address of the buffer into $t1
	add	$t1, $t1, $t0	# adds $t0 (the current position in the buffer) to $t1
	sb	$zero, ($t1)	# replaces the character at that position withh 0
	addi	$t0, $t0, 1	# adds 1 to $t1 to move to the next character
	bne	$t0, $a2, clearBuffer	# if $t0 != $a2, we haven't reached the end of the buffer yet, so loop back to the beginning of the function
	
	j	readInputFile	# if we have reached the end of the buffer, jump to function readInputFile
	
# closes the files one we are done encrypting/decrypting the whole file
doneReading:
	li	$v0, 16		# loads the service number for closing a file
	lw	$a0, inpt_dsc	# loads the file descriptor of the input file
	syscall			# issues syscall instruction
	
	li	$v0, 16		# loads the service number for closing a file
	lw	$a0, otpt_dsc	# loads the file descriptor of the output file
	syscall			# issues syscall instruction
	
	li	$t0, 0		# resets value of $t0 to 0 for use in the next function

# clears the key by replacing every character with 0	
# register $t0 contains 0
clearKey:
	la	$t1, key		# loads the address of the key
	add	$t1, $t1, $t0	# adds $t0 to $t1 to reach the current position in the key
	sb	$zero, ($t1)	# replaces the character at that position with 0
	addi	$t0, $t0, 1	# adds 1 to $t0 to move to the next character
	lw	$t2, length	# loads the length of the key into $t2
	addi	$t2, $t2, 1	# adds 1 to $t2 (since the length does not include the newline character)
	bne	$t0, $t2, clearKey # if $t0 != $t2, we haven't reached the end of the key yet, so loop back to the beginning of clearKey

	li	$t0, 0		# resets value of $t0 to 0 for use in the next function
	
# clears 'filename' by replacing every character with 0
# register $t0 contains 0
clearFilename:
	la	$t1, filename	# loads the address of 'filename'
	add	$t1, $t1, $t0	# adds $t0 to $t1 to reach the current position in the filename
	sb	$zero, ($t1)	# replaces the character at that position with 0
	addi	$t0, $t0, 1	# adds 1 to $t0 to move to the next character
	add	$t2, $t1, $t0	# adds $t0 to $t1 and stores in $t2 to reach the position of the next character in the filename
	lb	$t3, ($t2)	# loads that character into $t3
	bne	$t3, $zero, clearFilename	# if that character does not equal 0, we are not done clearing the filename, so loop back to the beginning of clearFilename
	
	j	menu		# jump to the menu

# exits the program	
exit:
	li	$v0, 10		# loads the service number for terminating the program
	syscall			# issues syscall instruction


	
	
