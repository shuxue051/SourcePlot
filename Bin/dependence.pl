use DBI;

($connectStr)=@ARGV;
if ($connectStr eq ''){
print "please input DataBase connection string,like CAS/**/DEV**:\n";
chomp($connectStr=<STDIN>);
}

print "please input package name for Analytics,such as CAS_BAS_SC_UTL:\n";
chomp($package_name=<STDIN>);

$connectStr=~m#(\w+)\/(\w+)@(\w+)#;
$user=$1;
$passwd=$2;
$dbname=$3;

$file_pre_path='C:\\';
$file_pre_path=~s#\\#\\\\#g;
#print $dbname.','.$user.','.$passwd;
$dbname="dev03";
$user="CAS";
$passwd="dev031130";
$dbh="";
$dbh = DBI->connect("dbi:Oracle:$dbname",$user,$passwd) or die "can't connect to
database ". DBI-errstr;

$sqlStr="  select NAME  nm,
           TYPE  typ,
           REFERENCED_NAME  ref_nm,
           REFERENCED_TYPE  ref_typ	
      from dba_dependencies 
     where type <> 'SYNONYM' 
	   and owner='CAS'
     --  and referenced_name like 'TPT_%'
	   and NAME ='".$package_name ."'";
#print   $sqlStr; 
$sth=$dbh->prepare($sqlStr);
$sth->execute;

 %tag_typ_color=("PROCEDURE"=>"blue",
                 "FUNCTION"=>"yellow",
				 "PACKAGE"=>"brown"	,
				 "PACKAGE BODY"=>"red",
				 "TABLE"=>"green",
				 "VIEW"=>"pink"
			    );
				
while (@recs=$sth->fetchrow_array) {
#print $recs[0].":".$recs[1].":".$recs[2]."\n";
push @tableRef,'"'.$recs[0].'"' .'->'.'"'.$recs[2].'"';
push @tableRef,'"'.$recs[0].'"' .'[color='.$tag_typ_color{$recs[1]}.']' if $tag_typ_color{$recs[1]};
push @tableRef,'"'.$recs[2].'"' .'[color='.$tag_typ_color{$recs[3]}.']' if $tag_typ_color{$recs[3]};
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
}

dot_plot(write_dot(@tableRef,"dependence"),"dot");
dot_plot(write_dot(@tableRef,"dependence"),"fdp");
print "please open $file_pre_path to view the result";



