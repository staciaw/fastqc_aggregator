#!/usr/bin/perl
use strict;
use warnings;
use File::Find;

# This script, given a directory, will scrape all subdirectories for fastQC output
# files (called "fastqc_data") and generate R code as output which, when piped through R,
# generates compiled data plots.

# USAGE: process_experiment.pl <directory_with_fastqc_outputs> <outputdir> | R --slave
# INPUT: a directory (first argument) that has multiple output files from FastQC for 
#	different samples
# OUTPUT: a directory (second argument) created by the script if it doesn't exist with the html 
#	and a subdirectory for the PNG images.

# Example (on osono.hci.utah.edu):\n";
# process_experiment.pl /Data01/gnomex/Analysis/experiment/103R /Data01/www/stacia_test/output | R --slave

if ($#ARGV < 1) {
	print "USAGE: process_experiment.pl <directory_with_fastqc_outputs> <outputdir> | R --slave\n\n";
	exit;
}

my @files;
my $exprnum;
my $start_dir = $ARGV[0];  # top level dir to search
find( 
    sub { if (/fastqc_data/) {push @files, $File::Find::name unless -d;} }, 
    $start_dir
);

my $outdir = $ARGV[1];
my $imgdir = $outdir."/Images/";
if (!-e $outdir) {
    print "dir.create('$outdir',mode='755')\n";
    print "Sys.chmod('$outdir','755')\n";
} 
if (!-e $imgdir) {
    print "dir.create('$imgdir',mode='755')\n";
    print "Sys.chmod('$imgdir','755')\n";
} 

print "system('cp html/fastqc_report.html $outdir/fastqc_report.html')\n";
my ($script,$legend_loc,$xlab,$ylab);
my $good_col = "darkgreen";
my $xsize = 675;
my $ysize = 675;
#========================================================================
my $f = $imgdir."per_base_quality.png";
print "f = '$f'\n";
print "png(f,height=$ysize,width=$xsize,pointsize=16)\n";
$script = "bin/get_base_qual.pl";
$legend_loc = "bottomleft";
$xlab = "Position in read";
$ylab = "Base quality";
&process($script,$legend_loc,$xlab,$ylab);
print "dev.off()\n";
print "Sys.chmod(f,'755')\n";

#========================================================================
$f = $imgdir."per_sequence_quality.png";
print "f = '$f'\n";
print "png(f,height=$ysize,width=$xsize,pointsize=16)\n";
$script = "bin/get_read_qual.pl";
$legend_loc = "topleft";
$xlab = "Quality score";
$ylab = "Number of reads";
&process($script,$legend_loc,$xlab,$ylab);
print "dev.off()\n";
print "Sys.chmod(f,'755')\n";

#========================================================================
$f = $imgdir."per_base_gc_content.png";
print "f = '$f'\n";
print "png(f,height=$ysize,width=$xsize,pointsize=16)\n";
$script = "bin/get_gc_content.pl";
$legend_loc = "bottomleft";
$xlab = "Position in read";
$ylab = "GC Content";
&process($script,$legend_loc,$xlab,$ylab);
print "dev.off()\n";
print "Sys.chmod(f,'755')\n";

#========================================================================
$f = $imgdir."per_sequence_gc_content.png";
print "f = '$f'\n";
print "png(f,height=$ysize,width=$xsize,pointsize=16)\n";
$script = "bin/get_gcseq_content.pl";
$legend_loc = "topleft";
$xlab = "GC content";
$ylab = "Number of reads";
&process($script,$legend_loc,$xlab,$ylab);
print "dev.off()\n";
print "Sys.chmod(f,'755')\n";

#========================================================================
$f = $imgdir."per_base_n_content.png";
print "f = '$f'\n";
print "png(f,height=$ysize,width=$xsize,pointsize=16)\n";
$script = "bin/get_n_content.pl";
$legend_loc = "topleft";
$xlab = "Position in read";
$ylab = "N content";
my $ylim = 30;
&process($script,$legend_loc,$xlab,$ylab,$ylim);
print "dev.off()\n";
print "Sys.chmod(f,'755')\n";

#========================================================================
$f = $imgdir."duplication_levels.png";
print "f = '$f'\n";
print "png(f,height=$ysize,width=$xsize,pointsize=16)\n";
$script = "bin/get_dup.pl";
$legend_loc = "topright";
$xlab = "Duplication level";
$ylab = "Percent of reads";
&process($script,$legend_loc,$xlab,$ylab);
print "dev.off()\n";
print "Sys.chmod(f,'755')\n";

