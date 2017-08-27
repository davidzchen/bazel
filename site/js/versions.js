---
---

var versions = [
{% for version in site.data.versions %}
  "{{ version }}",
{% endfor %}
];

$(function() {
  for (var i = 0; i < versions.length; i++) {
    $('#versions-menu-items').append(
        $('<li></li>').html(
            '<a href="/versions/' + versions[i] + '">' + versions[i] + '</a>'));
  }
});
