# odyshbayeh-1201462
# abdelrahman-abed _1193191

.data
newLine:     .asciiz "\n"
menu:  .asciiz "please select an option:\n1. add a new medical test\n2. search for a test by patient ID\n3. retrieve abnormal tests\n4. update an existing test result\n5.delete a test\n6. calculate average test value\n7. exit\n> "
scndmenu: .asciiz "\nwhat would you like to retrieve?\n1. all patient tests\n2. all abnormal patient tests\n3. all patient tests within a specific period\n> "
wronginput: .asciiz "invalid input detected..\n"
wrong_id:     .asciiz "invalid id entered. please ensure the id has 7 digits.\n"
exitmessage:  .asciiz "exiting the program..\n"
patientid: .asciiz "please enter the Patient ID 7 digits: "
testname: .asciiz "please enter the test name: "
testdate: .asciiz "please enter the test date (YYYY-MM): "
testresult: .asciiz "please enter the test result: "
addedseccefully:   .asciiz "the test was added .\n"
searchid: .asciiz "please enter the Patient id to search for: "
updateresult: .asciiz "please enter the new test result: "
deleteconfirm: .asciiz "the test was deleted successfully.\n"
invaliddatefound:        .asciiz "\nplease use the format (YYYY-MM)\n"
patientnotfoundmsg:    .asciiz "\nthis patient does not exist.\n\n"
avnotfoundmsg:         .asciiz "\nthis test does not have a value.\n"
selectrecord:       .asciiz "\nselect a record from the following list: \n"
date1msg:        .asciiz "\nenter the start date (YYYY-MM): "
date2msg:        .asciiz "\nenter the end date (YYYY-MM): "
temp:       .space 128
outofrangemsg:    .asciiz "\nthe number you entered is not within the range\n"
floatFormat: .asciiz "%f\n"
name:        .space 64
lower:       .float 0.0
upper:       .float 0.0
floatBuffer: .space 4
float_val: .float 3.14
patientId:   .space 8
test_Name:     .space 16
test_Date:     .space 16
test_Result:      .space 8
date1:       .space 9
date2:       .space 9
testNames:   .space 2048
lowerLimits: .space 128
upperLimits: .space 128

recordsFile:  .asciiz "medical.txt"
outputFile:   .asciiz "newrecords.txt"
patientIds:   .space 1024
patientTests: .space 2048
testDates:    .space 1024 
testResults:  .space 128

errorMessage: .asciiz "\nthe input file contains errors.\n"
dots:         .asciiz ":"
space:        .asciiz " "
distinctTests: .space 1024

comma:            .asciiz ","
buffer:           .space 256
tempFloat:        .space 8

inputBuffer:  .space 64
patientIdBuffer: .space 8
testNameBuffer: .space 32
testDateBuffer: .space 8
testResultBuffer: .space 16

maxTests:     .word 100
testRecordLength: .word 80

testRecords:  .space 8000

.text
.globl main


#****************************************************
main:

    # Open the file containing patient records for reading
    li $v0, 13
    la $a0, recordsFile
    li $a1, 0
    li $a2, 0
    syscall
    move $s0, $v0

    # Read from the patient records file into the buffer
    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 128
    syscall

    # Close the patient records file
    li $v0, 16
    move $a0, $s0
    syscall

    # Process and display the data from the buffer
    la $a0, buffer
    li $v0, 4
    syscall 

    # Trim the buffer again to prepare for parsing patient records
    la $a1, buffer
    jal trimString

    # Read and process patient records
    la $a1, buffer
    jal read_patients
    
    # Main menu interaction loop
    menu_loop:
        # Display the main menu
        li $v0, 4
        la $a0, menu
        syscall

        # Get user input
        li $v0, 8
        la $a0, inputBuffer
        li $a1, 3
        syscall

        # Process the input to navigate to appropriate function
        lb $t1, inputBuffer
        li $t2, '0'
        sub $t1, $t1, $t2 

        blt $t1, 1, invalidOption
        bgt $t1, 7, invalidOption

        li $t0, 1
        beq $t1, $t0, addTest
        li $t0, 2
        beq $t1, $t0, searchTest
        li $t0, 3
        beq $t1, $t0, retrieveUnnormalTests
        li $t0, 4
        beq $t1, $t0, updateTest
        li $t0, 5
        beq $t1, $t0, deleteTest
        li $t0, 6
        beq $t1, $t0, calculateAverage
        li $t0, 7
        beq $t1, $t0, exitProgram

    # Handle invalid menu option selections
    invalidOption:
        li $v0, 4
        la $a0, wronginput
        syscall
        j menu_loop
       
      
#****************************************************
exitProgram:
        li $v0, 4
        la $a0, exitmessage 
        syscall
        
        li $v0, 10
        syscall
#****************************************************
addTest:
    # Load addresses of the patient record arrays into the corresponding registers
    la $s4, patientIds
    la $s5, patientTests
    la $s6, testDates
    la $s7, testResults
    
    # Find the next empty slot in the patient records to add a new test
    loop_until:
        move $a0, $s4
        lb $t0, 0($a0)                 # Load the first byte of the current patient ID
        beq $t0, 0, is_ready_until     # If it's zero, we found an empty slot
        addiu $s4, $s4, 8              # Otherwise, increment to the next patient ID slot
        addiu $s5, $s5, 16             # Increment to the next test name slot
        addiu $s6, $s6, 8              # Increment to the next test date slot
        addiu $s7, $s7, 4              # Increment to the next test result slot
        j loop_until                   # Continue searching
    
    # We've found an empty slot
    is_ready_until:
        # Prompt the user to enter a patient ID
        la $a0, patientid
        li $v0, 4
        syscall
    
        # Read the patient ID from the user
        la $a0, patientId
        li $a1, 8
        li $v0, 8
        syscall
        
        # Validate the patient ID (must be numeric)
        la $a0, patientId
        xor $t0, $t0, $t0               # Clear $t0 to use it for checking each character
        
        check_id:
            lb $t0, 0($a0)              # Load byte from buffer
            beq $t0, 0, check_id_done   # If it's zero, we're done checking
            bgt $t0, '9', id_error      # If character is greater than '9', it's an error
            blt $t0, '0', id_error      # If character is less than '0', it's an error
            addiu $a0, $a0, 1           # Move to next character
            j check_id                  # Loop back to check next character
        
        id_error:
            # If there's an error in the patient ID, display error message and return to menu
            la $a0, wrong_id
            li $v0, 4
            syscall
            j menu_loop
        
        check_id_done:
        
        # Output a newline to separate input prompts
        la $a0, newLine
        li $v0, 4
        syscall
        
        # Prompt the user to enter the test name
        la $a0, testname
        li $v0, 4
        syscall
        
        # Read the test name from the user
        la $a0, test_Name
        li $a1, 16
        li $v0, 8
        syscall
        
        # Trim whitespace from the test name
        la $a0, test_Name
        la $a1, test_Name
        jal trimString
        
        # Prompt the user to enter the test date
        la $a0, testdate
        li $v0, 4
        syscall
          
        # Read the test date from the user
        la $a0, test_Date
        li $a1, 8
        li $v0, 8
        syscall
        
        # Check if the entered date is valid
        la $a0, test_Date
        jal check_date
        bgt $t1, 0, date_error         # If there's an error, jump to date_error
        
        # Output a newline to separate input prompts
        la $a0, newLine
        li $v0, 4
        syscall
        
        # Prompt the user to enter the test result
        la $a0, testresult
        syscall
        
        # Read the test result from the user
        la $a0, test_Result
        li $a1, 9
        li $v0, 8
        syscall
        
        # Trim whitespace and parse the test result as a float
        la $a0, test_Result
        la $a1, test_Result
        jal trimString
        la $a0, test_Result
        jal parseFloat
        
        # Store the test result in the appropriate memory location, ensuring alignment for floating point operations
        andi $s7, $s7, 0xFFFFFFFC
        s.s $f0, 0($s7)
        
        # Copy validated and formatted input into patient records
        move $a2, $s4
        la $a0, patientId
        jal copy_string
        
        move $a2, $s5
        la $a0, test_Name
        jal copy_string
        
        move $a2, $s6
        la $a0, test_Date
        jal copy_string
        jal write_to_file
        # Return to the main menu loop
        j menu_loop
        
    date_error:
        # Handle date input errors by displaying an error message and returning to the main menu
        la $a0, invaliddatefound
        li $v0, 4
        syscall
        
        # Return to the main menu loop
        j menu_loop

