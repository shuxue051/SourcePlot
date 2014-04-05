use DBI;
($connectStr)=@ARGV;
if ($connectStr eq ''){
print "please input DataBase connection string,like CAS/**/DEV**:\n";
chomp($connectStr=<STDIN>);
}

print "please input package name for Analytics,such as CAS_BAS_SC_UTL:\n";
chomp($package_name=<STDIN>);
$package_name="\U$package_name";
#$package_name = 'JET_ISSUE';
$connectStr=~m#(\w+)\/(\w+)@(\w+)#;
$user=$1;
$passwd=$2;
$dbname=$3;
#print $dbname.','.$user.','.$passwd;
#$dbname="dev03";
#$user="CAS";
#$passwd="dev031130";
$dbh="";
$dbh = DBI->connect("dbi:Oracle:$dbname",$user,$passwd) or die "can't connect to
database ". DBI-errstr;

$file_name=$package_name;
$sqlStr= "select text 
         from dba_source 
		 where type='PACKAGE' 
		 and name = '".$package_name ."' order by line";
$sqlStr_body= "select text 
         from dba_source 
		 where type='PACKAGE BODY' 
		 and name = '".$package_name."' order by line";

$sqlStr_dep="select src.line, src.TEXT, arg.PACKAGE_NAME || '.' || arg.OBJECT_NAME
  from dba_source src,
       (select distinct PACKAGE_NAME, OBJECT_NAME, owner from dba_arguments) arg
 where exists
 (select null
          from dba_dependencies dep
         where dep.owner = src.owner
           and dep.type = src.TYPE
           and dep.name = src.name
           and arg.owner = dep.referenced_owner
           and arg.PACKAGE_NAME = dep.referenced_name
           and dep.referenced_owner = 'CAS')
   and instr(upper(src.TEXT), arg.PACKAGE_NAME || '.' || arg.OBJECT_NAME) > 0
   and src.name = '".$package_name."'
	 ";
	
$sth=$dbh->prepare($sqlStr);
$sth->execute;

while (@recs=$sth->fetchrow_array) {
#print $recs[0].":".$recs[1].":".$recs[2]."\n";
push @spec_input_txt,$recs[0];
}
if (@spec_input_txt == 0){
print "not exist $package_name,please check!";
}
$sth_body=$dbh->prepare($sqlStr_body);
$sth_body->execute;
while (@recs=$sth_body->fetchrow_array) {
#print $recs[0].":".$recs[1].":".$recs[2]."\n";
push @input_txt,$recs[0];
}

$sth_dep=$dbh->prepare($sqlStr_dep);
$sth_dep->execute;

while (@recs=$sth_dep->fetchrow_array) {
#print $recs[0].":".$recs[1].":".$recs[2]."\n";
$depend{$recs[0]}=$recs[2];
}
$dbh->disconnect;

$input_txt= join " ",@input_txt;

$file_pre_path='C:\\';
$file_pre_path=~s#\\#\\\\#g;
$spec_input_txt= join ' ',@spec_input_txt;
$temp_path="c:\\temp.txt";
open FH2, ">", $temp_path
    or die "Can't open ".$temp_path.";, $!";
#print FH2 $input_txt;	
%unit_typ_color=("Function"=>"red",
                 "Procedure"=>"green",
				 "Package Body"=>"brown",
				 "FUNCTION"=>"red",
				 "PROCEDURE"=>"green",
				 "PACKAGE BODY"=>"brown");	
#spec_fun
while($spec_input_txt=~/^\s*\b(?<fun_typ>function|procedure)\b\s+(?<fun>\w+)/igm){
my $spec_fun= "\U$+{fun_typ}".'|'.$+{fun};
$spec_fun{$spec_fun} =1;
#print FH2 $spec_fun."\n";
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
if ($test=~/^\s*(?<funtyp>function|procedure)\s+(?<fun>\w+)(\s*)/i)
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
  if ($test=~/^(\s*)\bend\b(\s+)(\w+)(\s*);/i) 
  {   
	$tmp= $3;
	unless ($tmp=~/(\bif\b|\bloop\b|\bcase\b)/i) 
	{
	$funnm=pop @fun;
	
	if (exists $unit_trees_start{$unit_fun_full_name}){
	my $txt_start=$unit_trees_start{$unit_fun_full_name};
	$unit_trees_end{$unit_fun_full_name}= $line_num-1;
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
	$unit_trees_end{$unit_fun_full_name}= $line_num-1;
	$unit_trees_txt{$unit_fun_full_name}=join "\n",@fun_txt[$txt_start..$line_num-1];	
	delete $unit_trees_start{$unit_fun_full_name};
	}
  }
$fun_list{$line_num}=$fun[@fun-1];  
}
}	
#sub callgraph
#print FH2 keys %unit_trees_txt;

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

@fun_full_name = keys %unit_trees;
while (($key,$value) = each %depend){  
  $caller_fun = $fun_list{$key-1};
  if ($caller_fun ne ""){
  push @sub_callgraph,'"'.$caller_fun.'"'."->".'"'.$value.'"';   
  push @sub_callgraph,'"'.$caller_fun.'"'.'[label="'.$unit_trees_label{$caller_fun}.'",color='.$unit_typ_color{$unit_trees_typ{$caller_fun}}.']';
  }
}
#post_proc
  while (($key,$value) = each %unit_trees){
  push @unit_trees,'"'.$key.'"'."->".'"'.$value.'"' if $value ne '';
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
print "please open $file_pre_path to view the result";

