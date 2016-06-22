{% if theme.fancybox %}
  <script type="text/javascript" src="http://apps.bdimg.com/libs/fancybox/2.1.5/jquery.fancybox.pack.js"></script>
  <script type="text/javascript" src="{{ url_for(theme.js) }}/fancy-box.js?v={{ theme.version }}"></script>
{% endif %}
