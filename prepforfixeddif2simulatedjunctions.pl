#!/bin/perl
use warnings;
use strict;
use POSIX;

#This script takes the output from "/home/owens/bin/reformat/ctab2prepforparentblocks.pl" and simulates samples with different junction densities. It uses the missing data patterns of my real samples and also simulates wrongly called identity using a bayesian strategy.

my $min_junctions_per_cm = 1;
my $max_junctions_per_cm = 10000;
my $increment = 1;
my $rep = 10; #Reps per species;
my $total_cm = 1394.91; #For XRQ annuus genome.
my $error_multiplier = 10;

my @species_list = ("Ano","Des","Par");
my %error;
$error{5}=0.007567428 * 2;
$error{6}=0.005486178 * 2;
$error{7}=0.004158341 * 2;
$error{8}=0.003259651 * 2;
$error{9}=0.002623258 * 2;
$error{10}=0.002156185 * 2;
$error{11}=0.00180328 * 2;

foreach my $key (sort keys %error) {
    $error{$key} = $error{$key}* $error_multiplier;
}

my %species;
$species{"Des1484"}="Des";
$species{"des2458"}="Des";
$species{"Sample_DES1476"}="Des";
$species{"Ano1495"}="Ano";
$species{"Sample_Ano1506"}="Ano";
$species{"Sample_des1486"}="Des";
$species{"Sample_Des2463"}="Des";
$species{"Sample_desA2"}="Des";
$species{"Sample_desc"}="Des";
$species{"king141B"}="Par";
$species{"king145B"}="Par";
$species{"king147A"}="Par";
$species{"King151"}="Par";
$species{"king152"}="Par";
$species{"King156B"}="Par";
$species{"Sample_king1443"}="Par";
$species{"Sample_king159B"}="Par";

my %name;
my %data;
my %site;
my %location;
my $counter;
my %err_hash;
#Load in site data including where missing data is.
while(<STDIN>){
  chomp;
  my @a = split(/\t/,$_);
  if ($. == 1){
    foreach my $i (4..$#a){
      $name{$i} = $a[$i];
    }
  }else{
    my $chr = $a[0];
    my $cm = $a[2];
    my $current_error = $error{$a[3]};
    if ($chr =~ m/Chr00/){next;}
    $counter++;
    $err_hash{$counter} = $current_error;
    $site{$counter} = $chr;
    $location{$counter} = $cm;
    foreach my $i (4..$#a){
      if ($a[$i] eq "N"){
        $data{$name{$i}}{$counter} = 0;
      }else{
        $data{$name{$i}}{$counter} = 1;
      }
    }  
  }
}

foreach my $current_species (@species_list){
  for (my $density = $min_junctions_per_cm; $density <=$max_junctions_per_cm; $density += $increment){
    my $junc_dist = 1 / $density;
    for (my $j = 1; $j <= $rep; $j+=1){
      my $junc_counter;
      my $start = rand($junc_dist);
      my $template = (keys %species)[rand keys %species];
      until($species{$template} eq $current_species){
        $template = (keys %species)[rand keys %species];
      }
      #Keep track of parentage using even and odd divisions of the increment;
      my $current_state;
      my $current_chr;
      foreach my $n (1..$counter){
        my $chr = $site{$n};
        unless($current_chr){
          $current_chr = $chr;
        }
        if ($current_chr ne $chr){
          undef($current_state);
          $current_chr = $chr;
        }
        
        if ($data{$template}{$n}){ #Only continue if it's got data in the template
          my $cm = $location{$n};
          my $true_state;
          if ($cm < $start){
            $true_state = 0;
          }else{
            my $window = floor(($cm - $start)/$junc_dist);
            if ($window % 2 == 0){
              $true_state = 2;
            }else{
              $true_state = 0;
            }
#print STDERR "\n$cm\t$window\t$true_state";
          }
#print "\n$cm\tTrue state is $true_state";
          my $accurate = 0; #Check to see if marker is randomly wrong.
	  my $rand = rand(1);
          if ($rand > $err_hash{$n}){
            $accurate = 1;
          }
#print "\taccuracy = $accurate";
          my $viewed_state;
          if ($accurate){
            $viewed_state = $true_state;
          }else{
            if ($true_state == 0){
              $viewed_state = 2;
            }else{
              $viewed_state = 0;
            }
          }
#print "\tViewed_state = $viewed_state";
          if (defined $current_state){
	    my $added_junc = abs($viewed_state - $current_state)/2;
            $junc_counter += $added_junc;
#print "\t+$added_junc";
            $current_state = $viewed_state;
          }else{
            $current_state = $viewed_state;
          }
        }
      }
      print "\n$current_species\t$template\t$density\t$junc_counter";
    }
  }
}