#****************************************************
searchTest:
    
    li $v0, 4
    la $a0, patientid
    syscall
    
    la $a0, patientId
    li $a1, 8
    li $v0, 8
    syscall
    
    la $a0, patientId
    jal find_patient
    
    la $a0, newLine
    li $v0, 4
    syscall
    
    beq $t4, 0, not_found_error
    
    la $a0, scndmenu
    syscall

    li $v0, 8
    la $a0, inputBuffer
    li $a1, 3
    syscall

    lb $t1, inputBuffer
    li $t2, '0'
    sub $t1, $t1, $t2
    
    
    li $t0, 1
    beq $t1, $t0, retrieve_all
    
    li $t0, 2
    beq $t1, $t0, retrieve_upnormals
    
    li $t0, 3
    beq $t1, $t0, retrieve_period
    
    j menu_loop
    
    retrieve_all:
        la $a0, newLine
        li $v0, 4
        syscall
        
        la $s0, patientIds
        la $s1, patientTests
        la $s2, testDates
        la $s3, testResults
        
        move $a1, $s0
        la $a2, patientId
        
        xor $t0, $t0, $t0
        xor $t1, $t1, $t1
        searchLoop1:
            lb $t0, 0($a1)
            lb $t1, 0($a2)
            
            beq $t0, 0, patient_found1
            
            bne $t0, $t1, not_found_yet1
            
            addiu $a1, $a1, 1
            addiu $a2, $a2, 1
            j searchLoop1
            
            not_found_yet1:
                addiu $s0, $s0, 8
                addiu $s1, $s1, 16
                addiu $s2, $s2, 8
                addiu $s3, $s3, 4
                lb $t0, 0($s0)
                beq $t0, 0, menu_loop
                move $a1, $s0
                la $a2, patientId
                lb $t0, 0($a1)
                beq $t0, 0, patient_not_found1
                j searchLoop1
                
            patient_not_found1:
                j menu_loop
            
            patient_found1:
                move $a0, $s0
                li $v0, 4
                syscall
                
                la $a0, dots
                syscall
                
                la $a0, space
                syscall
                
                move $a0, $s1
                syscall
                la $a0, comma
                syscall
                la $a0, space
                syscall
                
                move $a0, $s2
                syscall
                la $a0, comma
                syscall
                la $a0, space
                syscall
                
                move $t5, $s3
                andi $t5, $t5, 0xFFFFFFFC
                l.s $f12, 0($t5)
                li $v0, 2
                syscall
                la $a0, newLine
                li $v0, 4
                syscall
                
                addiu $s0, $s0, 8
                addiu $s1, $s1, 16
                addiu $s2, $s2, 8
                addiu $s3, $s3, 4
                move $a1, $s0
                lb $t0, 0($s0)
                beq $t0, 0, menu_loop
            j searchLoop1
            
    
    retrieve_upnormals:
        la $a0, newLine
        li $v0, 4
        syscall
        
        la $s0, patientIds
        la $s1, patientTests
        la $s2, testDates
        la $s3, testResults
        
        move $a1, $s0
        la $a2, patientId
        
        xor $t0, $t0, $t0
        xor $t1, $t1, $t1
        searchLoop2:
            lb $t0, 0($a1)
            lb $t1, 0($a2)
            
            beq $t0, 0, patient_found2
            
            bne $t0, $t1, not_found_yet2
            
            addiu $a1, $a1, 1
            addiu $a2, $a2, 1
            j searchLoop2
            
            not_found_yet2:
                addiu $s0, $s0, 8
                addiu $s1, $s1, 16
                addiu $s2, $s2, 8
                addiu $s3, $s3, 4
                lb $t0, 0($s0)
                beq $t0, 0, menu_loop
                move $a1, $s0
                la $a2, patientId
                lb $t0, 0($a1)
                beq $t0, 0, patient_not_found2
                j searchLoop2
                
            patient_not_found2:
                j menu_loop
            
            patient_found2:
                jal check_unnormal
                bne $t5, 1, not_found_yet2
                move $a0, $s0
                li $v0, 4
                syscall
                
                la $a0, dots
                syscall
                
                la $a0, space
                syscall
                
                move $a0, $s1
                syscall
                la $a0, comma
                syscall
                la $a0, space
                syscall
                
                move $a0, $s2
                syscall
                la $a0, comma
                syscall
                la $a0, space
                syscall
                
                move $t5, $s3
                andi $t5, $t5, 0xFFFFFFFC
                l.s $f12, 0($t5)
                li $v0, 2
                syscall
                la $a0, newLine
                li $v0, 4
                syscall
                
                addiu $s0, $s0, 8
                addiu $s1, $s1, 16
                addiu $s2, $s2, 8
                addiu $s3, $s3, 4
                move $a1, $s0
                lb $t0, 0($s0)
                beq $t0, 0, menu_loop
            j searchLoop2
