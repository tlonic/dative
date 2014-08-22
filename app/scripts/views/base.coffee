define [
  'jquery'
  'lodash'
  'backbone'
  'utils/utils'
], ($, _, Backbone, utils) ->

  # Base View
  # --------------
  #
  # This is the view that all Dative views should inherit from.
  #
  # The class attribute jQueryUIColors contains all of the color information to
  # match the jQueryUI theme currently in use.
  #
  # The other functionality is from
  # http://blog.shinetech.com/2012/10/10/efficient-stateful-views-with-backbone-js-part-1/ and
  # http://lostechies.com/derickbailey/2011/09/15/zombies-run-managing-page-transitions-in-backbone-apps/
  # It helps in the creation of Backbone views that can keep track of the
  # subviews that they have rendered and can close them appropriately to
  # avoid zombies and memory leaks.

  class BaseView extends Backbone.View

    @debugMode: false

    # Class attribute that holds the jQueryUI colors of the jQueryUI theme
    # currently in use.
    @jQueryUIColors: $.getJQueryUIColors()

    # TODO: figure out where/how to store/persist user settings
    @userSettings:
      formItemsPerPage: 10

    trim: (string) ->
      console.log 'in trim!'
      console.log "got |#{string}|"
      string.replace /^\s+|\s+$/g, ''
      console.log "returning |#{string}|"
      string

    snake2camel: (string) ->
      string.replace(/(_[a-z])/g, ($1) ->
        $1.toUpperCase().replace('_',''))

    camel2snake: (string) ->
      string.replace(/([A-Z])/g, ($1) ->
        "_#{$1.toLowerCase()}")

    # Cleanly closes this view and all of it's rendered subviews
    close: ->
      @$el.empty()
      @undelegateEvents()
      if @_renderedSubViews?
        for renderedSubView in @_renderedSubViews
          renderedSubView.close()
      @onClose?()

    # Registers a subview as having been rendered by this view
    rendered: (subView) ->
      if not @_renderedSubViews?
        @_renderedSubViews = []
        console.log '@_renderedSubViews initialized'
        console.log @_renderedSubViews
      if subView not in @_renderedSubViews
        @_renderedSubViews.push subView
      return subView

    # Deregisters a subview that has been manually closed by this view
    closed: (subView) ->
      console.log '@_renderedSubViews after a closed call'
      console.log @_renderedSubViews
      #@_renderedSubViews = _(@_renderedSubViews).without subView
      @_renderedSubViews = _.without @_renderedSubViews, subView

    # Show Spinner Indicator (http://www.ajaxload.info/)
    showSpinner: ->
      $('body').append($('<img>')
        .attr('src': 'images/ajax-loader.gif', 'id': 'spinner'))

    hideSpinner: ->
      $('#spinner').remove()

    guid: utils.guid

