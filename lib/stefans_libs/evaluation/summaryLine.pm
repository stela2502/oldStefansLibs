package summaryLine;
#  Copyright (C) 2008 Stefan Lang

#  This program is free software; you can redistribute it 
#  and/or modify it under the terms of the GNU General Public License 
#  as published by the Free Software Foundation; 
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful, 
#  but WITHOUT ANY WARRANTY; without even the implied warranty of 
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License 
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

use strict;

sub new {

   my ( $class, $organism, $celltype, $antibody, $filename, $data_length ) = @_;

   my ( $self );

#   print "init summaryLine $organism, $celltype, $antibody, $filename, $data_length\n";

   die "bitte die Organismus Art angeben \n" unless ( defined $organism );
   die "bitte die Zelltyp Art angeben \n" unless ( defined $celltype );
   die "bitte den verwendeten Antikörper angeben \n" unless ( defined $antibody );
   die "bitte den Datei Namen angeben \n" unless ( defined $filename );
   die "bitte die Länge der Daten angeben \n" unless ( defined $data_length );

   $self = {
     organism => $organism,
     celltype => $celltype,
     antibody => $antibody,
     gbFilename => $filename,
     data_length => $data_length,
     'V-count' => 0,
     'D-count' => 0,
     'J-count' => 0,
     'V-start' => undef,
     'D-start' => undef,
     'J-start' => undef,
     'V-end' => undef,
     'D-end' => undef,
     'J-end' => undef,
     'V-total' => undef,
     'D-total' => undef,
     'J-total' => undef,  
   };

   foreach my $key (keys %$self){
      next if ( defined $self->{$key});
      my @temp;
      for (my $i = 0; $i < $data_length; $i++){
        $temp[$i] = 0;
      }
      $self->{$key} = \@temp;
   }

   bless ($self , $class ) if ( $class eq "summaryLine");
   return $self;
}

sub AddData{
  my ( $self, $tableLine_activationState_array ) = @_;
  my ( $activationState, $sumary, $actual, $myDataArray);
#  print "AddData:::\n";
  foreach $activationState (@$tableLine_activationState_array){
#      print "match to -$activationState->{match_to}-\n";
      $sumary = $activationState->{summary_data};
      $actual = $activationState->{Ig_type};
      $self->{"$actual-count"} ++ if ( $activationState->{match_to} eq "start");
      $actual = "$actual-$activationState->{match_to}";
      $myDataArray = $self->{$actual};
      for ( my $i = 0; $i < @$sumary; $i++){
        @$myDataArray[$i] ++ if ( defined @$sumary[$i] && @$sumary[$i] > 0);
#        print "$i($activationState->{Ig_type}): $activationState->{Ig_type}-count |$self->{\"$activationState->{Ig_type}-count\"}| new @$sumary[$i] , here @$myDataArray[$i] \n";
      }
  }
}

sub PrintHelp{
  my ( $self) = @_;
  return "where did the enriched regions match to the Ig or TCR sequences?\npossible matches are:\nstart (5 prime region)\nend (in the 3 prime region)\ntotal (all over the segment)\n\n\n";

}

sub PrintHeader{
  my ( $self ) = @_;
  my ( $string, $return);

  $string = "organism\tcelltype\tantibody\tsequence type {V,D,J}\tfilename";
  for ( my $i = 0; $i < $self->{data_length};$i++){
    $string = "$string\tstart Iteration Nr. $i";
  }
  $string = "$string\t\tfilename";
  for ( my $i = 0; $i < $self->{data_length};$i++){
    $string = "$string\tend Iteration Nr. $i";
  }
  $string = "$string\t\tfilename";
  for ( my $i = 0; $i < $self->{data_length};$i++){
    $string = "$string\ttotal Iteration Nr. $i";
  }
  $string = "$string\n";
  return $string;
}

sub SummaryHeader{
  my ( $self ) = @_;
  return "filename\tV segments\tD segemnts\tJ segments\n";
}

sub SummaryData{
  my ( $self ) = @_;
  return "$self->{gbFilename}\t$self->{'V-count'}\t$self->{'D-count'}\t$self->{'J-count'}\n";
}

sub PrintData{
  my ( $self) = @_;
  my ( $string , $return, $variable);

  $string = "$self->{organism}\t$self->{celltype}\t$self->{antibody}\tV\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"V-start"}, $self->{'V-count'});
  $string = "$string$variable\t\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"V-end"}, $self->{'V-count'});
  $string = "$string$variable\t\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"V-total"}, $self->{'V-count'});
  $string = "$string$variable\n";
  $return->{V} = "$string";

  $string = "$self->{organism}\t$self->{celltype}\t$self->{antibody}\tD\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"D-start"}, $self->{'D-count'});
  $string = "$string$variable\t\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"D-end"}, $self->{'D-count'});
  $string = "$string$variable\t\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"D-total"}, $self->{'D-count'});
  $string = "$string$variable\n";
  $return->{D} = "$string";

  $string = "$self->{organism}\t$self->{celltype}\t$self->{antibody}\tJ\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"J-start"}, $self->{'J-count'});
  $string = "$string$variable\t\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"J-end"}, $self->{'J-count'});
  $string = "$string$variable\t\t$self->{gbFilename}\t";
  $variable = $self->getVariable($self->{"J-total"}, $self->{'J-count'});
  $string = "$string$variable\n";
  $return->{J} = "$string";

  return $return;
}

sub getVariable{
  my ( $self, $var_array, $var_divisor ) = @_;

  my @return;

  for ( my $i = 0; $i < @$var_array; $i++){
    $return[$i] = (@$var_array[$i] / $var_divisor) * 100 if ( $var_divisor != 0);
    $return[$i] = "-" if ( $var_divisor == 0);
  }
  return join("\t",@return);
}

1;