#**************************************************** 
check_unnormal:
    la $s4, testNames
    la $s5, lowerLimits
    la $s6, upperLimits
    move $a0, $s4
    
    move $a1, $s1
    
    check_unnormal_loop:
        lb $t0, 0($a0)
        lb $t1, 0($a1)
        beq $t0, 0, check_a1
        bne $t0, $t1, check_next_test
        addiu $a0, $a0, 1
        addiu $a1, $a1, 1
        j check_unnormal_loop
    check_a1:
        bne $t1, 0, check_next_test
        l.s $f0, 0($s5)
        andi $s3, $s3, 0xFFFFFFFC
        l.s $f1, 0($s3)
        c.lt.s $f1, $f0
        bc1t this_is_unnormal
        
        l.s $f0, 0($s6)
        c.lt.s $f0, $f1
        bc1t this_is_unnormal
        jr $ra
    check_next_test:
        addiu $s4, $s4, 16
        addiu $s5, $s5, 4
        addiu $s6, $s6, 4
        move $a1, $s1
        lb $t0, 0($s4)
        move $a0, $s4
        bne $t0, 0, check_unnormal_loop
        xor $t5, $t5, $t5
        jr $ra
            
    this_is_unnormal:
        li $t5, 1
    
    jr $ra           
       
    
    retrieve_period:
       
        la $a0, date1msg
        li $v0, 4
        syscall
        
        la $a0, date1
        li $a1, 9
        li $v0, 8
        syscall
        la $a0, date1
        jal parse_date
        
        move $s6, $v0
        
        la $a0, date2msg
        li $v0, 4
        syscall
        
        la $a0, date2
        li $a1, 9
        li $v0, 8
        syscall
        
        la $a0, date2
        jal parse_date
        move $s7, $v0
        
        la $s0, patientIds
        la $s1, patientTests
        la $s2, testDates
        la $s3, testResults
        
        move $a1, $s0
        la $a2, patientId
        
        xor $t0, $t0, $t0
        xor $t1, $t1, $t1
        searchLoop3:
            lb $t0, 0($a1)
            lb $t1, 0($a2)
            
            beq $t0, 0, patient_found3
            
            bne $t0, $t1, not_found_yet3
            
            addiu $a1, $a1, 1
            addiu $a2, $a2, 1
            j searchLoop3
            
            not_found_yet3:
                addiu $s0, $s0, 8
                addiu $s1, $s1, 16
                addiu $s2, $s2, 8
                addiu $s3, $s3, 4
                lb $t0, 0($s0)
                beq $t0, 0, menu_loop
                move $a1, $s0
                la $a2, patientId
                lb $t0, 0($a1)
                beq $t0, 0, patient_not_found3
                j searchLoop3
                
            patient_not_found3:
                j menu_loop
            
            patient_found3:
                move $a0, $s2
                jal parse_date
                move $t5, $v0
                
                blt $t5, $s6, not_found_yet3
                bgt $t5, $s7, not_found_yet3
                
                move $a0, $s0
                li $v0, 4
                syscall
                
                la $a0, dots
                syscall
                
                la $a0, space
                syscall
                
                move $a0, $s1
                syscall
                la $a0, comma
                syscall
                la $a0, space
                syscall
                
                move $a0, $s2
                syscall
                la $a0, comma
                syscall
                la $a0, space
                syscall
                
                move $t5, $s3
                andi $t5, $t5, 0xFFFFFFFC
                l.s $f12, 0($t5)
                li $v0, 2
                syscall
                la $a0, newLine
                li $v0, 4
                syscall
                
                addiu $s0, $s0, 8
                addiu $s1, $s1, 16
                addiu $s2, $s2, 8
                addiu $s3, $s3, 4
                move $a1, $s0
                lb $t0, 0($s0)
                beq $t0, 0, menu_loop
            j searchLoop3
    j menu_loop
    
    
    not_found_error:
        la $a0, patientnotfoundmsg
        li $v0, 4
        syscall
        j menu_loop
#****************************************************
parse_date:
    li $t1, 10
    li $v0, 0
    li $t2, 4
    
#****************************************************
parse_year:
    lb $t3, 0($a0)
    li $t5, '0'
    li $t6, '9'
    blt $t3, $t5, date_error
    bgt $t3, $t6, date_error
    sub $t3, $t3, $t5
    mul $v0, $v0, $t1
    add $v0, $v0, $t3
    addi $a0, $a0, 1
    addi $t2, $t2, -1
    bnez $t2, parse_year

    lb $t3, 0($a0)
    li $t4, '-'
    bne $t3, $t4, date_error
    addi $a0, $a0, 1

    li $t2, 2            
    mul $v0, $v0, 100

#****************************************************        
parse_month:
    lb $t3, 0($a0)
    blt $t3, $t5, date_error
    bgt $t3, $t6, date_error
    sub $t3, $t3, $t5
    add $v0, $v0, $t3
    addi $a0, $a0, 1
    addi $t2, $t2, -1
    bnez $t2, parse_month

    jr $ra

#****************************************************
retrieveUnnormalTests:
    la $a0, testname
    li $v0, 4
    syscall
    
    la $a0, name
    li $a1, 16
    li $v0, 8
    syscall
    
    la $a0, name
    la $a1, name
    jal trimString
    la $a0, name
    
    find_in_ranges:
        la $s0, testNames
        la $s1, lowerLimits
        la $s2, upperLimits
        la $a0, name
        move $a1, $s0
        xor $t0, $t0, $t0
        xor $t1, $t1, $t1
        xor $t2, $t2, $t2
        xor $t3, $t3, $t3
        find_in_ranges_loop:
            lb $t0, 0($a0)
            lb $t1, 0($a1)
            
            beq $t0, 0, check_if_0
            beq $t0, 0xa, check_if_0
            bne $t0, $t1, test_not_found_yet
            addiu $a0, $a0, 1
            addiu $a1, $a1, 1
            j find_in_ranges_loop
        check_if_0:
            beq $t1, 0, test_found
        
        test_not_found_yet:
            la $a0, name
            addiu $s0, $s0, 16
            addiu $s1, $s1, 4
            addiu $s2, $s2, 4
            lb $t1, 0($s0)
            beq $t1, 0, test_average_not_exist
            move $a1, $s0
            j find_in_ranges_loop
        test_found:
            jal print_upnormals
            j menu_loop
        test_average_not_exist:
            la $a0, avnotfoundmsg
            li $v0, 4
            syscall
    
    j menu_loop

#****************************************************
updateTest:
    jal select_record
        
    la $a0, testresult
    li $v0, 4
    syscall
    
    li $v0, 6
    syscall
    
    andi $s3, $s3, 0xFFFFFFFC
    
    s.s $f0, 0($s3)
    jal write_to_file              
    j menu_loop

#****************************************************

