section Section1;

shared getJsonFromFacebook = let
    Source = List.Buffer(getGroupDataFunction(tokenParam, groupIDParam)),
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
in
    #"Converted to Table";

shared posts = let
    Source = getJsonFromFacebook,
    #"Expanded Column1" = Table.ExpandRecordColumn(Source, "Column1", {"from", "story", "created_time", "id", "updated_time", "likes", "message", "to", "picture", "link", "name", "caption", "comments", "reactions", "shares"}, {"from", "story", "created_time", "post id", "updated_time", "likes", "message", "to", "picture", "link", "name", "caption", "comments", "reactions", "shares"}),
    #"Added Custom" = Table.AddColumn(#"Expanded Column1", "group", each "sem.russia"),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "typeOfRow", each "post"),
    #"Expanded from" = Table.ExpandRecordColumn(#"Added Custom1", "from", {"name", "id"}, {"author name", "author id"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded from",{"to", "comments"}),
    #"Inserted Parsed Date" = Table.AddColumn(#"Removed Columns", "ParseDate", each Date.From(DateTimeZone.From([created_time])), type date),
    #"Inserted Parsed Time" = Table.AddColumn(#"Inserted Parsed Date", "ParseTime", each Time.From(DateTimeZone.From([created_time])), type time)
in
    #"Inserted Parsed Time";

shared comments_1 = let
    Source = getJsonFromFacebook,
    #"Expanded Column1" = Table.ExpandRecordColumn(Source, "Column1", {"id", "comments"}, {"post id", "comments"}),
    #"Expanded comments" = Table.ExpandRecordColumn(#"Expanded Column1", "comments", {"data"}, {"data"}),
    #"Expanded data" = Table.ExpandListColumn(#"Expanded comments", "data"),
    #"Expanded data1" = Table.ExpandRecordColumn(#"Expanded data", "data", {"message", "from", "id", "created_time", "comments", "likes"}, {"message", "data.from", "comment id", "data.created_time", "data.comments", "likes"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded data1", each [comment id] <> null),
    #"Expanded data.from" = Table.ExpandRecordColumn(#"Filtered Rows", "data.from", {"name", "id"}, {"author name", "author id"}),
    #"Reordered Columns" = Table.ReorderColumns(#"Expanded data.from",{"post id", "comment id", "message", "author name", "author id", "data.created_time", "data.comments", "likes"}),
    #"Added Custom" = Table.AddColumn(#"Reordered Columns", "typeOfRow", each "comment"),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "commentLevel", each "1"),
    #"Inserted Parsed Date" = Table.AddColumn(#"Added Custom1", "ParseDate", each Date.From(DateTimeZone.From([data.created_time])), type date),
    #"Inserted Parsed Time" = Table.AddColumn(#"Inserted Parsed Date", "ParseTime", each Time.From(DateTimeZone.From([data.created_time])), type time),
    #"Renamed Columns" = Table.RenameColumns(#"Inserted Parsed Time",{{"data.created_time", "created_time"}})
in
    #"Renamed Columns";

shared comments_2 = let
    Source = getJsonFromFacebook,
    #"Expanded Column1" = Table.ExpandRecordColumn(Source, "Column1", {"id", "comments"}, {"post id", "comments"}),
    #"Expanded comments" = Table.ExpandRecordColumn(#"Expanded Column1", "comments", {"data"}, {"data"}),
    #"Expanded data" = Table.ExpandListColumn(#"Expanded comments", "data"),
    #"Expanded data1" = Table.ExpandRecordColumn(#"Expanded data", "data", {"id", "comments"}, {"comment id", "data.comments"}),
    Custom1 = Table.SelectRows(#"Expanded data1", each [data.comments] <> null),
    #"Added Custom" = Table.AddColumn(Custom1, "typeOfRow", each "comment"),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "commentLevel", each "2"),
    #"Expanded data.comments" = Table.ExpandRecordColumn(#"Added Custom1", "data.comments", {"data"}, {"data"}),
    #"Expanded data2" = Table.ExpandListColumn(#"Expanded data.comments", "data"),
    #"Expanded data3" = Table.ExpandRecordColumn(#"Expanded data2", "data", {"message", "from", "likes", "id", "created_time"}, {"message", "from", "likes", "comment id2", "created_time"}),
    #"Reordered Columns" = Table.ReorderColumns(#"Expanded data3",{"post id", "comment id", "comment id2", "message", "from", "likes", "typeOfRow"}),
    #"Expanded from" = Table.ExpandRecordColumn(#"Reordered Columns", "from", {"name", "id"}, {"author name", "author id"}),
    Custom2 = Table.AddColumn(#"Expanded from", "ParseDate", each Date.From(DateTimeZone.From([created_time])), type date),
    Custom3 = Table.AddColumn(Custom2 , "ParseTime", each Time.From(DateTimeZone.From([created_time])), type time)
in
    Custom3;

shared groupsAndTheirIds = let
    Source = getGroups(tokenParam),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"id", Int64.Type}}),
    #"Sorted Rows" = Table.Sort(#"Changed Type",{{"id", Order.Descending}})
