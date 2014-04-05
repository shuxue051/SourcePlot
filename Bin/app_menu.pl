use DBI;
use Encode;
($connectStr)=@ARGV;
if ($connectStr eq ''){
print "please input DataBase connection string,like CAS/**/DEV**:\n";
chomp($connectStr=<STDIN>);
}

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

$sqlStr="  select menu_cd, menu_label, parent_menu_cd, fcn_nm
             from tapp_menus   
            where app_cd = 'CAS' 		 	 
   ";
#print   $sqlStr; 
$sth=$dbh->prepare($sqlStr);
$sth->execute;

				
while (@recs=$sth->fetchrow_array) {
#print $recs[0].":".$recs[1].":".$recs[2]."\n";
push @tableRef,'"'.$recs[0].'"' .'->'.'"'.$recs[2].'"';
push @tableRef,'"'.$recs[0].'"' .'[label='.'"'.$recs[1].'"'.']' if $recs[1];
}
$dbh->disconnect;

 my %hash=();
 foreach (@tableRef) {
 $hash{$_}=1;
 }
 my @tableRef=sort keys %hash;
$file_pre_path='C:\\';
$file_pre_path=~s#\\#\\\\#g;
#file output
 sub write_dot(\@$){
 my ($ref_callgraph,$post_file_name) = @_;
 my  @dotgraph = @{$ref_callgraph}; 
 my $dot_file_name = $file_name.'_'.$post_file_name;
 my $dot_file_path = $file_pre_path.$dot_file_name.".dot";
 
 open LOG, ">:raw", $dot_file_path;
 print LOG "digraph ".$dot_file_name."{\n";
 print LOG 'edge[fontname="FangSong"];'."\n"; 
 print LOG 'node[fontname="Microsoft YaHei",shape=box];'."\n";
 foreach (0..@dotgraph){ 
 #print LOG $dotgraph[$_].";\n" if $dotgraph[$_];
 print LOG encode("utf-8",decode('gb2312',$dotgraph[$_])).";\n" if $dotgraph[$_];
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

dot_plot(write_dot(@tableRef,"app_menu"),"dot");
print "please open $file_pre_path to view the result";