deleteTest:
    jal select_record            # Call the select_record function to choose a record to delete
    
    move $s4, $s0                # Move the pointer for patientIds to $s4
    move $s5, $s1                # Move the pointer for patientTests to $s5
    move $s6, $s2                # Move the pointer for testDates to $s6
    move $s7, $s3                # Move the pointer for testResults to $s7
    
    loop_to_end:
        addiu $s4, $s4, 8            # Move the pointer for patientIds to the next entry
        addiu $s5, $s5, 16           # Move the pointer for patientTests to the next entry
        addiu $s6, $s6, 8            # Move the pointer for testDates to the next entry
        addiu $s7, $s7, 4            # Move the pointer for testResults to the next entry
        
        lb $t0, 0($s4)               # Load a byte from patientIds into $t0
        beq $t0, 0, end_reached      # If the byte is null, end of records is reached
        j loop_to_end                # Jump back to loop_to_end
        
    end_reached:
        subiu $s4, $s4, 8            # Move the pointer for patientIds back by 1 entry
        subiu $s5, $s5, 16           # Move the pointer for patientTests back by 1 entry
        subiu $s6, $s6, 8            # Move the pointer for testDates back by 1 entry
        subiu $s7, $s7, 4            # Move the pointer for testResults back by 1 entry
        
        beq $s4, $s0, only_remove    # If the record to delete is the last one, only remove
        
        remove_and_copy:
            andi $s3, $s3, 0xFFFFFFFC    # Align the pointer for testResults to 4-byte boundary
            andi $s7, $s7, 0xFFFFFFFC    # Align the pointer for testResults to 4-byte boundary
            
            move $a0, $s0                 # Load the address of patientIds into $a0
            li $t5, 8                     # Load 8 into $t5 (size of patientId)
            jal reset_string              # Reset patientId
            
            move $a0, $s1                 # Load the address of patientTests into $a0
            li $t5, 16                    # Load 16 into $t5 (size of patientTest)
            jal reset_string              # Reset patientTest
            
            move $a0, $s2                 # Load the address of testDates into $a0
            li $t5, 8                     # Load 8 into $t5 (size of testDate)
            jal reset_string              # Reset testDate
            
            move $a0, $s3                 # Load the address of testResults into $a0
            li $t5, 4                     # Load 4 into $t5 (size of testResult)
            jal reset_string              # Reset testResult
            
            move $a0, $s4                 # Load the address of the record to delete into $a0
            move $a2, $s0                 # Load the address of patientIds into $a2
            jal copy_string               # Copy patientId to patientIds
            
            move $a0, $s5                 # Load the address of the record to delete into $a0
            move $a2, $s1                 # Load the address of patientTests into $a2
            jal copy_string               # Copy patientTest to patientTests
            
            move $a0, $s6                 # Load the address of the record to delete into $a0
            move $a2, $s2                 # Load the address of testDates into $a2
            jal copy_string               # Copy testDate to testDates

            l.s $f0, 0($s7)               # Load the float from testResults into $f0
            s.s $f0, 0($s3)               # Store the float in testResults
            
            move $a0, $s4                 # Load the address of the record to delete into $a0
            li $t5, 8                     # Load 8 into $t5 (size of patientId)
            jal reset_string              # Reset patientId
            
            move $a0, $s5                 # Load the address of the record to delete into $a0
            li $t5, 16                    # Load 16 into $t5 (size of patientTest)
            jal reset_string              # Reset patientTest
            
            move $a0, $s6                 # Load the address of the record to delete into $a0
            li $t5, 8                     # Load 8 into $t5 (size of testDate)
            jal reset_string              # Reset testDate
            
            move $a0, $s7                 # Load the address of the record to delete into $a0
            li $t5, 4                     # Load 4 into $t5 (size of testResult)
            jal reset_string              # Reset testResult
            
            jal write_to_file             # Call the write_to_file function to update the file
            
    j menu_loop                        # Jump back to the menu loop
    
    only_remove:
        move $a0, $s4                    # Load the address of the record to delete into $a0
        li $t5, 8                        # Load 8 into $t5 (size of patientId)
        jal reset_string                 # Reset patientId
        
        move $a0, $s5                    # Load the address of the record to delete into $a0
        li $t5, 16                       # Load 16 into $t5 (size of patientTest)
        jal reset_string                 # Reset patientTest
        
        move $a0, $s6                    # Load the address of the record to delete into $a0
        li $t5, 8                        # Load 8 into $t5 (size of testDate)
        jal reset_string                 # Reset testDate
        
        move $a0, $s7                    # Load the address of the record to delete into $a0
        li $t5, 4                        # Load 4 into $t5 (size of testResult)
        jal reset_string                 # Reset testResult

    j menu_loop                          # Jump back to the menu loop

#****************************************************
calculateAverage:
    jal store_distincts
    
    la $s0, distinctTests
    
    calculation:
        lb $t0, 0($s0)
        beq $t0, 0, menu_loop   
        la $a0, newLine
        li $v0, 4
        syscall
        move $a0, $s0
        syscall
        la $a0, dots
        syscall
        la $a0, space
        syscall
        move $a1, $s0
       
        jal calculate_current
        mtc1 $t5, $f1
        cvt.s.w $f1, $f1
        div.s $f0, $f0, $f1
        
        mov.s $f12, $f0
        li $v0, 2
        syscall 
        la $a0, newLine
        li $v0, 4
        syscall
        
        addiu $s0, $s0, 16
        j calculation
            
    
    j menu_loop
    
#****************************************************
calculate_current:
    
    mtc1 $zero, $f0
    xor $t5, $t5, $t5
    la $s2, testResults
    la $s1, patientTests
    andi $s2, $s2, 0xFFFFFFFC
    move $a0, $s0
    move $a1, $s1
    
    check_and_calc:
        lb $t0, 0($a0)
        lb $t1, 0($a1)
        beq $t0, 0, check_t1_1
        bne $t0, $t1, see_next
        addiu $a0, $a0, 1
        addiu $a1, $a1, 1
        j check_and_calc
    check_t1_1:
        bne $t1, 0, see_next
        l.s $f1, 0($s2)
        add.s $f0, $f0, $f1
        addiu $t5, $t5, 1
    see_next:
        addiu $s1, $s1, 16
        addiu $s2, $s2, 4
        move $a1, $s1
        move $a0, $s0
        lb $t0, 0($s1)
        bne $t0, 0, check_and_calc
    jr $ra
    
#****************************************************
print_upnormals:
    move $a0, $s0
    la $t3, patientIds
    la $t4, patientTests
    la $t5, testDates
    la $t6, testResults
    move $a1, $t4
    find_tests_loop:
        lb $t0, 0($a0)
        lb $t1, 0($a1)
        
        beq $t0, 0, check_if_0_1
        bne $t0, $t1, not_in_record
        
        addiu $a0, $a0, 1
        addiu $a1, $a1, 1
        j find_tests_loop
        
    check_if_0_1:
        beq $t1, 0, same_test_record
        addiu $t3, $t3, 8
        addiu $t4, $t4, 16
        addiu $t5, $t5, 8
        addiu $t6, $t6, 4
        lb $t0, 0($t4)
        beq $t0, 0, records_checking_done
        move $a1, $t4
        move $a0, $s0
        j find_tests_loop
    same_test_record:
        andi $t6, $t6, 0xFFFFFFFC
        andi $s1, $s1, 0xFFFFFFFC
        andi $s2, $s2, 0xFFFFFFFC
        l.s $f1, 0($t6)
        l.s $f2, 0($s1)
        c.lt.s $f1, $f2
        bc1t found_upnormal_test
        
        l.s $f2, 0($s2)
        c.lt.s $f2, $f1
        bc1t found_upnormal_test
        addiu $t3, $t3, 8
        addiu $t4, $t4, 16
        addiu $t5, $t5, 8
        addiu $t6, $t6, 4
        lb $t0, 0($t4)
        beq $t0, 0, records_checking_done
        move $a1, $t4
        move $a0, $s0
        j find_tests_loop
    found_upnormal_test:
        
        la $a0, newLine
        li $v0, 4
        syscall
        
        move $a0, $t3
        li $v0, 4
        syscall
        
        la $a0, dots
        syscall
        la $a0, space
        syscall
        
        move $a0, $t4
        syscall
        
        la $a0, comma
        syscall
        la $a0, space
        syscall
        
        move $a0, $t5
        syscall
        
        la $a0, comma
        syscall
        
        la $a0, space
        syscall
        
        mov.s $f12, $f1
        li $v0, 2
        syscall
        
        la $a0, newLine
        li $v0, 4
        syscall
        
        addiu $t3, $t3, 8
        addiu $t4, $t4, 16
        addiu $t5, $t5, 8
        addiu $t6, $t6, 4
        lb $t0, 0($t4)
        beq $t0, 0, records_checking_done
        move $a1, $t4
        move $a0, $s0
        j find_tests_loop
    not_in_record:
        addiu $t3, $t3, 8
        addiu $t4, $t4, 16
        addiu $t5, $t5, 8
        addiu $t6, $t6, 4
        lb $t0, 0($t4)
        beq $t0, 0, records_checking_done
        move $a1, $t4
        move $a0, $s0
        j find_tests_loop
      
    records_checking_done:
    jr $ra

