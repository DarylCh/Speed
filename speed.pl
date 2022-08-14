#!/usr/bin/perl -w
#
#
# This program serves as a simplified implementation of the Unix command 'sed'. 
# As such many of its fundamental features are included, such as the regex 
# line editing commands, delete features as well as the standard print and 
# quit functions. The program has been expanded to accept both numerical and 
# regex address ranges, and flexible delimiter usage is acceptable. Input from 
# files are accepted as well as from standard input.
#
# While all of the standard features have been coded already, the more complicated
# intricacies from Subset 02 of the assignment have not yet been implemplemented.
#
################################################################################

# Variable initialisation
# Initialises the various sentinel variables used in the program
$index = 1;
$program = "";
$flag = "";
$lower = "";
$upper = "";
$capture = 0;
$quitCommand = 0;
$printSwitch = 0;
$answer = "";
$delSwitch = 0;
$printSwitch = 0;
$quitCommand = 0;
$modifier = "";
$fileUsed = 0;
$subAnswer = 0;
$subSwitch = 0;
$capture = 0;
$subCapture = 0;
$delCapture = 0;
$lastCapture = 0;
$printCapture = 0;
$program = "";
$printCount = 0;

# Auxillary Functions (Header)
# For ease of understanding, I have split the auxillary functions into two parts.
# The header comes before the 'main' function and mostly covers the preparative
# work done before the main function is executed. Most of the primary functions
# called by the main have been placed under it. 


# This function takes the given command line arguments and processes them 
# accordingly. This includes splitting arguments by semicolons and removing 
# whitespaces and commas. Once done it will then transfer the arguments 
# to the @programs array for the main program.
sub sortCommandArgs {
    if ($#ARGV == -1) {
        print STDERR "usage: speed [-i] [-n] [-f <script-file> | <sed-command>] [<files>...]\n";
        exit 1;
    }
    $program = shift @ARGV;
    # handles and processes the flags
    if ($program eq "-n") {
        $flag = $program;
        $program = shift @ARGV;
        $flagUsed = 1;
    }
    
    if ($program eq "-f") {
        $file = shift @ARGV;
        $fileUsed = 1;
    }

    if ($fileUsed == 1) {
        sortFiles();
    }

    # checks if mutiple arugments exist, and splits them accordingly
    if (defined($program) && $program =~ /\;/) {
        $multipleComms = 1;
        @programs = split(';', $program);
    }
    elsif (defined($program) && $program =~ /\n/) {
        $multipleComms = 1;
        @programs = split('\n', $program);
    }
    elsif (defined($program) && $program ne "") {
        push(@programs, $program);
    }

    # loop that removes spaces and hashes from the given arguments
    foreach $prog(@programs) {
        $i++;
        $prog =~ s/ //g;
        $prog =~ s/#.*//g;
    }
    if ($i > 1) {
        $multipleComms = 1;
    }
}


# This function extracts the arguments from a given file and appends them to the 
# @programs array. This is called from the sortCommandArgs function.
sub sortFiles {
    open FILE, "<", $file or die "speed: couldn't open file $file: No such file or directory\n";
    if (defined($ARGV[0]) && $ARGV[0] !~ /\.txt/) {
        $program = shift @ARGV;
    }
    else {
        $program = "";
    }
    while ($fil = <FILE>) {
        chomp ($fil);
        if ($fil =~ /\;/) {
            $multipleComms = 1;
            @programs = split(';', $fil);
        }
        elsif ($fil =~ /\n/) {
            $multipleComms = 1;
            @programs = split('\n', $fil);
        }
        else {
            push @programs, $fil;
        }
    }
    close (FILE);
}


# A number of sentinal variables have been used throughout this project. This
# function simply resets them when called to ensure accurate processing
# of arguments.
sub resetFlags {
    $delFunc = 0;
    $quitFunc = 0;
    $printFunc = 0;
    $subFunc = 0;
    $argIsLastOnly = 0;
    $argIsNum = 0;
    $argIsRegex = 0;
    $argIsSplit = 0;
    $lowerIsNum = 0;
    $lowerIsRegex = 0;
    $upperIsRegex = 0;
    $upperIsNum = 0;
}

# Organises the command line arguments for implementation.
sortCommandArgs();


