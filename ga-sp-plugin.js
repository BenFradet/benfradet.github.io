function GaSpPlugin(tracker, config) {
  this.endpoint = config.endpoint;
  console.log('ga sp plugin loaded, sending stuff to: ' + this.endpoint);

  var ga = getGA();
  var sht = 'sendHitTask';
  ga(function(tracker) {
    var originalSht = tracker.get(sht);
    tracker.set(sht, function(model) {
      var payload = model.get('hitPayload');
      originalSht(model);
      console.log('sending ' + payload);
      //var request = new XMLHttpRequest();
      //request.open('get', endpoint + '?' + payload, true);
      //request.send();
    });
  });
}

function providePlugin(pluginName, pluginConstructor) {
  var ga = getGA();
  if (typeof ga == 'function') {
    ga('provide', pluginName, pluginConstructor);
  }
}

function getGA() {
  return window[window['GoogleAnalyticsObject'] || 'ga'];
}

providePlugin('gaSpPlugin', GaSpPlugin);

// use with:
// <script>
// // usual isogram
// ga('create', 'UA-XXXXX-Y', 'auto');
// ga('require', 'gaSpPlugin', { endpoint: 'https://something-else-than.ga/collect' });
// ga('send', 'pageView');
// </script>
// <scipt async src="ga-sp-plugin.js"></script>
