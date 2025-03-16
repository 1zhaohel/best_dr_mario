    .data
ADDR_DSPL:
    .word 0x10008000
ADDR_KBRD:
    .word 0xffff0000

GRID:
    .space 4096 # 32 * 32 * 4
GRID_SIZE:
    .word 4096
DISPLAY_WIDTH:
    .word 32
DISPLAY_HEIGHT:
    .word 32
PIXEL_SIZE:
    .word 4

FRAMERATE:
    .word 180

# Border within the jar, inclusive
MIN_X:
    .word 0
MAX_X:
    .word 31
MIN_Y:
    .word 0
MAX_Y:
    .word 31
    
RED_COLOR:
    .word 0xff0000
YELLOW_COLOR:
    .word 0xffff00
BLUE_COLOR:
    .word 0x0000ff
BACKGROUND_COLOR:
    .word 0x000000


    .text
	.globl main

main:
    jal generate_block
    li $s6, 0               # Initialize timer to 0
    jal initialize_grid
    jal draw_grid
    
    j game_loop

exit:
    jr $ra

initialize_grid:
    la $t0, GRID            # Load grid address ($t0) into counter
    lw $t1, GRID_SIZE       # Lood grid size ($t1)
    add $t1, $t1, $t0       # Specify max index ($t1)
    lw $t2, PIXEL_SIZE      # Load pixel size ($t2)
    lw $t3, BACKGROUND_COLOR    # Load pixel color
    while_initialize_grid:
        bge $t0, $t1, exit # Exit loop if counter ($t0) >= max index ($t1)
        sw $t3, 0($t0)      # Save color into grid index 
        add $t0, $t0, $t2   # Increment counter by pixel size
        j while_initialize_grid

draw_grid:
    la $t0, GRID            # Load grid address ($t0) into counter
    lw $t1, GRID_SIZE       # Lood grid size ($t1)
    add $t1, $t1, $t0       # Specify max index ($t1)
    lw $t2, PIXEL_SIZE      # Load pixel size ($t2)
    lw $t3, ADDR_DSPL       # Load display address ($t3) into counter
    while_draw_grid:
        bge $t0, $t1, exit # Exit loop if counter ($t0) >= max index ($t1)
        lw $t4, 0($t0)      # Load the color from the grid ($t4)
        sw $t4, 0($t3)      # Save color into display index 
        add $t0, $t0, $t2   # Increment grid counter by pixel size
        add $t3, $t3, $t2   # Increment display counter by pixel size
        j while_draw_grid

generate_block:
    # Save $ra (in main after generate_block) and restore after random_color
    sub $sp, $sp, 4
    sw $ra, 0($sp)
    
    lw $t0 DISPLAY_WIDTH
    li $t1 2
    div $t1, $t0, $t1       # Halve the display width into $t1
    subi $t0, $t1, 1        # Subtract 1 from $t1 into $t0
    # initialize half #1 starting coordinates
    move $s0, $t0
    lw $s1, MIN_Y
    # initialize half #1 starting color
    jal random_color
    move $s2, $v0
    # initialize half #2 starting coordinates
    move $s3, $t1
    lw $s4, MIN_Y
    # initialize half #2 starting color
    jal random_color
    move $s5, $v0
    
    # Restore $ra (in main after generate_block) after random_color
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

random_color:
    # Generate random number from (0, 1, 2)
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    beq $a0, 0, set_color_red
    beq $a0, 1, set_color_yellow
    beq $a0, 2, set_color_blue
    
set_color_red:
    lw $v0, RED_COLOR
    jr $ra                  # Return to call in generate_block

set_color_yellow:
    lw $v0, YELLOW_COLOR
    jr $ra                  # Return to call in generate_block

set_color_blue:
    lw $v0, BLUE_COLOR
    jr $ra                  # Return to call in generate_block

##############################################################################
# GAME LOOP
##############################################################################
game_loop:
    jal clear_block
    jal keyboard_input
    jal increment_timer
    jal draw_grid
    
    j game_loop

clear_block:
    # Save $ra (in game_loop after clear_block) before draw_block
    sub $sp, $sp, 4
    sw $ra, 0($sp)
    
    # Remove old block position
    li $a0, 0
    jal draw_block
    
    # Restore $ra (in game_loop after clear_block) after draw_block
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

