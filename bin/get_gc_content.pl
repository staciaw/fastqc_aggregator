#!/usr/bin/perl

my $counts;
my $color;
my $gc_content_flag = 0;

    
while (<>) {
	chomp;
	if ($gc_content_flag && />>END_MODULE/) {
		goto STOP;
	}
	if ($gc_content_flag) {
		my ($qual,$count) = split(/\t/);
		$counts .= "$count,";
	}
	if (/>>Per base GC content\s+(\w+)$/) {
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
	if (/Base\s+%GC/) {
		$gc_content_flag = 1;
	}
}

STOP:
chop($counts);
print "col = $color\n($counts)\n";
