#!/usr/bin/env perl
use Mojolicious::Lite;
use Text::Markdown 'markdown';
use Data::Dumper;
use DateTime;

plugin 'TemplateToolkit';

my $dir = 'db/';

get '/' => sub {
    my $c = shift;

    my $filter = $c->param("badge");

    
    opendir (my $dh, $dir) or die $!;
    my $body = '';
    my @eds = ();
    while(my $file = readdir($dh))
    {
        if($file !~ /\./)
        {
            push @eds, $file;
        } 
    }
    my @out = ();
    for(sort @eds)
    {
        my $ok = $filter ? 0 : 1;
        my $node = $_;
        open(my $fh, "<:encoding(UTF-8)", "$dir" . $node . '/' . $node . '.title') || die $dir . $node . '/' . $node . '.title' . " not available: $!";
        my $title = $node . ' - ' . <$fh>;
        close($fh);
        my $content = 1;
        my $body = '';
        my $body_c =  "$dir" . $node . '/' . $node . '.' . sprintf("%02d", $content);
        while( open(my $ch, "<:encoding(UTF-8)",  "$body_c") )
        {
            local $/ = undef;
            $body .= markdown(<$ch>);
            $content++;
            $body_c =  "$dir" . $node . '/' . $node . '.' . sprintf("%02d", $content);
        } 
        my $badges_c =  "$dir" . $node . '/' . $node . '.badges' ;
        my @badges = ();
        if( open(my $bh, "< $badges_c") )
        {
            my $b_string = <$bh>;
            chomp $b_string;
            $ok = 1 if($filter && $b_string =~ /$filter/);
            @badges = split ',', $b_string;
        }
        my $sendings_c =  "$dir" . $node . '/' . $node . '.sendings' ;
        my @sendings = ();
        if( open(my $sh, "< $sendings_c") )
        {
            for(<$sh>)
            {
                chomp;
                my $s = $_;
                if($s =~ /^\*(.*)$/)
                {
                    push @sendings, { tag => 'secondary', send => $1}
                }
                elsif($s =~ /^\+(.*)$/)
                {
                    push @sendings, { tag => 'success', send => $1}
                }
                else
                {
                    push @sendings, { tag => 'danger', send => $s}
                }
            }
            #chomp (@sendings = <$sh>);
        }
        push @out, { id => $node, title => $title, body => $body, badges => \@badges, sendings => \@sendings } if $ok;
        
    }



    $c->render(template => 'index', handler => 'tt2', eds => \@out);
};

get '/new' => sub {
    my $c = shift;
    my $name = $c->param("name");

    opendir (my $dh, $dir) or die $!;
    my @eds = ();
    while(my $file = readdir($dh))
    {
        if($file !~ /\./)
        {
            push @eds, $file;
        } 
    }
    @eds = sort @eds;
    my $last = $eds[-1];
    my $new = $last+1;
    my $id = sprintf("%04d", $new);
    my $new_dir = $dir . $id;
    mkdir $new_dir;

    open(my $th, "> $new_dir/$id.title");
    binmode($th, ":utf8");
    print {$th} "$name\n===\n\n";
    close($th);

    #open(my $fh, "> $new_dir/$id.01");
    #print {$fh} DateTime->now->dmy('/') . "\n---\n\n";
    #close($fh);

    $c->redirect_to('/');

};

get '/new-contribute' => sub {
    my $c = shift;
    my $ed = $c->param("ed");
    my $contribute = $c->param("contribute");
    my $body = '';
    my @eds = ();
    my $ed_dir = "$dir" . $ed . '/';
    opendir (my $dh, $ed_dir) or die $!;
    my $counter = 0;
    while(my $file = readdir($dh))
    {
        if($file =~ /$ed\.(\d\d)/)
        {
            my $new_c = $1;
            if(int($new_c) > $counter)
            {
                $counter = int($new_c); 
            }
        }
    }
    my $file_ext = sprintf("%02d", $counter + 1);
    open(my $fh, "> $ed_dir/$ed.$file_ext");
    binmode($fh, ":utf8");
    print {$fh} DateTime->now->dmy('/') . "\n---\n\n";
    print {$fh} $contribute;
    close($fh);
    $c->redirect_to('/#ed' . $ed);
};

