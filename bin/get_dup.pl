#!/usr/bin/perl

my $counts;
my $color;
my $dup_flag = 0;

    
while (<>) {
	chomp;
	if ($dup_flag && />>END_MODULE/) {
		goto STOP;
	}
	if ($dup_flag) {
		my ($qual,$count) = split(/\t/);
		$counts .= "$count,";
	}
	if (/>>Sequence Duplication Levels\s+(\w+)$/) {
		if ($1 eq "pass") {
			$color = "green";
		} elsif ($1 eq "warn") {
			$color = "yellow";
		} elsif ($1 eq "fail") {
			$color = "red";
		} else {
			print "$1 didn't match PROBLEM\n"; exit;
		}
	}
	if (/Relative/) {
		$dup_flag = 1;
	}
}

STOP:
chop($counts);
print "col = $color\n($counts)\n";
