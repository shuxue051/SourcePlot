
($file_path,$spec_file_path)=@ARGV;
$file_path=~m#\\([^\\]+)$#i;
$file_full_name=$1;
$file_path=~/^(([\d\D]*)\\)/i;
$file_pre_path=$1;
$file_full_name=~m#^(\w+)#i;
$file_name=$1;

$file_path=~s#\\#\\\\#g;
$file_pre_path=~s#\\#\\\\#g;
%unit_typ_color=("Function"=>"red",
                 "Procedure"=>"green",
				 "Package Body"=>"brown",
				 "FUNCTION"=>"red",
				 "PROCEDURE"=>"green",
				 "PACKAGE BODY"=>"brown");
open (FH, $file_path)
    or die "Can't open ".$file_full_name.";, $!";
$spec_file_path=$file_pre_path.substr($file_name,0,length($file_name)-5).'.sql';	
if ( -e $spec_file_path){	
open (FH_SPEC, $spec_file_path)
    or die "Can't open ".$spec_file_path.";, $!";	
@spec_input_txt=<FH_SPEC>;
}
	
@input_txt=<FH>;
$input_txt= join '',@input_txt;

$spec_input_txt= join '',@spec_input_txt;
$temp_path="c:\\temp.txt";
open FH2, ">", $temp_path
    or die "Can't open ".$temp_path.";, $!";
#spec_fun
while($spec_input_txt=~/^\s*\b(?<fun_typ>function|procedure)\b\s+(?<fun>\w+)/igm){
my $spec_fun= "\U$+{fun_typ}".'|'.$+{fun};
$spec_fun{$spec_fun} =1;
print FH2 $spec_fun."\n";
push @spec_funs,$spec_fun;
}

&proc_sub_unit2($input_txt);
sub proc_sub_unit2{
my ($fun_txt)=@_;
my @fun_txt=split "\n",$fun_txt;
@fun=();
my $seq_num=0;
for (0..@fun_txt-1){
$line_num=$_;
$test = $fun_txt[$_];

#function procedure package body
if ($test=~/^\s*(?<funtyp>(package body)|function|procedure)\s+(?<fun>\w+)(\s*)/i)
  {  
    if (@fun==0){
	$parent=$file_name;}
    else{    
    $parent= $fun[@fun-1];}
	$unit_fun_full_name = $parent.'.'."\U$+{funtyp}".'|'."$+{fun}";
	push @fun, $unit_fun_full_name;	
	$seq_num++;
	#print $unit_fun_full_name."\n"; 
	 $unit_trees{$unit_fun_full_name}=$parent;
	 $unit_trees_label{$unit_fun_full_name}=$+{fun};
	 $unit_trees_typ{$unit_fun_full_name}="\U$+{funtyp}";
	 $unit_trees_depth{$unit_fun_full_name}=scalar @fun;
	 $unit_trees_seqnum{$unit_fun_full_name}=$seq_num;	 
	}
#begin
  if ($test=~/^\s*\bbegin\b\s*/i) {
    $unit_fun_full_name=$fun[@fun-1];
	$unit_trees_start{$unit_fun_full_name}=$line_num;	
	}
#end if/end loop /end case
  if ($test=~/^(\s*)\bend\b(\s+)(\w+)(\s*)/i) 
  {   
	$tmp= $3;
	unless ($tmp=~/(\bif\b|\bloop\b|\bcase\b)/i) 
	{
	$funnm=pop @fun;
	
	if (exists $unit_trees_start{$unit_fun_full_name}){
	my $txt_start=$unit_trees_start{$unit_fun_full_name};
	$unit_trees_txt{$unit_fun_full_name}=join "\n",@fun_txt[$txt_start..$line_num-1];	
	delete $unit_trees_start{$unit_fun_full_name};
	}	
	}	
  }  	
#end ;
#if ($test=~/^\s*\bend\b\s*(?!(loop|if|case))\s*[;]{1}/i) 
if ($test=~/^(\s*)\bend\b(\s*);/i) 
  { 
	$funnm=pop @fun;
	
    if (exists $unit_trees_start{$unit_fun_full_name}){	
	my $txt_start=$unit_trees_start{$unit_fun_full_name};
	$unit_trees_txt{$unit_fun_full_name}=join "\n",@fun_txt[$txt_start..$line_num-1];	
	delete $unit_trees_start{$unit_fun_full_name};
	}
  }  
}
}	
#sub callgraph
print FH2 keys %unit_trees_txt;
print FH2 $unit_trees_txt{"cas_bas_sc_query_body.PROCEDURE|stat_pbassh011"};
@unit_sub_funs= keys %unit_trees_typ;
while (my ($caller_fun,$caller_txt)=each %unit_trees_txt){
#print FH2 $caller_txt;
  for (@unit_sub_funs){ 
    my $called_fun=$_;
    my($is_true_call,$test_fun_nm,$call_typ)=&is_true_call($caller_fun,$called_fun);
    if ($is_true_call==1){	  
      if ($caller_txt=~/[^'](\b$test_fun_nm\b)[^']/i && $caller_fun){
	  push @sub_callgraph,'"'.$caller_fun.'"'."->".'"'.$called_fun.'"';
	  push @sub_callgraph,'"'.$caller_fun.'"'.'[label="'.$unit_trees_label{$caller_fun}.'",color='.$unit_typ_color{$unit_trees_typ{$caller_fun}}.']';
	  push @sub_callgraph,'"'.$called_fun.'"'.'[label="'.$unit_trees_label{$called_fun}.'",color='.$unit_typ_color{$unit_trees_typ{$called_fun}}.']';
	  }
    }
  }
}

