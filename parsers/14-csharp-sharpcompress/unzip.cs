using SharpCompress.Archives.Zip;
using SharpCompress.Common;
using SharpCompress.Readers;

if (!TryResolvePaths(args, out var inputPath, out var outputPath))
{
    return;
}

using (var archive = ZipArchive.Open(inputPath))
{
    var opt = new ExtractionOptions()
    {
        ExtractFullPath = true,
        Overwrite = true
    };
    archive.ExtractAllEntries().WriteAllToDirectory(outputPath, opt);
}

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