#****************************************************
find_patient:
    xor $t0, $t0, $t0
    xor $t1, $t1, $t1
    xor $t2, $t2, $t2
    la $a1, patientIds
    move $s1, $a0
    move $s2, $a1
    
    find_loop: 
        lb $t0, 0($a0)
        lb $t1, 0($a1)
        
        beq $t1, 0, found_patient
        
        bne $t0, $t1, not_found_yet
        
        addiu $a0, $a0, 1
        addiu $a1, $a1, 1
        j find_loop
        
    not_found_yet:
        move $a0, $s1
        addiu $s2, $s2, 8
        move $a1, $s2
        lb $t1, 0($a1)
        beq $t1, 0, patient_not_found
        j find_loop
    
    found_patient:
        xor $t4, $t4, $t4
        addiu $t4, $t4, 1
        jr $ra
        
    patient_not_found:
        xor $t4, $t4, $t4    
    
    jr $ra
    
#****************************************************
parse_averages:
    move $s0, $ra
    xor $t4, $t4, $t4
    xor $t5, $t5, $t5
    xor $t6, $t6, $t6
    xor $t7, $t7, $t7
    xor $s3, $s3, $s3
    xor $s4, $s4, $s4
    xor $s5, $s5, $s5
    xor $s6, $s6, $s6
    xor $s7, $s7, $s7
    
    la $s5, testNames
    la $s6, lowerLimits
    la $s7, upperLimits
    
    addiu $s3, $s3, 1
    la $t5, temp
    parse_tests:
        beq $s4, 1, exit_averages
        lb $t0, ($a1)
        beq $t0, ',', do_parse
        beq $t0, 0xd, check_before_parse
        beq $t0, 0, check_before_parse
        beq $t0, 0xa, no_store
        sb $t0, 0($t5)
        addiu $t5, $t5, 1
        no_store:
        addiu $a1, $a1, 1
        j parse_tests
        
        check_before_parse:
            addiu $a1, $a1, 1
            lb $t0, ($a1)
            beq $t0, 0, read_averages_is_done
            subiu $a1, $a1, 1
        do_parse:
            beq $s3, 1, read_av_name
            beq $s3, 2, read_av_lower
            beq $s3, 3, read_av_upper
            jr $ra
        read_av_name:
            la $a2, name
            la $a0, temp
            jal copy_string
            move $a2, $s5
            la $a0, temp
            jal copy_string
            
            addiu $s5, $s5, 16
            addiu $s3, $s3, 1
            
            j call_reset
        read_av_lower:
            
            la $a0, temp
            jal parseFloat
            andi $s6, $s6, 0xFFFFFFFC
            s.s $f0, 0($s6)
            addiu $s6, $s6, 4
            
            addiu $s3, $s3, 1
            j call_reset
            
        read_av_upper:
            la $a0, temp
            jal parseFloat
            andi $s7, $s7, 0xFFFFFFFC
            s.s $f0, 0($s7)
            
            addiu $s7, $s7, 4
            
            xor $s3, $s3, $s3
            addiu $s3, $s3, 1
            j call_reset
        
        read_averages_is_done:
            li $s4, 1
            j do_parse
        
        call_reset:
            la $a0, temp
            li $t5, 64
            jal reset_string
            addiu $a1, $a1, 1
            la $t5, temp
            beq $s4, 1, exit_averages
            j parse_tests
            
        exit_averages:
            jr $s0           