#
#
# Main Function. Forms the basis for the entire program.
#####################################################################
# Loops through every line of STDIN or the provided file.
while ($line = <>) {
    $index = 1;
    $printCalled = 0;
    $delCalled = 0;
    $quitCalled = 0;
    $subCalled = 0;
    # This loops through every program for each line in the file.
    foreach my $program(@programs) {
        resetFlags();

        # Idenifies which function the user has called for
        if ($program =~ /(.*)([qpd])$/) {
            $argument = $1;
            $command = $2;
            if ($command eq "q") {
                $quitFunc = 1;
            }
            elsif ($command eq "p") {
                $printFunc = 1;
            }
            elsif ($command eq "d") {
                $delFunc = 1;
            }
        }
    
        elsif ($program =~ /^.*s(\S).*(\S)(.)$/) {
            $subFunc = 1;
            # This captures substiute commands with the 'g' modifier
            if ($program =~ /^.*s(\S)(.*)\S.*(\S)g$/ && "$1" eq "$3") {
                $subFunc = 1;
                $delim = $1;
                $program =~ /^(.*)s\Q$delim\E(.*)\Q$delim\E(.*)\Q$delim\Eg$/;
                $argument = $1;
                $regex = $2;
                $substitute = $3;
                $modifier = "g";
            }
            # This captures substiute commands without the 'g' modifier
            elsif ($program =~ /^.*s(\S)(.*)\S.*(\S)$/ && "$1" eq "$3") {
                $delim = $1;
                $program =~ /^(.*)s\Q$delim\E(.*)\Q$delim\E(.*)\Q$delim\E$/;
                $argument = $1;
                $regex = $2;
                $substitute = $3;
            }
        }
    
        sortInputArgs();
         

        # Calls the quit function for subset 0 functions
        if ($quitFunc) {
            $quitCalled = 1;
            quitFunction();
        }

        # Calls the print function for subset 0 functions
        if ($printFunc && !$argIsSplit) {
            $printCalled = 1;
            printFunction();
        }

        # Calls the delete function for subset 0 functions
        elsif ($delFunc && !$argIsSplit) {
            $delCalled = 1;
            delFunction();
        }
        
        # Calls the substitute function for subset 0 functions
        elsif ($subFunc) {
            $subCalled = 1;
            subFunction(); 
        }

        
        # Manages the the functions with address range arguments
        if ($argIsSplit) {
            manageSplit();
        }
    
        # Terminates the program early if its condition is reached
        if ($quitCommand == 1) {
            executeQuit();
        }


        if ($subFunc && $subSwitch == 1 && $subAnswer ne "$line") {
            $answer = $subAnswer;
            $subCalled = 1;
        }
        print "delSwitch $delSwitch on line '$line'\n";
        if ($printSwitch == 1 && $delSwitch != 1) {
            executePrint();
        }
  
    }
   
    chomp($answer);
    chomp($subAnswer);

    # Prints either the substiuted line or newline depending on the 
    # parameter passed.
    
    if ($delSwitch != 1 && !$flagUsed) {
        if ($subSwitch == 1 && $subAnswer ne "$line") {
            $answer = $subAnswer;
            $subSwitch = 0;
            if ($printCount > 0) {
                $printCount--;
            }
            $line = $answer;
        }
        
        print "$answer\n";
    
    }
    $i = 0;

    $printCount = 0;
    # Resets function parameters if the 'capture' variable is disabled
    if ($delSwitch == 1 && $delCapture == 0) {
        $delSwitch = 0;  
    }
    
    if ($printSwitch == 1 && $capture == 0) {
        $printSwitch = 0;
    }
    
}


# This function reguates the quit command if it is called. 
sub quitFunction {
    $answer = $line;
    if ($argIsSplit) {
        print "speed: command line: invalid command\n";
        exit 1;
    }
    elsif ($argIsLastOnly && eof) {
        $quitCommand = 1;
    }
    
    elsif ($argIsNum && $. == $argument) {
        $quitCommand = 1;
    }
    elsif ($argIsRegex && $line =~ /${regex}/) {
        $quitCommand = 1;
    }

    if ($quitCommand == 1 && !$multipleComms) {
        print "$line";
        exit 0;
    }
}

