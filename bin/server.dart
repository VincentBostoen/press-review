import 'dart:core';
import 'dart:io';
import 'press_review.dart';

final HOST = '127.0.0.1';
final PORT = 4040;

void main() {
  HttpServer.bind(HOST, PORT).then(gotMessage, onError: printError);
}

void gotMessage(_server) {
  _server.listen((HttpRequest request) {
    switch (request.method) {
      case 'GET': 
        handleGet(request);
        break;
      case 'OPTIONS': 
        handleOptions(request);
        break;
      default: defaultHandler(request);
    }
  },
  onError: printError); // .listen failed
  print('Listening for GET and POST on http://$HOST:$PORT');
}

void handleGet(HttpRequest req) {
  HttpResponse res = req.response;
  print('${req.method}: ${req.uri.path}');
  addCorsHeaders(res);

  res.headers.contentType = new ContentType("application", "json", charset: "utf-8");
  
  generatePressReview().then((pressReview){
      res.write(pressReview);
      res.close();    
  });
}

void addCorsHeaders(HttpResponse res) {
  res.headers.add('Access-Control-Allow-Origin', '*');
  res.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.headers.add('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
}

void handleOptions(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  print('${req.method}: ${req.uri.path}');
  res.statusCode = HttpStatus.NO_CONTENT;
  res.close();
}

void defaultHandler(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  res.statusCode = HttpStatus.NOT_FOUND;
  res.write('Not found: ${req.method}, ${req.uri.path}');
  res.close();
}

void printError(error) => print(error);