get '/judge' => sub {
    my $c = shift;
    my $ed = $c->param("ed");
    my $b = $c->param("b");
    my $ed_badges = "$dir" . $ed . '/' .$ed.'.badges';
    open(my $fh, "< $ed_badges");
    my $badges = <$fh>;
    chomp $badges;
    close($fh);
    if($badges =~ /$b/)
    {
        my @bdgs = split(',', $badges);
        @bdgs = grep { $_ ne $b } @bdgs;
        $badges = join(',', @bdgs);
    }
    else
    {
        if($badges)
        {
            $badges .= ",$b";
        }
        else
        {
            $badges .= $b;
        }
    }
    open(my $fho, "> $ed_badges");
    print {$fho} $badges;
    close($fho);
    $c->redirect_to('/#ed' . $ed);
};


app->start;
__DATA__

@@ index.html.tt2
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="/css/bootstrap.min.css">
    <link href="/css/open-iconic-bootstrap.css" rel="stylesheet">
    <script src="/js/jquery-3.3.1.min.js"></script>
    <script src="/js/bootstrap.bundle.min.js"></script>
</head>
<body>
    <div class="jumbotron text-center">
        <h1>Database editori</h1>
        <p>
            <a class="btn btn-outline-info" href="/"><span class="oi oi-globe" aria-hidden="true"></span></a>
            <a class="btn btn-outline-info" href="/?badge=bell"><span class="oi oi-bell" aria-hidden="true"></span></a>
        </p>
    </div>
    <div class="container">
    [% FOREACH ed IN eds %]
        <div id="ed[% ed.id %]" class="well">
        <p>
            <button class="btn btn-primary" type="button" data-toggle="collapse" data-target="#collapse[% ed.id %]" aria-expanded="false" aria-controls="collapse[% ed.id %]">[% ed.title %]</button>
            [% FOREACH bdg IN ed.badges %]
            <button type="button" class="btn btn-outline-info" disabled><span class="oi oi-[% bdg %]" aria-hidden="true"></span></button>
            [% END %]
        </p>
        </div>
        [% FOREACH s IN ed.sendings %]
        <h6 class="row"><span class="badge badge-[% s.tag %]">[% s.send %]</span></h6>
        [% END %]
        <p>
            <div class="row">
            <span>
            <form class="form-inline" action="/judge">
            <input type="hidden" id="ed" name="ed" value="[% ed.id %]" />
            <input type="hidden" id="b" name="b" value="bell" />
            <button type="submit" class="btn btn-secondary btn-sm" type="button">Good</button>
            </form>
            </span>
            <span>
            <form class="form-inline" action="/judge">
            <input type="hidden" id="ed" name="ed" value="[% ed.id %]" />
            <input type="hidden" id="b" name="b" value="thumb-down" />
            <button type="submit" class="btn btn-secondary btn-sm" type="button">Dislike</button>
            </form>
            </span>
            <span>
            <form class="form-inline" action="/judge">
            <input type="hidden" id="ed" name="ed" value="[% ed.id %]" />
            <input type="hidden" id="b" name="b" value="trash" />
            <button type="submit" class="btn btn-secondary btn-sm" type="button">Trash</button>
            </form>
            </span>
            </div>
        </p>
        <div class="collapse" id="collapse[% ed.id %]">
            <div class="card card-body">
                [% ed.body %]
            </div>
            <div class="card card-body">
                <form class="form-inline" action="/new-contribute">
                    <input type="hidden" id="ed" name="ed" value="[% ed.id %]" />
                    <div class="form-group mx-sm-3 mb-2"  >
                    <label for="name" class="sr-only">Nuova</label>
                    <textarea class="form-control" id="contribute" name="contribute" placeholder="Nuovo contributo" rows="5" style="width: 600px;"></textarea>
                    </div>
                    <button type="submit" class="btn btn-primary mb-2">Aggiungi</button>
                </form>
            </div>
        </div>
        <br />
    [% END %]
    </div>
    <div class="container">
    <form class="form-inline" action="/new">
        <div class="form-group mx-sm-3 mb-2">
            <label for="name" class="sr-only">Nuova</label>
            <input type="text" class="form-control" id="name" name="name" placeholder="Nuova casa editrice">
        </div>
        <button type="submit" class="btn btn-primary mb-2">Crea</button>
    </form>
    <br />
    <br />
    </div>
    <div class="container bg-light">
        <p>Powered by Mojolicious</p>
    </div>
</body>
</html>