# This function regulates the print function if it is called. 
sub printFunction {
    # command for the '$' address operator
    $answer = $line;
    if ($argIsLastOnly && eof) {
        print "$answer";
        if (!$flagUsed) {
            print "$answer";
        }
        exit 0;
    }
    
    # parameters for the '-n' address flag
    elsif ($flagUsed) {
        if ($argIsNum && $. == $argument) {
            $printSwitch = 1;
        } 
        elsif ($argIsRegex && $line =~ /${regex}/) {
            $printSwitch = 1;
        }
    }

    elsif ($argument eq "" && !$argIsLastOnly) {
        $printSwitch = 1;
    }
    elsif ($argIsNum && $. == $argument) {
        $printSwitch = 1;
    }
    elsif ($argIsRegex && $line =~ /${regex}/) {
        $printSwitch = 1;
    }
}

# This function manages the delete function if it is called.
sub delFunction {
    $answer = $line;
    if ($argument eq "") {
        exit 0;
    }
    # command for the '$' address operator
    if ($argIsLastOnly && eof) {
        exit 0;
    }  
    if ($argIsNum && $. == $argument) {
        $delSwitch = 1;
    }
    elsif ($argIsRegex && $line =~ /${regex}/) {
        $delSwitch = 1;
    }
}


# This function manages the substitute function if it is called.
sub subFunction {
    $subAnswer = $line;
    # removes the '/' to create a regex expression
    if ($argIsNum || $argIsRegex) {
        $argument =~ s/\///g;
    }
    elsif (!$argIsLastOnly) {
        $argument = "";
    }
    if ($line =~ /${regex}/ && !$argIsLastOnly) {
        $subAnswer = $line;
        $newLine = $line;
        
        # substiutes the regex matches in the line
        if ($modifier eq "g") {
            $newLine =~ s/${regex}/$substitute/g;
        }
        else {
            $newLine =~ s/${regex}/$substitute/;
        }
        # only applies for arguments that are not address ranges
        if ($argument ne "" && !$argIsSplit) {
            if ($argIsNum && $. == $argument) {
                $subSwitch = 1;
                $subAnswer = $newLine;
                # $line = $subAnswer;
                
            }
            elsif ($argIsRegex && $line =~ /${argument}/) {
                $subSwitch = 1;
                $subAnswer = $newLine;
                # $line = $subAnswer;
            }
            else {
                $subSwitch = 1;
            }
        }

        elsif ($argIsSplit) {
            if ($lowerIsNum && $upperIsNum && 
                $. >= $lower && $. <= $upper) {
                $subCapture = 1;
                $subSwitch = 1;
                $subAnswer = $newLine;
            }

            elsif ($lowerIsNum && $upperIsRegex && 
                   $. == $lower ... $line =~ /${upperRegex}/) {
                $subSwitch = 1;
                $subCapture = 1;
                $subAnswer = $newLine;
            }
            
            elsif ($lowerIsRegex && $upperIsRegex && 
                   $line =~ /${lowerRegex}/ ... $line =~ /${upperRegex}/) {
                $subSwitch = 1;
                $subCapture = 1;
            }

            if ($subSwitch == 1) {
                $subAnswer = $newLine;
                $subCapture = 1;
            }
            
        }

        else {
            $subAnswer = $newLine;
            $subSwitch = 1;
        } 
          
    }

    else {
        $subSwitch = 1;
    }       
}


# This function is reponsible for identifying the type of arguments
# being passed to it. It will then activate the right sentinel 
# variables, so that the arguments are processed as intended by the 
# user.
sub sortInputArgs {
    if ($argument =~ /^\$$/) {
        $argIsLastOnly = 1;
    }
    elsif ($argument =~ /^[0-9]+$/) {
        $argIsNum = 1;
    }

    # split arguments, with upper and lower bounds
    elsif ($argument =~ /(.*)\,(.*)/) {
        $lower = $1;
        $upper = $2;
        
        $argIsRegex = 1;
        $argIsSplit = 1;
        if ($lower =~ /^[0-9]+$/) {
            $lowerIsNum = 1;
        }
        elsif ($lower =~ /\/(.*)\//) {
            $lowerIsRegex = 1;
            $lowerRegex = $1;
        }

        if ($upper =~ /^[0-9]+$/) {
            $upperIsNum = 1;
        }
        elsif ($upper =~ /\/(.*)\//) {
            $upperIsRegex = 1;
            $upperRegex = $1;
        }
        
    }

    elsif ($argument =~ /\//) {
        $argIsRegex = 1;
        if (!$subFunc) {
            $regex = $argument;
        }
        
        $regex =~ s/\///g;
    }

    # Uses 'capture' variables to indicate to the main function when 
    # a line lies inbetween given address ranges.
    if ($argIsSplit) {
        assignCapture();
    }
}


