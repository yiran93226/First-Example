#!/usr/bin/perl -w
use warnings;
use strict;

my $exec_string = "perl assembleMech.pl";
my (@fuels) = @ARGV;
my ($baseMech, $thirdbodyMech);

my $flagAR = 0;
foreach (@fuels) {
	if ($_ eq "AR") {
		$baseMech = "base_AR.mech";
		$thirdbodyMech = "thirdbody_AR.mech";
		$flagAR = 1;
		last;
	}
}
if ($flagAR == 0) {
	$baseMech = "base.mech";
	$thirdbodyMech = "thirdbody.mech";	
}
$exec_string = $exec_string." ".$baseMech." depReac_base.mech";

# print "Enter the output file: ";
# my $outFile = <STDIN>; # I moved chomp to a new line to make it more readable
# chomp $outFile; # Get rid of newline character at the end
# exit 0 if ($outFile eq ""); # If empty string, exit.

my $message = "!!!Your outFile name (last entry) matches one of the existing file names!!!\n!!!Provide an alternative name!!!\n";

my $outFile = pop(@fuels);
if (($outFile eq "base.mech")||($outFile eq "depReac_base.mech")||($outFile eq "thirdbody.mech")) { die $message; }
if (($outFile eq "heptane_highT.mech")||($outFile eq "depReac_heptane_1.mech")) { die $message; }
if (($outFile eq "isooctane_highT.mech")||($outFile eq "depReac_isooctane.mech")) { die $message; }
if (($outFile eq "aromatics.mech")||($outFile eq "depReac_aromatics.mech")) { die $message; }
if (($outFile eq "dodecane_highT_minus_base.mech")||($outFile eq "depReac_dodecane_1.mech")||($outFile eq "dodecane_lowT.mech")) {
	 die $message; 
}
if (($outFile eq "methylcyclohexane_highT_minus_base.mech")||($outFile eq "depReac_methylcyclohexane.mech")||($outFile eq "methylcyclohexane_lowT.mech")) {
 	 die $message; 
}

print "Output file is: ",$outFile,"\n";
open(OUT, ">$outFile") or die "!! Cannot open file $outFile !!";
close(OUT);

my $flagArom = 0;
foreach (@fuels) {
	if ($_ =~ /aromatics/i) {$flagArom = 1; last;}
}

foreach (@fuels) {
	if ($_ =~ /NC7/i) {
		$exec_string = $exec_string." heptane_highT.mech depReac_heptane_1.mech";
	}
	if ($_ =~ /IC8/i) {
		$exec_string = $exec_string." isooctane_highT.mech depReac_isooctane.mech";
	}
	if ($_ =~ /aromatics/i) {
		$exec_string = $exec_string." aromatics.mech depReac_aromatics.mech";
	}
	if ($_ =~ /NC12/i) {
		$exec_string = $exec_string." dodecane_highT_minus_base.mech depReac_dodecane_1.mech";
		if ($_ =~ /NC12_LOWT/i){ $exec_string = $exec_string." dodecane_lowT.mech"; }
	}
	if ($_ =~ /MCH/i) {
		if ($flagArom == 0) {
			$exec_string = $exec_string." aromatics.mech depReac_aromatics.mech methylcyclohexane_highT_minus_base.mech depReac_methylcyclohexane.mech";			
		}
		else {$exec_string = $exec_string." methylcyclohexane_highT_minus_base.mech depReac_methylcyclohexane.mech";}
		if ($_ =~ /MCH_LOWT/i){ $exec_string = $exec_string." methylcyclohexane_lowT.mech"; }		
	}
}
$exec_string = $exec_string." $thirdbodyMech ";
$exec_string = $exec_string.$outFile;
print "Executing $exec_string\n";
system($exec_string);
