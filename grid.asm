    .data
GRID:
    .space 16384 # 64 * 64 * 4
GRID_SIZE:
    .word 16384
DISPLAY_WIDTH:
    .word 64
DISPLAY_HEIGHT:
    .word 64
PIXEL_SIZE:
    .word 4

ADDR_DSPL:
    .word 0x10008000
ADDR_KBRD:
    .word 0xffff0000
    
RED_COLOR:
    .word 0xff0000
YELLOW_COLOR:
    .word 0xffff00
BLUE_COLOR:
    .word 0x0000ff


    .text
	.globl main

main:
    # initialize starting coordinates
    li $s0, 32
    li $s1, 32
    
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
    lw $t3, YELLOW_COLOR    # Load pixel color
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

game_loop:
    jal keyboard_input
    jal draw_pixel
    
    j game_loop

keyboard_input:
    li $v0, 32                      # Load system call to read character
    li $a0, 1                       # Specify file descriptor (stdin)
    syscall                         # Read a character
                                    
    lw $t0, ADDR_KBRD               # Load base address for keyboard ($t0)
    lw $t1, 0($t0)                  # Load first word from keyboard ($t1)
    beq $t1, 1, handle_input        # If key pressed (first word is 1), handle key press
    
    jr $ra

# main:
    # li $s0, 32                  # Initialize starting coordinates (x = 32)
    # li $s1, 32                  # Initialize starting coordinates (y = 32)
    
    # jal initialize_grid         # Initialize grid
    # jal draw_grid               # Draw grid
    
    # j game_loop                 # Start the game loop

# initialize_grid:
    # la $t0, GRID                # Load base address of grid into $t0
    # lw $t1, GRID_SIZE           # Load grid size into $t1
    # add $t1, $t1, $t0           # Specify max index in $t1 (end address)
    # lw $t2, PIXEL_SIZE          # Load pixel size into $t2
    # lw $t3, YELLOW_COLOR        # Load yellow color into $t3
    
# while_initialize_grid:
    # bge $t0, $t1, exit_initialize_grid  # If $t0 >= end of grid, exit
    # sw $t3, 0($t0)             # Store yellow color in current grid cell
    # add $t0, $t0, $t2          # Increment grid address by pixel size
    # j while_initialize_grid     # Continue loop

# exit_initialize_grid:
    # jr $ra                      # Return from function

# draw_grid:
    # la $t0, GRID                # Load grid base address into $t0
    # lw $t1, GRID_SIZE           # Load grid size into $t1
    # add $t1, $t1, $t0           # Calculate max index (end address)
    # lw $t2, PIXEL_SIZE          # Load pixel size into $t2
    # lw $t3, ADDR_DSPL           # Load display base address into $t3

# while_draw_grid:
    # bge $t0, $t1, exit_draw_grid  # If $t0 >= end of grid, exit
    # lw $t4, 0($t0)               # Load pixel color from grid
    # sw $t4, 0($t3)               # Store pixel color to display
    # add $t0, $t0, $t2            # Increment grid address by pixel size
    # add $t3, $t3, $t2            # Increment display address by pixel size
    # j while_draw_grid            # Continue loop

# exit_draw_grid:
    # jr $ra                       # Return from function

# game_loop:
    # jal keyboard_input           # Get keyboard input
    # jal draw_pixel               # Draw pixel (or update display)
    
    # j game_loop                  # Continue game loop

# keyboard_input:
    # li $v0, 32                   # Load syscall to read character (32 = read char)
    # li $a0, 1                    # Specify file descriptor (stdin)
    # syscall                      # Read character input
    
    # lw $t0, ADDR_KBRD            # Load base address for keyboard input into $t0
    # lw $t1, 0($t0)               # Load keyboard input from the mapped address
    # beq $t1, 1, handle_input     # If key is pressed (value 1), handle it
    
    # jr $ra                       # Return from function

handle_input:                       # A key is pressed
    # $t0 = keyboard address, $t1 = full keyboard input
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 113, respond_to_Q      # Check if the key q was pressed
    beq $a0, 119, respond_to_W      # Check if the key a was pressed
    beq $a0, 97, respond_to_A       # Check if the key a was pressed
    beq $a0, 115, respond_to_S      # Check if the key a was pressed
    beq $a0, 100, respond_to_D      # Check if the key a was pressed

    li $v0, 11                      # Load system call to print character
    syscall                         # Print previously read character ($a0)

    jr $ra

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall

respond_to_W:
    subi $s1, $s1, 1
    jr $ra
respond_to_A:
    subi $s0, $s0, 1
    jr $ra
respond_to_S:
    addi $s1, $s1, 1
    jr $ra
respond_to_D:
    addi $s0, $s0, 1
    jr $ra

draw_pixel:
    lw $t7, RED_COLOR       # $t7 = red
    lw $t8, YELLOW_COLOR    # $t8 = yellow
    lw $t9, BLUE_COLOR      # $t9 = blue
    
    lw $t0, ADDR_DSPL       # Load base address for the display ($t0)
    
    lw $t1, DISPLAY_WIDTH   # Load the display width ($t1)
    lw $t2, DISPLAY_HEIGHT  # Load the display height ($t2) (not needed)
    lw $t3, PIXEL_SIZE      # Load pixel size/integer length
    
    mult $t4, $s0, $t3      # x-offset ($t4): Multiply x-coordinate ($s0) by pixel size ($t3)
    mult $t5, $s1, $t1      # Convert y-coordinate into length using display width ($t1) 
    mult $t5, $t5, $t3      # y-offset ($t5): Multiply y-coordinate length ($s5) by pixel size ($t3)
    
    add $t0, $t0, $t4       # Add the x-offset ($t4) into the address
    add $t0, $t0, $t5       # Add the y-offset ($t5) into the address

    sw $t9, 0($t0)          # Store the value of $t9 at the address in $t0
    
    jr $ra