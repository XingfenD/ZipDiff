FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

WORKDIR /unzip

RUN dotnet new console

RUN dotnet add package SharpCompress --version 0.38.0

RUN dotnet tool install --tool-path /tools coverlet.console --version 6.0.2
RUN dotnet tool install --tool-path /tools dotnet-coverage --version 17.14.1

RUN rm ./*.cs

COPY unzip.cs .

RUN dotnet build -c Release

FROM mcr.microsoft.com/dotnet/runtime:9.0

COPY --from=build /unzip/bin/Release/net9.0 /build
COPY --from=build /tools /tools
RUN apt-get update && apt-get install -y --no-install-recommends libxml2 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
