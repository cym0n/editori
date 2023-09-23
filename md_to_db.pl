
use strict;
use v5.10;
use Data::Dumper;




my $base_dir = './db';
my $counter;
my $id;
my $directory;

open(my $fh, "<", "editori.md") || die $!;


my $possibly_title = '';
my $possibly_body = '';

my $title = '';

#`rm -rf $base_dir/*`;

my $first = 1;


my @doc;
my $cursor = 0;
my $body = undef;

for(<$fh>)
{
    my $line = $_;
    if($line =~ /===/)
    {
        if($doc[$cursor])
        {
            $doc[$cursor]->{body} = $body;
            $cursor++;
            $doc[$cursor]->{title} = $title . $line;
            $body = '';
            $title = '';
        }
        else
        {
            $doc[$cursor]->{title} = $title . $line;
            $body = '';
            $title = '';
        }   
    }
    else
    {
        $body .= $title;
        $title = $line;
    }
}
close($fh);
$counter = 1;
for(@doc)
{
    my $ed = $_;
    $id = sprintf("%04d", $counter);
    $directory = $base_dir . '/' . $id;
    mkdir $directory;
    open(my $tfh, "> $directory/$id.title");
    binmode($tfh, ":utf8");
    print {$tfh} $ed->{title};
    close($tfh);
    parse_body($ed->{body});
    $counter++;
}

sub parse_body
{
    my $body = shift;
    my $snippet = '';
    my $previous;
    my $c = 1;
    my $possible_title;

    my @structure;

    my $counter;
    for(split /^/m, $body)
    {
        my $line = $_;
        if($line =~ '---')
        {
            if($structure[$counter])
            {
                $structure[$counter]->{body} = $snippet;
                $counter++;
                $structure[$counter]->{title} = $possible_title . $line;
                $snippet = '';
                $possible_title = '';
            }
            else
            {
                $structure[$counter]->{title} = $possible_title . $line;
                $snippet = '';
                $possible_title = '';
            }
        }
        else
        {
            $snippet .= $possible_title;
            $possible_title = $line;
        }
    }
    if($snippet)
    {
        $structure[$counter]->{body} = $snippet;
    }
    for(@structure)
    {
        my $part = $_;
        my $cs = sprintf("%02d", $c);
        open(my $snfh, "> $directory/$id.$cs")|| die "Can't open $directory/$id.$cs: " .$!;
        binmode($snfh, ":utf8");
        print {$snfh} $_->{title} . $_->{body};
        close($snfh);
        $c++;
    }
}
