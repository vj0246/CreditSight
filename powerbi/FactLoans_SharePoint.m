// Create a Text parameter named SharePointSiteUrl before pasting this into a
// blank query named financial_loan. Use the site URL, not a file-sharing link.
let
    Files = SharePoint.Files(SharePointSiteUrl, [ApiVersion = 15]),
    Matches = Table.SelectRows(
        Files,
        each [Name] = "financial_loan_clean.csv" and [Extension] = ".csv"
    ),
    FileCount = Table.RowCount(Matches),
    FileContent = if FileCount = 1 then Matches{0}[Content]
        else error Error.Record(
            "Source file count",
            "Expected exactly one financial_loan_clean.csv in this SharePoint site.",
            FileCount
        ),
    Csv = Csv.Document(
        FileContent,
        [Delimiter = ",", Columns = 16, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Headers = Table.PromoteHeaders(Csv, [PromoteAllScalars = true]),
    Typed = Table.TransformColumnTypes(Headers, {
        {"loan_record_key", type text},
        {"issue_date", type date},
        {"loan_status", type text},
        {"grade", type text},
        {"sub_grade", type text},
        {"purpose", type text},
        {"home_ownership", type text},
        {"annual_income", type number},
        {"dti", type number},
        {"int_rate", type number},
        {"loan_amount", Int64.Type},
        {"funded_amount", Int64.Type},
        {"total_payment", Currency.Type},
        {"term", type text},
        {"emp_length", type text},
        {"address_state", type text}
    }, "en-US"),
    WithDTIBand = Table.AddColumn(
        Typed,
        "DTIBand",
        each if [dti] = null then "Unknown"
            else if [dti] < 0.10 then "Low: <10%"
            else if [dti] < 0.20 then "Medium: 10-<20%"
            else "High: >=20%",
        type text
    )
in
    WithDTIBand
