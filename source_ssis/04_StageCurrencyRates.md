# 04_StageCurrencyRates.dtsx

**Intent:** Pure ingestion. Read the tab-delimited `SampleCurrencyData.txt`
(real Microsoft tutorial file format) and land it in `stg.CurrencyRate`. No
transforms.

**Data Flow (single Data Flow Task "Stage Currency Rates"):**
1. `Microsoft.FlatFileSource` — `SampleCurrencyData.txt`
   (4 cols: AverageRate, CurrencyKey, CurrencyDateKey, EndOfDayRate)
2. `Microsoft.OLEDBDestination` — `[stg].[CurrencyRate]`

**Note:** the package's flat-file connection string points at a Windows path
(`C:\SSISPOC\source_ssis\SampleCurrencyData.txt`) for SSIS authenticity. The
real file lives next to this package; adjust the path if the agent needs to
read the data during a run.

**Expected agent classification:** **Ingestion**.
