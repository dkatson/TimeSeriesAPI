pageextension 50110 "Item List Extension" extends "Item List"
{
    actions
    {
        addlast(Item)
        {
            action(MonthlyForecast)
            {
                Caption = 'Get Monthly Sales Forecast';
                Image = Forecast;
                ApplicationArea = All;

                trigger OnAction();
                var
                    MLForecast: Codeunit "Machine Learning Forecast";
                begin
                    Message('Monthly sales forecast: %1',
                        MLForecast.CalculateForecast(Rec));
                end;
            }
        }
    }
}