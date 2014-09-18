import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:convert';
import 'feed_entry.dart';

HttpRequest request;

@CustomTag('press-review')
class PressReview extends PolymerElement {
  List<FeedEntry> feedEntries = new List();
  @observable Map<String, List<FeedEntry>> entriesByCategory = new Map();
  
  HttpRequest request;
  
  PressReview.created() : super.created() {
    request = new HttpRequest();
    request.onReadyStateChange.listen(onData); 
    var url = 'http://127.0.0.1:4040';
    request.open('GET', url);
    request.send();
  }
  
void onData(_) {
  if (request.readyState == HttpRequest.DONE &&
      request.status == 200) {
    List data = JSON.decode(request.responseText);
    
    data.forEach((item) {
      feedEntries.add(new FeedEntry()
                          ..title = item['title']
                          ..category = item['category']
                          ..link = item['link']);
    });
    
    entriesByCategory = new Map.fromIterable(feedEntries, key: (item) => item.category, value: (item) => feedEntries.where((entry) => entry.category == item.category));
    entriesByCategory = toObservable(entriesByCategory);
      
  } else if (request.readyState == HttpRequest.DONE &&
      request.status == 0) {
    document.body.text = 'No server';
  }
}
}