#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

use XML::LibXML;
use XML::LibXML::XPathContext;

use Getopt::Long qw(GetOptions);

my $xhtml_ns = "http://www.w3.org/1999/xhtml";

sub _get_xpc
{
    my ($node) = @_;
    my $xpc = XML::LibXML::XPathContext->new($node);
    $xpc->registerNs("xhtml", $xhtml_ns);

    return $xpc;
}

my $out_fn;

GetOptions(
    "output|o=s" => \$out_fn,
);

# Input the filename
my $filename = shift(@ARGV)
    or die "Give me a filename as a command argument: myscript FILENAME";

# Prepare the objects.
my $xml = XML::LibXML->new;
my $root_node = $xml->parse_file($filename);
{
    my $scenes_list = _get_xpc($root_node)->findnodes(
        q{//xhtml:div[@class='screenplay']/xhtml:div[@class='scene']/xhtml:div[@class='scene' and xhtml:h2]}
    )
        or die "Cannot find top-level scenes list.";

    my $idx = 0;
    $scenes_list->foreach(sub
    {
        my ($orig_scene) = @_;

        my $scene = $orig_scene->cloneNode(1);

        {
            my $scene_xpc = _get_xpc($scene);
            foreach my $h_idx (2 .. 6)
            {
                foreach my $h_tag ($scene_xpc->findnodes(qq{xhtml:h$h_idx}))
                {
                    my $copy = $h_tag->cloneNode(1);
                    $copy->setNodeName('h' . ($h_idx-1));

                    my $parent = $h_tag->parentNode;
                    $parent->replaceChild($copy, $h_tag);
                }
            }
        }

        {
            my $scene_xpc = _get_xpc($scene);

            my $title = $scene_xpc->findnodes('xhtml:h1')->[0]->textContent();
            io->file("./for-epub-xhtmls/scene-" . ($idx+1) . ".xhtml")->utf8->print(<<"EOF");
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE
    html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">
<head>
<title>$title</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
@{[$scene->toString()]}
</body>
</html>
EOF
        }
        $idx++;
    });
}
