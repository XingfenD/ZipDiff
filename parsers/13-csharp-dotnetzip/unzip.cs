using Ionic.Zip;
using System.IO;

internal static class Program
{
    private static int Main(string[] args)
    {
        if (!TryResolvePaths(args, out var inputPath, out var outputPath))
        {
            return 1;
        }

        if (!ZipFile.CheckZip(inputPath))
        {
            return 1;
        }

        Directory.CreateDirectory(outputPath);
        using (ZipFile zip = ZipFile.Read(inputPath))
        {
            foreach (ZipEntry entry in zip)
            {
                if (!TryExtractEntry(entry, outputPath))
                {
                    return 1;
                }
            }
        }

        return 0;
    }

    private static bool TryExtractEntry(ZipEntry entry, string outputPath)
    {
        try
        {
            entry.Extract(outputPath, ExtractExistingFileAction.OverwriteSilently);
            return true;
        }
        catch (ArgumentException)
        {
            // DotNetZip can emit invalid Linux file attributes for some inputs.
            // Retry once with normalized attributes.
            try
            {
                entry.Attributes = entry.IsDirectory
                    ? FileAttributes.Directory
                    : FileAttributes.Normal;
                entry.Extract(outputPath, ExtractExistingFileAction.OverwriteSilently);
                return true;
            }
            catch
            {
                return false;
            }
        }
    }

    private static bool TryResolvePaths(string[] args, out string inputPath, out string outputPath)
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
}
