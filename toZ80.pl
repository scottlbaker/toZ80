#!/usr/bin/perl

# =========================================================
# A script to convert 8080 to Z80 assembler mnemonics
#
# (c) Scott L. Baker, Sierra Circuit Design
# =========================================================

use strict;
use warnings;

my $progname  = "toZ80.pl";

use Getopt::Long;

my $opt_ifile = "";   # input  file name
my $opt_ofile = "";   # output file name
my $opt_uc    = 0;    # convert to upper case
my $opt_lc    = 0;    # convert to lower case
my $opt_help  = 0;    # print help

Getopt::Long::config("pass_through");
Getopt::Long::GetOptions(
    "in=s"  => \$opt_ifile,
    "out=s" => \$opt_ofile,
    "uc"    => \$opt_uc,
    "lc"    => \$opt_lc,
    "help"  => \$opt_help,
    );

$opt_help = 1 if (!$opt_ifile);
$opt_help = 1 if (!$opt_ofile);

if($opt_help){
    &help();
    exit(0);
}

# open the 8080 source file

open(FP1, "< $opt_ifile") || die("Cannot open $opt_ifile: $!");

my $temp;           # temp string
my $csave;          # temp saved comment
my $label;          # temp saved label
my @out = ();       # output array

my @in = <FP1>;     # read file to input array
close(FP1);

