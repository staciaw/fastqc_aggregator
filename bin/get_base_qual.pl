#!/usr/bin/perl

my $nums;
my $color;
my $flag = 0;

    
while (<>) {
    if ($flag && />>END_MODULE/) {
		goto STOP;
	}
	if ($flag) {
   		my ($loc,$num) = split(/\t/);
        $nums .= "$num,";
    }
    if (/>>Per base sequence quality\s(\w+)$/) {
    	if ($1 eq 'pass') {
       		$color = "green";
        } elsif ($1 eq 'warn') {
        	$color = "yellow";
        } elsif ($1 eq 'fail') {
        	$color = "red";
        } else {
            ;
        }
    }
    if (/Mean/) {
    	$flag = 1;
    }
}

STOP:
chop($nums);
print "col = $color\n($nums)\n";