keyboard_input:
    # Save $ra (in main after keyboard_input) and restore in update_block
    sub $sp, $sp, 4
    sw $ra, 0($sp)
    
    li $v0, 32                      # Load system call to read character
    li $a0, 1                       # Specify file descriptor (stdin)
    syscall                         # Read a character
                                    
    lw $a0, ADDR_KBRD               # Load base address for keyboard ($t0)
    lw $t1, 0($a0)                  # Load first word from keyboard ($t1)
    beq $t1, 1, handle_input        # If key pressed (first word is 1), handle key press
    
    j update_block

handle_input:                       # A key is pressed
    # $a0 = full keyboard input
    
    lw $a0, 4($a0)                  # Load second word from keyboard
    
    # Save inputted character ($a0) and restore after set_pixel
    sub $sp, $sp, 4
    sw $a0, 0($sp) 
    
    # Restore inputted character ($a0) after set_pixel
    lw $a0, 0($sp)
    addi $sp, $sp, 4
    
    li $v0, 1                      # Set output
    syscall                         # Print inputted character ($a0)
    
    beq $a0, 113, end_game          # Check if the key q was pressed
    
    beq $a0, 119, rotate            # Check if the key w was pressed
    beq $a0, 97, move_left          # Check if the key a was pressed
    beq $a0, 115, move_down         # Check if the key s was pressed
    beq $a0, 100, move_right        # Check if the key d was pressed
    
    beq $a0, 107, rotate            # Check if the key k was pressed
    beq $a0, 104, move_left         # Check if the key h was pressed
    beq $a0, 106, move_down         # Check if the key j was pressed
    beq $a0, 108, move_right        # Check if the key l was pressed
    
    j update_block

update_block:
    # Draw new pixel position
    li $a0, 1
    jal draw_block
    
    # Restore $ra (in main after keyboard_input) after saving in keyboard_input
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_block:
    # $a0 = 0 to clear, otherwise draw
    
    move $t0, $a0
    
    # Save $ra and $t0 before set_pixel
    sub $sp, $sp, 8
    sw $ra, 4($sp)
    sw $t0, 0($sp)
    
    # Half #1
    move $a0, $s0                   # Load the x-coordinate ($s0) into $a0
    move $a1, $s1                   # Load the y-coordinate ($s1) into $a1
    beqz $t0, clear_color_1         # If input ($a0) is 0, set color to background color
    move $a2, $s2                   # Load pixel color ($s2) into $a2
    j draw_half_1
    clear_color_1:
        lw $a2, BACKGROUND_COLOR
    draw_half_1:
        jal set_pixel                   # Draw the pixel at the x and y-coordinate
    
    # Restore $t0 after set_pixel
    lw $t0, 0($sp)
    addi $sp, $sp, 4
    
    # Half #2
    move $a0, $s3                   # Load the x-coordinate ($s3) into $a0
    move $a1, $s4                   # Load the y-coordinate ($s4) into $a1
    beqz $t0, clear_color_2         # If input ($a0) is 0, set color to background color
    move $a2, $s5                   # Load pixel color ($s5) into $a2
    j draw_half_2
    clear_color_2:
        lw $a2, BACKGROUND_COLOR
    draw_half_2:
        jal set_pixel                   # Draw the pixel at the x and y-coordinate
    
    # Restore $ra after set_pixel
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

end_game:
	li $v0, 10                      # Quit gracefully
	syscall

rotate:
    # Half #2 is to the right of half #1
    subi $t0, $s3, 1
    beq $s0, $t0, rotate_three_to_six
    # Half #2 is below half #1
    subi $t1, $s4, 1
    beq $s1, $t1, rotate_six_to_nine
    # Half #2 is to the left of half #1
    addi $t0, $s3, 1
    beq $s0, $t0, rotate_nine_to_twelve
    # Half #2 is above half #1
    addi $t1, $s4, 1
    beq $s1, $t1, rotate_twelve_to_three
    
    j update_block

