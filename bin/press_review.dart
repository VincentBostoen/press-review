import 'package:http/http.dart' as http;
import 'package:jsonx/jsonx.dart' as jsonx;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'feed_entry.dart';

final String spreadsheet_columns = "article, url, section";
final String spreadsheetKey = "SPREADSHEET_KEY_HERE!!!";
final String spreadsheet_json_feed_url = "https://spreadsheets.google.com/feeds/list/SPREADSHEET_KEY/ocx/public/basic?alt=json";

List<String> columns;
String spreadsheetFeedUrl = spreadsheet_json_feed_url.replaceAll("SPREADSHEET_KEY", spreadsheetKey);

Future<String> generatePressReview() {
  var completer = new Completer();
  
  fetchSpreadsheetContent().then((content) {
    List<FeedEntry> feedEntries = parseFeedContent(content);
    logFeedEntries(feedEntries);
    completer.complete(jsonx.encode(feedEntries));
  });
  
  return completer.future;
}

Future<String> fetchSpreadsheetContent() {
  var completer = new Completer();
   columns = spreadsheet_columns.split(", ");
   
   print("Welcome to the press review");
   print("We will fetch $spreadsheetFeedUrl \n");
   
   http.get(spreadsheetFeedUrl).then((response) {
     completer.complete(response.body);
   });
   return completer.future;
}

List<FeedEntry> parseFeedContent(String feedContent) {
  
  List<FeedEntry> feedEntries = new List();
  
  Map<String,String> datas = JSON.decode(feedContent);
  
  for(Map entry in datas["feed"]["entry"]){
    String entryContent = entry["content"]["\$t"];
    
    int titleStartIndex = entryContent.indexOf(columns[0]) + columns[0].length + 2;
    int linkStartIndex = entryContent.indexOf(", ${columns[1]}: ") + columns[1].length + 4;
    int categoryStartIndex = entryContent.indexOf(", ${columns[2]}: ") + columns[2].length + 4;
    
    String title = entryContent.substring(titleStartIndex, entryContent.indexOf(", ${columns[1]}: "));
    String link = entryContent.contains(", ${columns[2]}: ") ? entryContent.substring(linkStartIndex, entryContent.indexOf(", ${columns[2]}: ")) : entryContent.substring(linkStartIndex);
    String category = entryContent.contains(", ${columns[2]}: ") ? entryContent.substring(categoryStartIndex) : "Autre";
    
    feedEntries.add(new FeedEntry()
                              ..title = title
                              ..link = link
                              ..category = category);
  }

  print("Parsed ${feedEntries.length} entries");
  return feedEntries;
}

void logFeedEntries(List<FeedEntry> feedEntries) {
  Map<String, List<FeedEntry>> entriesByCategory = new Map.fromIterable(feedEntries, key: (item) => item.category, value: (item) => feedEntries.where((entry) => entry.category == item.category));
  String postContent = "";
  
  entriesByCategory.keys.forEach((title) { 
    postContent += "\n*$title :*";
    entriesByCategory[title].forEach((postEntry) => postContent += postEntry.toString() + "\n");
  });
  
  print(postContent);
}
