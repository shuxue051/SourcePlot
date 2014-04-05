use DBI;

#($connectStr)=@ARGV;
print "please input DataBase connection string,like CAS/**/DEV**:\n";
chomp($connectStr=<STDIN>);

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

$sqlStr="select a.owner r_owner
      ,a.table_name r_table_name
      ,substr(c.column_name, 1, 127) r_column_name
      ,b.owner 
      ,b.table_name 
      ,substr(d.column_name, 1, 127) column_name 
      ,a.table_name||'.'||trim(c.column_name)||'='||b.table_name||'.'||d.column_name  statements 
      ,trim(c.column_name)||'='||d.column_name  statements2 
  from user_constraints  a
      ,user_constraints  b
      ,user_cons_columns c
      ,user_cons_columns d
 where a.r_constraint_name = b.constraint_name
   and a.constraint_type = 'R'
   and b.constraint_type = 'P'
   and a.r_owner = b.owner
   and a.constraint_name = c.constraint_name
   and b.constraint_name = d.constraint_name
   and c.position = d.position
   and a.owner = c.owner
   and a.table_name = c.table_name
   and b.owner = d.owner
   and b.table_name = d.table_name  
  -- and upper('TBAS_DOC_RECEIVE_HDRS') in (a.table_name,b.table_name)  
   --and (a.table_name like 'TPOLICYS%'
   --or b.table_name like 'TPOLICYS%')
   ";
#print   $sqlStr; 
$sth=$dbh->prepare($sqlStr);
$sth->execute;

while (@recs=$sth->fetchrow_array) {
#print $recs[0].":".$recs[1].":".$recs[2]."\n";
push @tableRef,$recs[1] .'->'.$recs[4];
}
$dbh->disconnect;

 my %hash=();
 foreach (@tableRef) {
 $hash{$_}=1;
 }
 my @tableRef=sort keys %hash;

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
my $out_path = $file_pre_path.$out_typ."_".$plot_typ.".pdf";
system $dot_path." -Grankdir=LR -Tpdf ".$data_path." -o ".$out_path;
}

dot_plot(write_dot(@tableRef,"tableRef"),"dot");