#****************************************************
read_patients:
    move $s0, $ra             # Save the return address in $s0
    xor $t5, $t5, $t5         # Initialize $t5 to 0 (counter for ID characters)
    xor $t6, $t6, $t6         # Initialize $t6 to 0 (counter for test characters)
    xor $t7, $t7, $t7         # Initialize $t7 to 0 (counter for date characters)
    xor $s1, $s1, $s1         # Initialize $s1 to 0 (counter for result characters)
    xor $a2, $a2, $a2         # Initialize $a2 to 0 (index for storing in patientIds)
    xor $s4, $s4, $s4         # Initialize $s4 to 0 (pointer for patientIds)
    xor $s5, $s5, $s5         # Initialize $s5 to 0 (pointer for patientTests)
    xor $s6, $s6, $s6         # Initialize $s6 to 0 (pointer for testDates)
    xor $s7, $s7, $s7         # Initialize $s7 to 0 (pointer for testResults)
    la $s4, patientIds        # Load the address of patientIds into $s4
    la $s5, patientTests      # Load the address of patientTests into $s5
    la $s6, testDates         # Load the address of testDates into $s6
    la $s7, testResults       # Load the address of testResults into $s7
    
    read_patients_loop:
        la $a0, temp               # Load the address of the temporary buffer into $a0
        lb $t5, 0($a1)             # Load a byte from the buffer into $t5
        beq $t5, 0xd, check_eof    # If the byte is a carriage return, check for end of file
        beq $t5, '\0', eof_reached # If the byte is null, end of file is reached
        subiu $a1, $a1, 1          # Move the buffer pointer back by 1 byte
        read_id:
            addiu $a1, $a1, 1          # Move to the next character in the buffer
            lb $t5, 0($a1)             # Load a byte from the buffer into $t5
            beq $t5, ' ', read_id      # If the byte is a space, continue reading ID
            beq $t5, ':', id_done      # If the byte is a colon, ID reading is done
            blt $t5, '0', error_msg   # If the byte is less than '0', display error message
            bgt $t5, '9', error_msg   # If the byte is greater than '9', display error message
            sb $t5, 0($a0)             # Store the byte in the temporary buffer
            addiu $t7, $t7, 1          # Increment the counter for ID characters
            addiu $a0, $a0, 1          # Move to the next character in the temporary buffer
            j read_id                  # Jump back to read_id
                
        id_done:
            move $a2, $s4              # Move the pointer for patientIds to $a2
            la $a0, temp               # Load the address of the temporary buffer into $a0
            jal copy_string            # Call the copy_string function to copy ID into patientIds
            
            addiu $s4, $s4, 8          # Move the pointer for patientIds to the next entry
            la $a0, temp               # Load the address of the temporary buffer into $a0
            jal reset_string           # Reset the temporary buffer
            la $a0, temp               # Load the address of the temporary buffer into $a0
            
        read_tst:
            addiu $a1, $a1, 1          # Move to the next character in the buffer
            lb $t5, 0($a1)             # Load a byte from the buffer into $t5
            beq $t5, ' ', read_tst     # If the byte is a space, continue reading test
            beq $t5, ',', tst_done     # If the byte is a comma, test reading is done
            jal check_is_char          # Call the check_is_char function to verify valid character
            sb $t5, 0($a0)             # Store the byte in the temporary buffer
            addiu $a0, $a0, 1          # Move to the next character in the temporary buffer
            j read_tst                 # Jump back to read_tst
            
        tst_done:
            move $a2, $s5              # Move the pointer for patientTests to $a2
            la $a0, temp               # Load the address of the temporary buffer into $a0
            jal copy_string            # Call the copy_string function to copy test into patientTests

            addiu $s5, $s5, 16         # Move the pointer for patientTests to the next entry
            la $a0, temp               # Load the address of the temporary buffer into $a0
            jal reset_string           # Reset the temporary buffer
            la $a0, temp               # Load the address of the temporary buffer into $a0
            
        read_date:
            addiu $a1, $a1, 1          # Move to the next character in the buffer
            lb $t5, 0($a1)             # Load a byte from the buffer into $t5
            beq $t5, ' ', read_date    # If the byte is a space, continue reading date
            beq $t5, ',', date_done    # If the byte is a comma, date reading is done
            blt $t5, '0', check_minus  # If the byte is less than '0', check for minus sign
            bgt $t5, '9', error_msg   # If the byte is greater than '9', display error message
            sb $t5, 0($a0)             # Store the byte in the temporary buffer
            addiu $a0, $a0, 1          # Move to the next character in the temporary buffer
            j read_date                # Jump back to read_date
            
        check_minus:
            bne $t5, '-', error_msg    # If the byte is not a minus sign, display error message
            sb $t5, 0($a0)             # Store the minus sign in the temporary buffer
            addiu $a0, $a0, 1          # Move to the next character in the temporary buffer
            j read_date                # Jump back to read_date
            
        date_done:
            move $a2, $s6              # Move the pointer for testDates to $a2
            la $a0, temp               # Load the address of the temporary buffer into $a0
            jal copy_string            # Call the copy_string function to copy date into testDates

            addiu $s6, $s6, 8          # Move the pointer for testDates to the next entry
            la $a0, temp               # Load the address of the temporary buffer into $a0
            jal reset_string           # Reset the temporary buffer
            la $a0, temp               # Load the address of the temporary buffer into $a0
            
        read_result:
            addiu $a1, $a1, 1          # Move to the next character in the buffer
            lb $t5, 0($a1)             # Load a byte from the buffer into $t5
            beq $t5, ' ', read_result  # If the byte is a space, continue reading result
            beq $t5, 0xd, result_done  # If the byte is a carriage return, result reading is done
            beq $t5, 0, result_done    # If the byte is null, result reading is done
            beq $t5, '.', store_without_check  # If the byte is a period, store without checking
            blt $t5, '0', error_msg   # If the byte is less than '0', display error message
            bgt $t5, '9', error_msg   # If the byte is greater than '9', display error message
            store_without_check:
            sb $t5, 0($a0)             # Store the byte in the temporary buffer
            addiu $a0, $a0, 1          # Move to the next character in the temporary buffer
            j read_result              # Jump back to read_result
            
        result_done:
            la $a0, temp               # Load the address of the temporary buffer into $a0
            jal parseFloat             # Call the parseFloat function to convert result to float
            
            andi $s7, $s7, 0xFFFFFFFC  # Align the pointer for testResults to 4-byte boundary
            s.s $f0, 0($s7)            # Store the float result in testResults
            
            addiu $s7, $s7, 4          # Move the pointer for testResults to the next entry
            
            la $a0, temp               # Load the address of the temporary buffer into $a0
            li $t5, 20                 # Load 20 into $t5 (size of temporary buffer)
            jal reset_string           # Reset the temporary buffer
            
            j read_patients_loop       # Jump back to read_patients_loop
            
        check_eof:
            addiu $a1, $a1, 1          # Move to the next character in the buffer
            lb $t5, 0($a1)             # Load a byte from the buffer into $t5
            beq $t5, 0, eof_reached    # If the byte is null, end of file is reached
            beq $t5, 0xa, new_line_reached  # If the byte is a newline, check for end of file
            j read_patients_loop       # Jump back to read_patients_loop
            
        new_line_reached:
            addiu $a1, $a1, 1          # Move to the next character in the buffer
            lb $t5, 0($a1)             # Load a byte from the buffer into $t5
            beq $t5, 0, eof_reached    # If the byte is null, end of file is reached
            j read_patients_loop       # Jump back to read_patients_loop
            
    eof_reached:
        jr $s0                       # Return to the calling function


#****************************************************
check_date:
    xor $t0, $t0, $t0
    xor $t1, $t1, $t1
    xor $t2, $t2, $t2
    check_date_loop:
        lb $t0, 0($a0)
        beq $t2, 7, check_date_done
        beq $t2, 4, check_dash
        bgt $t0, '9', set_t1
        blt $t0, '0', set_t1
        addiu $t2, $t2, 1
        addiu $a0, $a0, 1
        j check_date_loop
        check_dash:
            bne $t0, '-', set_t1
            addiu $a0, $a0, 1
            addiu $t2, $t2, 1
            j check_date_loop
        set_t1:
            addiu $t1, $t1, 1
    check_date_done:
        jr $ra
#****************************************************
check_is_char:
    bgt $t5, 'z', error_msg
    blt $t5, 'A', error_msg
    bgt $t5, 'Z', check_a
    jr $ra
    check_a:
        blt $t5, 'a', error_msg
        jr $ra
#****************************************************       
error_msg: 
    la $a0, errorMessage
    li $v0, 4
    syscall
    
    li $v0, 10
    syscall    


#****************************************************
reset_string:
    reset_loop:
        sb $zero, ($a0)
        addiu $a0, $a0, 1
        subiu $t5, $t5, 1
        beq $t5, 0, reset_done
        j reset_loop
    reset_done:
        jr $ra
#****************************************************       
copy_string:
    copy_loop:
        lb $t0, 0($a0)
        sb $t0, 0($a2)
        beq $t0, $zero, done
        addiu $a0, $a0, 1
        addiu $a2, $a2, 1 
        j copy_loop
done:
   jr $ra

#****************************************************
trimString:
    trim_leading:
        lb $t0, 0($a0)           # Load a byte from the input string into $t0
        beqz $t0, exit_trim      # If the byte is null (end of string), jump to exit_trim
        li $t1, 32               # ASCII code for space character
        li $t2, 10               # ASCII code for newline character
        beq $t0, $t1, next_char  # If the byte is a space character, jump to next_char
        beq $t0, $t2, next_char  # If the byte is a newline character, jump to next_char
        j copy_chars             # Otherwise, jump to copy_chars

    next_char:
        addi $a0, $a0, 1         # Move to the next character in the input string
        j trim_leading           # Jump back to the beginning of trim_leading

    copy_chars:
        lb $t0, 0($a0)           # Load a byte from the input string into $t0
        beqz $t0, exit_trim      # If the byte is null (end of string), jump to exit_trim
        sb $t0, 0($a1)           # Store the byte in the output string
        addi $a0, $a0, 1         # Move to the next character in the input string
        addi $a1, $a1, 1         # Move to the next character in the output string
        j copy_chars             # Jump back to the beginning of copy_chars

    exit_trim:
        sb $zero, 0($a1)         # Null-terminate the output string
        jr $ra                    # Return to the calling function

