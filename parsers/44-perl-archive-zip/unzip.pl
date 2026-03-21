use strict;
BEGIN {
    # 必须在 use Archive::Zip 前执行
    @INC = grep {
        !m!/auto/IO/Uncompress/UnZip/! && !m!/IO/Uncompress/UnZip\.pm$!
    } @INC;
}
use Archive::Zip qw(:ERROR_CODES);
print "PP loaded from: $INC{'IO/Uncompress/UnZip/PP.pm'}\n";

my $zip = Archive::Zip->new();
my $status = $zip->read($ARGV[0]);
die 'Failed to read ZIP' if $status != AZ_OK;
$status = $zip->extractTree('', $ARGV[1]);
die 'Failed to extract ZIP' if $status != AZ_OK;