#========================================================================
#========================================================================
sub process {
	my ($script,$legend_loc,$xlab,$ylab,$ylim) = @_;
	my $col = "";
	my $i = 1;
	my $bad_count = 0;
	my $color;
	my $pch = 0; 
	my $legend_txt = "";
	my $first = 1;
	my $maxstr;
	my $printstr = "";
	for my $file (sort @files) {
		open(F,"$script $file |");
	 	my $badflag = 0;
		my $x = "A".$i;
		$i++;
		while (<F>) {
			chomp;
			if (/green/ ) {
				    $color = $good_col;
			} elsif (/red/ || /yellow/) {
				if (/red/) { $color = "darkred"; }
				if (/yellow/) { $color = "orange"; }
				if ($col) {
					$col .= ",\"$color\"";
				} else {
					$col = "\"$color\"";
				}
				$bad_count++;
				$badflag = 1;
			} else {
				if ($badflag) {
					if ($file =~ /(\d+X\d+)\/\S+(R[12]{1})\D/) {
						if ($legend_txt) {
							$legend_txt .= ",\"$1-$2\"";
						} else {
							$legend_txt = "\"$1-$2\"";
				 		}
					} elsif ($file =~ /(\d+X\d+)\/fastqc/) {
						if ($legend_txt) {
							$legend_txt .= ",\"$1\"";
						} else {
							$legend_txt = "\"$1\"";
				 		}
					}
				}

				print $x," = c",$_,"\n";
				if ($first) {
					$maxstr = "m=max(A1";
					my $num_datasets = 1 + $#files;
					if ($color eq $good_col) {
					$printstr .=  "plot(seq(1,length(".$x.")),".$x.",ylab='$ylab',xlab='$xlab',type='l',col='$color',";
					$printstr .= "xlim=c(1,length(".$x.")),ylim=c(0,m), main='$num_datasets datasets',lwd=.35)\n";
					} else {
					$printstr .=  "plot(seq(1,length(".$x.")),".$x.",ylab='$ylab',xlab='$xlab',type='l',col='$color',";
					$printstr .= "xlim=c(1,length(".$x.")),ylim=c(0,m), main='$num_datasets datasets',cex=.50,pch=$pch)\n";
					$pch++;
					}
					$first = 0;
				}else {
					$maxstr .= ",$x";
					if ($color eq $good_col) {
						$printstr .=  "points(".$x.",type='l',lwd=.45,col='$color')\n";
					} else {
						$printstr .=  "points(".$x.",type='o',col='$color',cex=0.5,pch=$pch)\n";
						$pch++;
					}
				}
			}
		}
		close(F);
	}
	print $maxstr,")\n";
	if ($ylim) { print "m=$ylim\n"; }
	print $printstr;
	if ($legend_txt) {
		my $ncol = int($bad_count / 12) + 1;
		print "legend('$legend_loc',legend=c($legend_txt),title='Samples that failed/had warning',text.col=c($col),ncol=$ncol,pch=seq(1,$bad_count),lwd=1,cex=0.75)\n";
	}
}

# no recollection what this is for
sub process_table {
	my ($script,$legend_loc,$xlab,$ylab,$ylim) = @_;
	my $col = "";
	my $i = 1;
	my $bad_count = 0;
	my $color;
	my $pch = 0; 
	my $legend_txt = "";
	my $first = 1;
	my $maxstr;
	my $printstr = "";
	for my $file (sort @files) {
		open(F,"$script $file |");
	 	my $badflag = 0;
		my $x = "A".$i;
		$i++;
		while (<F>) {
			chomp;
			if (/green/ ) {
				    $color = $good_col;
			} elsif (/red/ || /yellow/) {
				if (/red/) { $color = "darkred"; }
				if (/yellow/) { $color = "orange"; }
				if ($col) {
					$col .= ",\"$color\"";
				} else {
					$col = "\"$color\"";
				}
				$bad_count++;
				$badflag = 1;
			} else {
				if ($badflag) {
					if ($file =~ /(\d+X\d+)\/\S+(R[12]{1})\D/) {
						if ($legend_txt) {
							$legend_txt .= ",\"$1-$2\"";
						} else {
							$legend_txt = "\"$1-$2\"";
				 		}
					} elsif ($file =~ /(\d+X\d+)\/fastqc/) {
						if ($legend_txt) {
							$legend_txt .= ",\"$1\"";
						} else {
							$legend_txt = "\"$1\"";
				 		}
					}
				}

				print $x," = c",$_,"\n";
				if ($first) {
					$maxstr = "m=max(A1";
					my $num_datasets = 1 + $#files;
					$printstr .=  "plot(seq(1,length(".$x.")),".$x.",ylab='$ylab',xlab='$xlab',type='l',col='$color',";
					$printstr .= "xlim=c(1,length(".$x.")),ylim=c(0,m), main='$num_datasets datasets',cex=.50,lwd=.35)\n";
					$first = 0;
				}else {
					$maxstr .= ",$x";
					if ($color eq $good_col) {
						$printstr .=  "points(".$x.",type='l',lwd=.35,col='$color',cex=0.5)\n";
					} else {
						$printstr .=  "points(".$x.",type='o',col='$color',cex=0.5,pch=$pch)\n";
						$pch++;
					}
				}
			}
		}
		close(F);
	}
		print $maxstr,")\n";
		if ($ylim) { print "m=$ylim\n"; }
		print $printstr;
	if ($legend_txt) {
		my $ncol = int($bad_count / 12) + 1;
		print "legend('$legend_loc',legend=c($legend_txt),text.col=c($col),ncol=$ncol,pch=seq(1,$bad_count),lwd=1,cex=0.75)\n";
	}
}


