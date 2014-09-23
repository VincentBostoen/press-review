import 'package:http/http.dart' as http;
import 'package:jsonx/jsonx.dart' as jsonx;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'feed_entry.dart';

final String spreadsheet_columns = "groupe, article, url, dart-ʕ̮ʔ";
final String spreadsheetKey = "";
final String spreadsheet_json_feed_url = "https://spreadsheets.google.com/feeds/list/SPREADSHEET_KEY/ocx/public/basic?alt=json";

List<String> columns;
String spreadsheetFeedUrl = spreadsheet_json_feed_url.replaceAll("SPREADSHEET_KEY", spreadsheetKey);

Future<String> generatePressReview() {
  var completer = new Completer();
  
  fetchSpreadsheetContent().then((content) {
    List<FeedEntry> feedEntries = parseFeedContent(content);
    
    print("-- Parsed enties : --");
    logFeedEntries(feedEntries);
    
    List<FeedEntry> filteredEntries = filterEntries(feedEntries);
    
    print("-- Filtered enties : --");
    logFeedEntries(filteredEntries);
    
    completer.complete(jsonx.encode(filteredEntries));
  });
  
  return completer.future;
}

List<FeedEntry> filterEntries(List<FeedEntry> feedEntries) {
  return feedEntries.where((FeedEntry entry) => entry.destination != null && entry.destination.startsWith("Revue de presse")).toList(); 
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
    
    int categoryStartIndex = entryContent.contains(columns[0]) ? entryContent.indexOf(columns[0]) + columns[0].length + 2 : 0;
    int titleStartIndex = entryContent.contains(columns[0]) ? entryContent.indexOf(", ${columns[1]}: ") + columns[1].length + 4 : entryContent.indexOf("${columns[1]}:") + columns[1].length + 2 ;
    int linkStartIndex = entryContent.indexOf(", ${columns[2]}: ") + columns[2].length + 4;
    
    int destinationEndIndex = entryContent.lastIndexOf(", ") > entryContent.indexOf(", ${columns[3]}") ? entryContent.lastIndexOf(", ") : entryContent.length;
    int destinationStartIndex = entryContent.contains(columns[3]) ? entryContent.indexOf(", ${columns[3]}"): destinationEndIndex;
    
    String category = entryContent.contains("${columns[0]}: ") ? entryContent.substring(categoryStartIndex, entryContent.indexOf(", ${columns[1]}: ")) : "Autre";
    String title = entryContent.substring(titleStartIndex, entryContent.indexOf(", ${columns[2]}: "));
    String link = entryContent.substring(linkStartIndex, destinationStartIndex);
    String destination = entryContent.contains(columns[3]) ? entryContent.substring(destinationStartIndex + columns[3].length + 4, destinationEndIndex) : "Aucune";
        
    feedEntries.add(new FeedEntry()
                              ..title = title
                              ..link = link
                              ..category = category
                              ..destination = destination);
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
