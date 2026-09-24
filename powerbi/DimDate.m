// Create as a blank query named DimDate after financial_loan[issue_date] is typed as Date.
let
    IssueDates = List.RemoveNulls(financial_loan[issue_date]),
    StartDate = Date.StartOfYear(List.Min(IssueDates)),
    EndDate = Date.EndOfYear(List.Max(IssueDates)),
    Dates = List.Dates(
        StartDate,
        Duration.Days(EndDate - StartDate) + 1,
        #duration(1, 0, 0, 0)
    ),
    DateTable = Table.FromList(Dates, Splitter.SplitByNothing(), {"Date"}),
    Typed = Table.TransformColumnTypes(DateTable, {{"Date", type date}}),
    WithYear = Table.AddColumn(Typed, "Year", each Date.Year([Date]), Int64.Type),
    WithQuarter = Table.AddColumn(
        WithYear, "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text
    ),
    WithMonthNumber = Table.AddColumn(
        WithQuarter, "MonthNumber", each Date.Month([Date]), Int64.Type
    ),
    WithYearMonth = Table.AddColumn(
        WithMonthNumber, "YearMonth", each [Year] * 100 + [MonthNumber], Int64.Type
    ),
    WithMonthLabel = Table.AddColumn(
        WithYearMonth, "MonthYear", each Date.ToText([Date], "MMM yyyy", "en-US"), type text
    )
in
    WithMonthLabel
