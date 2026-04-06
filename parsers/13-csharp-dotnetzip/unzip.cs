using Ionic.Zip;

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

        using (ZipFile zip = ZipFile.Read(inputPath))
        {
            zip.ExtractAll(outputPath, ExtractExistingFileAction.OverwriteSilently);
        }

        return 0;
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
