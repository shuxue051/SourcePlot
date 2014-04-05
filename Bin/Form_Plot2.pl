#函数层次图 
#调用关系图
#布局层次图
#read var $file_path
($file_path1,$file_path2)=@ARGV;
$file_path = $file_path1.$file_path2;

# $file_path= "D:\\SVN_Source_Dev\\Release_20140110\\050_Forms\\CIS_POLCHG_QUOTA.fmb" ;
$file_path=~m#\\([^\\]+)$#i;
$file_full_name=$1;
$file_path=~/^(([\d\D]*)\\)/i;
$file_pre_path=$1;
$file_full_name=~m#^(\w+)#i;
$file_name=$1;
#gen form txt
 $f_module= $file_path;
 $f_out_txt=$file_pre_path.$file_name.".txt";
 $FormsToolPath= "\"D:\\Program Files\\ORCL Toolbox\\FormsTool V2.0\\FormsTool.exe\"";
 $FormsToolCmd=$FormsToolPath."/explore /module=".$f_module."  /out=".$f_out_txt." /nostat";

 system $FormsToolCmd;
#print $FormsToolCmd;

#parse form txt
#$f_out_txt= "D:\\SVN_Source_Dev\\Release_20140110\\050_Forms\\CIS_POLCHG_QUOTA.txt";
$txt_file_path=$f_out_txt;
$^I =".bak";
#$file_path=~s#\\#\\\\#g;
#$file_pre_path=~s#\\#\\\\#g;

$info_path=$file_pre_path.$file_name."_info.txt";
$temp_path="c:\\temp.txt";
open (FH, $txt_file_path)
    or die "Can't open ".$txt_file_path.";, $!";
open FH2, ">", $temp_path
    or die "Can't open ".$temp_path.";, $!";
open FH_INFO, ">", $info_path
    or die "Can't open ".$info_path.";, $!";	
@input_txt=<FH>;
$input_txt= join '',@input_txt;
#print "@input_txt\n";	

#pre process   
$input_txt=~s#\n\s{53}~\s{2}##g;
#print FH2 "$input_txt";

@form_txt=split "\n",$input_txt;

#pre-process
($block_txt)=$input_txt=~/\n(\s{2}Block[\d\D]*?)\n\s{2}\w/;
($unit_txt)=$input_txt=~/\n(\s{2}Program Unit[\d\D]*?)\n\s{2}\w/;
($trigger_txt)=$input_txt=~/\n(\s{2}Trigger[\d\D]*?)\n\s{2}\w/;
($canvas_txt)=$input_txt=~/\n(\s{2}Canvas[\d\D]*?)\n\s{2}\w/;
($lov_txt)=$input_txt=~/\n(\s{2}LOV[\d\D]*?)\n\s{2}\w/;
($FormName)=($form_txt[0])=~/^\s*(\w+)\s*$/; 

@blocks=$block_txt=~/^\s{4}(\w+)/gm;   #block name
@units=$unit_txt=~/^\s{4}(\w+)/gm;     #unit name
@canvas=$canvas_txt=~/^\s{4}(\w+)/gm;     #canvas name
@lovs=$lov_txt=~/^\s{4}(\w+)/gm;     #lov name
#unit
%unit_txt = ($unit_txt =~ /\n\s{4}(\w+)[\d\D]*?\s{6}Program Unit Text\s{30}[*]?([\d\D]*?)\s{6}Program Unit Type/g);
%unit_typ = ($unit_txt =~ /\n\s{4}(\w+)[\d\D]*?\s{6}Program Unit Type\s{30}[*-]?\s*?(\w[\d\D]*?)\n/g);
#%unit_txt %unit_typ 忽略package spec
%unit_typ_color=("Function"=>"red",
                 "Procedure"=>"green",
				 "Package Body"=>"brown",
				 "FUNCTION"=>"red",
				 "PROCEDURE"=>"green",
				 "PACKAGE BODY"=>"brown",
				 "Package Spec"=>"brown",
				 "PACKAGE SPEC"=>"brown");