in
    #"Sorted Rows";

shared bigFeedAndCommentsTable = let
    Source = Table.Combine({posts,comments_1,comments_2}),
    #"Removed Columns" = Table.RemoveColumns(Source,{"data.comments"}),
    #"Reordered Columns" = Table.ReorderColumns(#"Removed Columns",{"post id", "comment id", "comment id2", "author name", "author id", "story", "created_time", "updated_time", "message", "picture", "link", "name", "caption", "group", "typeOfRow", "ParseDate", "ParseTime", "commentLevel", "likes"}),
    #"Changed Type3" = Table.TransformColumnTypes(#"Reordered Columns",{{"created_time", type datetimezone}}),
    #"Sorted Rows1" = Table.Sort(#"Changed Type3",{{"created_time", Order.Ascending}}),
    #"Inserted Merged Column" = Table.AddColumn(#"Sorted Rows1", "idOfRow", each Text.Combine({[post id], Text.From([comment id], "en-US"), Text.From([comment id2], "en-US")}, "_"), type text),
    #"Changed Type" = Table.TransformColumnTypes(#"Inserted Merged Column",{{"created_time", type datetime}, {"updated_time", type datetime}}),
    #"Removed Columns1" = Table.RemoveColumns(#"Changed Type",{"likes", "reactions"}),
    #"Expanded shares" = Table.ExpandRecordColumn(#"Removed Columns1", "shares", {"count"}, {"shares.count"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Expanded shares",{{"shares.count", Int64.Type}}),
    #"Inserted Merged Column1" = Table.AddColumn(#"Changed Type1", "message1", each Text.Combine({[message], [story],
Text.From([link], "ru-RU")}, "
"), type text),
    #"Removed Columns3" = Table.RemoveColumns(#"Inserted Merged Column1",{"message"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Removed Columns3",{{"message1", "message"}}),
    #"Added Index" = Table.AddIndexColumn(#"Renamed Columns1", "Index", 0, 1),
    #"Renamed Columns" = Table.RenameColumns(#"Added Index",{{"author name", "person name"}, {"author id", "person id"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "url", each Text.Combine({"https://www.facebook.com/" & [post id], "?comment_id=" & [comment id], "&reply_comment_id=" & [comment id2]}, "")),
    #"Filtered Rows" = Table.SelectRows(#"Added Custom", each ([person id] <> null)),
    #"Changed Type2" = Table.TransformColumnTypes(#"Filtered Rows",{{"idOfRow", type text}})
in
    #"Changed Type2";

