function handler(event) {
  var request = event.request;
  var host = request.headers.host && request.headers.host.value;

  if (host === "www.frankidugboe.com") {
    var queryParts = [];
    var querystring = request.querystring || {};

    Object.keys(querystring).forEach(function (key) {
      var parameter = querystring[key];

      if (parameter.multiValue) {
        parameter.multiValue.forEach(function (item) {
          queryParts.push(
            encodeURIComponent(key) + "=" + encodeURIComponent(item.value)
          );
        });
      } else {
        queryParts.push(
          encodeURIComponent(key) + "=" + encodeURIComponent(parameter.value || "")
        );
      }
    });

    var location = "https://frankidugboe.com" + request.uri;

    if (queryParts.length > 0) {
      location += "?" + queryParts.join("&");
    }

    return {
      statusCode: 301,
      statusDescription: "Moved Permanently",
      headers: {
        location: {
          value: location,
        },
      },
    };
  }

  var uri = request.uri;

  if (uri.endsWith("/")) {
    request.uri = uri + "index.html";
  } else if (!uri.includes(".")) {
    request.uri = uri + "/index.html";
  }

  return request;
}
