String get apiHost {
  bool isProd = const bool.fromEnvironment('dart.vm.product');
  if (isProd) {
    return 'https://api.restall.it';
    // replace with your production API endpoint
  }

  //return "http://localhost:5000";
  return 'https://api.restall.it';
  // replace with your own development API endpoint
}
