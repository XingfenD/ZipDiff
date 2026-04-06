using ICSharpCode.SharpZipLib.Zip;

if (!TryResolvePaths(args, out var inputPath, out var outputPath))
{
    return;
}

using (ZipFile zipFile = new ZipFile(inputPath))
{
    if (!zipFile.TestArchive(true))
    {
        return;
    }
}

new FastZip().ExtractZip(inputPath, outputPath, null);

static bool TryResolvePaths(string[] args, out string inputPath, out string outputPath)
{
    inputPath = string.Empty;
    outputPath = string.Empty;

    if (args.Length >= 2)
    {
        inputPath = args[0];
        outputPath = args[1];
        return true;
    }

    var envInput = System.Environment.GetEnvironmentVariable("ZIPDIFF_INPUT");
    var envOutput = System.Environment.GetEnvironmentVariable("ZIPDIFF_OUTPUT");

    if (string.IsNullOrWhiteSpace(envInput) || string.IsNullOrWhiteSpace(envOutput))
    {
        return false;
    }

    inputPath = envInput;
    outputPath = envOutput;
    return true;
}