#****************************************************
parseFloat:
    li $t1, 0               # Initialize integer part accumulator to 0
    li $t2, 0               # Initialize fractional part accumulator to 0
    li $t3, 1               # Initialize fractional part divisor to 1
    li $t4, 0               # Flag for detecting decimal point

    parseFloat_loop:
        lb $t0, 0($a0)          # Load a byte from the input string into $t0
        beq $t0, 46, decimal    # If the byte is '.', jump to decimal
        beqz $t0, finish        # If the byte is null (end of string), jump to finish
        bnez $t4, frac_part    # If the decimal flag is set, jump to frac_part

        subi $t0, $t0, 48      # Convert ASCII digit to integer
        mul $t1, $t1, 10       # Multiply the integer part accumulator by 10
        add $t1, $t1, $t0      # Add the current digit to the integer part accumulator
        j parse_next           # Jump to parse_next

    decimal:
        li $t4, 1               # Set the decimal flag to indicate the start of the fractional part
        j parse_next            # Jump to parse_next

    frac_part:
        subi $t0, $t0, 48       # Convert ASCII digit to integer
        mul $t2, $t2, 10        # Multiply the fractional part accumulator by 10
        add $t2, $t2, $t0       # Add the current digit to the fractional part accumulator
        mul $t3, $t3, 10        # Multiply the fractional part divisor by 10
        j parse_next            # Jump to parse_next

    parse_next:
        addi $a0, $a0, 1        # Move to the next character in the input string
        j parseFloat_loop       # Jump back to the beginning of the parseFloat_loop

    finish:
        mtc1 $t1, $f1           # Move the integer part accumulator to $f1
        cvt.s.w $f1, $f1        # Convert the integer part to single precision float

        mtc1 $t2, $f2           # Move the fractional part accumulator to $f2
        cvt.s.w $f2, $f2        # Convert the fractional part to single precision float
        mtc1 $t3, $f3           # Move the fractional part divisor to $f3
        cvt.s.w $f3, $f3        # Convert the fractional part divisor to single precision float
        div.s $f2, $f2, $f3    # Divide the fractional part by the divisor

        add.s $f0, $f1, $f2    # Add the integer and fractional parts together to get the final float result

        jr $ra                             

#****************************************************
select_record:
    
    la $s0, patientIds          # Load the address of patientIds array into $s0
    la $s1, patientTests        # Load the address of patientTests array into $s1
    la $s2, testDates           # Load the address of testDates array into $s2
    la $s3, testResults         # Load the address of testResults array into $s3
    xor $t3, $t3, $t3          # Initialize counter for record numbers to 0
    addiu $t3, $t3, 1          # Increment counter for the first record
    xor $t4, $t4, $t4          # Initialize counter for loop iterations to 0
    
    la $a0, selectrecord        # Load the address of the selectrecord message into $a0
    li $v0, 4                   # System call for printing a string
    syscall                     

    print_records_loop:
    addiu $t4, $t4, 1           # Increment loop iteration counter
    
    lb $t0, 0($s0)               # Load a byte from patientIds array into $t0
    beq $t0, 0, print_records_done  # If the byte is 0 (end of string), jump to print_records_done
    
    move $a0, $t4               # Move the record number to be printed to $a0
    li $v0, 1                   # System call for printing an integer
    syscall                     
    
    li $a0, '-'                 # Load '-' character into $a0
    li $v0, 11                  # System call for printing a character
    syscall                     
    
    move $a0, $s0               # Load the address of patientIds array into $a0
    li $v0, 4                   # System call for printing a string
    syscall                     
    
    la $a0, dots                # Load the address of the dots message into $a0
    syscall                     
    
    la $a0, space               # Load the address of the space message into $a0
    syscall                     
    
    move $a0, $s1               # Load the address of patientTests array into $a0
    syscall                     
    
    la $a0, comma               # Load the address of the comma message into $a0
    syscall                     
    
    la $a0, space               # Load the address of the space message into $a0
    syscall                     
    
    move $a0, $s2               # Load the address of testDates array into $a0
    syscall                     
    
    la $a0, comma               # Load the address of the comma message into $a0
    syscall                     
    
    la $a0, space               # Load the address of the space message into $a0
    syscall                     
    
    andi $s3, $s3, 0xFFFFFFFC   # Clear the last 2 bits of the address in $s3
    l.s $f12, 0($s3)            # Load a single precision floating point number from testResults array into $f12
    li $v0, 2                   # System call for printing a floating point number
    syscall                     
    
    la $a0, newLine             # Load the address of the newLine message into $a0
    li $v0, 4                   # System call for printing a string
    syscall                     
    
    addiu $s0, $s0, 8           # Move to the next record in patientIds array
    addiu $s1, $s1, 16          # Move to the next record in patientTests array
    addiu $s2, $s2, 8           # Move to the next record in testDates array
    addiu $s3, $s3, 4           # Move to the next record in testResults array
    addiu $t3, $t3, 1           # Increment the record number counter
    j print_records_loop        # Jump back to the beginning of the print_records_loop
    
    print_records_done:
    li $a0, '>'                 # Load '>' character into $a0
    li $v0, 11                  # System call for printing a character
    syscall                     
    
    li $a0, ' '                 # Load space character into $a0
    syscall                     

    li $v0, 5                   # System call for reading an integer
    syscall                     
   
    blt $v0, 1, out_of_range    # If the input is less than 1, jump to out_of_range
    bge $v0, $t3, out_of_range  # If the input is greater than the number of records, jump to out_of_range
    
    move $t1, $v0               # Move the selected record number to $t1

    la $s0, patientIds          # Load the address of patientIds array into $s0
    la $s1, patientTests        # Load the address of patientTests array into $s1
    la $s2, testDates           # Load the address of testDates array into $s2
    la $s3, testResults         # Load the address of testResults array into $s3
    
    xor $t2, $t2, $t2          # Initialize counter for record numbers to 0
    addiu $t2, $t2, 1          # Increment counter for the first record
    increment_loop:
        beq $t1, $t2, increment_reached  # If the selected record number is reached, jump to increment_reached
        addiu $s0, $s0, 8      # Move to the next record in patientIds array
        addiu $s1, $s1, 16     # Move to the next record in patientTests array
        addiu $s2, $s2, 8      # Move to the next record in testDates array
        addiu $s3, $s3, 4      # Move to the next record in testResults array
        addiu $t2, $t2, 1      # Increment the counter for record numbers
        j increment_loop       # Jump back to the beginning of the increment_loop
    increment_reached:
        jr $ra                   # Return to the calling function
    out_of_range:
        
        la $a0, outofrangemsg    # Load the address of the outofrangemsg message into $a0
        li $v0, 4                # System call for printing a string
        syscall                  
        j menu_loop              