rotate_three_to_six:
    lw $t0, MAX_Y
    bge $s1, $t0, update_block
    move $s3, $s0
    addi $s4, $s1, 1
    j update_block

rotate_six_to_nine:
    lw $t0, MIN_X
    ble $s0, $t0, update_block
    move $s4, $s1
    subi $s3, $s0, 1
    j update_block

rotate_nine_to_twelve:
    lw $t0, MIN_Y
    ble $s1, $t0, update_block
    move $s3, $s0
    subi $s4, $s1, 1
    j update_block

rotate_twelve_to_three:
    lw $t0, MAX_X
    bge $s0, $t0, update_block
    move $s4, $s1
    addi $s3, $s0, 1
    j update_block

# move_up:
    # End if block is at top border
    # lw $t0, MIN_Y
    # ble $s1, $t0, update_block
    # ble $s4, $t0, update_block
    # Move 1 step up
    # subi $s1, $s1, 1
    # subi $s4, $s4, 1
    # j update_block

move_left:
    # End if block is at left border
    lw $t0, MIN_X
    ble $s0, $t0, update_block
    ble $s3, $t0, update_block
    # Move 1 step left
    subi $s0, $s0, 1
    subi $s3, $s3, 1
    j update_block

move_down:
    # End if block is at bottom border
    lw $t0, MAX_Y
    bge $s1, $t0, update_block
    bge $s4, $t0, update_block
    # Move 1 step down
    addi $s1, $s1, 1
    addi $s4, $s4, 1
    j update_block

move_right:
    # End of block is at right border
    lw $t0, MAX_X
    bge $s0, $t0, update_block
    bge $s3, $t0, update_block
    # Move 1 step right
    addi $s0, $s0, 1
    addi $s3, $s3, 1
    j update_block

coord_to_idx:   # Converts x and y-coordinates to the corresponding memory index in the grid
    # $a0 = x-coordinate, $a1 = y-coordinate
    # $v0 = index in display or grid
    
    la $t0, GRID       # Load base address for the grid ($t0)
    
    lw $t1, DISPLAY_WIDTH   # Load the display width ($t1)
    lw $t2, DISPLAY_HEIGHT  # Load the display height ($t2) (not needed)
    lw $t3, PIXEL_SIZE      # Load pixel size/integer length
    
    mult $t4, $a0, $t3      # x-offset ($t4): Multiply x-coordinate ($s0) by pixel size ($t3)
    mult $t5, $a1, $t1      # Convert y-coordinate into length using display width ($t1) 
    mult $t5, $t5, $t3      # y-offset ($t5): Multiply y-coordinate length ($s5) by pixel size ($t3)
    
    add $t0, $t0, $t4       # Add the x-offset ($t4) into the address
    add $t0, $t0, $t5       # Add the y-offset ($t5) into the address
    
    move $v0, $t0
    
    jr $ra                  # Return to caller (main)

set_pixel:
    # $a0 = x-coordinate, $a1 = y-coordinate, $a2 = color
    
    # Save $ra before calling coord_to_idx
    sub $sp, $sp, 4
    sw $ra, 0($sp)
    
    jal coord_to_idx
    
    move $t0, $v0           # Move the returned index to $t0
    sw $a2, 0($t0)          # Store the value of $a2 at the address in $t0
    
    # Restore $ra after returning from coord_to_idx
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

get_pixel:
    # $a0 = x-coordinate, $a1 = y-coordinate
    # $v0 = color of the pixel at the x and y-coordinates
    
    # Save $ra before calling coord_to_idx
    sub $sp, $sp, 4
    sw $ra, 0($sp)
    
    jal coord_to_idx
    
    move $t0, $v0           # Move the returned index to $t0
    lw $v0, 0($t0)          # Load the value at the grid index into $v0
    
    # Restore $ra after returning from coord_to_idx
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

increment_timer:
    lw $t0, FRAMERATE
    addi $s6, $s6, 1
    beq $s6, $t0, tick_timer
    
    jr $ra

tick_timer:
    # Save $ra (in game_loop after increment_timer) and restore in update_block
    sub $sp, $sp, 4
    sw $ra, 0($sp)
    
    jal clear_block
    
    li $s6, 0
    j move_down
