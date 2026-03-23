FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build

WORKDIR /unzip

RUN dotnet new console

RUN dotnet add package SharpZipLib --version 1.4.2

RUN dotnet tool install --tool-path /tools coverlet.console --version 6.0.2

RUN rm ./*.cs

COPY unzip.cs .

RUN dotnet build -c Release

FROM mcr.microsoft.com/dotnet/runtime:9.0-alpine

COPY --from=build /unzip/bin/Release/net9.0 /build
COPY --from=build /tools /tools

WORKDIR /workspace

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