while (($key,$value)=each %unit_typ){
if ($value eq "Package Body"){
($tmp_txt)=($unit_txt =~ /\n\s{4}$key[\d\D]*?\s{6}Program Unit Text\s{30}[*]?(.*\n(\s{6}.*\n)*?)\s{6}Program Unit Type\s{30}[*]{1}  Package Spec\n/);
$pack_spec_txt{$key}=$tmp_txt;
#print FH2 $key."\n";
#print FH2 $tmp_txt."\n\n";
}
elsif ($value eq "Package Spec"){
$pack_spec_txt{$key}=$unit_txt{$key};
($tmp_unit_txt)=($unit_txt =~ /\n\s{4}$key[\d\D]*?\s{6}Program Unit Text\s{30}[*]?(.*\n(\s{6}.*\n)*?)\s{6}Program Unit Type\s{30}[*]{1}  Package Body\n/);
$unit_txt{$key}=$tmp_unit_txt;
#print FH2 $key."\n";
#print FH2 $tmp_unit_txt."\n\n";
}
}

# 有问题%pack_spec_txt=($unit_txt =~ /\n\s{4}(\w+)[\d\D]*?\s{6}Program Unit Text\s{30}[*]?([\d\D]*?)\s{6}Program Unit Type\s{30}[*]{1}  Package Spec\n/g);
#package spec fun
while (($key,$value)=each %pack_spec_txt){
#print FH2 $key."\n";
#print FH2 $value;
while($value=~/^\s*\b(?<fun_typ>function|procedure)\b\s+(?<fun>\w+)/igm){
my $spec_fun= $key."."."\U$+{fun_typ}".'|'.$+{fun};
$spec_fun{$spec_fun} =1;
#print FH2 $spec_fun."\n";
push @spec_funs,$spec_fun;
}
}
#list fun name 
while (($key,$value)=each %unit_txt){
#print FH2 $value; 
@temp_unit_funs=$value=~/^\s*\b(?:function|procedure)\b\s+(\w+)/igm;
for(@temp_unit_funs){ 
#print FH2 $key.'.'.$_."\n" if $_ ne $key;
push @unit_funs,$key.'.'.$_."\n" if $_ ne $key;
}
&proc_sub_unit2($value);
}

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
     @full_label=$unit_fun_full_name=~/\w+[|](\w+)/g;
	 $unit_trees_full_label{$unit_fun_full_name}=join '.',@full_label;	 
	}
#begin
  if ($test=~/^\s*\bbegin\b\s*/i) {
    $unit_fun_full_name=$fun[@fun-1];
	$unit_trees_start{$unit_fun_full_name}=$line_num;	
	}
