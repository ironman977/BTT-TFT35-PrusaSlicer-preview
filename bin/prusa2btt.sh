#!/bin/bash


function pnm2ascii {
	PNMFILE=$1
	XSIZE=$2
	YSIZE=$3
	cat "$PNMFILE" | perl -e 'my $debug = 0;
my $xsize = $ARGV[0];
my $ysize = $ARGV[1];
printf ";%04x%04x\r\n",$xsize,$ysize;
my $skip = 3;
while (<STDIN>) {
	if ($skip) { $skip--; next};
	s/\r|\n//g; #remove garbage at the end
	my @a = split / /, $_;
	print ";";
	print "Line size ",scalar @a,"\n" if $debug;
	do {
		my $r = shift @a;
		my $g = shift @a;
		my $b = shift @a;
		printf(" size=%d R/G/B: %d/%d/%d\n",scalar @a,$r,$g,$b) if $debug;
		# Convert to RGB565
		my $r5=$r>>3;
		my $g6=$g>>2;
		my $b5=$b>>3;
		my $rgb565 = ($r5<<11) | ($g6<<5) | $b5;	
		printf "%04x",$rgb565;
	} while (@a);
	print "\r\n";
	}' $XSIZE $YSIZE
}


FILENAME="$1"
DIRNAME=$(dirname "$FILENAME")
BASENAME=$(basename "$FILENAME" | sed -e 's/.gcode//')
TEMPFILE=$(tempfile)
NOTUMBGCODE=$(tempfile -s .gcode)
B64FILE=$(tempfile -s .b64)
PNGFILE=$(tempfile -s .png)
PNMFILE=$(tempfile -s .pnm)

cd "$DIRNAME"

# extract thumbnail
grep -A1000 "thumbnail begin" "$FILENAME" | grep -B1000 "thumbnail end" | grep -v thumbnail | sed -e 's/; //' > $B64FILE
base64 -d $B64FILE > $PNGFILE
# remove thumbnail
grep -B1000 "thumbnail begin" "$FILENAME" | grep -v thumbnail > $NOTUMBGCODE
grep -A1000000 "thumbnail end" "$FILENAME" | grep -v thumbnail >> $NOTUMBGCODE
#70x70
convert $PNGFILE -alpha off -resize 70x70! -compress none $PNMFILE
#/home/frav77/bin/pnm2ascii.pl $PNMFILE 70 70 >> $TEMPFILE
pnm2ascii $PNMFILE 70 70 >> $TEMPFILE
#95x80
convert $PNGFILE -alpha off -resize 95x80! -compress none $PNMFILE
pnm2ascii $PNMFILE 95 80 >> $TEMPFILE
#95x95
convert $PNGFILE -alpha off -resize 95x95! -compress none $PNMFILE
pnm2ascii $PNMFILE 95 95 >> $TEMPFILE
#160x140
convert $PNGFILE -alpha off -resize 160x140! -compress none $PNMFILE
pnm2ascii $PNMFILE 160 140 >> $TEMPFILE
# finish
echo -e "; bigtree thumbnail end\n" >> $TEMPFILE

#sostituisce il gcode con uno nuovo
rm "$FILENAME"
cat $TEMPFILE $NOTUMBGCODE > "$FILENAME"



rm $B64FILE
rm $PNGFILE
rm $TEMPFILE
rm $NOTUMBGCODE
rm $PNMFILE

exit 0