shared bigLikesTable = let
    Source = Table.Combine({posts,comments_1,comments_2}),
    #"Removed Columns" = Table.RemoveColumns(Source,{"data.comments"}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Removed Columns",{{"created_time", type datetimezone}}),
    #"Sorted Rows" = Table.Sort(#"Changed Type2",{{"ParseDate", Order.Ascending}}),
    #"Reordered Columns" = Table.ReorderColumns(#"Sorted Rows",{"post id", "comment id", "comment id2", "author name", "author id", "story", "created_time", "updated_time", "message", "picture", "link", "name", "caption", "group", "typeOfRow", "ParseDate", "ParseTime", "commentLevel"}),
    #"Inserted Merged Column" = Table.AddColumn(#"Reordered Columns", "idOfRow", each Text.Combine({[post id], Text.From([comment id], "en-US"), Text.From([comment id2], "en-US")}, "_"), type text),
    #"Removed Columns1" = Table.RemoveColumns(#"Inserted Merged Column",{"post id", "comment id", "comment id2", "story", "updated_time", "message", "picture", "link", "name", "caption", "group", "typeOfRow", "commentLevel", "shares"}),
    Custom1 = Table.SelectRows(#"Removed Columns1", each [likes] <> null),
    #"Changed Type" = Table.TransformColumnTypes(Custom1,{{"created_time", type datetime}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type", "Custom", each if [likes]=null then {} else List.Transform([likes][data], each Record.AddField(_, "type", "LIKE"))),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "Custom.1", each [reactions][data]?),
    #"Added Custom2" = Table.AddColumn(#"Added Custom1", "Custom.2", each List.Distinct(List.Combine({if [Custom.1] = null then {} else [Custom.1], [Custom]}))),
    #"Removed Columns2" = Table.RemoveColumns(#"Added Custom2",{"likes", "reactions", "Custom", "Custom.1"}),
    #"Expanded Custom.2" = Table.ExpandListColumn(#"Removed Columns2", "Custom.2"),
    #"Expanded Custom.1" = Table.ExpandRecordColumn(#"Expanded Custom.2", "Custom.2", {"id", "name", "type"}, {"id", "name", "type"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded Custom.1",{{"type", "typeOfRow"}, {"id", "person id"}, {"name", "person name"}}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Renamed Columns",{{"idOfRow", type text}}),
    #"Filtered Rows" = Table.SelectRows(#"Changed Type1", each ([person id] <> [author id]))
in
    #"Filtered Rows";

shared dateTable = let CreateDateTable = (StartDate as date, EndDate as date, optional Culture as nullable text) as table =>
  let
    DayCount = Duration.Days(Duration.From(EndDate - StartDate)),
    Source = List.Dates(StartDate,DayCount,#duration(1,0,0,0)),
    TableFromList = Table.FromList(Source, Splitter.SplitByNothing()),    
    ChangedType = Table.TransformColumnTypes(TableFromList,{{"Column1", type date}}),
    RenamedColumns = Table.RenameColumns(ChangedType,{{"Column1", "Date"}}),
    InsertYear = Table.AddColumn(RenamedColumns, "Year", each Date.Year([Date])),
    InsertQuarter = Table.AddColumn(InsertYear, "QuarterOfYear", each Date.QuarterOfYear([Date])),
    InsertMonth = Table.AddColumn(InsertQuarter, "MonthOfYear", each Date.Month([Date])),
    InsertDay = Table.AddColumn(InsertMonth, "DayOfMonth", each Date.Day([Date])),
    InsertDayInt = Table.AddColumn(InsertDay, "DateInt", each [Year] * 10000 + [MonthOfYear] * 100 + [DayOfMonth]),
    InsertMonthName = Table.AddColumn(InsertDayInt, "MonthName", each Date.ToText([Date], "MMMM", Culture), type text),
    InsertCalendarMonth = Table.AddColumn(InsertMonthName, "MonthInCalendar", each (try(Text.Range([MonthName],0,3)) otherwise [MonthName]) & " " & Number.ToText([Year])),
    InsertCalendarQtr = Table.AddColumn(InsertCalendarMonth, "QuarterInCalendar", each "Q" & Number.ToText([QuarterOfYear]) & " " & Number.ToText([Year])),
    InsertDayWeek = Table.AddColumn(InsertCalendarQtr, "DayInWeek", each Date.DayOfWeek([Date])),
    InsertDayName = Table.AddColumn(InsertDayWeek, "DayOfWeekName", each Date.ToText([Date], "dddd", Culture), type text),
    InsertWeekEnding = Table.AddColumn(InsertDayName, "WeekEnding", each Date.EndOfWeek([Date]), type date)    
  in
    InsertWeekEnding,

    #"Invoked FunctionCreateDateTable" = CreateDateTable(#date(2015, 5, 1), Date.From(DateTime.LocalNow()), null),
    #"Added Index" = Table.AddIndexColumn(#"Invoked FunctionCreateDateTable", "Index", 1, 1),
    #"Inserted Start of Month" = Table.AddColumn(#"Added Index", "StartOfMonth", each Date.StartOfMonth([Date]), type date),
    #"Sorted Rows" = Table.Sort(#"Inserted Start of Month",{{"Date", Order.Descending}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Sorted Rows",{{"Year", Int64.Type}, {"QuarterOfYear", Int64.Type}, {"MonthOfYear", Int64.Type}, {"DayOfMonth", Int64.Type}, {"DateInt", Int64.Type}, {"DayInWeek", Int64.Type}, {"Index", Int64.Type}}),
    #"Added Index1" = Table.AddIndexColumn(#"Changed Type", "daySequenceReverse", 0, -1),
    #"Inserted Integer-Division" = Table.AddColumn(#"Added Index1", "weekSequenceReverse", each Number.IntegerDivide([daySequenceReverse], 7), Int64.Type)
in
    #"Inserted Integer-Division";

shared feedOfEvents = let
    Source = Table.Combine({bigLikesTable,bigFeedAndCommentsTable}),
    #"Removed Other Columns" = Table.SelectColumns(Source,{"created_time", "ParseDate", "ParseTime", "idOfRow", "person id", "person name", "typeOfRow"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Other Columns",{{"typeOfRow", type text}, {"idOfRow", type text}})
in
    #"Changed Type";

shared activeMembersList = let
    Source = feedOfEvents,
    #"Grouped Rows" = Table.Group(Source, {"person id"}, {{"person name", each List.First([person name]), type text}, {"count of actions", each Table.RowCount(_), type number}, {"fist action", each List.Min([ParseDate]), type date}, {"last action", each List.Max([ParseDate]), type date}}),
    #"Sorted Rows" = Table.Sort(#"Grouped Rows",{{"count of actions", Order.Descending}}),
    #"Filtered Rows" = Table.SelectRows(#"Sorted Rows", each ([person id] <> null)),
    #"Inserted Start of Month" = Table.AddColumn(#"Filtered Rows", "FirstActionStartOfMonth", each Date.StartOfMonth([fist action]), type date)
in
    #"Inserted Start of Month";

shared tokenParam = "EAACEdEose0cBAJtZBa4oU2Mff0j4PRUViVcTiNNxOuL0ZAW15EziaMtqbeNHDZCJTZATbXZBZCZCwVO0q8y3zgNAZA6D9Cg3jJr3ZACx54Cxu9Iid8SZBbd98OU4eUBZBrwm3CSLSg26YqZCwS58mJ1QyJy1ZAjfEXZAXZBKpHQTZCIOpB3RbZAJvsGSMyvTeZCuZBJqZCZAykewZD" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true];

shared groupIDParam = "1385177031811951" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=false];

