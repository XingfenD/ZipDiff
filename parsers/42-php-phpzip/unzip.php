<?php

require __DIR__ . "/vendor/autoload.php";

if (!function_exists('xdebug_start_code_coverage')) {
    fwrite(STDERR, "xdebug coverage is not available\n");
    exit(1);
}

$zipPath = $argv[1];
$outPath = $argv[2];
$covPath = $argv[3];

xdebug_start_code_coverage(XDEBUG_CC_UNUSED | XDEBUG_CC_DEAD_CODE);

$zipFile = new \PhpZip\ZipFile();
$zipFile->openFile($zipPath)->extractTo($outPath);

$coverage = xdebug_get_code_coverage();
xdebug_stop_code_coverage();

file_put_contents($covPath, json_encode($coverage));
