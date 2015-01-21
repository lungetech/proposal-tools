#!/usr/bin/perl -W
#
# "My Ph.D. advisor rewrote himself in bash.", integrated into one tool, with a
# few cleanups for LaTeX.
#
# Original code from:
# http://matt.might.net/articles/shell-scripts-for-passive-voice-weasel-words-duplicates/
#
# No license implied.  See original site for license.
#

use warnings;
use strict;

my $errors = 0;

if ( !@ARGV ) {
    print "usage: dups <file> ...\n";
    exit;
}

sub build_passive_re {
    my @prefix = qw(am are were being is been was be);
    # my @prefix = qw(am are were being been was be);
    my @words  = qw(awoken been born beat become begun bent beset bet bid bidden
      bound bitten bled blown broken bred brought broadcast built burnt burst
      bought cast caught chosen clung come cost crept cut dealt dug dived
      done drawn dreamt driven drunk eaten fallen fed felt fought found fit
      fled flung flown forbidden forgotten foregone forgiven forsaken frozen
      gotten given gone ground grown hung heard hidden hit held hurt kept
      knelt knit known laid led leapt learnt left lent let lain lighted lost
      made meant met misspelt mistaken mown overcome overdone overtaken
      overthrown paid pled proven put quit read rid ridden rung risen run
      sawn said seen sought sold sent set sewn shaken shaven shorn shed shone
      shod shot shown shrunk shut sung sunk sat slept slain slid slung slit
      smitten sown spoken sped spent spilt spun spit split spread sprung
      stood stolen stuck stung stunk stridden struck strung striven sworn
      swept swollen swum swung taken taught torn told thought thrived thrown
      thrust trodden understood upheld upset woken worn woven wed wept wound
      won withheld withstood wrung written);

    return
        '\b((?:'
      . join( '|', @prefix )
      . ')\b(\snot\s)?\s*(?:\w+ed|'
      . join( '|', @words ) . '))\b';
}

sub build_weasel_re {
    my @weasels = qw(many various very fairly several extremely exceedingly quite
        remarkably few surprisingly mostly largely huge tiny excellent interestingly
        significantly substantially clearly vast relatively completely);

    push( @weasels, "(?:notice|note) (?:this|that)", "(?:are|is) a number" );

    return '\b((?<!\\\\)(?:' . join( '|', @weasels ) . '))\b';
}

sub error {
    my ($name, $filename, $line, $line_number, $highlight) = @_;
    my $green = "\033[92m";
    my $reset = "\033[0m";
    $highlight =~ s/\\/\\\\/g;
    $highlight =~ s/\./\\./g;
    $line =~ s/($highlight)/$green$1$reset/g;
    print "$filename: $line_number ($name) - $highlight: $line\n";
    $errors++;
}

sub build_acro_re {
    # caps, some number of lowercase, caps
    my $acro = '[A-Z]{1,}[a-z]{0,}[A-Z]{1,}';

    # (space or period), acro, (plural, whitespace, or owners)
    return '([\s\.]+' . $acro . '(?:[\s\.s]|\'s))';
}

my $weasel_re = build_weasel_re();
my $passive_re = build_passive_re();
my $acro_re = build_acro_re();

foreach my $filename (@ARGV) {
    open (FILE, '<', $filename) or die $!;

    my $LastWord = "";
    my $LineNum  = 0;

    # \begin{verbatim}
    #   00 00 00 00     ....
    # \end{verbatim}
    my $verbatim = 0;

    while (<FILE>) {
        chomp;

        $LineNum++;

        error('TODO', $filename, $_, $LineNum, $1) if (/(TODO|XXX)/);

        if ( $filename =~ /\.tex$/ ) {
            if (/^\s*\\begin{verbatim}\s*$/) {
                $verbatim = 1;
                next;
            }

            if (/^\s*\\end{verbatim}\s*$/) {
                $verbatim = 0;
                next;
            }

            next if ($verbatim);

            # skip over comments
            s/(?<!\\)\%.*//;
        }


        error('trailing whitespace', $filename, $_, $LineNum, $1) if (/(\.\s+)$/);
        error('weasel', $filename, $_, $LineNum, $1) if (/$weasel_re/);
        error('passive voice', $filename, $_, $LineNum, $1) if (/$passive_re/);

        # check for non-wrapped acronymns.  Use the acronymn package!
        # wrap non-acronymns via {} makes them not be selected.
        if ( $filename =~ /\.tex$/ ) {
            if (/$acro_re/) {
                my $line = $_;
                $line =~ s/\{.*?\}//g;
                $line =~ s/\[.*?\]//g;
                if ( $line =~ /$acro_re/ ) {
                    error('wrap acronymn', $filename, $_, $LineNum, $1);
                }
            }
        }

        if ($filename =~ /\.tex$/) {
            # latex writing style.  Except for \item lines, a line should have at most one sentence.
            if (!/\\item/) {
                if (/(\.\s+[\w\\]+)/) {
                    error('multiple sentence line', $filename, $_, $LineNum, $1);
                }
            }

            # latex writing style.  All lines that do not start as a latex
            # macro should be a sentence, and therefor have a period.
            if (length($_) > 0 && !/^\s*\\/ && !/[.:{}]$/) {
                error('Missing period', $filename, $_, $LineNum, '');
            }

            # latex writing style.  \item entries should not have a period
            if (/^\s*\\item/ && /(\.)$/) {
                error('item entries with period', $filename, $_, $LineNum, $1);
            }
        }

        foreach my $word (split(/(\W+)/)) {
            # Skip spaces:
            next if $word =~ /^\s*$/;

            # Skip punctuation:
            if ( $word =~ /^\W+$/ ) {
                $LastWord = "";
                next;
            }

            # Duplicate word?  Thanks to Sean Cronin for tip on case.
            if ( lc($word) eq lc($LastWord) ) {
                error('dup', $filename, $_, $LineNum, $word);
            }

            # Mark this as the last word:
            $LastWord = $word;
        }
    }

    close FILE;
}

# Exit code = number of duplicates found.
exit $errors;