# This function is called when implementing address ranges. It first 
# assigns a temporary 'capture' variable and then the program will
# check if the given line is currently inbetween the user specified
# address ranges. Capture will change to '1' (from 0) if so, and be
# reassinged to its functional equivalent.
sub assignCapture {
    if ($printFunc) {
        $capture = $printCapture;
    }
    elsif ($delFunc) {
        $capture = $delCapture;
    }
    elsif ($subFunc) {
        $capture = $subCapture;
    }

    if ($lowerIsNum && $upperIsNum) {
        # if ($. == $upper) {
        #     $lastCapture = 1;
        #     $capture = 0;
        # }
        if ($. >= $lower && $. <= $upper) {
            $capture = 1;
        }
        else {
            $capture = 0;
        }
        
    }

    elsif ($lowerIsRegex && $upperIsNum) {
        if ($line =~ /${lowerRegex}/) {
            $capture = 1;
        }

        elsif ($. == $upper && $capture == 1) {
            $lastCapture = 1;
            $capture = 0;
        }
        elsif ($printFunc) {
            if ($capture == 1) {
                $lastCapture = 0;
            }
            $capture = 0;
        }   
    }

    elsif ($lowerIsNum && $upperIsRegex) {
        
        $capture = 0;

        if ($. == $lower ... $line =~ /${upperRegex}/) {
            if ($line =~ /${upperRegex}/) {
                $lastCapture = 1;
            }
            $capture = 1;
        }
        else {
            $capture = 0;
        }
    }

    elsif ($lowerIsRegex && $upperIsRegex) {
        
        $capture = 0;
        $answer = $line;
        if ($line =~ /${lowerRegex}/ ... $line =~ /${upperRegex}/) {
            if ($line =~ /${upperRegex}/) {
                $lastCapture = 1;
            }
            $capture = 1;
        }
        else {
            $capture = 0;
        }

    }

    if ($printFunc) {
        $printCapture = $capture;
    }
    elsif ($delFunc) {
        $delCapture = $capture;
    }
    elsif ($subFunc) {
        $subCapture = $capture;
    }
}

# This function is called to manage all functions where an address ranges
# have been given as the parameters for the function. The relevent 
# 'switches' will be applied for the relevent functions. The 'capture' variable
# has been uniquely assigned to the functions so that they do not get mixed up
# when multiple commands are executed.
sub manageSplit {
    $answer = $line;
    chomp ($subAnswer);
    chomp ($line);

    if ($delFunc && $delCapture == 1) {
        $delSwitch = 1;
    }
    elsif ($delFunc && $delCapture == 0) {
        $delSwitch = 0;
    }
    # this allows for the line to still be printed at the end 
    # of the address range
    elsif ($printFunc && $lastCapture == 1) {
        $lastCapture = 0;
        $printSwitch = 1;
    }
    elsif ($printFunc && $printCapture == 1) {
        $printSwitch = 1;
    }
    # same but for the print function
    elsif ($subFunc && $subAnswer ne "$line" && $subCapture == 1) {
        $answer = $line;
        $subSwitch = 1;
    }
    elsif ($subFunc && $subAnswer ne "$line" && $lastCapture == 1) {
        $answer = $line;
        $subSwitch = 1;
    }
    
    if ($subSwitch == 1 && $argIsSplit && $delSwitch != 1) {
        if ($subCapture == 1 || $lastCapture == 1) {
            if ($lastCapture == 1) {
                $lastCapture = 0;
            }
        }
        else {
            $subSwitch = 0;
            $subAnswer = $answer; 
            $line = $answer;
        }
    }
}


# This function is called by the main function to exit the program. 
sub executeQuit {
    chomp($answer);
    # A print line on the same program would prevent a program quit.
    if ($delSwitch == 1) {
        $quitCommand = 0;
    }
    else {
        if ($printSwitch == 1) {
            print "$answer\n";
        }
        print "$answer\n";
        exit 0;
    }

}


# This function is called by the main function to print the current line. 
sub executePrint {
    chomp($line);
    if ($subCalled != 1) {
        print "$line\n";
    }
    $subCalled = 0;
    $printCount++;
    $printSwitch = 0;
}
