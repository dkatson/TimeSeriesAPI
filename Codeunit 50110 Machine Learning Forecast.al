codeunit 50110 "Machine Learning Forecast"
{
    procedure CalculateForecast(Item: Record Item): Decimal;
    var
        MLForecastSetup: Record "ML Forecast Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        Date: Record Date;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        TimeSeriesManagement: Codeunit "Time Series Management";
    begin
        MLForecastSetup.Get();
        TimeSeriesManagement.Initialize(
            MLForecastSetup."Endpoint URI", MLForecastSetup."API Key",
            0, false);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);

        TimeSeriesManagement.PrepareData(
            ItemLedgerEntry,
            ItemLedgerEntry.FieldNo("Item No."),
            ItemLedgerEntry.FieldNo("Posting Date"),
            ItemLedgerEntry.FieldNo(Quantity),
            Date."Period Type"::Month,
            WorkDate,
            12);

        TimeSeriesManagement.GetPreparedData(TempTimeSeriesBuffer);
        if TempTimeSeriesBuffer.FindSet() then
            repeat
                TempTimeSeriesBuffer.Value := -TempTimeSeriesBuffer.Value;
                TempTimeSeriesBuffer.Modify();
            until TempTimeSeriesBuffer.Next() = 0;

        TimeSeriesManagement.Forecast(1, 0, 0);
        TimeSeriesManagement.GetForecast(TempTimeSeriesForecast);
        if TempTimeSeriesForecast.FindFirst() then
            exit(TempTimeSeriesForecast.Value);
    end;

    procedure CalculateForecastBulk(
        ItemNoFilter: Text;
        PeriodType: Option Date,Week,Month,Quarter,Year;
        NumberOfForecastPeriods: Integer;
        NumberOfPastPeriods: Integer;
        ConfidenceLevel: Integer;
        ForecastAlgorithm: Option ARIMA,ETS,STL,"ETS+ARIMA","ETS+STL",ALL;
        var TempTimeSeriesForecast: Record "Time Series Forecast" temporary);
    var
        MLForecastSetup: Record "ML Forecast Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempTimeSeriesForecast2: Record "Time Series Forecast" temporary;
        TimeSeriesManagement: Codeunit "Time Series Management";
    begin
        if not TempTimeSeriesForecast.IsTemporary() then
            Error('TempTimeSeriesForecast must be temporary.');

        MLForecastSetup.Get();
        TimeSeriesManagement.Initialize(
            MLForecastSetup."Endpoint URI", MLForecastSetup."API Key",
            0, false);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetFilter("Item No.", ItemNoFilter);

        TimeSeriesManagement.PrepareData(
           ItemLedgerEntry,
           ItemLedgerEntry.FieldNo("Item No."),
           ItemLedgerEntry.FieldNo("Posting Date"),
           ItemLedgerEntry.FieldNo(Quantity),
           PeriodType,
           WorkDate,
           NumberOfPastPeriods);

        TimeSeriesManagement.Forecast(
            NumberOfForecastPeriods,
            ConfidenceLevel,
            ForecastAlgorithm);
        TimeSeriesManagement.GetForecast(TempTimeSeriesForecast2);

        TempTimeSeriesForecast.Reset();
        TempTimeSeriesForecast.DeleteAll();
        if TempTimeSeriesForecast2.FindSet() then
            repeat
                TempTimeSeriesForecast := TempTimeSeriesForecast2;
                TempTimeSeriesForecast.Insert();
            until TempTimeSeriesForecast2.Next() = 0;
    end;

    procedure CreatePurchaseOrder(var TempTimeSeriesForecast: Record "Time Series Forecast"; QualityBar: Decimal; VendorNo: Code[20]);
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        TempTimeSeriesForecast.SetFilter(Value, '<>0');
        if TempTimeSeriesForecast.FindSet() then begin
            PurchHeader.Validate("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
            PurchHeader.Insert(true);

            repeat
                if (TempTimeSeriesForecast."Delta %" <= QualityBar) or (QualityBar = 0) then begin
                    PurchLine.Init();
                    PurchLine.Validate("Document Type", PurchHeader."Document Type");
                    PurchLine.Validate("Document No.", PurchHeader."No.");
                    PurchLine.Validate("Line No.", PurchLine."Line No." + 10000);
                    PurchLine.Validate(Type, PurchLine.Type::Item);
                    PurchLine.Validate("No.", TempTimeSeriesForecast."Group ID");
                    PurchLine.Validate(Quantity,
                        Round(-TempTimeSeriesForecast.Value, 1));
                    PurchLine.Insert(true);
                end;
            until TempTimeSeriesForecast.Next() = 0;
            Page.Run(Page::"Purchase Order", PurchHeader);
        end;
    end;
}