#end if/end loop /end case
  if ($test=~/^(\s*)\bend\b(\s+)(\w+)(\s*);/i) 
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
#print FH2 $unit_trees_txt{"PBASSH006.PACKAGE BODY|pkg_cli_eval.FUNCTION|getKey"};
#sub callgraph
@unit_sub_funs= keys %unit_trees_typ;
while (my ($caller_fun,$caller_txt)=each %unit_trees_txt){
#print FH2 $caller_txt;
$caller_txt =~s#\/\*[\d\D]*?\*\/##g;
  for (@unit_sub_funs){ 
    my $called_fun=$_;
    my($is_true_call,$test_fun_nm,$call_typ)=&is_true_call($caller_fun,$called_fun);
    if ($is_true_call==1){	  
      if ($caller_txt=~/[^'](\b$test_fun_nm\b)[^']/i){
	  push @sub_callgraph,'"'.$caller_fun.'"'."->".'"'.$called_fun.'"';
	  push @sub_callgraph,'"'.$caller_fun.'"'.'[label="'.$unit_trees_full_label{$caller_fun}.'",color='.$unit_typ_color{$unit_trees_typ{$caller_fun}}.']';
	  push @sub_callgraph,'"'.$called_fun.'"'.'[label="'.$unit_trees_full_label{$called_fun}.'",color='.$unit_typ_color{$unit_trees_typ{$called_fun}}.']';
	  
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
if ($caller_fun_nm[0] eq $called_fun_nm[0]
  && $caller_fun_typ[0] eq 'PACKAGE BODY'
  && $called_fun_typ[0] eq 'PACKAGE BODY'
  && scalar @called_fun_nm == 2
  && $unit_trees_seqnum{$caller_fun} > $unit_trees_seqnum{$called_fun}){
  $is_true = 1;
  $call_typ = 2;
  $test_fun_nm=$called_fun_nm[-1];
  }
#3.package spec 
$test_spec_fun="\U$called_fun_nm[0]".".".$called_fun_typ[1].'|'.$called_fun_nm[1];
#print $test_spec_fun."\n";
if (scalar @called_fun_nm == 2 
#&& "\U$unit_typ{$called_fun_nm[0]}" eq "PACKAGE BODY"
&& $called_fun_typ[0] eq "PACKAGE BODY"
&& exists $spec_fun{$test_spec_fun}
){
$is_true = 1;
  if ($caller_fun_nm[0] eq $called_fun_nm[0]){
  $call_typ = 3.1;
  $test_fun_nm=$called_fun_nm[-1];
  }
  else{
  $call_typ = 3.2;
  $test_fun_nm= join '.',@called_fun_nm[0..1];
  }
}
#4.units(function/procedure)
if (scalar @called_fun_nm==1
#&& "\U$unit_typ{$called_fun_nm[0]}" ne "PACKAGE BODY"
&& $called_fun_typ[0] ne "PACKAGE BODY"
){
$is_true = 1;
$call_typ = 4;
$test_fun_nm=$called_fun_nm[-1];
}
#5.db objects

#return 
return ($is_true,$test_fun_nm,$call_typ);
}
#item
for (0..@blocks-1)
{
$curr_block = @blocks[$_];
#print $curr_block."\n";
($temp_block_txt)=$block_txt=~/\n\s{4}$curr_block[\d\D]*?\n\s{6}Item[\d\D]*?\n(\s{8}[\d\D]*?)\n\s{2,4}?\w/;

#@temp_block_items=$temp_block_txt=~/^\s{4}$curr_block[\d\D]*?\n\s{6}Item[\d\D]*?\n(\w+)/gm; 
@temp_block_items=$temp_block_txt=~/^\s{8}(\w+)/gm; 
#print FH2 $temp_block_txt."\n";
for (@temp_block_items)
{
$curr_item = $_;
push @block_items, $curr_block.".".$curr_item;  #block_item name
($temp_block_item_txt)=$temp_block_txt=~/\s{8}$curr_item\n\s{10}Trigger[\d\D]*?\n(\s{12}[\d\D]*?)\n\s{10}\w+/;
($item_prompt)=$temp_block_txt=~/\s{8}$curr_item\n[\d\D]*?\s{10}Prompt\s{37}[*-]?([\d\D]*?)\n\s{10}\w+/;
$item_prompt{$curr_item}=$item_prompt;
#print $item_prompt{$curr_item};

#print FH2 $temp_block_item_txt."\n";
@temp_block_item_trigers=$temp_block_item_txt=~/^\s{12}([\w-]+)/gm; 
my %temp_item_triger_txt =($temp_block_item_txt =~/\s{12}([\w-]+)[\d\D]*?\n\s{14}Trigger Text([\d\D]*)(?:\n\s{12})?/g);
  for (@temp_block_item_trigers)
  {
  push @block_item_triggers, $curr_block.".".$curr_item.".".$_;  #block_item_trigger name  
  }
 
 while (($key,$value) = each %temp_item_triger_txt){
 my $curr_unit_txt = $value;
 
 #print FH2 $curr_block.".".$curr_item.".".$key;
   for (@units){     
     if ($curr_unit_txt=~/(\b$_\b)/i) {	 
	 push @trigcallgraph,'"'.$curr_block."|".$curr_item."|".$key.'"'.'[shape=record,label="<f0>'.$curr_block.'|<f1>'.$curr_item.'|<f2>'.$key.'"]';	 
     push @trigcallgraph,$_.'[style=filled,color='.$unit_typ_color{$unit_typ{$_}}.']';
	 push @trigcallgraph,'"'.$curr_block."|".$curr_item."|".$key.'"'."->".$_ if $key ne $_;	 
	 }
   }
 }    
}
#print  "@temp_block_items\n";
}

#print FH2 $block_txt."\n"; 
#print $line_num="line_num:".@form_txt;

#****************output info txt
my $format = "The blocks are:(".scalar @blocks.")\n". ("  %-10s\n"x @blocks);
printf FH_INFO $format, @blocks;
my $format = "The items are:(".scalar @block_items.")\n". ("  %-30s\n"x @block_items);
printf FH_INFO $format, @block_items;
my $format = "The block_item_triggers are:(".scalar @block_item_triggers.")\n". ("  %-30s\n"x @block_item_triggers);
printf FH_INFO $format, @block_item_triggers;
my $format = "The units are:(".scalar @units.")\n". ("  %-10s\n"x @units);
printf FH_INFO $format, @units;
my $format = "The canvas are:(".scalar @canvas.")\n". ("  %-10s\n"x @canvas);
printf FH_INFO $format, @canvas;
my $format = "The lovs are:(".scalar @lovs.")\n". ("%  -10s\n"x @lovs);
printf FH_INFO $format, @lovs;

@item_prompt_key= keys %item_prompt;
@item_prompt_value= values %item_prompt;
foreach(@item_prompt_key)
{printf FH_INFO "  %-40s  \n",$_."            ".$item_prompt{$_};
}
while (($key, $value) = each %unit_typ){
print FH_INFO "$key => $value\n";
}
close  FH_INFO;

#print FH2 $unit_txt{'CHECK_IS_ANY_CHANGE'}."\n";
#*****************************#

#print FH2 "@units"."\n";  
 close  FH;
#print FH2 (values %unit_txt); 
#print FH2 (keys %unit_txt);
 
 #processing txt 
 while (($key,$value) = each %unit_txt){
 my $curr_unit_txt = $value; 
 $curr_unit_txt =~s#\/\*[\d\D]*?\*\/##g;
 #print FH2 $value;
   for (@units){
     #print $key."?".$_."\n";
     if ($curr_unit_txt=~/(\b$_\b)/i) {
     push @callgraph,$key."->".$_ if $key ne $_;
	 push @callgraph,$key.'[style=filled,color='.$unit_typ_color{$unit_typ{$key}}.']';
	 push @callgraph,$_.'[style=filled,color='.$unit_typ_color{$unit_typ{$_}}.']';
	 }
   }
 } 
 
  while (($key,$value) = each %unit_trees){
  push @unit_trees,'"'.$key.'"'."->".'"'.$value.'"';
 } 
  while (($key,$value) = each %unit_trees_label){
  push @unit_trees,'"'.$key.'"'.'[label="'.$value.'",color='.$unit_typ_color{$unit_trees_typ{$key}}.']';
 } 
 #print "@callgraph";
 close  FH2;
 #post process 
 
 #add legend
 sub add_legend{
 print LOG "subgraph cluster0{\n";
 while (($key,$value)=each %unit_typ_color){ 
 print LOG '"'.$key.'"'.'[color='.$value.'];'."\n";
 }
 print LOG 'label=legend;}'."\n"; 
 }
 #delete  duplicate record
 my %hash=();
 foreach (@callgraph) {
 $hash{$_}=1;
 }
 my @callgraph=sort keys %hash;
 
 my %hash=();
 foreach (@trigcallgraph) {
 $hash{$_}=1;
 }
 my @trigcallgraph=sort keys %hash;
 
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
dot_plot(write_dot(@callgraph,"callgraph"),"dot");
dot_plot(write_dot(@callgraph,"callgraph"),"fdp");
dot_plot(write_dot(@trigcallgraph,"trigcallgraph"),"dot");
dot_plot(write_dot(@trigcallgraph,"trigcallgraph"),"fdp");

dot_plot(write_dot(@unit_trees,"unit_trees"),"dot");
dot_plot(write_dot(@sub_callgraph,"sub_callgraph"),"dot");