sub is_true_call{
my ($caller_fun,$called_fun)=@_;
@caller_fun_nm=$caller_fun=~/\.(?:.*?)\|(\w+)/g;
@caller_fun_typ=$caller_fun=~/\.(.*?)\|(?:\w+)/g;
@called_fun_nm=$called_fun=~/\.(?:.*?)\|(\w+)/g;
@called_fun_typ=$called_fun=~/\.(.*?)\|(?:\w+)/g;
my $is_true=0;
my $call_typ;
my $test_fun_nm;
#1.sub funs
if (length $caller_fun <length $called_fun
 && substr($called_fun,0,length($caller_fun)) eq $caller_fun){
$is_true = 1;
$call_typ = 1;
$test_fun_nm=$called_fun_nm[-1];
}
#2.pre funs ***same package body**
if (scalar @called_fun_nm == 1
  && $unit_trees_seqnum{$caller_fun} > $unit_trees_seqnum{$called_fun}){
  $is_true = 1;
  $call_typ = 2;
  $test_fun_nm=$called_fun_nm[-1];
  }
#3.package spec 
$test_spec_fun=$called_fun_typ[0].'|'.$called_fun_nm[0];
#print $test_spec_fun."\n";
if (scalar @called_fun_nm == 1
&& exists $spec_fun{$test_spec_fun}
){
$is_true = 1;
  $call_typ = 3.1;
  $test_fun_nm=$called_fun_nm[-1];

}
#4.db objects

#return 
return ($is_true,$test_fun_nm,$call_typ);
}

#post_proc
  while (($key,$value) = each %unit_trees){
  push @unit_trees,'"'.$key.'"'."->".'"'.$value.'"';
 } 
  while (($key,$value) = each %unit_trees_label){
  push @unit_trees,'"'.$key.'"'.'[label="'.$value.'",color='.$unit_typ_color{$unit_trees_typ{$key}}.']';
 } 

 my %hash=();
 foreach (@sub_callgraph) {
 $hash{$_}=1;
 }
 my @sub_callgraph=sort keys %hash;
 
 #file output
 sub write_dot(\@$){
 my ($ref_callgraph,$post_file_name) = @_;
 my  @dotgraph = @{$ref_callgraph}; 
 my $dot_file_name = $file_name.'_'.$post_file_name;
 my $dot_file_path = $file_pre_path.$dot_file_name.".dot";
 open LOG, ">", $dot_file_path;
 print LOG "digraph ".$dot_file_name."{";
 foreach (0..@dotgraph){
 print LOG $dotgraph[$_].";\n" if $dotgraph[$_];
 }
 print LOG "}";
 close LOG; 
 return $dot_file_path;
 } 
#plot graph
sub dot_plot{
(my $data_path,my $plot_typ)= @_;
my ($out_typ) = $data_path=~m#([\w_]*?)[.]{1}\w+?$#;
my $dot_path = "\"D:\\Program Files\\Graphviz2.30\\bin\\".$plot_typ.".exe\"" ;
my $out_path = $file_pre_path.$out_typ."_".$plot_typ.".png";
system $dot_path." -Grankdir=LR -Tpng ".$data_path." -o ".$out_path;
my $out_path = $file_pre_path.$out_typ."_".$plot_typ.".svg";
system $dot_path." -Grankdir=LR -Tsvg ".$data_path." -o ".$out_path;
}

dot_plot(write_dot(@unit_trees,"unit_trees"),"dot");
dot_plot(write_dot(@sub_callgraph,"sub_callgraph"),"dot");