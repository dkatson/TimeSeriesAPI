codeunit 50110 "Machine Learning Forecast"
{
    procedure CalculateForecast(Item: Record Item): Decimal;
    var
        MLForecastSetup: Record "ML Forecast Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Date: Record Date;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        TimeSeriesManagement: Codeunit "Time Series Management";
    begin
        MLForecastSetup.Get();
        TimeSeriesManagement.Initialize(
            MLForecastSetup."Endpoint URI", MLForecastSetup."API Key",
            0, false);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry No.", ItemLedgerEntry."Entry Type"::Sale);

        TimeSeriesManagement.PrepareData(
            ItemLedgerEntry,
            ItemLedgerEntry.FieldNo("Item No."),
            ItemLedgerEntry.FieldNo("Posting Date"),
            ItemLedgerEntry.FieldNo(Quantity),
            Date."Period Type"::Month,
            WorkDate,
            12);

        TimeSeriesManagement.Forecast(1, 0, 0);
        TimeSeriesManagement.GetForecast(TempTimeSeriesForecast);
        if TempTimeSeriesForecast.FindFirst() then
            exit(TempTimeSeriesForecast.Value);
    end;
}