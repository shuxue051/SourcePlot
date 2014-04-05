
#($file_path)=@ARGV;
#$file_path="D:\\SVN_Source_Dev\\Release_20140110\\060_Reports\\RPTRCM10SH.Rdf";
$file_path="D:\\SVN_Source_Dev\\Release_20140110\\060_Reports\\CASRBL09SH.Rdf";
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
 print $FormsToolCmd;
 system $FormsToolCmd;
 
 %tag_typ_color=("Boilerplates"=>"red",
                 "Frames"=>"green",
				 "Fields"=>"blue"				
			    );
 
$txt_file_path=$f_out_txt;
$^I =".bak";
$info_path=$file_pre_path.$file_name."_info.csv";
$temp_path="c:\\temp.txt";
open (FH, $txt_file_path)
    or die "Can't open ".$txt_file_path.";, $!";
open FH2, ">", $temp_path
    or die "Can't open ".$temp_path.";, $!";
open FH_INFO, ">", $info_path
    or die "Can't open ".$info_path.";, $!";	
@input_txt=<FH>;
$input_txt= join '',@input_txt;
close FH;
#pre process   
$input_txt=~s#\n\s{53}~\s{2}##g;
@report_txt=split "\n",$input_txt;

($layout_main)=$input_txt=~/\n(\s{4}Layout Main[\d\D]*?)\n\s{4}Layout Trailer/;

#print FH_INFO $layout_main;
@layout_main=split "\n",$layout_main;
#print FH2 @layout_main;
for (@layout_main) {
$curr_line = $_;

$curr_pre_line = substr($curr_line,0,53); 
$curr_post_line = substr($curr_line,56); 
#$curr_blank_num = length($curr_pre_line=~/^(\s+)\w/);
$curr_blank_num = length($curr_line);

$curr_line =~s/^\s+|\s+$//g;
$curr_pre_line =~s/^\s+|\s+$//g;
$curr_blank_num = $curr_blank_num - length($curr_line);

if ($curr_line eq 'Frames' ||$curr_line eq 'Boilerplates' ||$curr_line eq 'Fields')
{
$l_tag_start = 1;
$curr_tag_type= $curr_line;
push @tag_type,$curr_tag_type;
$parent_blank_num = $curr_blank_num; 
#print FH2 $parent_blank_num."\n";
#print FH2 $curr_line."\n";
}

elsif($curr_blank_num == $parent_blank_num+2 ){
   #print FH2 $curr_line."\n";
    if (@tag_full_path==0){
	$parent=$file_name;
	}
    else{    
    $parent= $tag_full_path[@tag_full_path-1];
	}
$curr_tag_name=$curr_line;
$curr_tag_full_name = $curr_tag_type.'|'.$curr_tag_name;
$curr_tag_full_path = $parent.'.'.$curr_tag_full_name;
push @tag_full_path,$curr_tag_full_path;
$tag_parent{$curr_tag_full_path}= $parent;
$tag_label{$curr_tag_full_path}= $curr_tag_name;
$tag_type{$curr_tag_full_path}= $curr_tag_type;
$tag_depth{$curr_tag_full_path}=scalar @tag_full_path;
}
elsif ($curr_pre_line eq 'Text'){
$tag_text{$curr_tag_full_path} =  $curr_post_line;
}
elsif ($curr_pre_line eq 'Source'){
$tag_source{$curr_tag_full_path} =  $curr_post_line;
}
elsif($curr_pre_line eq 'Y Position'){ 
$l_tag_start = 0;
pop @tag_full_path;

}

}
#output info
  while (($key,$value) = each %tag_parent){
  if ($tag_type{$key} eq 'Boilerplates'){
  print FH_INFO $tag_label{$key}.','.$tag_label{$value}.','.$tag_text{$key}."\n";
  }
  elsif ($tag_type{$key} eq 'Fields'){
  print FH_INFO $tag_label{$key}.','.$tag_label{$value}.','.$tag_source{$key}."\n";
  }
  } 


#post process
  while (($key,$value) = each %tag_parent){
  push @tag_trees,'"'.$key.'"'."->".'"'.$value.'"';
 } 
  while (($key,$value) = each %tag_label){
  push @tag_trees,'"'.$key.'"'.'[label="'.$value.'",color='.$tag_typ_color{$tag_type{$key}}.']';
 } 

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

dot_plot(write_dot(@tag_trees,"tag_trees"),"dot");





