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
                Promoted = true;
                PromotedCategory = Category4;
                ApplicationArea = All;

                trigger OnAction();
                var
                    MLForecast: Codeunit "Machine Learning Forecast";
                begin
                    Message('Monthly sales forecast: %1 %2',
                        MLForecast.CalculateForecast(Rec),
                        Rec."Base Unit of Measure");
                end;
            }
        }
    }
}