#!/usr/bin/perl -w
use warnings;
use strict;

#### Usage ####
#perl assembleMech.pl baseMech heptaneMech depMech1 depMech2 depMech3 ... outFile                          
###############

if( $ARGV[0] eq '-h' || $ARGV[0] eq '-help') {
	help();
	exit; 
}

open(CHECK, ">outCheck") or die "!! Cannot open file outCheck !!";

my (@mechs) = @ARGV;
my $outFile = pop(@mechs);
my @allReacs;
gatherAllReacs();

# Remove any duplicates
my @tmp = @allReacs;
@allReacs = ();
my $totl = 0;
@allReacs = @{rmDuplicates(@tmp)};

# Print reactions in a neat way
# print "Max length: ",$totl,"\n";
printReactions();
close(CHECK);

sub gatherAllReacs {
	# Gather all reactions
	# Don't worry about organizing them
	foreach (@mechs) {
		open(REACS, "<$_") or die "!! Cannot open file $_ !!";
		my @reacs = <REACS>;
		push (@allReacs, @reacs);
		close(REACS);	
	}
}

sub getLength {
	
	my ($tmp) = @_;
	my $len;
	
	chomp($tmp);
#	$tmp =~ s/\s+//g;
	if ($tmp =~ /}/) {
		my @tmp1 = split('}',$tmp);
	    $len = 1+length($tmp1[0]);
	}
	else {$len = length($tmp);}
	
	return $len;
}

sub rmDuplicates {
    
	my (@array) = @_;
    my @unique = ();
    my %seen   = ();
	my $flag = 0;
	my $tag = "";
	
	foreach (@array) {
		
		my $reac = $_;
		chomp($reac);
		
		# Dealing with comments
		# We will remove those reactions which have been commented out
		# Those you want to keep as comments - put ## at the beginning
		if ($_ =~ /^\#\#/) { $tag = $tag.$_; next;} 
		if (($_ =~ /^\#/)&&($_ =~ /:/)) {next; }
		
		# Remove new lines - we will add them as needed
		if (($_ eq "\n")||($_ eq "\#\n")) {next;}
		
		# Record relevant comments
		if ($_ =~ /^\# \#/) {next;}
		if ($_ =~ /^\#/) { 
			$tag = $tag.$_;
			next; 
		}
		
		if ($_ =~ /^Let/i) {
			if ($tag ne "") {
				push (@unique, $tag);
				$tag = "";
			}
			push (@unique, $_);
			$flag = 0;
			next;		
		}
		
		# For pressure dependent reactions
		if (($_ !~ /{/)||($_ =~ /fca/i)||($_ =~ /fcb/i)||($_ =~ /fcc/i)) {
			if ($flag == 0) { # These coefficients corresponds to a unique reaction
			    #print CHECK "Possible problematic reaction:\n!!! $_ !!!\n";
				push (@unique, $_);
				next;
			}
			else {next;}			
		}
		
		# 
        if (!exists($seen{$reac})) {
		    # Write proper comments
			if ($tag ne "") {
				push (@unique, $tag);
				$tag = "";
			}
			$flag = 0;
        	$seen{$reac} = 1;
	        push (@unique, $_);
			# print CHECK "!!! Unique reaction identified: !!!\n$_\n"; 			
			
			my $tmp = $_;
			my $len = getLength($tmp);
			if ($len>$totl) {$totl = $len;}
        }
		else {
			# print CHECK "!!! Duplicate identified: !!!\n$_\n"; 
			$flag = 1;
			next;
		}
				
	}
	
	#print $_,"\n" foreach (@unique);
	
	return \@unique;
}

# Print each mech in a neat way
sub printReactions {
	open (OUT, ">$outFile") or die "!!! Cannot open $outFile to write !!!";
	
	foreach (@allReacs) {
		if ($_ =~ /^\#/){
			print OUT "\n\n",$_,"\n";
		}
		else { print OUT beautifyReac($_); }
	}
	
	close (OUT);
}

sub splitNumChar {
	my ($spname) = @_;
	if ($spname =~ /^(\d)([A-Z])/) {
		print CHECK $spname,"--> \t"; 
		my $num = $1; my $char = $2; 
		$spname =~ s/$num$char/$num $char/; 
		print CHECK $spname,"\n";
	}
	return $spname;
	
}
sub beautifyReac {
	my ($reac) = @_;
	my $beautyReac;
	
	if ($reac =~ /:/) { # Proper reaction, meaning not the pressure dependent lines
		$beautyReac = getLabel($reac).": ";

		my @reactants = @{getReacSpec($reac)};
		my @products = @{getProdSpec($reac)};

		for my $i (0 .. $#reactants) {
			$reactants[$i] = splitNumChar($reactants[$i]);
			$beautyReac = $beautyReac.$reactants[$i]." ";
			if (!($i == $#reactants)) {$beautyReac = $beautyReac."+ ";}
		}
		# print "After reactants: ",$beautyReac,"\n";
		
		$beautyReac = $beautyReac."-\> ";
		for my $i (0 .. $#products) { 
			$products[$i] = splitNumChar($products[$i]);	
			$beautyReac = $beautyReac.$products[$i]." ";
			if (!($i == $#products)) {$beautyReac = $beautyReac."+ ";}
		}
		# print "After products: ",$beautyReac,"\n";
		
		# Regularize A = , n = , E = 
		my @tmp = split('{',$reac);
		my $rate = "\{".$tmp[1];
		$rate =~ s/\s+//g;
		$rate =~ s/a=/ A = /i; 	$rate =~ s/ai=/ Ai = /i;
		$rate =~ s/n=/ n = /i;  $rate =~ s/ni=/ ni = /i;
		$rate =~ s/e=/ E = /i;  $rate =~ s/ei=/ Ei = /i; 		
		$rate =~ s/\}/ \}/;
		
		my $tmp1 = $beautyReac.$rate;
		my $len = getLength($tmp1);
		my $slen = $totl-$len; 
		for my $i (1 .. $slen) {$beautyReac = $beautyReac." ";}
		$beautyReac = $beautyReac.$rate."\n";
		
		# print "At end: ",$beautyReac,"\n\n";
		#die "\n\nEnd of one beauty\n\n";
	}
	else {
		$beautyReac = $reac;
		if (($beautyReac =~ /=/)&&($beautyReac !~ /Let/i)) {
			$beautyReac =~ s/^\s+//g;
			my $tmp1 = $beautyReac;
			my $len = getLength($tmp1);
			my $slen = $totl-$len; 
			for my $i (1 .. $slen) {$beautyReac = " ".$beautyReac;}			
		}
		
	}
	
	# print "At end: ",$beautyReac,"\n\n";
	return $beautyReac;
}

sub getReacSpec {
	my ($currReac) = @_;
	$currReac =~ s/\s+//g;
	my @tmp1 = split(':',$currReac);
	my @tmp2 = split('->',$tmp1[1]); #Left of -> is captured
    my $shortReac = $tmp2[0];
	my @tmp3 = split('\+',$shortReac);
	return \@tmp3;
}

sub getProdSpec {
	my ($currReac) = @_;
	$currReac =~ s/\s+//g;
	my @tmp1 = split(':',$currReac);
	my @tmp2 = split('->',$tmp1[1]); #Right of -> is captured
	my @tmp3 = split('{',$tmp2[1]); #Left of { is captured
    my $shortReac = $tmp3[0];
	my @tmp4 = split('\+',$shortReac);
	return \@tmp4;
}

sub getLabel {
	my ($currReac) = @_;
	$currReac =~ s/\s+//g;
	my @tmp1 = split(':',$currReac);
	return $tmp1[0];
}