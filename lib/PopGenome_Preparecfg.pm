package PopGenome_Preparecfg;
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray);
use FindBin '$Bin';
use YAML::Tiny;
use lib "$Bin/lib";

# pending function: check cleandata, check readgroup uniqueness

sub Main{

    my $usage="
    Usage:
    Options:
        -i <input>   input list_file contain 3 col (or 4 col for PE),name and raw_path(must be fastq format)
        -s <seqtype> input sequence type [SE]|PE
        -o <opath>   output file [./result.yml]
        -m <mem>     memory needed[2G]
        -t <thread>  thread needed[4]
        -q <queue>   queue [st.q]
        -P <prj>     Project Number [P18Z10200N0119]
        -h|?Help!
    Example:perl $0 -i name_path.list -j Y 
";
    my $args = shift; 
    my @args = @{$args};
    my %opts;
    my %var;

    GetOptionsFromArray (\@args, \%opts, 
        'input=s',
        'seqtype=s',
        'outcfg=s',
        'template=s',
        'mem=s',
        'threads=s',
        'queue=s',
        'prj=s',
        'platform=s',
        'phred=s',
        'outdir=s',
        'cleandata',
        'help');

 #   print "$opts{outpath}\n";

    if($opts{help} or !$opts{input}){die "$usage\n";}
    $opts{seqtype} ||= "PE";
    $opts{outcfg} ||= "./result.yml";
    $opts{mem} ||= "2G";
    $opts{threads} ||= 4;
    $opts{queue} ||= "st.q";
    $opts{prj} ||= "P18Z10200N0119";
    $opts{platform} ||= "BGISEQ500";
    $opts{phred} ||= 33;
    $opts{template} ||= "$Bin/lib/template.yml";

    my $fiterflag = "rawdata";
    if (defined $opts{cleandata}){
        $fiterflag = "cleandata";
    }
    
    my $yaml = YAML::Tiny->read( $opts{template} );
    my %cfg = %{$yaml->[0]};

#    print "$opts{outpath}\n";

    unless (exists $cfg{args}{threads}){$cfg{args}{threads}=$opts{threads}}
    unless (exists $cfg{args}{prj}){$cfg{args}{prj}=$opts{prj}}
    unless (exists $cfg{args}{queue}){$cfg{args}{queue}=$opts{queue}}
    unless (exists $cfg{args}{mem}){$cfg{args}{mem}=$opts{mem}}

    if (defined $opts{outdir}){
        $cfg{args}{outdir}=$opts{outdir};
    }

    open IN,"$opts{input}" or die $!;
    my %sample;
    while(<IN>){
        chomp;
        my @a = (split /\s+/,$_);
        my $name = $a[0];
        $sample{$name}=1;
        $cfg{fqdata}{$name}{$fiterflag}{$a[1]}{'Flag'} = $opts{seqtype};
        $cfg{fqdata}{$name}{$fiterflag}{$a[1]}{'PL'} = $opts{platform};
        $cfg{fqdata}{$name}{$fiterflag}{$a[1]}{'Phred'} = $opts{phred};
        $cfg{fqdata}{$name}{$fiterflag}{$a[1]}{'fq1'} = $a[2];
        if ($opts{seqtype} eq "PE"){
            $cfg{fqdata}{$name}{$fiterflag}{$a[1]}{'fq2'} = $a[3];
        }
    }
    close IN;

    foreach my $sample (keys %sample){
        $cfg{population}{$sample}{'presumed_population'}="All";
    }

    # create this yaml object
    $yaml = YAML::Tiny->new( \%cfg );
    # Save both documents to a file
    $yaml->write( $opts{outcfg} );
#    print "$opts{outpath}\n";

}

1;