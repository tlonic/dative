define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
], ( $, _, Backbone, JST, BaseView) ->

  # Progress Widget View
  # --------------------
  #
  # Displays spinning ball and flashes messages when events occur.

  class ProgressWidgetView extends BaseView

    template: JST['app/scripts/templates/progress-widget.ejs']
    spinnerId: '#progress-widget-spinner'

    initialize: ->
      @tasks = {}
      @listenTo Backbone, 'longTask:register', @registerTask
      @listenTo Backbone, 'longTask:deregister', @deregisterTask

    registerTask: (taskName, taskId) ->
      @tasks[taskId] = taskName
      @$el.show()
      @spin()
      @refreshTaskDescriptions()

    deregisterTask: (taskId) ->
      delete @tasks[taskId]
      if Object.keys(@tasks).length is 0
        @stop()
        @$el.hide()

    refreshTaskDescriptions: ->
      tasksList = @$('.progress-widget-tasks ul')
      tasksList.empty()
      for taskId, taskName of @tasks
        tasksList.append "<li>#{taskName}</li>"

    render: ->
      @$el.html(@template()).hide()

    # Make the shadow border of the progress widget pulsate
    pulsate: ->
      @$('.progress-widget').addClass('pulse1')
      f = =>
        @$('.progress-widget').toggleClass 'pulse2'
      setInterval f, 500

    # Options for spin.js, cf. http://fgnass.github.io/spin.js/
    spinnerOptions:
      lines: 13 # The number of lines to draw
      length: 15 # The length of each line
      width: 2 # The line thickness
      radius: 10 # The radius of the inner circle
      corners: 1 # Corner roundness (0..1)
      rotate: 0 # The rotation offset
      direction: 1 # 1: clockwise -1: counterclockwise
      color: 'white' #'#000' # #rgb or #rrggbb or array of colors
      speed: 2.2 # Rounds per second
      trail: 60 # Afterglow percentage
      shadow: false # Whether to render a shadow
      hwaccel: false # Whether to use hardware acceleration
      className: 'spinner' # The CSS class to assign to the spinner
      zIndex: 2e9 # The z-index (defaults to 2000000000)
      top: '50px'
      #top: '50%' # Top position relative to parent
      #left: '50%' # Left position relative to parent

    spin: ->
      @$(@spinnerId).spin @spinnerOptions

    stop: ->
      @$(@spinnerId).spin false