#****************************************************
store_distincts:
     la $s0, distinctTests        # Load the address of distinctTests array into $s0
     la $s1, patientTests         # Load the address of patientTests array into $s1
     
     move $a0, $s0                # Move the address of distinctTests array to $a0
     move $a1, $s1                # Move the address of patientTests array to $a1
     
     
     store_loop:
         move $s5, $ra            # Preserve the return address
         jal check_existent      # Call the check_existent function to determine if the record exists in distinctTests
         move $ra, $s5            # Restore the return address
         beq $t5, 0, do_store     # If the record is distinct, jump to do_store
         addiu $s1, $s1, 16      # Move to the next record in patientTests
         move $a1, $s1            # Update the pointer to patientTests in $a1
         move $a0, $s0            # Reset the pointer to distinctTests in $a0
         j store_loop             # Jump back to the beginning of the loop to check the next record
         
     
     do_store:
         copying:                  
             lb $t0, 0($a1)       # Load a byte from the current position in patientTests into $t0
             sb $t0, 0($a0)       # Store the byte into the current position in distinctTests
             beq $t0, 0, copying_done  # If the byte is 0 (end of string), jump to copying_done
             addiu $a0, $a0, 1    # Move to the next position in distinctTests
             addiu $a1, $a1, 1    # Move to the next position in patientTests
             j copying            # Jump back to the beginning of the copying loop
         copying_done:
             addiu $s0, $s0, 16   # Move to the next record in distinctTests
             addiu $s1, $s1, 16   # Move to the next record in patientTests
             lb $t0, 0($s1)       # Load a byte from the current position in patientTests into $t0
             beq $t0, 0, distincts_store_done  # If the byte is 0 (end of string), jump to distincts_store_done
             move $a1, $s1         # Update the pointer to patientTests in $a1
             move $a0, $s0         # Update the pointer to distinctTests in $a0
             j store_loop          # Jump back to the beginning of the store_loop to process the next record
         
     
     distincts_store_done:
         jr $ra                      

#****************************************************
     
check_existent:
     move $a2, $s1                # Copy the address of the patientTests array to $a2
     la $s2, distinctTests        # Load the address of the distinctTests array into $s2
     la $a3, distinctTests        # Copy the address of the distinctTests array to $a3
     
    
     check_existent_loop:
         lb $t0, 0($a2)           # Load a byte from the current position in patientTests into $t0
         lb $t1, 0($a3)           # Load a byte from the current position in distinctTests into $t1
         beq $t0, 0, check_t1     # If the byte in patientTests is 0, jump to check_t1
         bne $t0, $t1, not_this_index  # If the bytes in patientTests and distinctTests are not equal, jump to not_this_index
         addiu $a2, $a2, 1        # Increment the pointer to patientTests by 1
         addiu $a3, $a3, 1        # Increment the pointer to distinctTests by 1
         j check_existent_loop   # Jump back to the beginning of the loop
         
     
     not_this_index:
         move $a2, $s1            # Reset the pointer to patientTests to its original address
         addiu $s2, $s2, 16       # Move the pointer to the next record in distinctTests
         move $a3, $s2            # Update the pointer to distinctTests
         lb $t0, 0($s2)           # Load a byte from the current position in distinctTests into $t0
         beq $t0, 0, this_distinct  # If the byte in distinctTests is 0, jump to this_distinct
         j check_existent_loop   # Otherwise, continue checking other records in distinctTests
         
     check_t1:
         beq $t1, 0, not_distinct  # If the byte in distinctTests is 0, jump to not_distinct
         j not_this_index         # Otherwise, continue checking other records in distinctTests
         
     # Jump target if the record in patientTests is distinct
     this_distinct:
         move $t5, $zero          # Set $t5 to 0 (indicating distinct record)
         jr $ra                   # Return to the calling function
         
     # Jump target if the record in patientTests is not distinct
     not_distinct:        
         li $t5, 1                # Set $t5 to 1 (indicating non-distinct record)
         jr $ra                   # Return to the calling function


write_to_file:
        # Open the file for writing
    li $v0, 13             # syscall for open file
    la $a0, outputFile     # pointer to the file name
    li $a1, 1            # flags (WR_ONLY | CREAT | TRUNC)
    li $a2, 0            # mode (permissions, equivalent to 0644)
    syscall
    move $s5, $v0          # store file descriptor in s5
    bltz $s5, menu_loop         # if s5 is negative, exit the program

    # Prepare data pointers
    la $s0, patientIds
    la $s1, patientTests
    la $s2, testDates
    la $s3, testResults

loop:
    lb $t2, 0($s0)
    beqz $t2, close_file

    li $v0, 15
    move $a0, $s5
    move $a1, $s0
    li $a2, 7
    syscall

    # Write dots as separator
    li $v0, 15
    move $a0, $s5
    la $a1, dots
    li $a2, 1
    syscall
    
    li $v0, 15
    move $a0, $s5
    la $a1, space
    li $a2, 1
    syscall
    
    # Write patient test
    li $v0, 15
    move $a0, $s5
    move $a1, $s1
    li $a2, 7
    syscall

    # Write comma as separator
    li $v0, 15
    move $a0, $s5
    la $a1, comma
    li $a2, 1
    syscall
    
    li $v0, 15
    move $a0, $s5
    la $a1, space
    li $a2, 1
    syscall
    
    # Write test date
    li $v0, 15
    move $a0, $s5
    move $a1, $s2
    li $a2, 7
    syscall

    # Write comma and space before test result
    li $v0, 15
    move $a0, $s5
    la $a1, comma
    li $a2, 1
    syscall
      
    andi $s3, 0xFFFFFFFC
    
    lwc1 $f0, 0($s3)      # Load the float from memory
    
    move $s7, $ra
    jal float_to_string
    move $ra, $s7
    
    li $v0, 15             
    move $a0, $s5          # File descriptor
    la $a1, floatBuffer    # Address of the buffer holding the float
    li $a2, 4              # Length to write (size of a float)
    syscall

    li $v0, 15
    move $a0, $s5
    la $a1, newLine
    li $a2, 1
    syscall

    addiu $s0, $s0, 8     # Next patient ID
    addiu $s1, $s1, 16    # Next patient test
    addiu $s2, $s2, 8    # Next test date
    addiu $s3, $s3, 4     # Next test result

    lb $t1, 0($s0)
    bnez $t1, loop

close_file:
    li $v0, 16    
    move $a0, $s5  
    syscall
    jr $ra
            
 float_to_string:
    sw $ra, 0($sp)
    addiu $sp, $sp, -4

    cvt.w.s $f0, $f0
    mfc1 $t0, $f0

    li $t1, 10  
    la $t2, floatBuffer

int_to_string_loop:
    div $t0, $t1
    mflo $t0
    mfhi $t3

    addiu $t3, $t3, '0'
    sb $t3, 0($t2)

    addiu $t2, $t2, 1
    
    bnez $t0, int_to_string_loop

    sb $zero, 0($t2)

    addiu $sp, $sp, 4
    lw $ra, 0($sp)
    jr $ra
