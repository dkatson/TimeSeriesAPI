page 50101 "Data Preparation"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
        }
    }

    actions
    {
        area(Processing)
        {
            action(PrepareData)
            {
                Caption = 'Prepare Data';
                Image = DataEntry;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Codeunit.Run(50101);
                end;
            }
        }
    }
}