foreach (@in) {

    chomp;

    # clear the saved comment
    $csave = "";
    $label = "";

    ## skip full-line comments
    if (/^\s*;/) {
        push(@out, "$_\n");
        next;
    }

    ## save non-full-line comments
    if (/;/) {
        ($_,$csave) = split(/;/,$_);
        if ($csave !~ /\S/) {
            $csave = "";
        }
    }

    ## save labels
    if (/^(\S+):/) {
        ($label,$temp) = split(/:/,$_);
        $_ = $temp;
    }

    ## replace ,m with ,(HL)
    s/,(\s*)[Mm]/,$1(HL)/;

    ## replace m,r with (HL,r)
    s/[Mm](\s*),/(HL)$1,/;

    ## ANI
    if (/\s+[Aa][Nn][Ii](?!\S)/) {
        s/[Aa][Nn][Ii]/AND/;
        &pushx();
        next;
    }

    ## ORI
    if (/\s+[Oo][Rr][Ii](?!\S)/) {
        s/[Oo][Rr][Ii]/OR/;
        &pushx();
        next;
    }

    ## XRI
    if (/\s+[Xx][Rr][Ii](?!\S)/) {
        s/[Xx][Rr][Ii]/XOR/;
        &pushx();
        next;
    }

    ## LDA word
    if (/\s+[Ll][Dd][Aa](?!\S)/) {
        s/[Ll][Dd][Aa](\s+)(\S+)/LD$1A,\($2\)/;
        &pushx();
        next;
    }

    ## STA word
    if (/\s+[Ss][Tt][Aa](?!\S)/) {
        s/[Ss][Tt][Aa](\s+)(\S+)/LD$1\($2\),A/;
        &pushx();
        next;
    }

    ## LHLD word
    if (/\s+[Ll][Hh][Ll][Dd](?!\S)/) {
        s/[Ll][Hh][Ll][Dd](\s+)(\S+)/LD$1HL,\($2\)/;
        &pushx();
        next;
    }

    ## SHLD word
    if (/\s+[Ss][Hh][Ll][Dd](?!\S)/) {
        s/[Ss][Hh][Ll][Dd](\s+)(\S+)/LD$1\($2\),HL/;
        &pushx();
        next;
    }

    ## IN byte
    if (/\s+[Ii][Nn](\s+)(\S+)/) {
        s/[Ii][Nn]\s+(\S+)/IN A,\($1\)/;
        &pushx();
        next;
    }

    ## OUT byte
    if (/\s+[Oo][Uu][Tt](\s+)(\S+)/) {
        s/[Oo][Uu][Tt]\s+(\S+)/OUT \($1\),A/;
        &pushx();
        next;
    }


    ## ADI
    if (/\s+[Aa][Dd][Ii](\s+)(\S+)/) {
        s/[Aa][Dd][Ii](\s+)(\S+)/ADD$1A,$2/;
        &pushx();
        next;
    }

    ## ACI
    if (/\s+[Aa][Cc][Ii](\s+)(\S+)/) {
        s/[Aa][Cc][Ii](\s+)(\S+)/ADC$1A,$2/;
        &pushx();
        next;
    }

    ## SUI
    if (/\s+[Ss][Uu][Ii](?!\S)/) {
        s/[Ss][Uu][Ii]/SUB/;
        &pushx();
        next;
    }

    ## SBI
    if (/\s+[Ss][Bb][Ii](\s+)(\S+)/) {
        s/[Ss][Bb][Ii](\s+)(\S+)/SBC$1A,$2/;
        &pushx();
        next;
    }

    ## CPI
    if (/\s+[Cc][Pp][Ii](?!\S)/) {
        s/[Cc][Pp][Ii]/CP/;
        &pushx();
        next;
    }

    ## CNZ
    if (/\s+[Cc][Nn][Zz](?!\S)/) {
        s/[Cc][Nn][Zz]/CALL NZ,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## CNC
    if (/\s+[Cc][Nn][Cc](?!\S)/) {
        s/[Cc][Nn][Cc]/CALL NC,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## CPO
    if (/\s+[Cc][Pp][Oo](?!\S)/) {
        s/[Cc][Pp][Oo]/CALL PO,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## CPE
    if (/\s+[Cc][Pp][Ee](?!\S)/) {
        s/[Cc][Pp][Ee]/CALL PE,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## CZ
    if (/\s+[Cc][Zz](?!\S)/) {
        s/[Cc][Zz]/CALL Z,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## CC
    if (/\s+[Cc][Cc](?!\S)/) {
        s/[Cc][Cc]/CALL C,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## CP
    if (/\s+[Cc][Pp](?!\S)/) {
        s/[Cc][Pp]/CALL P,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## CM
    if (/\s+[Cc][Mm](?!\S)/) {
        s/[Cc][Mm]/CALL PE,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## CMA
    if (/\s+[Cc][Mm][Aa](?!\S)/) {
        s/[Cc][Mm][Aa]/CPL/;
        &pushx();
        next;
    }

    ## HLT
    if (/\s+[Hh][Ll][Tt](?!\S)/) {
        s/[Hh][Ll][Tt]/HALT/;
        &pushx();
        next;
    }

    ## SPHL
    if (/\s+[Ss][Pp][Hh][Ll](?!\S)/) {
        s/[Ss][Pp][Hh][Ll]/LD SP,HL/;
        &pushx();
        next;
    }

    ## XCHG
    if (/\s+[Xx][Cc][Hh][Gg](?!\S)/) {
        s/[Xx][Cc][Hh][Gg]/EX DE,HL/;
        &pushx();
        next;
    }

    ## XTHL
    if (/\s+[Xx][Tt][Hh][Ll](?!\S)/) {
        s/[Xx][Tt][Hh][Ll]/EX (SP),HL/;
        &pushx();
        next;
    }

    ## PCHL
    if (/\s+[Pp][Cc][Hh][Ll](?!\S)/) {
        s/[Pp][Cc][Hh][Ll]/JP (HL)/;
        &pushx();
        next;
    }

    ## MOV
    if (/\s+[Mm][Oo][Vv]\s+/) {
        s/[Mm][Oo][Vv]/LD/;
        &pushx();
        next;
    }

    ## MVI
    if (/\s+[Mm][Vv][Ii]\s+/) {
        s/[Mm][Vv][Ii]/LD/;
        &pushx();
        next;
    }

    ## JMP
    if (/\s+[Jj][Mm][Pp]\s+/) {
        s/[Jj][Mm][Pp]/JP/;
        &pushx();
        next;
    }

    ## JZ
    if (/\s+[Jj][Zz]\s+/) {
        s/[Jj][Zz]/JP Z,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## JC
    if (/\s+[Jj][Cc]\s+/) {
        s/[Jj][Cc]/JP C,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## JP
    if (/\s+[Jj][Pp]\s+/) {
        s/[Jj][Pp]/JP P,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## JM
    if (/\s+[Jj][Mm]\s+/) {
        s/[Jj][Mm]/JP M,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## JNZ
    if (/\s+[Jj][Nn][Zz]\s+/) {
        s/[Jj][Nn][Zz]/JP NZ,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## JNC
    if (/\s+[Jj][Nn][Cc]\s+/) {
        s/[Jj][Nn][Cc]/JP NC,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## JPO
    if (/\s+[Jj][Pp][Oo]\s+/) {
        s/[Jj][Pp][Oo]/JP PO,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## JPE
    if (/\s+[Jj][Pp][Ee]\s+/) {
        s/[Jj][Pp][Ee]/JP PE,/;
        s/,\s+/,/;
        &pushx();
        next;
    }

    ## RLC
    if (/\s+[Rr][Ll][Cc](?!\S)/) {
        s/[Rr][Ll][Cc]/RLCA/;
        &pushx();
        next;
    }

    ## RRC
    if (/\s+[Rr][Rr][Cc](?!\S)/) {
        s/[Rr][Rr][Cc]/RRCA/;
        &pushx();
        next;
    }

    ## RAL
    if (/\s+[Rr][Aa][Ll](?!\S)/) {
        s/[Rr][Aa][Ll]/RLA/;
        &pushx();
        next;
    }

    ## RAR
    if (/\s+[Rr][Aa][Rr](?!\S)/) {
        s/[Rr][Aa][Rr]/RRA/;
        &pushx();
        next;
    }

    ## RNZ
    if (/\s+[Rr][Nn][Zz](?!\S)/) {
        s/[Rr][Nn][Zz]/RET NZ/;
        &pushx();
        next;
    }

    ## RNC
    if (/\s+[Rr][Nn][Cc](?!\S)/) {
        s/[Rr][Nn][Cc]/RET NC/;
        &pushx();
        next;
    }

    ## RPO
    if (/\s+[Rr][Pp][Oo](?!\S)/) {
        s/[Rr][Pp][Oo]/RET PO/;
        &pushx();
        next;
    }

    ## RPE
    if (/\s+[Rr][Pp][Ee](?!\S)/) {
        s/[Rr][Pp][Ee]/RET PE/;
        &pushx();
        next;
    }

    ## RZ
    if (/\s+[Rr][Zz](?!\S)/) {
        s/[Rr][Zz]/RET Z/;
        &pushx();
        next;
    }

    ## RC
    if (/\s+[Rr][Cc](?!\S)/) {
        s/[Rr][Cc]/RET C/;
        &pushx();
        next;
    }

    ## RP
    if (/\s+[Rr][Pp](?!\S)/) {
        s/[Rr][Pp]/RET P/;
        &pushx();
        next;
    }

    ## RM
    if (/\s+[Rr][Mm](?!\S)/) {
        s/[Rr][Mm]/RET M/;
        &pushx();
        next;
    }

    ## STC
    if (/\s+[Ss][Tt][Cc](?!\S)/) {
        s/[Ss][Tt][Cc]/SCF/;
        &pushx();
        next;
    }

    ## CMC
    if (/\s+[Cc][Mm][Cc](?!\S)/) {
        s/[Cc][Mm][Cc]/CCF/;
        &pushx();
        next;
    }

    ## PUSH
    if (/\s+[Pp][Uu][Ss][Hh](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xreg($2);
        my $nd = &xend();
        s/[Pp][Uu][Ss][Hh].+/PUSH$sx$op$nd/;
        &pushx();
        next;
    }

    ## POP
    if (/\s+[Pp][Oo][Pp](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xreg($2);
        my $nd = &xend();
        s/[Pp][Oo][Pp].+/POP$sx$op$nd/;
        &pushx();
        next;
    }

    ## LXI
    if (/\s+[Ll][Xx][Ii](\s+)(\S+)/) {
        my $sx = $1;
        my $op = $2;
        my ($op1,$op2) = split(/,/,$op);
        $op1 = &xreg($op1);
        my $nd = &xend();
        s/[Ll][Xx][Ii].+/LD$sx$op1,$op2$nd/;
        &pushx();
        next;
    }

    ## DAD
    if (/\s+[Dd][Aa][Dd](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xreg($2);
        my $nd = &xend();
        s/[Dd][Aa][Dd].+/ADD HL,$op$nd/;
        &pushx();
        next;
    }

    ## INX
    if (/\s+[Ii][Nn][Xx](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xreg($2);
        my $nd = &xend();
        s/[Ii][Nn][Xx].+/INC$sx$op$nd/;
        &pushx();
        next;
    }

    ## DCX
    if (/\s+[Dd][Cc][Xx](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xreg($2);
        my $nd = &xend();
        s/[Dd][Cc][Xx].+/DEC$sx$op$nd/;
        &pushx();
        next;
    }

    ## LDAX
    if (/\s+[Ll][Dd][Aa][Xx](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xreg($2);
        my $nd = &xend();
        s/[Ll][Dd][Aa][Xx].+/LD${sx}A,\($op\)$nd/;
        &pushx();
        next;
    }

    ## STAX
    if (/\s+[Ss][Tt][Aa][Xx](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xreg($2);
        my $nd = &xend();
        s/[Ss][Tt][Aa][Xx].+/LD$sx\($op\),A$nd/;
        &pushx();
        next;
    }

    ## INR
    if (/\s+[Ii][Nn][Rr](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Ii][Nn][Rr].+/INC$sx$op$nd/;
        &pushx();
        next;
    }

    ## DCR
    if (/\s+[Dd][Cc][Rr](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Dd][Cc][Rr].+/DEC$sx$op$nd/;
        &pushx();
        next;
    }

    ## CMP
    if (/\s+[Cc][Mm][Pp](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Cc][Mm][Pp].+/CP$sx$op$nd/;
        &pushx();
        next;
    }

    ## ANA
    if (/\s+[Aa][Nn][Aa](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Aa][Nn][Aa].+/AND$sx$op$nd/;
        &pushx();
        next;
    }

    ## XRA
    if (/\s+[Xx][Rr][Aa](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Xx][Rr][Aa].+/XOR$sx$op$nd/;
        &pushx();
        next;
    }

    ## ORA
    if (/\s+[Oo][Rr][Aa](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Oo][Rr][Aa].+/OR$sx$op$nd/;
        &pushx();
        next;
    }

    ## ADD
    if (/\s+[Aa][Dd][Dd](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Aa][Dd][Dd].+/ADD${sx}A,$op$nd/;
        &pushx();
        next;
    }

    ## ADC
    if (/\s+[Aa][Dd][Cc](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Aa][Dd][Cc].+/ADC${sx}A,$op$nd/;
        &pushx();
        next;
    }

    ## SUB
    if (/\s+[Ss][Uu][Bb](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Ss][Uu][Bb].+/SUB${sx}$op$nd/;
        &pushx();
        next;
    }

    ## SBB
    if (/\s+[Ss][Bb][Bb](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xmem($2);
        my $nd = &xend();
        s/[Ss][Bb][Bb].+/SBC${sx}A,$op$nd/;
        &pushx();
        next;
    }

    ## RST
    if (/\s+[Rr][Ss][Tt](\s+)(\S+)/) {
        my $sx = $1;
        my $op = &xrst($2);
        my $nd = &xend();
        s/[Rr][Ss][Tt].+/RST$sx$op$nd/;
        &pushx();
        next;
    }

    ## default
    &pushy();

}

# write the translated z80 source file

open(FP2, "> $opt_ofile") || die("Cannot write to $opt_ofile: $!");
print FP2 @out;
close(FP2);


# =====================
# Subroutines
# =====================

sub pushx {
    $_ = uc if ($opt_uc);
    $_ = lc if ($opt_lc);
    if ($csave) {
        # restore comment
        $_ .= ";".$csave;
    }
    if ($label) {
        # restore lable
        $_ = $label.":".$_;
    }
    push(@out, "$_\n");
}

sub pushy {
    if (/^(\S+)(\s+)(.+)/) {
        my $lb = $1;  # label
        my $sx = $2;  # space
        my $nd = $3;  # rest of line
        $lb = uc $lb if ($opt_uc);
        $lb = lc $lb if ($opt_lc);
        $_= $lb.$sx.$nd
    }
    if ($csave) {
        # restore comment
        $_ .= ";".$csave;
    }
    if ($label) {
        # restore lable
        $_ = $label.":".$_;
    }
    push(@out, "$_\n");
}

sub xreg {
    # fix register name
    my ($op) = @_;
    $op =~ s/[Bb]/BC/;
    $op =~ s/[Dd]/DE/;
    $op =~ s/[Hh]/HL/;
    $op =~ s/[Pp][Ss][Ww]/AF/;
    return $op;
}

sub xmem {
    # fix m
    my ($op) = @_;
    $op =~ s/[Mm]/(HL)/;
    return $op;
}

sub xend {
    # look for ending whitespace
    my $ws = "";
    if (/(\s+)$/) {$ws = $1;}
    return $ws;
}

sub xrst {
    # fix restart number
    my ($op) = @_;
    if ($op =~ /(\d)(\d)/) {$op =~ $2;}
    $op =~ s/0/00h/;
    $op =~ s/1/08h/;
    $op =~ s/2/10h/;
    $op =~ s/3/18h/;
    $op =~ s/4/20h/;
    $op =~ s/5/28h/;
    $op =~ s/6/30h/;
    $op =~ s/7/38h/;
    return $op;
}

sub help {
    print "\n Usage: $progname <options>\n\n";

    print "   -in  <file>  :: input  file name (required)\n";
    print "   -out <file>  :: output file name (required)\n";
    print "   -uc          :: convert to upper case\n";
    print "   -lc          :: convert to lower case\n";
    print "   -help        :: print this message\n\n";

    print " Example: $progname -i <infile> -o <outfile>\n\n";
}