getGroups = let
    Source = (tokenParam as text) => let
    url = "https://graph.facebook.com/v2.7/me?fields=groups.limit(999)&access_token=" & tokenParam,
    iterrations = 9999,
    Custom2 = Json.Document(Web.Contents(url)),
        groups1 = Custom2[groups],
        data = groups1[data],
        #"Converted to Table" = Table.FromList(data, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"name", "privacy", "id"}, {"name", "privacy", "id"})
    in
        #"Expanded Column1"
in
    Source;

getGroupDataFunction = let
    Source = (tokenParam as text, groupIDParam as text) => let
 iterations = 9999,          // Number of iterations
 url = 
  "https://graph.facebook.com/v2.7/" & groupIDParam &"/feed?fields=message%2Clikes.limit(999)%2Ccomments.limit(999)%7Bmessage%2Cfrom%2Cid%2Clikes.limit(999)%2Ccomments.limit(999)%7Bmessage%2Cfrom%2Clikes.limit(999)%2Ccreated_time%7D%2Ccreated_time%7D%2Cfrom%2Cstory%2Ccreated_time%2Clink%2Creactions.limit(999)%2Cshares&access_token=" & tokenParam, // here goes your Facebook URL, Don't forget the access token
 
 FnGetOnePage =
  (url) as record =>
   let
    Source = Json.Document(Web.Contents(url)),
    data = try Source[data] otherwise null,
    next = try Source[paging][next] otherwise null,
    res = [Data=data, Next=next]
   in
    res,
 
 GeneratedList =
  List.Generate(
   ()=>[i=0, res = FnGetOnePage(url)],
   each [i]<iterations and [res][Next]<>null,
   each [i=[i]+1, res = FnGetOnePage([res][Next])],
   each [res][Data]),
    #"Converted to Table" = Table.FromList(GeneratedList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandListColumn(#"Converted to Table", "Column1"),
    Column1 = #"Expanded Column1"[Column1]
in
    Column1
in
    Source;