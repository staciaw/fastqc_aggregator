#!/usr/bin/perl

my $counts;
my $color;
my $min = 100;
my $max = 1;
my $over_flag = 0;

    
while (<>) {
	chomp;
	if ($over_flag && />>END_MODULE/) {
		goto STOP;
	}
	if ($over_flag) {
		($seq,$count,$per,$source) = split(/\s/);
		print "<TR> <TD>$seq</TD> <TD>$count</TD> <TD>$per</TD> <TD>$source</TD></TR>\n";
	}
	if (/>>Overrepresented sequences\s+(\w+)$/) {
		if ($1 eq "pass") {
			$color = "green";
		} elsif ($1 eq "warn") {
			$color = "yellow";
		} elsif ($1 eq "fail") {
			$color = "red";
		} else {
			print "$1 didn't match PROBLEM\n"; exit;
		}
		#print "col = $color\n";
	}
	if (/Possible/) {
		$over_flag = 1;
	}
}

STOP:
